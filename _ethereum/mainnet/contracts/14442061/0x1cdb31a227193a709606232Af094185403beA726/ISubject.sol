// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721.sol";

interface ISubject is IERC721 {
    function geneOf(uint256 tokenId) external view returns (uint256 gene);

    function lastTokenId() external view returns (uint256 tokenId);

    function setRareTraitsChances(uint256[] calldata entries) external;

    function setDaoAddress(address payable daoAddress) external;

    function setBaseURI(string memory _baseURI) external;

    function setArweaveAssetsJSON(string memory _arweaveAssetsJSON) external;
}
