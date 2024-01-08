pragma solidity >=0.5.0 <0.7.0;

import "./ERC721.sol";
import "./AufToken.sol";

contract AufNFT is Ownable, ERC721 {
  using SafeMath2 for uint;
  mapping(address => bool) public authorized;

  modifier onlyAuthorized() {
    require(authorized[msg.sender] || owner() == msg.sender);
    _;
  }

  constructor() ERC721("Amongus.finance Ticket", "ATICKET") public {
    _setBaseURI("https://raw.githubusercontent.com/aufgames/aufcore/main/nftURI/id_");
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

  function addAuthorized(address _toAdd) onlyOwner public {
    require(_toAdd != address(0));
    authorized[_toAdd] = true;
  }

  function removeAuthorized(address _toRemove) onlyOwner public {
    require(_toRemove != address(0));
    require(_toRemove != msg.sender);
    authorized[_toRemove] = false;
  }

  function mint(address to) public onlyAuthorized  {
        uint _tokenId = totalSupply().add(1);
        _mint(to, _tokenId);
    }

}