// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

interface IKronosSeedSale {
    function flipSeedSaleActive() external;

    function addToWhitelist(address[] calldata wallets, uint256 metadataId) external;

    function payWithUSDT(uint256 amount) external;

    function payWithUSDC(uint256 amount) external;

    function mint() external;

    function setBaseURI(string calldata newURI) external;

    function tokenURI(uint256 tokenID) external view returns (string memory);

    function withdrawTokens(address token) external;

    // Events
    event Payment(address from, uint256 amount, bool USDT);

    // State variables (you can include these if you want to access them directly)
    function seedSaleActive() external view returns (bool);

    function USDT() external view returns (address);

    function USDC() external view returns (address);

    function totalSupply() external view returns (uint256);

    function totalUSDTokenAmountCommitted() external view returns (uint256);

    function USDTokenAmountCommitted(address user) external view returns (uint256);

    function tokenIdToMetadataId(uint256 tokenId) external view returns (uint256);

    function metaIDForAddress(address user) external view returns (uint256);
}
