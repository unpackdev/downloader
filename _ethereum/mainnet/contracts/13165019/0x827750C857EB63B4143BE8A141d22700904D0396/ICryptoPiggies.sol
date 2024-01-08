//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "./IERC721.sol";
import "./IMetaDataGenerator.sol";

interface ICryptoPiggies is IERC721 {
    struct Piggy {
        uint256 gene;
        uint256 traitMask;
        uint256 balance;
        uint256 flipCost;
    }

    // Events

    event ResetMask(uint256 tokenId);
    event TurnTraitOn(uint256 tokenId, uint256 position);
    event TurnTraitOff(uint256 tokenId, uint256 position);
    event Deposit(uint256 tokenId, uint256 amount);
    event Break(uint256 piggiesBroken, uint256 amount, address to);

    // Functions for minting

    receive() external payable;

    function mintPiggies(uint256 piggiesToMint) external payable;

    function giftPiggies(uint256 piggiesToMint, address to) external payable;

    // Breaking

    function breakPiggies(uint256[] memory tokenIds, address payable to) external;

    // Manipulating mask

    function resetTraitMask(uint256 tokenId) external;

    function turnTraitOn(uint256 tokenId, uint256 position) external payable;

    function turnTraitOff(uint256 tokenId, uint256 position) external payable;

    function updateMultipleTraits(
        uint256 tokenId,
        uint256[] memory position,
        bool[] memory onOff
    ) external payable;

    // Depositing eth into a piggy

    function deposit(uint256 tokenId) external payable;

    // Views

    function getSVG(uint256 tokenId) external view returns (string memory);

    function piggyBalance(uint256 tokenId) external view returns (uint256);

    function geneOf(uint256 tokenId) external view returns (uint256);

    function traitMaskOf(uint256 tokenId) external view returns (uint256);

    function activeGeneOf(uint256 tokenId) external view returns (uint256);

    function getPiggy(uint256 tokenId) external view returns (Piggy memory);

    function flipCost(uint256 tokenId) external view returns (uint256);

    function broken() external view returns (uint256);

    function treasury() external view returns (address payable);

    function METADATAGENERATOR() external view returns (IMetaDataGenerator);
}
