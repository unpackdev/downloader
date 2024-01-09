// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC2981.sol";
import "./ReentrancyGuard.sol";

contract MiaKhalifaDAO is ERC721A, IERC2981, Ownable, ReentrancyGuard {
  string public baseURI = "ipfs://QmaxB7wr14hyzVfyqfnLtW7xaq9k1GDZVzAe1W4LWsxrNz/";
  uint256 public constant maxSupply = 1000;
  uint256 public constant mintTxLimit = 5;
  uint256 public constant mintFreeLimit = 500;
  uint256 public constant mintPrice = 0.01 ether;

  address private proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

  constructor() ERC721A("MiaKhalifaDAO", "MIADAO", mintTxLimit) {}

  modifier requireMints(uint256 tokenQty) {
    require(tokenQty <= mintTxLimit, "Exceeded the maximum mints per transaction.");
    require(totalSupply() + tokenQty <= maxSupply, "Cannot mint more than the maximum supply.");
    _;
  }

  function mint(uint256 tokenQty) external payable nonReentrant requireMints(tokenQty) {
    if (totalSupply() > mintFreeLimit) require((mintPrice * tokenQty) == msg.value, "Incorrect ETH value sent");
    _safeMint(msg.sender, tokenQty);
  }

  function freeMint(uint256 tokenQty) external nonReentrant requireMints(tokenQty) {
    require(totalSupply() <= mintFreeLimit, "Cannot mint more than the maximum supply of free mints.");
    _safeMint(msg.sender, tokenQty);
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

}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}