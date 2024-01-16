// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract Suitcase is ERC721Enumerable,ReentrancyGuard, Ownable {
  using Strings for uint256;
  string public baseURI;
  string public suitecaseDigitalExtension = ".json";
  string public notRevealedUri;
  uint256 public maxSuitcaseSupply = 1500;
  bool public suitcaseHalted = true;
  bool public revealSuitcases = true;

    event MintedSuitcase(
        uint256 tokenId,
        uint256 amount,
        address indexed buyer,
        string travelkit
    );
   
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  function giftSuitcase(uint256 _suitcaseAmount, address holder) external onlyOwner {
        uint256 suitcaseSupply = totalSupply();
         require(!suitcaseHalted, "the contract is Halted");
        require(suitcaseSupply + _suitcaseAmount <= maxSuitcaseSupply, "Sold out");
        require(_suitcaseAmount > 0, "need to mint at least 1 NFT");
       
        for (uint256 i = 1; i <= _suitcaseAmount; i++) {
            _safeMint(holder, suitcaseSupply + i);
             emit MintedSuitcase(suitcaseSupply + i, _suitcaseAmount, holder,"Travel Kit Created");
        }
    }

  function suitecaseOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
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
    
    if(revealSuitcases == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), suitecaseDigitalExtension))
        : "";
  }

  function revealSuitcase() public onlyOwner {
      revealSuitcases = true;
  }
  
   function notrevealSuitecase() public onlyOwner {
      revealSuitcases = false;
  }
  
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newDigitalExtension) public onlyOwner {
    suitecaseDigitalExtension = _newDigitalExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function suitcasePause(bool _state) public onlyOwner {
    suitcaseHalted = _state;
  }

}