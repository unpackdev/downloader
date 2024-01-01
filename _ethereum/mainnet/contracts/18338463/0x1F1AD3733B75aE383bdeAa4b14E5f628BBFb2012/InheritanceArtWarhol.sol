//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./IERC20.sol";

contract iAIWarhol is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _counter;
  mapping(address => uint) public minters;
  mapping(uint256 => string) private tokenBaseURIs;
  uint public MAX_SUPPLY = 50;
  bool public saleIsActive = false;
  address private manager;
  address private appCaller;
  IERC20 public iAI;
  string public baseURI1;
  string public baseURI2;
  string public baseURI3;

  constructor() ERC721('Warhol Mao', 'iAI') Ownable() {}

  modifier onlyOwnerOrManager() {
    require(owner() == _msgSender() || manager == _msgSender(), 'Caller is not the owner or manager');
    _;
  }

  function setiAIaddress(address _tokenAddress) external onlyOwnerOrManager {
    iAI = IERC20(_tokenAddress);
  }

  function setManager(address _manager) external onlyOwner {
    manager = _manager;
  }

  function getManager() external view onlyOwnerOrManager returns (address) {
    return manager;
  }

  function setMaxSupply(uint _maxSupply) external onlyOwnerOrManager {
    MAX_SUPPLY = _maxSupply;
  }

  function totalToken() public view returns (uint256) {
    return _counter.current();
  }

  function flipSale() public onlyOwnerOrManager {
    saleIsActive = !saleIsActive;
  }

  function setBaseURI1(string calldata uri) external onlyOwnerOrManager {
    baseURI1 = uri;
  }

  function setBaseURI12(string calldata uri) external onlyOwnerOrManager {
    baseURI2 = uri;
  }

  function setBaseURI3(string calldata uri) external onlyOwnerOrManager {
    baseURI3 = uri;
  }

  function setBaseURI(uint256 tokenId, string memory uri) internal onlyOwnerOrManager {
    tokenBaseURIs[tokenId] = uri;
  }

  function baseURI(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');
    return tokenBaseURIs[tokenId];
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');
    return baseURI(tokenId);
  }

  function withdrawAll(address _address) public onlyOwnerOrManager {
    uint256 balance = address(this).balance;
    require(balance > 0, 'Balance is zero');
    (bool success, ) = _address.call{value: balance}('');
    require(success, 'Transfer failed.');
  }

  function widthdrawiAI(address _address, uint256 _amount) public onlyOwnerOrManager {
    iAI.transfer(_address, _amount);
  }

  function reserveMintNFT(uint256 reserveAmount, address mintAddress, string calldata uri) external onlyOwnerOrManager {
    require(totalSupply() + reserveAmount <= MAX_SUPPLY, 'Collection Sold Out');
    uint counter = _counter.current();
    for (uint256 i = 0; i < reserveAmount; i++) {
      setBaseURI(counter + 1, uri);
      _safeMint(mintAddress, counter + 1);
      _counter.increment();
    }
  }

  function mint(uint iAIamount, uint numberOfTokens, uint uriNumber) external payable {
    require(saleIsActive, 'Sale is not active.');
    require(numberOfTokens >= 1, 'You must at least mint 1 Token');
    require(totalSupply() + numberOfTokens <= MAX_SUPPLY, 'Collection Sold Out');

    iAI.transferFrom(msg.sender, address(this), iAIamount);

    string memory uri;
    if (uriNumber == 1) {
      uri = baseURI1;
    } else if (uriNumber == 2) {
      uri = baseURI2;
    } else {
      uri = baseURI3;
    }

    for (uint256 i = 0; i < numberOfTokens; i++) {
      uint256 mintIndex = _counter.current() + 1;
      if (mintIndex <= MAX_SUPPLY) {
        setBaseURI(mintIndex, uri);
        _safeMint(msg.sender, mintIndex);
        minters[msg.sender];
        _counter.increment();
      }
    }
  }

  // The following functions are overrides required by Solidity.
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
