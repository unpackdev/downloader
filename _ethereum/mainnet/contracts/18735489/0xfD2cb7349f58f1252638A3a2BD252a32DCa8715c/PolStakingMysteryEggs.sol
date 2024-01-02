// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract PolStakingMysteryEggs is ERC1155Supply, Ownable {
  using Strings for uint256;

  // Roles
  address public minter;

  //collection details
  string public name;
  string public externalURI;
  string public symbol;
  string public imageURI;

  struct NFT {
    string creatorName;
    uint256 maxSupply;
    uint256 minted;
    string name;
    string description;
    string fileExtension;
    string animationFileExtension;
    bool locked;
    uint256 price;
    uint256 startDate;
    uint256 endDate;
    uint256 generation;
  }

  mapping(uint256 => NFT) public nftInfos;

  event NFTInfosInitialized(uint256 tokenId, uint256 maxSupply, string name);
  event NFTInfosUpdated(uint256 indexed tokenId);
  event NFTMinted(address indexed to, uint256 tokenId, uint256 amount);
  event PermanentURI(string _uri, uint256 indexed _tokenId);

  modifier onlyMinter() {
    require(msg.sender == minter, "Caller is not the minter");
    _;
  }

  modifier isUnlocked(uint256 tokenId) {
    require(nftInfos[tokenId].locked == false, "NFT is locked and can't be changed");
    _;
  }

  constructor() ERC1155("") {
    name = "PolStaking Mystery Eggs";
    symbol = "PSME";
    imageURI = "https://api.onigiri.art/polstaking/mysteryeggs/";
    externalURI = "https://polstaking.io/mysteryeggs/";
    minter = msg.sender;

    // Initiate the First Egg
    nftInfos[1].creatorName = "PolStaking";
    nftInfos[1].maxSupply = 400;
    nftInfos[1].minted = 300;
    nftInfos[1].name = "The Ancient Egg";
    nftInfos[1].description = "Nestled in a weathered, rune-carved box, the ancient egg is a remnant of a bygone era, shrouded in mystery and legend. Its shell, subtly patterned and shrouded in shadow, hints at the potential for diverse, mystical creatures within. This enigmatic artifact, forgotten yet brimming with latent power, beckons adventurers and collectors alike with its allure of ancient magic. Reveal the secrets of the past and unleash the power of the ancient egg on https://polstaking.io!";
    nftInfos[1].fileExtension = ".jpg";
    nftInfos[1].locked = false;
    nftInfos[1].price = 0;
    nftInfos[1].startDate = block.timestamp;
    nftInfos[1].endDate = 1702681200;
    nftInfos[1].generation = 0;

    _mint(msg.sender, 1, 300, "");
    emit NFTMinted(msg.sender, 1, 300);
  }

  function mint(address to, uint256 tokenId, uint256 amount) external onlyMinter {
    require((block.timestamp >= nftInfos[tokenId].startDate) && (block.timestamp <= nftInfos[tokenId].endDate), "Minting period not active");
    require(nftInfos[tokenId].minted + amount <= nftInfos[tokenId].maxSupply, "Exceeds max supply");

    nftInfos[tokenId].minted += amount;

    _mint(to, tokenId, amount, "");
    emit NFTMinted(to, tokenId, amount);
    emit NFTInfosUpdated(tokenId);
  }

  function initializeNFTInfos(
    uint256 tokenId,
    string memory _creatorName,
    uint256 _price,
    uint256 _maxSupply,
    uint256 _startDate,
    uint256 _endDate,
    string memory _name,
    string memory _description,
    string memory _fileExtension,
    uint256 _gen
  ) external onlyOwner {
      require(_startDate < _endDate || _endDate == 0, "Start date should be before end date");

      NFT storage nft = nftInfos[tokenId];
      nft.creatorName = _creatorName;
      nft.maxSupply = _maxSupply;
      nft.name = _name;
      nft.description = _description;
      nft.fileExtension = _fileExtension;
      nft.animationFileExtension = _fileExtension;
      nft.locked = false;
      nft.startDate = _startDate == 0 ? block.timestamp : _startDate;
      nft.endDate = _endDate == 0 ? type(uint256).max : _endDate;
      nft.price = _price;
      nft.generation = _gen;

      emit NFTInfosInitialized(tokenId, _maxSupply, _name);
  }

  function uri(uint256 tokenId) public view override returns (string memory) {
    string memory baseURI = string(abi.encodePacked(imageURI, tokenId.toString(), nftInfos[tokenId].fileExtension));
    
    return string(abi.encodePacked(
      '{"name": "', nftInfos[tokenId].name,
      '", "description": "', nftInfos[tokenId].description,
      '", "image": "', baseURI,
      getAnimation(tokenId),
      '", "external_url": "', externalURI, tokenId.toString(),
      '", "attributes": [',
      getSupplyInfo(tokenId),
      '{"trait_type":"Gen","value":"', nftInfos[tokenId].generation,'"},'
      '{"trait_type":"Artist","value":"', nftInfos[tokenId].creatorName,'"}'
      ']}'
    ));
  }

  function getAnimation(uint256 tokenId) internal view returns (string memory) {
    string memory animationURI = '';
    if (bytes( nftInfos[tokenId].animationFileExtension).length > 0) {
      animationURI = string(abi.encodePacked('", "animation_url": "', imageURI, tokenId.toString(),  nftInfos[tokenId].animationFileExtension));
    }
    return animationURI;
  }

  function getSupplyInfo(uint256 tokenId) internal view returns (string memory) {
    string memory supplyInformations = '';
    supplyInformations =  string(abi.encodePacked(supplyInformations,'{"trait_type":"Supply","value":"', totalSupply(tokenId).toString(),'"},'));
    return string(abi.encodePacked(supplyInformations, '{"trait_type":"Minted","display_type":"number","value":', nftInfos[tokenId].minted.toString(),',"max_value":', nftInfos[tokenId].maxSupply.toString(),'},'));
  }

  function burn(uint256 tokenId, uint256 amount) external {
    require(amount > 0, "Amount should be greater than 0");
    require(amount <= balanceOf(msg.sender, tokenId), "Amount exceeds balance");

    _burn(msg.sender, tokenId, amount);
  }

  function lockBlueprint(uint256 tokenId) external onlyOwner {
    require(nftInfos[tokenId].locked == false, "Blueprint already locked");

    nftInfos[tokenId].locked = true;
    emit PermanentURI(uri(tokenId), tokenId);
  }

  function updateMintTime(uint256 tokenId, uint256 _startDate, uint256 _endDate) external isUnlocked(tokenId) onlyOwner {
    if(_startDate != 0) nftInfos[tokenId].startDate = _startDate;
    if(_endDate != 0) nftInfos[tokenId].endDate = _endDate;
    emit NFTInfosUpdated(tokenId);
  }

  function updateBlueprintPrice(uint256 tokenId, uint256 _price) external isUnlocked(tokenId) onlyOwner {
    nftInfos[tokenId].price = _price;
    emit NFTInfosUpdated(tokenId);
  }

  function updateBlueprintInfo(uint256 tokenId, string memory _name, string memory _description, string memory _fileExtension, string memory _animationFileExtension) external isUnlocked(tokenId) onlyOwner {
    nftInfos[tokenId].name = _name;
    nftInfos[tokenId].description = _description;
    nftInfos[tokenId].fileExtension = _fileExtension;
    nftInfos[tokenId].animationFileExtension = _animationFileExtension;
    emit NFTInfosUpdated(tokenId);
  }

  function setURIs(string memory _imageURI, string memory _externalURI) external onlyOwner {
    imageURI = _imageURI;
    externalURI = _externalURI;
  }

  function setMinter(address _minter) external onlyOwner {
    minter = _minter;
  }
}