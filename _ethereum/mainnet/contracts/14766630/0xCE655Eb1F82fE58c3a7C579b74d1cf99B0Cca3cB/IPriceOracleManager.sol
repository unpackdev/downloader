// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IPriceOracleManager {
    function getPriceOfTokenId(address voucher_, uint256 tokenId_)
        external
        view
        returns (int256 price_);

    function getPriceOfMaturity(address voucher_, uint64 maturity_)
        external
        view
        returns (int256 price_);
}
