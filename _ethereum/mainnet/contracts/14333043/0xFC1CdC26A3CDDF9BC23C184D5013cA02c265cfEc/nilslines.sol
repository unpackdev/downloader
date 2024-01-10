// SPDX-License-Identifier: None

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./Counters.sol";

contract nilslines is Ownable, ERC721 {
  
  using Counters for Counters.Counter;
  Counters.Counter private idCounter;

  using SafeMath for uint256;
  uint256 public maxSupply = 8;
  string public baseURI;
  address private deployer;

  constructor() ERC721("Nil Cordan", "NC") { 
    deployer = msg.sender;
  }

  function mint(uint amount) external {
    require(amount <= 8, "Tx limit");
    create(msg.sender, amount);
  }
  function create(address wallet, uint amount) internal {
    uint currentSupply = idCounter.current();
    require(currentSupply.add(amount) <= maxSupply, ":(");
    for(uint i = 0; i< amount; i++){
    currentSupply++;
    _safeMint(wallet, currentSupply);
    idCounter.increment();
    }
  }
  function totalSupply() public view returns (uint){
    return idCounter.current();
  }
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }
  function setUri(string calldata newUri) public onlyOwner {
    baseURI = newUri;
  }

}