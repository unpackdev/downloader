// SPDX-License-Identifier: ISC
pragma solidity >=0.4.22 <0.9.0;

import "./AdminOps.sol";
import "./ERC721Enumerable.sol";
import "./PermissionManagement.sol";
import "./Payable.sol";

/// @title NFT Contract
/// @author hey@kumareth.com
/// @notice An ERC721 Inheritable Contract with many features (like, ERC721Enumerable, accepting payments, admin ability to transfer tokens, etc.)
abstract contract NFT is AdminOps, ERC721Enumerable, Payable {
  constructor (
    string memory name_, 
    string memory symbol_,
    address _permissionManagementContractAddress,
    string memory contractURI_
  )
  ERC721(name_, symbol_)
  AdminOps(_permissionManagementContractAddress)
  Payable(_permissionManagementContractAddress)
  {
    _contractURI = contractURI_;
  }

  string public baseURI = ""; //-> could have been "https://monument.app/artifacts/"

  function _baseURI() internal view virtual override(ERC721) returns (string memory) {
    return baseURI;
  }

  function changeBaseURI(string memory baseURI_) public returns (string memory) {
    permissionManagement.adminOnlyMethod(msg.sender);
    baseURI = baseURI_;
    return baseURI;
  }

  string _contractURI = "";

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function changeContractURI(string memory contractURI_) public returns (string memory) {
    permissionManagement.adminOnlyMethod(msg.sender);
    _contractURI = contractURI_;
    return contractURI_;
  }

  function exists(uint256 tokenId) public view returns (bool) {
    return _exists(tokenId);
  }

  /* Extend AdminOps.sol */
  function godlySetTokenURI(uint256 _tokenId, string memory _tokenURI) 
    public
    returns(uint256)
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    _setTokenURI(_tokenId, _tokenURI);
    return _tokenId;
  }

  /* Overridings */
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  mapping(uint256 => string) private _tokenURIs;

  /// @notice Fetch URL of the Token
  /// @dev From OpenZepplin
  /// @param tokenId ID of the Token whose URI to fetch
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "URI query for nonexistent token");

      string memory _tokenURI = _tokenURIs[tokenId];
      string memory base = _baseURI();

      // If there is no base URI, return the token URI.
      if (bytes(base).length == 0) {
          return _tokenURI;
      }
      
      // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
      if (bytes(_tokenURI).length > 0) {
          return string(abi.encodePacked(base, _tokenURI));
      }

      return super.tokenURI(tokenId);
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
      require(_exists(tokenId), "URI set of nonexistent token");
      _tokenURIs[tokenId] = _tokenURI;
  }

  function _burn(uint256 tokenId) internal virtual override {
      super._burn(tokenId);

      if (bytes(_tokenURIs[tokenId]).length != 0) {
          delete _tokenURIs[tokenId];
      }
  }
}
