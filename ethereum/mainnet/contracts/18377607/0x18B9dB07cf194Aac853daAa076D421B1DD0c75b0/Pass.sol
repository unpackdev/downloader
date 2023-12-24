// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC721.sol";
import "./ERC721Royalty.sol";
import "./AccessControl.sol";
import "./IPass.sol";

contract Pass is IPass, ERC721, ERC721Royalty, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public tokenIdCounter;
    string private baseUri;
    uint256 public constant MAX_SUPPLY = 5555;

    constructor(string memory _baseUri) ERC721("raW Pass", "RAWPASS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        baseUri = _baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    /// @dev Get a new token ID and increment the counter.
    /// @return The new token ID.
    function getNewTokenId() internal returns (uint256) {
        // Start tokenIds at 1
        tokenIdCounter += 1;

        return tokenIdCounter;
    }

    /// @dev Mint an unrevealed token.
    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        // Ensure max supply is not exceeded.
        require(tokenIdCounter < MAX_SUPPLY, "Pass: MAX_SUPPLY_EXCEEDED");

        uint256 tokenId = getNewTokenId();
        _safeMint(to, tokenId);
    }

    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        super.grantRole(role, account);
    }

    function setBaseURI(string memory _baseUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseUri = _baseUri;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(IERC165, ERC721, ERC721Royalty, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
