// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./console.sol";

import "./ENS.sol";
import "./PublicResolver.sol";

import "./ECDSA.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract ENSNFTRegistrar is ERC721, Ownable {
  using ECDSA for bytes32;
  using Strings for uint256;

  event ControllerAdded(address indexed controller);
  event ControllerRemoved(address indexed controller);
  event ZoneMapped(string label, string tld);

  mapping (bytes32 => bytes32) public zones;
  mapping (bytes32 => uint256) public nonces;
  mapping (address => bool) public controllers;

  string public baseURI;

  ENS public ens;
  PublicResolver public resolver;

  constructor(
    ENS _registry,
    PublicResolver _resolver,
    string memory name,
    string memory symbol
  ) ERC721(name, symbol) {
    ens = _registry;
    resolver = _resolver;
  }

  function setResolver(PublicResolver _resolver) external onlyOwner {
    resolver = _resolver;
  }

  function setBaseURI(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  function tokenURI(uint256 tokenId)
    public view override(ERC721) returns (string memory)
  {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toHexString(32))) : "";
  }

  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
    emit ControllerAdded(controller);
  }

  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
    emit ControllerRemoved(controller);
  }

  function mapZone(string memory label, string memory tld) external onlyOwner {
    bytes32 _label = keccak256(bytes(label));
    bytes32 _tld = keccak256(bytes(tld));

    bytes32 _ens = keccak256(abi.encodePacked(bytes32(0x0), _tld));

    bytes32 _base = keccak256(abi.encodePacked(_ens, _label));
    bytes32 _zone = keccak256(abi.encodePacked(bytes32(0x0), _label));

    zones[_zone] = _base;
    emit ZoneMapped(label, tld);
  }

  function claim(
    address to,
    bytes32 zone,
    string memory label,
    bytes memory signature,
    uint256 nonce,
    bool avatar
  ) public virtual {
    bytes32 _label = keccak256(bytes(label));
    bytes32 domain = keccak256(abi.encodePacked(zone, _label));

    require(nonce > nonces[domain], "invalid nonce");

    bytes32 message = keccak256(abi.encodePacked(nonce, to, domain));
    address controller = message.toEthSignedMessageHash().recover(signature);

    require(controllers[controller], "unauthorized");

    _register(to, zone, _label, avatar);

    nonces[domain] = nonce;
  }

  function register(address to, bytes32 zone, string memory label, bool avatar) public virtual {
    require(controllers[msg.sender], "unauthorized");
    _register(to, zone, keccak256(bytes(label)), avatar);
  }

  function _register(address to, bytes32 zone, bytes32 label, bool avatar) internal virtual {
    bytes32 subnode = ens.setSubnodeOwner(zones[zone], label, address(this));
    bytes32 domain = keccak256(abi.encodePacked(zone, label));

    resolver.setAddr(subnode, to);

    if (avatar) {
      string memory urn = _generateUrn(domain);
      resolver.setText(subnode, "avatar", urn);
    }

    ens.setResolver(subnode, address(resolver));
    ens.setOwner(subnode, to);

    _mintOrTransfer(to, uint256(domain));
  }

  function _generateUrn(bytes32 domain) internal view returns (string memory urn) {
    string memory addr = uint256(uint160(address(this))).toHexString(20);
    string memory tokenId = uint256(domain).toString();
    urn = string(abi.encodePacked("eip155:1/erc721:", addr, "/", tokenId));
  }

  function _mintOrTransfer(address to, uint256 tokenId) internal virtual {
    if (_exists(tokenId)) {
      address owner = ERC721.ownerOf(tokenId);
      _transfer(owner, to, tokenId);
    } else {
      _mint(to, tokenId);
    }
  }

  function _approve(address to, uint256 tokenId) internal virtual override {
    require(to == address(0), "managed externally");
    super._approve(to, tokenId);
  }

  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual override {
    require(false, "managed externally");
    super._setApprovalForAll(owner, operator, approved);
  }

  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  ) internal view virtual override returns (bool) {
    require(false, "managed externally");
    return super._isApprovedOrOwner(spender, tokenId);
  }
}
