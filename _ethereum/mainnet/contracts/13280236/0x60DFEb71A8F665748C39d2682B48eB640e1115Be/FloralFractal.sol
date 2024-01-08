// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

contract FloralFractal is Ownable, ERC721Enumerable  {
  using SafeMath for uint;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  mapping(string => uint8) hashes;

  // Sale
  uint256 public price = 0.05 ether;
  uint public MAX_FF = 1000;
  uint public mintableSupply = 100;
  bool private isSaleActive = true;
  uint public maxPerTx = 20;
  string private _baseURIextended = 'https://floral-fractal.art/api/token/';
  uint[2500] public metaversePositions;


  constructor() ERC721("Floral Fractal", "ARTFF") {}

  // Modifiers
  modifier verifyBuy(uint _amount) {
    require(isSaleActive != false, "Sorry, Sale must be active!");
    require(_totalSupply() < mintableSupply, "Error 1000 Sold Out!");
    require(_totalSupply().add(_amount) <= mintableSupply, "Hold up! Purchase would exceed max supply. Try a lower amount.");
    require(_amount <= maxPerTx, "Hey you can not buy more than 20 at one time. Try a smaller amount.");
    require(msg.value >= price.mul(_amount), "Dang! You dont have enough ETH!");
    _;
  }

  //
  // FloralFractal
  //
  function toggleSaleState() external onlyOwner {
    isSaleActive = !isSaleActive;
  }

  function contractURI() public view returns (string memory) {
    return _baseURIextended;
  }

  function _baseURI() internal view override returns (string memory) {
      return _baseURIextended;
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
      _baseURIextended = baseURI_;
  }

  function _totalSupply() public view returns (uint) {
      return _tokenIds.current();
  }

  // Buy tokens
  function buyFloralFractal(uint _amount) external payable verifyBuy(_amount) {
    address _to = msg.sender;
    for (uint i = 0; i < _amount; i++) {
        uint id = _totalSupply() + 1;
        _safeMint(_to, id);
        _tokenIds.increment();
    }
  }

  // Price
  function setPrice(uint256 _newPrice) public onlyOwner {
      price = _newPrice;
  }

  // Mintable Supply
  function setMintableSupply(uint256 _newValue) public onlyOwner {
      mintableSupply = _newValue;
  }

  // balance
  function getBalance() public view returns(uint) {
    return address(this).balance;
  }

  // Withdraw
  function withdraw() public onlyOwner{
      address payable to = payable(msg.sender);
      to.transfer(getBalance());
  }

  function withdrawMoneyTo(address payable _to) public {
    _to.transfer(getBalance());
  }

  // Airdrop
  function airdrop(address[] calldata _recipients) external onlyOwner {
      require(
          totalSupply() + _recipients.length <= (MAX_FF),
          "Airdrop minting will exceed maximum supply"
      );
      require(_recipients.length != 0, "Address not found for minting");
      for (uint256 i = 0; i < _recipients.length; i++) {
          require(_recipients[i] != address(0), "Minting to Null address");
          //_mint(_recipients[i]);
          uint id = _totalSupply() + 1;
          _safeMint(_recipients[i], id);
          _tokenIds.increment();

      }
  }

  // Metaverse positions
  function setMetaversePosition(uint _tokenId, uint _position) public {
    require(_position < 2500, "Position must be lower than 2500");
    require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: transfer caller is not owner nor approved");

    metaversePositions[_position] = _tokenId;
  }

  function getAllPositions() public view returns (uint[2500] memory){
    uint[2500] memory d = metaversePositions;
    return d;
  }
}
