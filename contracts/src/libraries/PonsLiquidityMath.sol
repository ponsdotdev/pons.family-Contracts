// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Pons Family — liquidity valuation helpers for pons.family graduation checks.

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title PonsLiquidityMath
 * @author Pons Family
 * @notice Converts Uniswap V3 concentrated liquidity into token principals.
 * @dev Used by `PonsLaunchFactory.graduationStatus` so only locked LP depth
 * counts toward graduation — direct token gifts to the pool are ignored.
 */
library PonsLiquidityMath {
 uint256 private constant Q96 = 0x1000000000000000000000000;

 /**
 * @notice Token amounts represented by `liquidity` at the current price.
 */
 function getAmountsForLiquidity(
 uint160 sqrtRatioX96,
 uint160 sqrtRatioAX96,
 uint160 sqrtRatioBX96,
 uint128 liquidity
 ) internal pure returns (uint256 amount0, uint256 amount1) {
 if (sqrtRatioAX96 > sqrtRatioBX96) {
 (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
 }

 if (sqrtRatioX96 <= sqrtRatioAX96) {
 amount0 = _getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
 } else if (sqrtRatioX96 < sqrtRatioBX96) {
 amount0 = _getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
 amount1 = _getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
 } else {
 amount1 = _getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
 }
 }

 /// @dev token0 principal across [A, B] when price sits at / below the range.
 function _getAmount0ForLiquidity(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity)
 private
 pure
 returns (uint256)
 {
 return Math.mulDiv(uint256(liquidity) << 96, sqrtRatioBX96 - sqrtRatioAX96, sqrtRatioBX96) / sqrtRatioAX96;
 }

 /// @dev token1 principal across [A, B] when price sits at / above the range.
 function _getAmount1ForLiquidity(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity)
 private
 pure
 returns (uint256)
 {
 return Math.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, Q96);
 }
}
