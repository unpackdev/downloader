// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC2981.sol";
import "./ReentrancyGuard.sol";

contract ApeMoms is ERC721A, IERC2981, Ownable, ReentrancyGuard {
  string public baseURI = "ipfs://QmSMYjNDJzUMCk5p6mwPptPT8cmmPiqA38CxSpgKKoSnJa/";

  uint256 public constant maxSupply = 5555;
  uint256 public constant txLimit = 5;
  uint256 public constant freeSupply = 555;
  uint256 public constant price = 0.025 ether;

  address private proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

  constructor() ERC721A("ApeMoms", "APEMOMS") {}

  modifier mintRequire(uint256 count) {
    require(maxSupply > totalSupply(), "All mints have been claimed.");
    require(maxSupply >= totalSupply() + count, "Not enough supply left to mint your quantity.");
    require(txLimit + 1 > count, "Can't mint more than 5 at a time.");
    _;
  }

  function freeMint(uint256 count) external nonReentrant mintRequire(count) {
    require(freeSupply > totalSupply(), "All free mints have been claimed.");
    require(freeSupply >= totalSupply() + count, "Not enough free supply left to mint your quantity.");
    _safeMint(msg.sender, count);
  }

  function mint(uint256 count) external payable nonReentrant mintRequire(count) {
    require(price * count <= msg.value, "Did not send enough ETH to mint.");
    _safeMint(msg.sender, count);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory baseURI_new) external onlyOwner {
    baseURI = baseURI_new;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
    require(_exists(tokenId), "Nonexistent token");
    return (address(this), (salePrice * 5 / 100));
  }

  function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function isApprovedForAll(address owner, address operator) override public view returns (bool) {
    if (proxyRegistryAddress != address(0)){
      ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
      if (address(proxyRegistry.proxies(owner)) == operator) return true;
    }
    return super.isApprovedForAll(owner, operator);
  }

  function renounceOwnership() override public view onlyOwner {
    revert("This feature is not allowed for the ApeMoms contract");
  }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}