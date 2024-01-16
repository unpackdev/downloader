// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Base.sol";
import "./IMint.sol";
import "./LibMerkleProof.sol";
import "./LibMint.sol";
import "./ITokenOwnershipFacet.sol";


contract MintFacet is Base, IMint {

    modifier canMint() {
        if (msg.value != LibMint.getPrice()) revert InvalidETHAmount();
        if (LibMint.minted(msg.sender)) revert AlreadyMinted();
        _;
    }

    function mintWithProof(bytes32[] calldata _merkleProof)
        external
        payable
        onlyEoA
        canMint
    {
        if (!LibMint.isPrivateSaleActive()) revert PrivateSaleNotActive();
        if (!LibMerkleProof.verifyPrivateSale(_merkleProof)) revert InvalidProof();
        LibMint.setMinted(msg.sender);
        LibMint.mint(msg.sender, s);
    }

    function whaleMintWithProof(bytes32[] calldata _merkleProof)
        external
        payable
        onlyEoA
        canMint
    {
        if (!LibMint.isPrivateSaleActive()) revert PrivateSaleNotActive();
        if (!LibMerkleProof.verifyClaim(_merkleProof)) revert InvalidProof();
        if (!LibMint.meetsCondition(msg.sender)) revert DoesNotMeetMintCondition();
        LibMint.setMinted(msg.sender);
        LibMint.mint(msg.sender, s);
    }

    function mint() external payable onlyEoA canMint {
        if (!LibMint.isPublicSaleActive()) revert PrivateSaleNotActive();
        LibMint.setMinted(msg.sender);
        LibMint.mint(msg.sender, s);
    }

    function setPublicSale(bool active_) external {
        active_ ? LibMint.startPublicSale() : LibMint.stopPublicSale();
    }

    function setPrivateSale(bool active_) external {
        active_ ? LibMint.startPrivateSale() : LibMint.stopPrivateSale();
    }
}
