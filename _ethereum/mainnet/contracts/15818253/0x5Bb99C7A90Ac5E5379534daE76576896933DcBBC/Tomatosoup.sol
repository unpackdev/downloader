// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

// Github: @Evileye0666
contract Tomatosoup is ERC721Enumerable, Ownable, ReentrancyGuard {
  mapping(address => bool) public isMinted;
  uint256 public immutable maxSupply;
  uint256 public immutable price;
  uint256 public burnCounts;
  address public newContract;
  bool isReveal;
  string ipfsURI;
  //only user
  modifier callerIsUser() {
    require(!Address.isContract(_msgSender()), 'Contract is unallowed.');
    _;
  }

  //start
  constructor(
    string memory _ipfsURI,
    string memory _name,
    string memory _symbol,
    uint256 _maxSupply,
    uint256 _price
  ) payable ERC721(_name, _symbol) {
    ipfsURI = _ipfsURI;
    maxSupply = _maxSupply;
    price = _price;
  }

  //Pubmint NFT
  function pubMint(uint256 _quantity) external payable callerIsUser nonReentrant {
    address minter = _msgSender();
    uint256 totalPrice_ = getCaculatePrice(minter, _quantity);
    require(totalPrice_ <= msg.value, 'Value is Not Right.');
    require(totalSupply() + _quantity <= maxSupply, 'Exceed To MaxSupply.');
    if (!isMinted[minter]) isMinted[minter] = true;
    for (uint256 i = 0; i < _quantity; i++) {
      _safeMint(minter, totalSupply());
    }
  }

  function getCaculatePrice(address _address, uint256 _quantity) public view returns (uint256 _price) {
    _price = isMinted[_address] ? price * _quantity : price * (_quantity - 1);
  }

  //set token url
  function setIpfsURI(string memory _newIpfsURI, bool _reveal) public onlyOwner {
    ipfsURI = _newIpfsURI;
    isReveal = _reveal;
  }

  function burnTomato(uint256[] memory _tomatos) external {
    require(newContract != address(0), 'NewContract is not set.');
    require(newContract == msg.sender, 'Invalid burner address');
    require(burnCounts == _tomatos.length, 'Three Bear burn from Cow.');
    for (uint256 i = 0; i < _tomatos.length; i++) {
      _burn(_tomatos[i]);
    }
  }

  function setNewContract(address _contract, uint256 _burnCounts) public onlyOwner {
    newContract = _contract;
    burnCounts = _burnCounts;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return ipfsURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);
    string memory baseURI = _baseURI();
    string memory url = isReveal ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : baseURI;
    return bytes(baseURI).length > 0 ? url : '';
  }

  //Withdraw ETH.
  function withdraw() public payable onlyOwner {
    uint256 amount = address(this).balance;
    Address.sendValue(payable(msg.sender), amount);
  }
}
