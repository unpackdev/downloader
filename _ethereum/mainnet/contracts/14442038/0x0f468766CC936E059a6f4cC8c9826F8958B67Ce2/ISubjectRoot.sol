// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721.sol";

interface ISubjectRoot is IERC721 {

    function mintTokenOnPresale() external payable;

    function mintTokenOnSale() external payable;

    function bulkBuyTokensOnPresale(uint256 amount) external payable;

    function bulkBuyTokensOnSale(uint256 amount) external payable;

    function reserveMint(uint256 amount) external;

    function generateBossCharacters(uint256[] calldata entries) external;

    function morphGene(uint256 tokenId, uint256 genePosition) external payable;

    function randomizeGenome(uint256 tokenId) external payable;

    function setSubjectPrice(uint256 newSubjectPrice) external;

    function setMaxSupply(uint256 maxSupply) external;

    function setBulkBuyLimit(uint256 bulkBuyLimit) external;

    function changeBaseGenomeChangePrice(uint256 newGenomeChangePrice) external;

    function changeRandomizeGenomePrice(uint256 newRandomizeGenomePrice) external;

    function setPresaleStartDate(uint256 presaleStartDate) external;

    function setPresaleDuration(uint256 presaleDuration) external;

    function setWhitelistedWallets(address[] memory beneficiaries) external;

    function setWhitelistedContracts(address[] memory beneficiaries) external;

    function priceForGenomeChange(uint256 tokenId)
        external
        view
        returns (uint256 price);

    function isEligibleForPresale(address walletAddress)
        external
        view
        returns (bool);

    function whitelistBridgeAddress(address bridgeAddress, bool status) external;
}
