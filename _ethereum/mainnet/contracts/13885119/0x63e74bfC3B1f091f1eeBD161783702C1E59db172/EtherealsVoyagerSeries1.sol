pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";

contract EtherealsVoyagersSeries1 is ERC721, Ownable {
  uint256 internal _tokenIds;
  string internal _baseTokenURI;

  string public proof;
  uint256 public MAX_SUPPLY = 105;

  constructor() ERC721("Ethereals Voyagers Series 1", "VOYAGER SERIES 1") {
    for (uint256 i = 0; i < 5; i++) {
      _mint(msg.sender);
    }
  }

  function totalSupply() external view returns (uint256) {
    return _tokenIds;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setProof(string calldata _proof) public onlyOwner {
    proof = _proof;
  }

  function setBaseTokenURI(string calldata URI) public onlyOwner {
    _baseTokenURI = URI;
  }

  function mint(address[] calldata to) public onlyOwner {
    require(_tokenIds + to.length <= MAX_SUPPLY, "Exceeds maximum number of tokens");

    for (uint256 i = 0; i < to.length; i++) {
      _mint(to[i]);
    }
  }

  function _mint(address to) internal {
    _safeMint(to, _tokenIds);
    _tokenIds += 1;
  }
}