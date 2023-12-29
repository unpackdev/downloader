// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author wizrd0x

import "./TieredMetadata.sol";
import "./PassiveStaking.sol";
import "./DefaultOperatorFilterer.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./Administration.sol";
import "./Treasury.sol";

import "./ERC721A.sol";
import "./IERC721A.sol";

contract ERC721APassiveStaking is
    ERC721A,
    PassiveStaking,
    TieredMetadata,
    Administration,
    Treasury,
    ERC2981ContractWideRoyalties,
    DefaultOperatorFilterer
{
    constructor(
        string memory _name,
        string memory _symbol,
        address _recipient,
        uint256 _royalty,
        address owner
    ) ERC721A(_name, _symbol) Administration(owner) {
        _setRoyalties(_recipient, _royalty);
    }

    function tokenURI(uint256 tokenId) public view virtual override(IERC721A, ERC721A) returns (string memory) {
        return _tokenURI(tokenId);
    }

    function reveal() public isAdmin {
        _setRevealed();
    }

    function setUnrevealedBaseURI(string memory baseUri) public isAdmin {
        _setUnrevealedBaseURI(baseUri);
    }

    function setBaseURI(string memory baseUri) public isAdmin {
        _setBaseURI(baseUri);
    }

    function setTierBaseURI(uint256 tier_, string memory baseUri) public isAdmin {
        _setTierBaseURI(tier_, baseUri);
    }

    function addTier(Tier memory tier_) public isAdmin {
        _addTier(tier_);
    }

    function setStakingStartTime(uint256 startTime) public isAdmin {
        _setStartTime(startTime);
    }

    function setRoyalties(address recipient, uint256 value) public isAdmin {
        _setRoyalties(recipient, value);
    }

    // OVERRIDES FOR OPERATOR FILTERER //
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // END OVERRIDES FOR OPERATOR FILTERER //

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A, PassiveStaking, TieredMetadata) {
        TieredMetadata._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, ERC2981Base, Administration) returns (bool) {
        return
            interfaceId == bytes4(0x49064906) ||
            interfaceId == type(ERC2981Base).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
