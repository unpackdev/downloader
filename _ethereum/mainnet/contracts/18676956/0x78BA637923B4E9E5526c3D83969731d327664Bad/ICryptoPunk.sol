// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICryptoPunk {
    function punkIndexToAddress(uint256) external view returns (address);

    function buyPunk(uint256) external payable;

    function transferPunk(address, uint256) external;

    function offerPunkForSale(uint256, uint256) external;

    function offerPunkForSaleToAddress(
        uint256,
        uint256,
        address
    ) external;

    function acceptBidForPunk(uint256, uint256) external;
}
