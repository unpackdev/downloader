pragma solidity ^0.8.0;

//   '||'''|,    /||   '||'''|, '||''''| '||''''|    /||   .|'''', '||''''| 
//    ||   ||  // ||    ||   ||  ||   .   ||  .    // ||   ||       ||   .  
//    ||...|' //..||..  ||...|'  ||'''|   ||''|   //..||.. ||       ||'''|  
//    || \\       ||    || \\    ||       ||          ||   ||       ||      
//   .||  \\.     ||   .||  \\. .||....| .||.         ||   `|....' .||....| 

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract R4REF4CE is ERC721, Ownable {
  using Counters for Counters.Counter;

  // R4REF4CE Addresses:
  address _rare = 0x346C7D8D57Cb417676D5b7D477dc70E1d3d41fb3;
  address _face = 0xb76B0639d0B3789911475538060BF12eb39218A7;
  // Maximum supply cap:
  uint256 constant public _maxSupply = 101;
  // Initial base fee 0.5 ether:
  uint256 public _baseFee = 500000000000000000;
  // Initial queue fee 0.25 ether:
  uint256 public _queueFee = 250000000000000000;
  // Current length of queue:
  Counters.Counter private _queueLength;
  // Tracks next token ID and enforces max supply:
  Counters.Counter private _currentTokenId;

  constructor() ERC721("R4REF4CE", "R4REF4CE") {}

  function _baseURI() internal view virtual override returns (string memory) {
    return "https://r4ref4ce.xyz/api/token/";
  }

  // Current total supply of minted tokens:
  function totalSupply() public view returns (uint256) {
    return _currentTokenId.current();
  }

  // Current length of the queue:
  function queueLength() public view returns (uint256) {
    return _queueLength.current();
  }

  // Allow owner to decrement the queue when a new face is complete:
  function decrementQueue() external onlyOwner returns (uint256) {
    _queueLength.decrement();
    return _queueLength.current();
  }

  // Allow owner to change base fee:
  function setBaseFee(uint256 newFee) external onlyOwner returns (uint256) {
    _baseFee = newFee;
    return _baseFee;
  }

  // Allow owner to change queue fee:
  function setQueueFee(uint256 newFee) external onlyOwner returns (uint256) {
    _queueFee = newFee;
    return _queueFee;
  }

  // Allow R4REF4CE to withdraw fees:
  function withdraw() public onlyOwner {
    uint256 half = address(this).balance / 2;
    require(payable(_rare).send(half));
    require(payable(_face).send(half));
  }

  function mintFace() external payable returns (uint256) {
    // Enforce maximum supply:
    require(_currentTokenId.current() < _maxSupply, "Maximum supply has been reached!");
    // Enforce base fee + queue fee:
    require(msg.value >= _baseFee + _queueLength.current() * _queueFee, "Not enough ether provided!");
    // Get current token ID:
    uint256 tokenId = _currentTokenId.current();
    // Mint to sender:
    _mint(msg.sender, tokenId);
    // Increment current token ID:
    _currentTokenId.increment();
    // Increment queue:
    _queueLength.increment();
    return tokenId;
  }
}