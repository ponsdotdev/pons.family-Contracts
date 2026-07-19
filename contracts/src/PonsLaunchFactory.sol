// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Pons Family — launchpad factory for https://pons.family
// Deployed on Robinhood Chain at 0xA5aAb3F0c6EeadF30Ef1D3Eb997108E976351feB

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PonsLauncherToken} from "./PonsLauncherToken.sol";
import {PonsLiquidityMath} from "./libraries/PonsLiquidityMath.sol";
import {PonsTickMath} from "./libraries/PonsTickMath.sol";
import {
 INonfungiblePositionManagerLike,
 IPonsLaunchFactory,
 IPonsLaunchLocker,
 ISwapRouter02Like,
 ISwapRouterV3Like,
 IUniswapV3FactoryLike,
 IUniswapV3PoolStateLike
} from "./interfaces/ILaunchpad.sol";

/**
 * @title PonsLaunchFactory
 * @author Pons Family
 * @notice Primary entrypoint for the pons.family launchpad.
 * @dev Creators call `launchToken` once: we CREATE2 the ERC-20, seed a
 * one-sided Uniswap V3 position, hand the NFT to the locker, and optionally
 * route leftover native value into the first buy. Live deployment:
 * 0xA5aAb3F0c6EeadF30Ef1D3Eb997108E976351feB
 */
contract PonsLaunchFactory is Ownable2Step, ReentrancyGuard, IPonsLaunchFactory {
 using SafeERC20 for IERC20;

 // Full Uniswap V3 tick bounds — keep local so we never import periphery packages.
 int24 private constant MIN_TICK = -887272;
 int24 private constant MAX_TICK = 887272;
 uint256 private constant BASIS_POINTS = 10_000;
 // Every launched token address ends with ...bbbb (last two bytes).
 uint16 private constant TOKEN_ADDRESS_SUFFIX = 0xbbbb;
 // 16-bit suffix ~ 2^16 tries on average; headroom covers pool/code collisions.
 uint256 private constant VANITY_SEARCH_LIMIT = 1_000_000;

 struct Socials {
 string twitter;
 string telegram;
 string discord;
 string website;
 string farcaster;
 }

 struct TokenParams {
 string name;
 string symbol;
 string logo;
 string description;
 Socials socials;
 address feeWallet;
 }

 struct DexConfig {
 string name;
 address factory;
 address positionManager;
 address swapRouter;
 uint24 poolFee;
 int24 tickSpacing;
 bool enabled;
 }

 struct LaunchConfig {
 address pairToken;
 uint256 graduationThreshold;
 int24 initialTick;
 uint256 supply;
 uint16 maxWalletBps;
 uint16 maxTxBps;
 uint32 restrictionBlocks;
 uint24 reservedFee;
 bool enabled;
 bool routerRequiresDeadline;
 }

 error InvalidDexConfig();
 error InvalidDexId();
 error DexDisabled();
 error InvalidLaunchConfigId();
 error LaunchConfigDisabled();
 error InvalidBasisPoints();
 error InvalidMaxTxBasisPoints();
 error SupplyTooLow();
 error LaunchFeeNotPaid();
 error NotWhitelisted();
 error FeeTransferFailed();
 error TokenDeploymentFailed();
 error RouterNotSet();
 error ZeroAddress();
 error InvalidTokenParams();
 error TokenNotFound();
 error VanitySaltNotFound();

 event TokenDeployed(
 address indexed token,
 address indexed deployer,
 address indexed dexFactory,
 address pairToken,
 uint256 dexId,
 uint256 launchConfigId
 );
 event TokenLaunched(
 address indexed token,
 address indexed deployer,
 address indexed dexFactory,
 address pairToken,
 address pool,
 uint256 dexId,
 uint256 launchConfigId,
 uint256 positionId,
 uint256 restrictionsEndBlock,
 uint256 initialBuyAmount
 );
 event DexConfigAdded(
 uint256 indexed id,
 string name,
 address factory,
 address positionManager,
 address swapRouter,
 uint24 poolFee,
 int24 tickSpacing
 );
 event DexStatusUpdated(uint256 indexed id, bool enabled);
 event LaunchConfigAdded(
 uint256 indexed id,
 address pairToken,
 uint256 graduationThreshold,
 int24 initialTick,
 uint256 supply,
 uint16 maxWalletBps,
 uint16 maxTxBps,
 uint32 restrictionBlocks,
 uint24 reservedFee,
 bool enabled,
 bool routerRequiresDeadline
 );
 event LaunchConfigUpdated(
 uint256 indexed id,
 address pairToken,
 uint256 graduationThreshold,
 int24 initialTick,
 uint256 supply,
 uint16 maxWalletBps,
 uint16 maxTxBps,
 uint32 restrictionBlocks,
 uint24 reservedFee,
 bool enabled,
 bool routerRequiresDeadline
 );
 event LaunchFeeUpdated(uint256 launchFee);
 event LaunchEnabledUpdated(bool enabled);
 event WhitelistedLauncherUpdated(address indexed launcher, bool enabled);

 /// @dev Permanent NFT custody + protocol fee routing live behind this address.
 address public immutable locker;
 /// @dev Flat native fee charged before any optional seed buy.
 uint256 public launchFee;
 /// @dev When false, only `whitelistedLaunchers` may call `launchToken`.
 bool public launchEnabled;

 mapping(address launcher => bool enabled) public whitelistedLaunchers;
 mapping(address token => LaunchedToken launched) private _launchedTokens;
 mapping(address token => uint256 threshold) private _graduationThresholds;
 DexConfig[] private _dexConfigs;
 LaunchConfig[] private _launchConfigs;

 /// @param locker_ Pons locker that receives every launch position NFT.
 constructor(address initialOwner, address locker_, uint256 initialLaunchFee) Ownable(initialOwner) {
 if (locker_ == address(0)) revert ZeroAddress();
 locker = locker_;
 launchFee = initialLaunchFee;
 }

 /**
 * @notice Returns the number of configured V3 deployments.
 */
 function dexConfigCount() external view returns (uint256) {
 return _dexConfigs.length;
 }

 /**
 * @notice Returns the number of launch configurations.
 */
 function launchConfigCount() external view returns (uint256) {
 return _launchConfigs.length;
 }

 /**
 * @notice Returns one V3 deployment configuration.
 */
 function getDexConfig(uint256 id) external view returns (DexConfig memory) {
 if (id >= _dexConfigs.length) revert InvalidDexId();
 return _dexConfigs[id];
 }

 /**
 * @notice Returns one token launch configuration.
 */
 function getLaunchConfig(uint256 id) external view returns (LaunchConfig memory) {
 if (id >= _launchConfigs.length) revert InvalidLaunchConfigId();
 return _launchConfigs[id];
 }

 /**
 * @notice Returns the immutable record for a token created by this factory.
 */
 function getLaunchedToken(address token) external view override returns (LaunchedToken memory) {
 return _launchedTokens[token];
 }

 /**
 * @notice Derives graduation from paired-token principal in the locked V3 position.
 * Direct token donations to the pool do not affect this value. A zero threshold
 * disables graduation for the token.
 */
 function graduationStatus(address token)
 external
 view
 returns (uint256 pairedPrincipal, uint256 threshold, bool graduated)
 {
 LaunchedToken memory launched = _launchedTokens[token];
 if (!launched.exists) revert TokenNotFound();

 address pool = PonsLauncherToken(token).liquidityPool();
 (uint160 sqrtPriceX96,,,,,,) = IUniswapV3PoolStateLike(pool).slot0();
 (,,,,, int24 tickLower, int24 tickUpper, uint128 liquidity,,,,) =
 INonfungiblePositionManagerLike(launched.positionManager).positions(launched.positionId);
 (uint256 amount0, uint256 amount1) = PonsLiquidityMath.getAmountsForLiquidity(
 sqrtPriceX96,
 PonsTickMath.getSqrtRatioAtTick(tickLower),
 PonsTickMath.getSqrtRatioAtTick(tickUpper),
 liquidity
 );

 pairedPrincipal = launched.isToken0 ? amount1 : amount0;
 threshold = _graduationThresholds[token];
 graduated = threshold != 0 && pairedPrincipal >= threshold;
 }

 /**
 * @notice Adds a V3 factory, position manager, and router combination.
 */
 function addDexConfig(DexConfig calldata config) external onlyOwner returns (uint256 id) {
 _validateDexConfig(config);
 id = _dexConfigs.length;
 _dexConfigs.push(config);
 emit DexConfigAdded(
 id,
 config.name,
 config.factory,
 config.positionManager,
 config.swapRouter,
 config.poolFee,
 config.tickSpacing
 );
 }

 /**
 * @notice Enables or disables a configured V3 deployment.
 */
 function setDexStatus(uint256 id, bool enabled) external onlyOwner {
 if (id >= _dexConfigs.length) revert InvalidDexId();
 _dexConfigs[id].enabled = enabled;
 emit DexStatusUpdated(id, enabled);
 }

 /**
 * @notice Adds a launch configuration.
 */
 function addLaunchConfig(LaunchConfig calldata config) external onlyOwner returns (uint256 id) {
 _validateLaunchConfig(config);
 id = _launchConfigs.length;
 _launchConfigs.push(config);
 _emitLaunchConfigAdded(id, config);
 }

 /**
 * @notice Replaces an existing launch configuration.
 */
 function updateLaunchConfig(uint256 id, LaunchConfig calldata config) external onlyOwner {
 if (id >= _launchConfigs.length) revert InvalidLaunchConfigId();
 _validateLaunchConfig(config);
 _launchConfigs[id] = config;
 emit LaunchConfigUpdated(
 id,
 config.pairToken,
 config.graduationThreshold,
 config.initialTick,
 config.supply,
 config.maxWalletBps,
 config.maxTxBps,
 config.restrictionBlocks,
 config.reservedFee,
 config.enabled,
 config.routerRequiresDeadline
 );
 }

 /**
 * @notice Changes the fixed native launch fee.
 */
 function setLaunchFee(uint256 newLaunchFee) external onlyOwner {
 launchFee = newLaunchFee;
 emit LaunchFeeUpdated(newLaunchFee);
 }

 /**
 * @notice Opens or closes launches to non-whitelisted callers.
 */
 function setLaunchEnabled(bool enabled) external onlyOwner {
 launchEnabled = enabled;
 emit LaunchEnabledUpdated(enabled);
 }

 /**
 * @notice Grants or revokes permission to launch while the public gate is closed.
 */
 function setWhitelistedLauncher(address launcher, bool enabled) external onlyOwner {
 if (launcher == address(0)) revert ZeroAddress();
 whitelistedLaunchers[launcher] = enabled;
 emit WhitelistedLauncherUpdated(launcher, enabled);
 }

 /**
 * @notice Atomically deploys, pools, locks, records, and optionally buys a token.
 * @dev Extra native value above `launchFee` is the optional seed buy.
 * Deployed token addresses always end in `bbbb`.
 */
 function launchToken(TokenParams calldata params, uint256 launchConfigId, uint256 dexId, bytes32 salt)
 external
 payable
 nonReentrant
 returns (address token)
 {
 if (!launchEnabled && !whitelistedLaunchers[msg.sender]) {
 revert NotWhitelisted();
 }
 if (msg.value < launchFee) revert LaunchFeeNotPaid();
 if (dexId >= _dexConfigs.length) revert InvalidDexId();
 if (launchConfigId >= _launchConfigs.length) {
 revert InvalidLaunchConfigId();
 }
 if (bytes(params.name).length == 0 || bytes(params.symbol).length == 0) {
 revert InvalidTokenParams();
 }

 DexConfig memory dex = _dexConfigs[dexId];
 LaunchConfig memory config = _launchConfigs[launchConfigId];
 if (!dex.enabled) revert DexDisabled();
 if (!config.enabled) revert LaunchConfigDisabled();

 // Prefer an explicit fee wallet when the UI passes one; otherwise seed the creator.
 address initialBuyRecipient = params.feeWallet == address(0) ? msg.sender : params.feeWallet;
 bytes memory creationCode = _buildTokenCreationCode(params, config, dex, msg.sender);
 bytes32 initCodeHash = keccak256(creationCode);

 // Ensure the deployed token address ends in ...bbbb.
 (bytes32 deploySalt,) =
 _resolveVanitySalt(salt, initCodeHash, config.pairToken, dex.factory, dex.poolFee);

 _payLaunchFee();
 token = _deployToken(deploySalt, creationCode);
 emit TokenDeployed(token, msg.sender, dex.factory, config.pairToken, dexId, launchConfigId);

 // Token ordering flips the concentrated range; mirror the tick accordingly.
 bool isToken0 = token < config.pairToken;
 int24 poolTick = isToken0 ? config.initialTick : -config.initialTick;
 (int24 tickLower, int24 tickUpper) = _positionRange(isToken0, config.initialTick, dex.tickSpacing);

 INonfungiblePositionManagerLike manager = INonfungiblePositionManagerLike(dex.positionManager);
 (address token0, address token1) = isToken0 ? (token, config.pairToken) : (config.pairToken, token);
 address pool = manager.createAndInitializePoolIfNecessary(
 token0, token1, dex.poolFee, PonsTickMath.getSqrtRatioAtTick(poolTick)
 );

 // Deposit the full fixed supply as one-sided liquidity, then clear the allowance.
 IERC20(token).forceApprove(dex.positionManager, config.supply);
 (uint256 positionId,,,) = manager.mint(
 INonfungiblePositionManagerLike.MintParams({
 token0: token0,
 token1: token1,
 fee: dex.poolFee,
 tickLower: tickLower,
 tickUpper: tickUpper,
 amount0Desired: isToken0 ? config.supply : 0,
 amount1Desired: isToken0 ? 0 : config.supply,
 amount0Min: 0,
 amount1Min: 0,
 recipient: address(this),
 deadline: block.timestamp
 })
 );
 IERC20(token).forceApprove(dex.positionManager, 0);

 uint256 initialBuyAmount = msg.value - launchFee;
 uint256 restrictionEndBlock = PonsLauncherToken(token).restrictionEndBlock();
 _launchedTokens[token] = LaunchedToken({
 token: token,
 deployer: msg.sender,
 pairedToken: config.pairToken,
 positionManager: dex.positionManager,
 positionId: positionId,
 dexId: dexId,
 launchConfigId: launchConfigId,
 restrictionsEndBlock: restrictionEndBlock,
 supply: config.supply,
 isToken0: isToken0,
 poolFee: dex.poolFee,
 exists: true,
 initialBuyAmount: initialBuyAmount
 });
 _graduationThresholds[token] = config.graduationThreshold;

 // Locker owns the NFT permanently; factory only retains the launch record.
 manager.safeTransferFrom(address(this), locker, positionId);
 IPonsLaunchLocker(locker).lockPosition(token);
 // Point LP fee claims at the creator wallet when the UI supplies one.
 if (params.feeWallet != address(0)) {
 IPonsLaunchLocker(locker).setFeeRedirect(token, params.feeWallet);
 }

 emit TokenLaunched(
 token,
 msg.sender,
 dex.factory,
 config.pairToken,
 pool,
 dexId,
 launchConfigId,
 positionId,
 restrictionEndBlock,
 initialBuyAmount
 );

 if (initialBuyAmount != 0) {
 if (dex.swapRouter == address(0)) revert RouterNotSet();
 // Temporarily unlock the seed recipient for same-block anti-snipe rules.
 PonsLauncherToken(token).setInitialBuyRecipient(initialBuyRecipient);
 _executeInitialBuy(dex, config, token, initialBuyRecipient, initialBuyAmount);
 PonsLauncherToken(token).setInitialBuyRecipient(address(0));
 }
 }

 /**
 * @notice Computes a CREATE2 token address for the given inputs.
 */
 function predictTokenAddress(
 TokenParams calldata params,
 uint256 launchConfigId,
 uint256 dexId,
 bytes32 salt,
 address tokenDeployer
 ) external view returns (address) {
 if (dexId >= _dexConfigs.length) revert InvalidDexId();
 if (launchConfigId >= _launchConfigs.length) {
 revert InvalidLaunchConfigId();
 }
 bytes memory creationCode =
 _buildTokenCreationCode(params, _launchConfigs[launchConfigId], _dexConfigs[dexId], tokenDeployer);
 return _computeCreate2Address(salt, keccak256(creationCode));
 }

 /**
 * @notice Predicts the `…bbbb` token address that `launchToken` will deploy.
 */
 function predictVanityTokenAddress(
 TokenParams calldata params,
 uint256 launchConfigId,
 uint256 dexId,
 bytes32 saltSearchStart,
 address tokenDeployer
 ) external view returns (bytes32 deploySalt, address token) {
 if (dexId >= _dexConfigs.length) revert InvalidDexId();
 if (launchConfigId >= _launchConfigs.length) {
 revert InvalidLaunchConfigId();
 }
 DexConfig memory dex = _dexConfigs[dexId];
 LaunchConfig memory config = _launchConfigs[launchConfigId];
 bytes32 initCodeHash = keccak256(_buildTokenCreationCode(params, config, dex, tokenDeployer));
 return _resolveVanitySalt(saltSearchStart, initCodeHash, config.pairToken, dex.factory, dex.poolFee);
 }

 /**
 * @notice True when `token` ends with the required `bbbb` hex suffix.
 */
 function hasVanitySuffix(address token) external pure returns (bool) {
 return _hasRequiredSuffix(token);
 }

 function _buildTokenCreationCode(
 TokenParams calldata params,
 LaunchConfig memory config,
 DexConfig memory dex,
 address tokenDeployer
 ) private pure returns (bytes memory) {
 // Keep social fields packed into the token constructor for single-tx launches.
 PonsLauncherToken.Socials memory tokenSocials = PonsLauncherToken.Socials({
 twitter: params.socials.twitter,
 telegram: params.socials.telegram,
 discord: params.socials.discord,
 website: params.socials.website,
 farcaster: params.socials.farcaster
 });

 return abi.encodePacked(
 type(PonsLauncherToken).creationCode,
 abi.encode(
 params.name,
 params.symbol,
 params.logo,
 params.description,
 tokenSocials,
 tokenDeployer,
 dex.factory,
 dex.positionManager,
 config.pairToken,
 dex.poolFee,
 config.supply,
 config.maxWalletBps,
 config.maxTxBps,
 config.restrictionBlocks
 )
 );
 }

 function _deployToken(bytes32 salt, bytes memory creationCode) private returns (address token) {
 // CREATE2 so the UI can advertise the token address before the wallet confirms.
 assembly ("memory-safe") {
 token := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
 }
 if (token == address(0)) revert TokenDeploymentFailed();
 }

 function _payLaunchFee() private {
 if (launchFee == 0) return;
 address recipient = IPonsLaunchLocker(locker).protocolFeeRecipient();
 if (recipient == address(0)) revert ZeroAddress();
 (bool sent,) = payable(recipient).call{value: launchFee}("");
 if (!sent) revert FeeTransferFailed();
 }

 function _computeCreate2Address(bytes32 salt, bytes32 initCodeHash) private view returns (address) {
 return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, initCodeHash)))));
 }

 /// @dev Last two bytes of the address must equal `0xbbbb`.
 function _hasRequiredSuffix(address token) private pure returns (bool) {
 return uint16(uint160(token)) == TOKEN_ADDRESS_SUFFIX;
 }

 /**
 * @dev Finds a free token address ending in `bbbb`.
 */
 function _resolveVanitySalt(
 bytes32 startSalt,
 bytes32 initCodeHash,
 address pairToken,
 address dexFactory,
 uint24 poolFee
 ) private view returns (bytes32 salt, address predicted) {
 uint256 cursor = uint256(startSalt);
 for (uint256 i = 0; i < VANITY_SEARCH_LIMIT; ++i) {
 salt = bytes32(cursor + i);
 predicted = _computeCreate2Address(salt, initCodeHash);
 if (!_hasRequiredSuffix(predicted)) continue;
 if (predicted.code.length != 0) continue;
 if (IUniswapV3FactoryLike(dexFactory).getPool(predicted, pairToken, poolFee) != address(0)) continue;
 return (salt, predicted);
 }
 revert VanitySaltNotFound();
 }

 function _positionRange(bool isToken0, int24 initialTick, int24 tickSpacing)
 private
 pure
 returns (int24 tickLower, int24 tickUpper)
 {
 // Truncation toward zero matches Uniswap V3 usable boundary ticks.
 // forge-lint: disable-next-line(divide-before-multiply)
 int24 minUsableTick = (MIN_TICK / tickSpacing) * tickSpacing;
 // forge-lint: disable-next-line(divide-before-multiply)
 int24 maxUsableTick = (MAX_TICK / tickSpacing) * tickSpacing;

 // Put the entire supply on the token side of the starting price.
 if (isToken0) {
 return (initialTick, maxUsableTick);
 }
 return (minUsableTick, -initialTick);
 }

 function _validateDexConfig(DexConfig calldata config) private pure {
 if (
 bytes(config.name).length == 0 || config.factory == address(0) || config.positionManager == address(0)
 || config.poolFee == 0 || config.tickSpacing <= 0
 ) {
 revert InvalidDexConfig();
 }
 }

 function _validateLaunchConfig(LaunchConfig calldata config) private pure {
 if (config.pairToken == address(0)) revert ZeroAddress();
 if (config.maxWalletBps > BASIS_POINTS || config.maxTxBps > BASIS_POINTS) {
 revert InvalidBasisPoints();
 }
 uint16 expectedMaxTxBps = _tokenMaxTxBps(config.maxWalletBps);
 if (config.maxTxBps != expectedMaxTxBps) {
 revert InvalidMaxTxBasisPoints();
 }
 if (config.supply < 1 ether) revert SupplyTooLow();
 if (config.initialTick < MIN_TICK || config.initialTick > MAX_TICK || config.initialTick == 0) {
 revert InvalidLaunchConfigId();
 }
 }

 function _tokenMaxTxBps(uint16 maxWalletBps) private pure returns (uint16) {
 uint256 derived = (uint256(maxWalletBps) * 110) / 100;
 uint256 capped = derived > BASIS_POINTS ? BASIS_POINTS : derived;
 // The basis-point cap guarantees that the value fits uint16.
 // forge-lint: disable-next-line(unsafe-typecast)
 return uint16(capped);
 }

 function _emitLaunchConfigAdded(uint256 id, LaunchConfig calldata config) private {
 emit LaunchConfigAdded(
 id,
 config.pairToken,
 config.graduationThreshold,
 config.initialTick,
 config.supply,
 config.maxWalletBps,
 config.maxTxBps,
 config.restrictionBlocks,
 config.reservedFee,
 config.enabled,
 config.routerRequiresDeadline
 );
 }

 function _executeInitialBuy(
 DexConfig memory dex,
 LaunchConfig memory config,
 address token,
 address recipient,
 uint256 amountIn
 ) private {
 // Some deployments wire SwapRouter02 (no deadline); others need the classic V3 path.
 if (config.routerRequiresDeadline) {
 ISwapRouterV3Like(dex.swapRouter).exactInputSingle{value: amountIn}(
 ISwapRouterV3Like.ExactInputSingleParams({
 tokenIn: config.pairToken,
 tokenOut: token,
 fee: dex.poolFee,
 recipient: recipient,
 deadline: block.timestamp,
 amountIn: amountIn,
 amountOutMinimum: 0,
 sqrtPriceLimitX96: 0
 })
 );
 return;
 }

 ISwapRouter02Like(dex.swapRouter).exactInputSingle{value: amountIn}(
 ISwapRouter02Like.ExactInputSingleParams({
 tokenIn: config.pairToken,
 tokenOut: token,
 fee: dex.poolFee,
 recipient: recipient,
 amountIn: amountIn,
 amountOutMinimum: 0,
 sqrtPriceLimitX96: 0
 })
 );
 }
}
