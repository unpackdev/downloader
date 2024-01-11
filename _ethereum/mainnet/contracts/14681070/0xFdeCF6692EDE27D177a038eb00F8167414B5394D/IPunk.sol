// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPunkData {
    function punkImageSvg(uint16 index)
        external
        pure
        returns (string memory svg);

    function punkAttributes(uint16 index)
        external
        pure
        returns (string memory text);
}

interface IPunkMarket {
    function punkIndexToAddress(uint256 punkIndex) external returns (address);

    function punksOfferedForSale(uint256 punkIndex)
        external
        returns (
            bool,
            uint256,
            address,
            uint256,
            address
        );

    function buyPunk(uint256 punkIndex) external payable;

    function transferPunk(address to, uint256 punkIndex) external;
}
