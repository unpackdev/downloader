pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract SecretSanta is ERC721, Ownable {

  using SafeMath for uint256;

  uint256 public price = 40000000000000000; // 0.04 ETH

  uint256 public MAX_TOKENS = 10111;
  
  bool public saleIsActive = false;

  mapping (address => bool) public whitelist;

  constructor() ERC721("Secret Santa", "SANTA") {
    _setBaseURI("https://secret-santa-dapp.herokuapp.com/tokens/");
  }
  
  function addToWhitelist(address addr) public onlyOwner {
    whitelist[addr] = true;
  }
  
  function addListToWhitelist(address[] memory addrs) public onlyOwner {
    for (uint i = 0; i < addrs.length; i++) {
      whitelist[addrs[i]] = true;
    }
  }

  function deleteFromWhitelist(address addr) public onlyOwner {
    whitelist[addr] = false;
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    msg.sender.transfer(balance);
  }

  function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }   

  function setPrice(uint _price) public onlyOwner {
    price = _price;
  }

  function mint(uint numberOfTokens) public payable {
    require(whitelist[msg.sender] || saleIsActive, "Address must be whitelisted OR Sale must be active to mint Tokens");
    require(msg.value >= price.mul(numberOfTokens), "Ether value sent is not correct");
    mintTokens(msg.sender, numberOfTokens);
  }

  function mintTokens(address to, uint numberOfTokens) private {
    require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");

    for(uint i = 0; i < numberOfTokens; i++) {
      uint256 mintIndex = totalSupply();
      if (totalSupply() < MAX_TOKENS) {
	_safeMint(to, mintIndex);
      }
    }
  }


  function mintByOwner(address[] memory tos, uint[] memory amounts) public onlyOwner {
    for(uint i = 0; i < tos.length; i++) {
      mintTokens(tos[i], amounts[i]);
    }
  }

}
