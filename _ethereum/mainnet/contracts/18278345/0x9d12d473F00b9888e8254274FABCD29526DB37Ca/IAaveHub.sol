// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

interface IAaveHub {

    function AAVE_ADDRESS()
        external
        view
        returns (address);

    function aaveTokenAddress(
        address _underlyingToken
    )
        external
        view
        returns (address);

    function borrowExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _borrowAmount
    )
        external
        returns (uint256);

    function paybackExactShares(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _shares
    )
        external
        returns (uint256);

    function paybackExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _shares
    )
        external
        returns (uint256);
}