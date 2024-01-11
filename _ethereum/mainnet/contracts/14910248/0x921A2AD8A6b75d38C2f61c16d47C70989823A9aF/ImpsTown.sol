// SPDX-License-Identifier: MIT

/**********************************  HOME OF THE EVIL IMPS  *****************************
 __  .___  ___. .______     _______.___________.  ______   ____    __    ____ .__   __. 
|  | |   \/   | |   _  \   /       |           | /  __  \  \   \  /  \  /   / |  \ |  | 
|  | |  \  /  | |  |_)  | |   (----`---|  |----`|  |  |  |  \   \/    \/   /  |   \|  | 
|  | |  |\/|  | |   ___/   \   \       |  |     |  |  |  |   \            /   |  . `  | 
|  | |  |  |  | |  |   .----)   |      |  |     |  `--'  |    \    /\    /    |  |\   | 
|__| |__|  |__| | _|   |_______/       |__|      \______/      \__/  \__/     |__| \__| 

******************************************************************************************

HEY LOSER!

NOT SURE WHY YOU ARE HERE BUT YOU ARE LOOKING IN THE WRONG PLACE. 

THERE IS NOTHING SMART ABOUT THIS SMART CONTRACT.

IT IS SO DUMB.

LIKE YOU

******************************************************************************************/

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract ImpsTown is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;
  using Counters for Counters.Counter;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public revealed = false;

  uint256 public freeLimit = 2;
  mapping(address => uint256) public freeRecords;

  uint256 public mintLimit = 6;
  mapping(address => uint256) public mintRecords;

  uint256 public reservedforHell = 666;
  uint256 public howManyWentToHell;

  event mintEvent (
    address indexed user, 
    uint256 _mintAmountRecord,
    uint256 time
  );

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Exceeded Transaction Limit!");
    require(totalSupply() - reservedforHell + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Imps do not like wimps witout ether. We follow ether mama!");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {

    require(!paused, "The contract is paused!");

    if (msg.value == 0 ) {
      require(cost == 0, "Want free? Next life please.");
      require(freeRecords[msg.sender] +_mintAmount <= freeLimit,"Only 2 free imps per wallet! Steal from others!");
      freeRecords[msg.sender] += _mintAmount;
    } else {
       require(mintRecords[msg.sender] +_mintAmount <= mintLimit, "Only 6 mints per wallet! You are quite rich!");
    }
      _safeMint(msg.sender, _mintAmount);
      mintRecords[msg.sender] += _mintAmount;
      emit mintEvent(msg.sender, _mintAmount, block.timestamp);

  }
  
  function sentToHell(uint256 _mintAmount, address _receiver) external onlyOwner {
      require(howManyWentToHell + _mintAmount <= reservedforHell, "Hell is not very big bro");
      _safeMint(_receiver, _mintAmount);
      howManyWentToHell += _mintAmount;
      emit mintEvent(_receiver, _mintAmount, block.timestamp);
  }

  function airdropMint(address[] memory _recipients, uint256 _mintAmount) external mintCompliance(_mintAmount) onlyOwner
  {
        for (uint256 i = 0; i < _recipients.length; i++) {
            _safeMint(_recipients[i], _mintAmount);
              emit mintEvent(_recipients[i], _mintAmount, block.timestamp);
        }
    }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
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

    // =============================================================================
    // This will transfer the remaining contract balance to the Great Evil One.
    // And you shall not be able to do anything but to watch it via Etherscan.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);

  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

}
