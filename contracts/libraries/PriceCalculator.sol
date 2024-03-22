// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {FullMath} from "./FullMath.sol";

library PriceCalculator {
    function getPrice(
        uint160 sqrtRatioX96
    ) internal pure returns (uint256 price) {
        uint256 numerator1 = uint256(sqrtRatioX96) * uint256(sqrtRatioX96);
        uint256 numerator2 = 10 ** 18;
        price = FullMath.mulDiv(numerator1, numerator2, 1 << 192);
    }
}
