// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Pons Family — shared interfaces for the pons.family launchpad stack.
// Kept intentionally thin so we do not pull Uniswap periphery into the build.

/**
 * @notice Minimal Uniswap V3 + Pons surfaces used by factory and token.
 * @author Pons Family
 */
interface IUniswapV3FactoryLike {
 function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

interface IUniswapV3PoolStateLike {
 function slot0()
 external
 view
 returns (
 uint160 sqrtPriceX96,
 int24 tick,
 uint16 observationIndex,
 uint16 observationCardinality,
 uint16 observationCardinalityNext,
 uint8 feeProtocol,
 bool unlocked
 );
}

interface IUniswapV3PoolImmutablesLike {
 function fee() external view returns (uint24);
}

interface INonfungiblePositionManagerLike {
 struct MintParams {
 address token0;
 address token1;
 uint24 fee;
 int24 tickLower;
 int24 tickUpper;
 uint256 amount0Desired;
 uint256 amount1Desired;
 uint256 amount0Min;
 uint256 amount1Min;
 address recipient;
 uint256 deadline;
 }

 struct CollectParams {
 uint256 tokenId;
 address recipient;
 uint128 amount0Max;
 uint128 amount1Max;
 }

 function createAndInitializePoolIfNecessary(address token0, address token1, uint24 fee, uint160 sqrtPriceX96)
 external
 payable
 returns (address pool);

 function mint(MintParams calldata params)
 external
 payable
 returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

 function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

 function positions(uint256 tokenId)
 external
 view
 returns (
 uint96 nonce,
 address operator,
 address token0,
 address token1,
 uint24 fee,
 int24 tickLower,
 int24 tickUpper,
 uint128 liquidity,
 uint256 feeGrowthInside0LastX128,
 uint256 feeGrowthInside1LastX128,
 uint128 tokensOwed0,
 uint128 tokensOwed1
 );

 function ownerOf(uint256 tokenId) external view returns (address owner);

 function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface ISwapRouter02Like {
 struct ExactInputSingleParams {
 address tokenIn;
 address tokenOut;
 uint24 fee;
 address recipient;
 uint256 amountIn;
 uint256 amountOutMinimum;
 uint160 sqrtPriceLimitX96;
 }

 function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

interface ISwapRouterV3Like {
 struct ExactInputSingleParams {
 address tokenIn;
 address tokenOut;
 uint24 fee;
 address recipient;
 uint256 deadline;
 uint256 amountIn;
 uint256 amountOutMinimum;
 uint160 sqrtPriceLimitX96;
 }

 function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

interface IERC721ReceiverLike {
 function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
 external
 returns (bytes4);
}

interface IPonsLaunchFactory {
 /// @notice Canonical launch record stored by the factory for each token.
 struct LaunchedToken {
 address token;
 address deployer;
 address pairedToken;
 address positionManager;
 uint256 positionId;
 uint256 dexId;
 uint256 launchConfigId;
 uint256 restrictionsEndBlock;
 uint256 supply;
 bool isToken0;
 uint24 poolFee;
 bool exists;
 uint256 initialBuyAmount;
 }

 function getLaunchedToken(address token) external view returns (LaunchedToken memory);
}

/// @notice External locker that custodies launch NFTs and routes LP fees.
interface IPonsLaunchLocker {
 function protocolFeeRecipient() external view returns (address);

 function lockPosition(address token) external;

 function setFeeRedirect(address token, address newFeeWallet) external;
}
