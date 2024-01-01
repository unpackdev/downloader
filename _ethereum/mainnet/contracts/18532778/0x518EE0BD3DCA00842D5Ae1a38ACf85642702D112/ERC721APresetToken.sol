// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title Token Contract
 * @author akibe
 */

import "./ERC721A.sol";
import "./ERC4907A.sol";
import "./ERC721AQueryable.sol";
import "./ERC2981.sol";
import "./AccessControl.sol";
import "./Ownable.sol";

contract ERC721APresetToken is 
  ERC721A,
  ERC4907A,
  ERC721AQueryable,
  ERC2981,
  AccessControl,
  Ownable
{
    // ==========-==========-==========-==========-==========-==========
    // Variables
    // ==========-==========-==========-==========-==========-==========
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    string internal _baseTokenURI;

    // ==========-==========-==========-==========-==========-==========
    // ERC721 Interface
    // ==========-==========-==========-==========-==========-==========

     constructor(string memory name, string memory symbol, uint96 royalty) ERC721A(name, symbol) Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _setDefaultRoyalty(msg.sender, royalty);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721A, IERC721A, ERC4907A, ERC2981, AccessControl )
        returns (bool)
    {
        return 
          ERC721A.supportsInterface(interfaceId) || 
          ERC2981.supportsInterface(interfaceId) || 
          ERC4907A.supportsInterface(interfaceId) || 
          AccessControl.supportsInterface(interfaceId);
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

    // ========== Token
    function _startTokenId() internal pure override returns (uint256) {
      return 1;
    }
    function nextTokenId() public view returns (uint256) {
      return _nextTokenId();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function mint(address to, uint256 quantity) public onlyRole(MINTER_ROLE) {
        _mint(to, quantity);
    }
}
