pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract WSDC is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.09 ether;
  uint256 public maxSupply = 2997;
  uint256 public maxMintAmount = 5;
  uint256 public maxMintsPerAccount = 5;
  bool public paused = false;
  bool public revealed = false;
  bool public onlyAllowList = true;
  string public notRevealedUri;
  mapping(address => uint256) public mintsPerAccount;
  address[] public allowList;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    address _safe
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    mint(60, _safe);
    pause(true);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount, address to ) public payable {
    uint256 supply = totalSupply();
    require(to != address(0), "Minting to the null address is not allowed");
    require(!paused,"NFT is paused");
    require(_mintAmount > 0, "mint amount must be greater than 0"); 
    require(supply + _mintAmount <= maxSupply, "mint amount must be less than maxSupply");
    if (msg.sender != owner()) {
        if(onlyAllowList){
            require(isAllowListed(to), "You are not in the allow list");
        }
        require(_mintAmount <= maxMintAmount, "mint amount must be less than maxMintAmount");
        require(mintsPerAccount[to] < maxMintsPerAccount, "Sender has reached max mints per account");
        require(msg.value >= cost * _mintAmount, "Sender does not have enough ether to mint");
        mintsPerAccount[to] += _mintAmount;
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(to, supply + i);
    }
  }

  function walletOfOwner(address _owner)
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
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }

  function setMaxMintAmmount(uint256 _maxMintAmount) public onlyOwner {
      maxMintAmount = _maxMintAmount;
  }

  function uploadAllowList(address[] memory _allowList, bool overwrite) public onlyOwner {
    if(overwrite) {
        delete allowList;
        allowList = _allowList;
    } else {
        for (uint i=0; i < _allowList.length; i++) {
            allowList.push(_allowList[i]);
        }
    }
  }

  function isAllowListed(address account) public view returns (bool) {
    for (uint i=0; i < allowList.length; i++) {
        if(allowList[i] == account) {
            return true;
        }
    }
    return false;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw() public payable onlyOwner {
    //4% of mint
    (bool alx, ) = payable(0x527F912Fd8e7b268af681F7249FE1204855A15DA).call{value: address(this).balance * 4 / 100}("");
    require(alx);

    //10% of mint
    (bool design, ) = payable(0xd8fAAc71A20d38b84ADA19dc80419d5Fc17eDE76).call{value: address(this).balance * 10 / 100}("");
    require(design);

    //86% of mint
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);

  }
}
