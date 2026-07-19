// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Pons Family — launch token implementation for https://pons.family
// Always deployed through PonsLaunchFactory (CREATE2), never standalone.

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IUniswapV3FactoryLike, IUniswapV3PoolImmutablesLike} from "./interfaces/ILaunchpad.sol";

/**
 * @title PonsLauncherToken
 * @author Pons Family
 * @notice Fixed-supply ERC-20 used by every pons.family launch.
 * @dev The factory mints the full supply to itself, seeds the Uniswap V3
 * position, then lets normal trading begin. During `restrictionBlocks`
 * we only throttle buys that come out of the paired V3 pool — transfers
 * between EOAs and LP repositioning stay unrestricted.
 */
contract PonsLauncherToken is ERC20 {
 struct Socials {
 string twitter;
 string telegram;
 string discord;
 string website;
 string farcaster;
 }

 error LaunchBlockBuyBlocked(address recipient);
 error MaxWalletExceeded(address account, uint256 balance, uint256 limit);
 error MaxTxExceeded(address recipient, uint256 attempted, uint256 limit);
 error NotLaunchFactory();
 error ZeroAddress();

 /// @notice Creator wallet recorded for the pons.family UI.
 address public immutable deployer;
 /// @notice Parent factory; only this address may flip the seed-buy exemption.
 address public immutable launchFactory;
 address public immutable dexFactory;
 address public immutable positionManager;
 address public immutable pairToken;
 uint24 public immutable poolFee;

 uint256 public immutable launchBlock;
 uint256 public immutable restrictionBlocks;
 uint256 public immutable restrictionEndBlock;
 uint16 public immutable maxWalletBps;
 uint16 public immutable maxTxBps;

 string public logo;
 string public description;

 Socials private _socials;
 // Cleared immediately after the factory finishes the optional seed buy.
 address private _initialBuyRecipient;
 // Cumulative pool->wallet buys inside the restriction window.
 mapping(address recipient => uint256 amount) private _restrictedPoolBuys;

 /**
 * @notice Creates a launch token and mints its entire supply to the factory.
 * @dev `msg.sender` must be `PonsLaunchFactory`; we store it as `launchFactory`.
 */
 constructor(
 string memory name_,
 string memory symbol_,
 string memory logo_,
 string memory description_,
 Socials memory socials_,
 address deployer_,
 address dexFactory_,
 address positionManager_,
 address pairToken_,
 uint24 poolFee_,
 uint256 supply_,
 uint16 maxWalletBps_,
 uint16 maxTxBps_,
 uint32 restrictionBlocks_
 ) ERC20(name_, symbol_) {
 if (
 deployer_ == address(0) || dexFactory_ == address(0) || positionManager_ == address(0)
 || pairToken_ == address(0)
 ) {
 revert ZeroAddress();
 }

 deployer = deployer_;
 launchFactory = msg.sender;
 dexFactory = dexFactory_;
 positionManager = positionManager_;
 pairToken = pairToken_;
 poolFee = poolFee_;
 launchBlock = block.number;
 restrictionBlocks = restrictionBlocks_;
 restrictionEndBlock = block.number + restrictionBlocks_;
 maxWalletBps = maxWalletBps_;
 maxTxBps = maxTxBps_;
 logo = logo_;
 description = description_;
 _socials = socials_;

 // Factory receives supply so it can mint the one-sided V3 position in the same tx.
 _mint(msg.sender, supply_);
 }

 /**
 * @notice Canonical V3 pool for this token / pair / fee tier.
 */
 function liquidityPool() public view returns (address) {
 return IUniswapV3FactoryLike(dexFactory).getPool(address(this), pairToken, poolFee);
 }

 /**
 * @notice Social links shown on the pons.family token page.
 */
 function socials()
 external
 view
 returns (
 string memory twitter,
 string memory telegram,
 string memory discord,
 string memory website,
 string memory farcaster
 )
 {
 Socials memory values = _socials;
 return (values.twitter, values.telegram, values.discord, values.website, values.farcaster);
 }

 /**
 * @notice Creator + metadata bundle for frontend display.
 */
 function getTokenInfo()
 external
 view
 returns (
 address tokenDeployer,
 string memory tokenLogo,
 string memory tokenDescription,
 Socials memory tokenSocials
 )
 {
 return (deployer, logo, description, _socials);
 }

 /**
 * @notice Max recipient balance during the restricted launch window.
 */
 function maxWalletLimit() public view returns (uint256) {
 return (totalSupply() * maxWalletBps) / 10_000;
 }

 /// @dev Alias kept for clients that already expect this name.
 function maxWalletAmount() external view returns (uint256) {
 return maxWalletLimit();
 }

 /**
 * @notice Cumulative pool-buy cap during the restricted window.
 */
 function maxTxLimit() public view returns (uint256) {
 return (totalSupply() * maxTxBps) / 10_000;
 }

 /// @dev Alias kept for clients that already expect this name.
 function maxTxAmount() external view returns (uint256) {
 return maxTxLimit();
 }

 /**
 * @notice Factory-only toggle for the atomic seed-buy recipient.
 */
 function setInitialBuyRecipient(address recipient) external {
 if (msg.sender != launchFactory) revert NotLaunchFactory();
 _initialBuyRecipient = recipient;
 }

 /**
 * @dev Pool sells into wallets are throttled; everything else is a normal ERC-20 transfer.
 * Same-block snipes are blocked unless the factory is mid seed-buy for `to`.
 */
 function _update(address from, address to, uint256 value) internal override {
 if (from != address(0) && to != address(0) && block.number <= restrictionEndBlock) {
 bool isRestrictedBuy = _isPairPool(from);
 if (!isRestrictedBuy) {
 super._update(from, to, value);
 return;
 }

 bool isAtomicLaunchBuy =
 block.number == launchBlock && _initialBuyRecipient != address(0) && to == _initialBuyRecipient;
 if (!isAtomicLaunchBuy && block.number == launchBlock) {
 revert LaunchBlockBuyBlocked(to);
 }

 if (!isAtomicLaunchBuy) {
 uint256 walletLimit = maxWalletLimit();
 uint256 resultingBalance = balanceOf(to) + value;
 if (resultingBalance > walletLimit) {
 revert MaxWalletExceeded(to, resultingBalance, walletLimit);
 }

 uint256 cumulative = _restrictedPoolBuys[to] + value;
 uint256 cumulativeLimit = maxTxLimit();
 if (cumulative > cumulativeLimit) {
 revert MaxTxExceeded(to, cumulative, cumulativeLimit);
 }
 _restrictedPoolBuys[to] = cumulative;
 }
 }

 super._update(from, to, value);
 }

 /**
 * @dev Treat any factory-registered pool for this pair as in-scope, even if
 * the fee tier differs from the canonical launch fee.
 */
 function _isPairPool(address candidate) private view returns (bool) {
 address canonicalPool = liquidityPool();
 if (candidate == canonicalPool && canonicalPool != address(0)) return true;
 if (candidate.code.length == 0) return false;

 (bool feeRead, bytes memory feeData) =
 candidate.staticcall(abi.encodeCall(IUniswapV3PoolImmutablesLike.fee, ()));
 if (!feeRead || feeData.length < 32) return false;

 uint24 candidateFee = abi.decode(feeData, (uint24));
 return IUniswapV3FactoryLike(dexFactory).getPool(address(this), pairToken, candidateFee) == candidate;
 }
}
