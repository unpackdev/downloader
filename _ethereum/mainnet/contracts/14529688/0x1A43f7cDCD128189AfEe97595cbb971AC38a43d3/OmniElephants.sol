pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract OmniElephants is ERC721, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  Counters.Counter private _circulatingSupply;

  string public baseURI;
  string public baseURI_EXT; 
  bool public publicActive = false;

  // Constants
  uint256 public constant maxSupply = 5555;
  uint256 public constant freeSupply = 1000;
  uint256 public constant maxPerTx = 10;
  uint256 public constant cost = 0.009 ether;
   
  // Payment Addresses
  address constant host = 0xB342576F21B97FD15c62c0196370c0e641c846Cd;
  address constant dev = 0xf89F5867c0043c23FAe55a9d1dA6cC096c988804;

  constructor() ERC721("OmniElephants", "OmniElephant") {
    _tokenIds.increment();
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _mintedSupply() internal view returns (uint256) {
    return _tokenIds.current() - 1;
  }

  function publicMint(uint256 _mintAmount) public payable {
    require(publicActive, "Sale has not started yet.");
    require(_mintAmount > 0, "Quantity cannot be zero");
    require(_mintAmount <= maxPerTx, "Quantity cannot be zero");
    require(_mintedSupply() + _mintAmount <= maxSupply, "Quantity requested exceeds max supply.");

    if(_mintedSupply() > freeSupply){
      require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _mint(msg.sender, _tokenIds.current());

      // increment id counter
      _tokenIds.increment();
      _circulatingSupply.increment();
    }
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseURI_EXT))
        : "";
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseURI_EXT = _newBaseExtension;
  }

  function enablePublic(bool _state) public onlyOwner {
    publicActive = _state;
  }

  function totalSupply() public view returns (uint256) {
    return _circulatingSupply.current();
  }

  function withdraw() public payable onlyOwner {
    // Dev 25%
    (bool sm, ) = payable(dev).call{value: address(this).balance * 250 / 1000}("");
    require(sm);

    // Remainder 75%
    (bool os, ) = payable(host).call{value: address(this).balance}("");
    require(os);
  }
}