// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./Pausable.sol";
import "./ERC721A.sol";

contract MoonSharkNFT is ERC721A,AccessControl,Pausable {
  string private ipfsBase;
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  constructor(string memory _ipfs) ERC721A("MoonSharks", "SHARKS") {
    ipfsBase = _ipfs;
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
  }

  function mint(uint256 quantity) whenNotPaused() onlyRole(MINTER_ROLE) external {
    _mint(msg.sender, quantity);
  }

  function mintTo(uint256 quantity,address to) whenNotPaused() onlyRole(MINTER_ROLE) external {
    _mint(to, quantity);
  }

  function _baseURI() override internal view returns (string memory){
    return ipfsBase;
  }

  function setIpfs(string memory _ipfs) whenPaused() onlyRole(ADMIN_ROLE) external {
    ipfsBase = _ipfs;
  }

  function grantAdminRole(address adminAddress) onlyRole(ADMIN_ROLE) external {
    _setupRole(ADMIN_ROLE, adminAddress);
  }

  function grantMintRole(address mintAddress) onlyRole(ADMIN_ROLE) external {
    _setupRole(MINTER_ROLE, mintAddress);
  }

  function revokeAdminRole(address to) onlyRole(ADMIN_ROLE) external {
    _revokeRole(ADMIN_ROLE, to);
  }

  function revokeMintRole(address to) onlyRole(ADMIN_ROLE) external {
    _revokeRole(MINTER_ROLE, to);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory suffix = '.json';
    string memory baseURI = _baseURI();
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(string(abi.encodePacked(baseURI, _toString(tokenId))),suffix))  : '';
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function supportsInterface(bytes4 interfaceId) public pure override(ERC721A,AccessControl) returns (bool){
        return
            interfaceId == type(IAccessControl).interfaceId || 
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
  }

  function pause() external onlyRole(ADMIN_ROLE) {
    _pause();
  }

  function unPause() external onlyRole(ADMIN_ROLE) {
    _unpause();
  }

}
