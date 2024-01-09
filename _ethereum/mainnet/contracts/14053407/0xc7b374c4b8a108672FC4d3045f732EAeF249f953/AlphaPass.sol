// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";
import "./CollaborativeOwnable.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./IOwlToken.sol";
import "./MerkleProof.sol";
import "./ProxyRegistry.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract AlphaPass is ERC721Enumerable, CollaborativeOwnable, ReentrancyGuard {
  using SafeMath for uint256;
  using Address for address;
  using Strings for uint256;

  uint256 public maxSupply = 400;

  string public baseURI = "";
  address public proxyRegistryAddress = address(0);

  address public owlTokenAddress = address(0);

  uint256 public tokenMintPrice = 300 ether;
  bool public tokenMintIsActive = false;
  mapping(address => uint256) public lastMint;
  uint32 public mintCooldown = 172800;

  mapping(address => bool) public prepaidMinted;
  bytes32 public prepaidMerkleRoot;
  uint16 public reservedForPrepaid = 0;
  bool public prepaidMintIsActive = false;

  constructor(address _proxyRegistryAddress) ERC721("Moon Pass", "MOON") {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  //
  // Public / External
  //

  function remainingForMint() public view returns (uint256) {
    uint256 ts = totalSupply();
    uint256 available = maxSupply.sub(ts.add(reservedForPrepaid));
    return available;
  }

  function prepaidMint(bytes32[] calldata merkleProof) external nonReentrant {
    require(prepaidMintIsActive);
    require(!prepaidMinted[_msgSender()]);

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(merkleProof, prepaidMerkleRoot, leaf));

    uint256 ts = totalSupply();
    require(ts.add(1) <= maxSupply);

    _safeMint(_msgSender(), ts);

    prepaidMinted[_msgSender()] = true;
    reservedForPrepaid--;
  }

  function mintWithTokens() external nonReentrant {
    require(tokenMintIsActive);
    require(remainingForMint() > 0);

    uint256 elapsedTime = block.timestamp - lastMint[_msgSender()];
    require(elapsedTime >= mintCooldown, "cooldown");

    IOwlToken(owlTokenAddress).redeemTokens(_msgSender(), tokenMintPrice);

    uint256 ts = totalSupply();
    _safeMint(_msgSender(), ts);

    lastMint[_msgSender()] = block.timestamp;
  }

  // Override ERC721
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  // Override ERC721
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId));
        
    string memory __baseURI = _baseURI();
    return bytes(__baseURI).length > 0 ? string(abi.encodePacked(__baseURI, tokenId.toString(), ".json")) : '.json';
  }

  // Override ERC721
  function isApprovedForAll(address owner, address operator) override public view returns (bool) {
    if (address(proxyRegistryAddress) != address(0)) {
      ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
      if (address(proxyRegistry.proxies(owner)) == operator) {
        return true;
      }
    }
    return super.isApprovedForAll(owner, operator);
  }

  //
  // Collaborator Access
  //

  function airDrop(address to) external onlyCollaborator {
    require(to != address(0));
    require(remainingForMint() > 0);

    uint256 ts = totalSupply();
    _safeMint(to, ts);
  }

  function setBaseURI(string memory uri) external onlyCollaborator {
    baseURI = uri;
  }

  function reduceMaxSupply(uint256 newMaxSupply) external onlyCollaborator {
    require(newMaxSupply >= 0 && newMaxSupply < maxSupply);
    require(newMaxSupply >= totalSupply());
    maxSupply = newMaxSupply;
  }

  function setTokenMintIsActive(bool active) external onlyCollaborator {
    tokenMintIsActive = active;
  }

  function setTokenMintPrice(uint256 newPrice) external onlyCollaborator {
    tokenMintPrice = newPrice;
  }

  function setPrepaidMintIsActive(bool active) external onlyCollaborator {
    prepaidMintIsActive = active;
  }

  function setProxyRegistryAddress(address prAddress) external onlyCollaborator {
    proxyRegistryAddress = prAddress;
  }

  function setOwlTokenAddress(address newAddress) external onlyCollaborator {
    owlTokenAddress = newAddress;
  }

  function setMintCooldown(uint32 cooldown) external onlyCollaborator {
    mintCooldown = cooldown;
  }

  function setPrepaidMerkleRoot(bytes32 newRoot, uint16 newReserved) external onlyCollaborator {
    require(newReserved <= maxSupply);
    prepaidMerkleRoot = newRoot;
    reservedForPrepaid = newReserved;
  }

  function withdraw() external onlyCollaborator nonReentrant {
    uint256 balance = address(this).balance;
    payable(owner()).transfer(balance);
  }
}