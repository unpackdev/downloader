// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./ICToken.sol";

interface IComptroller {
    function getAssetsIn(address account)
        external
        view
        returns (ICToken[] memory);

    function oracle() external view returns (address);

    function markets(address cToken)
        external
        view
        returns (
            bool isListed,
            uint256 collateralFactorMantissa,
            bool isComped
        );

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}
