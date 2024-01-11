//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IOmc {
    function owner() external view returns (address);

    function getTotalSupply() external view returns (uint256);

    function setOmcEpoch(address omcEpoch) external;

    function setBaseURI(string memory baseURI) external;

    function setHiddenURI(string memory hiddenURI) external;

    function setPublicMintEnabled(bool state) external;

    function setSale(
        uint256 mintPrice,
        uint256 mintLimitPerUser,
        uint256 mintStartBlock,
        uint256 antiBotInterval,
        uint256 countLimitPerMint
    ) external;

    function reveal(bool state) external;

    function withdrawPayment() external;

    function publicMint(uint256 mintCount) external payable;

    function airDropMint(address receiver, uint256 requestedCount) external;
}
