// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ENS.sol";

/**
______________  ___________     _________________________ ___  
\______   \   \/  /  _____/     \_   _____/\__    ___/   |   \ 
 |     ___/\     /   \  ___      |    __)_   |    | /    ~    \
 |    |    /     \    \_\  \     |        \  |    | \    Y    /
 |____|   /___/\  \______  / /\ /_______  /  |____|  \___|_  / 
                \_/      \/  \/         \/                 \/  

www.pixelglyphs.io
*/

// ENS ADDRESS (Used on all networks) 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e

contract PxgRegistrar is ERC721Enumerable, Ownable {
  string BASE_URI;
  address RESOLVER;
  bytes32 public ROOT_NODE;
  uint256 PRICE;
  bool publicRegistrationOpen = false;
  ENS ens;
  ERC721 glyphs;

  mapping(uint256 => bool) public claimedGlyphIds;
  mapping(uint256 => address) public resolvers;
  uint256 public currentResolverVersion;
  uint256 count;

  constructor(
    string memory baseUri,
    address ensAddr,
    address glyphAddr,
    bytes32 node
  ) ERC721("PXG.ETH", "PXG.ETH") {
    BASE_URI = baseUri;
    ROOT_NODE = node;
    ens = ENS(ensAddr);
    glyphs = ERC721(glyphAddr);
    admin[msg.sender] = true;
  }

  function addResolverVersion(address resolver) public onlyOwner {
    resolvers[++currentResolverVersion] = resolver;
    RESOLVER = resolver;
  }

  function setBaseUri(string memory baseUri) public onlyOwner {
    BASE_URI = baseUri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return BASE_URI;
  }

  function openReg() public onlyOwner {
    publicRegistrationOpen = true;
  }

  function updatePrice(uint256 price) public onlyOwner {
    PRICE = price;
  }

  function getTokenIdFromNode(bytes32 node) public pure returns (uint256) {
    return uint256(node);
  }

  function getOwnerFromNode(bytes32 node) public view returns (address) {
    return _exists(uint256(node)) ? ownerOf(uint256(node)) : address(0);
  }

  function setResolver(bytes32 node, uint256 version) public {
    require(resolvers[version] != address(0), "PXG: Resolver does not exist");
    require(
      getOwnerFromNode(node) == msg.sender,
      "PXG: Only owner can set resolver"
    );
    ens.setResolver(node, resolvers[version]);
  }

  mapping(bytes32 => string) public nodeToLabel;

  // root node is pxg.eth subnode is subdomain label
  function _register(string calldata subdomain) internal {
    bytes32 subdomainLabel = keccak256(bytes(subdomain));
    bytes32 node = keccak256(abi.encodePacked(ROOT_NODE, subdomainLabel));

    address currentOwner = ens.owner(node);

    require(currentOwner == address(0), "PXG: Name already claimed");
    require(
      resolvers[currentResolverVersion] != address(0),
      "PXG: No resolver set"
    );

    // pxg.eth, mysubdomain, address
    ens.setSubnodeOwner(ROOT_NODE, subdomainLabel, address(this));
    ens.setResolver(node, RESOLVER);
    _safeMint(msg.sender, uint256(node));
    nodeToLabel[node] = subdomain;
    count++;
  }

  function resolver(bytes32 node) external view returns (address) {
    return ens.resolver(node);
  }

  mapping(address => bool) private admin;

  modifier onlyAdmin() {
    require(admin[msg.sender], "Not admin");
    _;
  }

  event CollectionSupportAdded(address collection);

  event ModifyAdmin(address adminAddr, bool value);

  function modifyAdmin(address adminAddr, bool value) public onlyAdmin {
    admin[adminAddr] = value;
    emit ModifyAdmin(adminAddr, value);
  }

  mapping(address => bool) supportedCollections;

  function addCollectionSupport(address collection) public onlyAdmin {
    supportedCollections[collection] = true;
    emit CollectionSupportAdded(collection);
  }

  function supportsCollection(address collection) public view returns (bool) {
    return supportedCollections[collection];
  }

  event ClaimedGlyph(uint256 indexed glyphId);

  function claimGlyph(string calldata subdomain, uint256 glyphId) public {
    require(
      glyphs.ownerOf(glyphId) == msg.sender &&
        claimedGlyphIds[glyphId] == false,
      "PXG: Unauthorized"
    );

    claimedGlyphIds[glyphId] = true;
    _register(subdomain);
    emit ClaimedGlyph(glyphId);
  }

  function register(string calldata subdomain) public payable {
    require(publicRegistrationOpen || count >= 10000, "Not allowed");
    // uint256 len = bytes(subdomain).length;
    require(msg.value == PRICE, "PXG: Invalid value");
    _register(subdomain);
  }
}
