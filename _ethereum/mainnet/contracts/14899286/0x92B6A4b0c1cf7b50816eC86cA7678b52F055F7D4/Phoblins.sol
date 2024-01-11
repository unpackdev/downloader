// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/* 
       .__          ___.   .__  .__        __                       
______ |  |__   ____\_ |__ |  | |__| _____/  |_  ______  _  ______  
\____ \|  |  \ /  _ \| __ \|  | |  |/    \   __\/  _ \ \/ \/ /    \ 
|  |_> >   Y  (  <_> ) \_\ \  |_|  |   |  \  | (  <_> )     /   |  \
|   __/|___|  /\____/|___  /____/__|___|  /__|  \____/ \/\_/|___|  /
|__|        \/           \/             \/                       \/ 

*/
                                                              
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract Phoblins is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256; 

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  uint256 public maxSupply = 9999;
  uint256 public maxMintAmountPerTx = 10;
  bool public paused = true;

  constructor(uint256 _maxSupply) ERC721A("phoblintown", "PHBLN") {}

  modifier mintCompliance(uint256 _mintAmount) {
      require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
      require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
      _;
  }

  function freeMint(uint256 _mintAmount) public mintCompliance(_mintAmount) {
      require(!paused, "Sale not open!");
      _safeMint(_msgSender(), _mintAmount);
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
      require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
      
      string memory currentBaseURI = _baseURI();
      return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
      uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
      uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
      paused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
      (bool os, ) = payable(owner()).call{value: address(this).balance}("");
      require(os, "Withdraw failed!");
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return uriPrefix;
  }
}