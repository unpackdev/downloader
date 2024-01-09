// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC721.sol";

interface IUnicornViceClub is IERC721 {
    function geneOf(uint256 tokenId) external view returns (uint256 gene);

    function mint() external payable;

    function presaleMint(uint256 amount) external payable;

    function reserveMint(uint256 amount) external;

    function bulkBuy(uint256 amount) external payable;

    function lastTokenId() external view returns (uint256 tokenId);

    function setUnicornViceClubPrice(uint256 newPrice) external;

    function setUnicornViceClubPresalePrice(uint256 newPrice) external;

    function setMaxSupply(uint256 maxSupply) external;

    function setBulkBuyLimit(uint256 bulkBuyLimit) external;

    function setBaseURI(string memory baseURI) external;

    function setOfficialSaleStart(uint256 newOfficialSaleStart) external;

    function setPresaleStart(uint256 newPresaleStart) external;
}
