//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRobos {
    function balanceOG(address _user) external view returns(uint256);

    function jrCount(address _user) external view returns(uint256);

    function generationOf(uint256 tokenId) external view returns (uint256 gene);

    function lastTokenId() external view returns (uint256 tokenId);

    function setMintCost(uint256 newMintCost) external;

    function setTxLimit(uint256 _bulkBuyLimit) external;

}