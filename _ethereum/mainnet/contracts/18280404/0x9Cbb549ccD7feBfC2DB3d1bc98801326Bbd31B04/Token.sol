// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title Token Contract
 * @author akibe
 */

import "./ERC721Enumerable.sol";
import "./ERC721Royalty.sol";
import "./ERC721Pausable.sol";
import "./ERC721Burnable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ERC721Reviewable.sol";
import "./ERC721Mintable.sol";

contract Token is
    ERC721Enumerable,
    ERC721Royalty,
    ERC721Pausable,
    ERC721Burnable,
    ERC721Reviewable,
    ERC721Mintable,
    AccessControl,
    Ownable
{
    // ==========-==========-==========-==========-==========-==========
    // Variables
    // ==========-==========-==========-==========-==========-==========
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant REVIEWER_ROLE = keccak256('REVIEWER_ROLE');

    string internal _baseTokenURI = '';
     string private _baseReviewedURI;

    // ==========-==========-==========-==========-==========-==========
    // ERC721 Interface
    // ==========-==========-==========-==========-==========-==========

     constructor(string memory name, string memory symbol, string memory baseTokenURI, uint96 royalty) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(REVIEWER_ROLE, msg.sender);
        _setDefaultRoyalty(msg.sender, royalty);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty, ERC721Reviewable, ERC721Mintable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable,ERC721Pausable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function tokensOfOwner(
        address owner
    ) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokens = new uint256[](balance);
        for (uint256 i; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner,i);
        }
        return tokens;
    }

    function tokensOfAll() external view returns (uint256[] memory) {
        uint256 balance = totalSupply();
        uint256[] memory tokens = new uint256[](balance);
        for (uint256 i; i < balance; i++) {
            tokens[i] = tokenByIndex(i);
        }
        return tokens;
    }

    // ========== Metadata
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    // ========== Royalty
    function setDefaultRoyalty(address receiver, uint96 value) external onlyOwner {
        _setDefaultRoyalty(receiver, value);
    }

    // ========== Pausable
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // ========== Burnable
    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    // ========== Reviewable
    function _startReviewId() internal pure override returns (uint256) {
        return 1;
    }

    function postReviewOfToken(
        uint256 tokenId,
        string memory uri
    ) public override onlyRole(REVIEWER_ROLE) returns (uint256) {
        return super.postReviewOfToken(tokenId, uri);
    }

    function postReviewOfContract(
        string calldata uri
    ) public override onlyRole(REVIEWER_ROLE) returns (uint256) {
        return super.postReviewOfContract(uri);
    }

    function _baseReviewURI() internal view override returns (string memory) {
        return _baseReviewedURI;
    }

    function setBaseReviewURI(string memory newBaseURI) public onlyOwner {
        _baseReviewedURI = newBaseURI;
    }

    function setReviewURI(uint256 reviewId, string memory uri) public onlyOwner {
        super._setReviewURI(reviewId, uri);
    }

    // ========== Mintable
    function mint(address to, uint256 tokenId) public override onlyRole(MINTER_ROLE) {
        super.mint(to, tokenId);
    }
}
