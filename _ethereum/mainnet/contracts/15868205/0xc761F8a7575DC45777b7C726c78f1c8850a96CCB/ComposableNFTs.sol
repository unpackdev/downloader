// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
// import "./console.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Base64.sol";
import "./Strings.sol";
import "./Layer.sol";

interface IWhitelist {
  function whitelistedAddresses(address) external view returns (bool);
}

contract ComposableNFTs is ERC721Enumerable, Ownable {
  bytes32 public termsOfService = "https://ghostballnft.com/Terms";
  
  enum LayerOrder {
    BACKGROUND,
    BODY,
    SPECIAL_BODY,
    EYES,
    GLASSES,
    SPECIAL_GLASSES,
    OUTFIT,
    HAT,
    HELMET
  }

  uint16 private numDefaultLayers = uint16(LayerOrder.HELMET) + 1;

  /// @notice When NFT minting begins (upon contract deployment)
  uint256 public mintStartDate;

  /// @notice paused is used to pause the contract in case of emergency
  bool private isPaused;

  /// @notice isRevealed is used to set the state whether or not NFTs are revealed or not
  bool private isRevealed;

  /// @notice Unique 1 of 1 NFTs will have JSON metadata and image file pre-uploaded to IPFS
  string private baseUri;

  /// @notice Records a pointer between the tokenId and the specialTokenId (which ranges from 1-maxSpecialTokenIds)
  mapping (uint256 => uint256) public tokenIdToSpecialTokenId;

  /// @notice Records how many NFTs an address has minted
  mapping (address => uint256) public mintsPerAddr;

  /// @notice max number of NFTs
  uint256 private maxTokenIds = 10000;

  /// @notice total number of tokens minted yet
  uint256 public tokenIds;

  /// @notice max number of 1 of 1 NFTs
  uint256 private maxSpecialTokenIds;

    /// @notice total number of 1 of 1 tokens minted yet
  uint256 public specialTokenIds;

  /// @notice metadata field for the NFT
  string private description;

  /// @notice cost per mint - 0.1 ETH
  uint256 private mintPrice = 100000000000000000;

  /// @notice array of all the individual SVG layers that go into the composable NFT
  Layer[] public layerContracts;

  /// @notice Contract containing the whitelist information for minting
  IWhitelist public whitelist;

  modifier onlyWhenNotPaused(){
    require(!isPaused, "Paused");
    _;
  }

  constructor(
    string memory _collectionName,
    string memory _symbol,
    string memory _description,
    string memory _baseUri,
    uint256 _maxSpecialTokenIds,
    address _whitelist
  ) ERC721(_collectionName, _symbol) {
    description = _description;
    baseUri = _baseUri;
    maxSpecialTokenIds = _maxSpecialTokenIds;
    whitelist= IWhitelist(_whitelist);
  }

  /// @notice Called by admin to initialize minting
  function startMint() public onlyOwner{
    if(mintStartDate == 0){
      mintStartDate = block.timestamp;
    }
  }

  /// @notice External function called by a user to mint an NFT - 1 at a time
  function mint(uint256 num) public payable onlyWhenNotPaused{
    require (mintStartDate != 0);
    require(num > 0, "invalid amount");

    if(block.timestamp < mintStartDate + 30 hours){
      require(whitelist.whitelistedAddresses(msg.sender) == true, "Not whitelisted");
    }
    
    require(mintsPerAddr[msg.sender] + num <= 5, "Max. 5 mints per wallet");
    require(msg.value == mintPrice * num);
    require(tokenIds + num < maxTokenIds);

    mintsPerAddr[msg.sender] += num;

    for(uint i=0; i<num; i++) {

      tokenIds += 1;
      _safeMint(msg.sender, tokenIds);
      mintItem(tokenIds);
    }
  }

  /// @notice Determines whether an NFT should be minted as an unique 1 of 1 NFT; maxSpecialTokenIds of the mints will be these special 1 of 1 NFTs
  function checkIfSpecialMint() private view returns(bool){
    // Uncomment below for Unit testing purposes only;
    // if(tokenIds == 9){ 
    //   return true;
    // }

    if(specialTokenIds == maxSpecialTokenIds){
      return false;
    }

    // This guarantees that maxSpecialTokenIds unique 1 of 1 NFTs will always be minted when the number of mints reaches 10000
    if(tokenIds > (maxTokenIds - maxSpecialTokenIds)){
      return true;
    }

    // Generates random number up to maxTokenIds, corresponding to the max number of mints
    uint pseudoRandomness = uint(
      keccak256(abi.encodePacked(
        tokenIds,
        blockhash(block.number),
        msg.sender
      ))) % maxTokenIds;

    // Double the chance during the 1st half of the mints to generate a unique 1 of 1 NFT
    if(
      (tokenIds <= (maxTokenIds / 2) && (pseudoRandomness < (maxSpecialTokenIds * 2))) || (pseudoRandomness < maxSpecialTokenIds)
    ){
      return true;
    }
    return false;
  }

  /// @notice Checks whether an already minted NFT is an unique 1 of 1 NFT
  function isSpecialNft(uint256 tokenId) internal view returns (bool){
    if(tokenIdToSpecialTokenId[tokenId] != 0){
      return true;
    }
    return false;
  }
  
  /// @notice Randomly generates each separate layer of the NFT's SVG upon mint; selectOption logic must be semi-hardcoded due to customized if-then logic
  /// @param tokenId ID of the NFT
  function mintItem(uint256 tokenId) private {
    bool shouldMintSpecialNft = checkIfSpecialMint();
    if(shouldMintSpecialNft == true){
      specialTokenIds++;
      tokenIdToSpecialTokenId[tokenIds] = specialTokenIds;
    } else {
      uint256[] memory randNums = generateRandomNumbers();

      bool noEyes;
      bool noHat;
      bool noHelmet;
      bool noOutfit;

      for(uint i = 0; i < numDefaultLayers; i++){
        if(i == uint(LayerOrder.HAT) || i == uint(LayerOrder.HELMET)){
          if (randNums[uint(LayerOrder.HAT)] % 100 < 80) {
            layerContracts[uint(LayerOrder.HAT)].selectOption(tokenId, randNums[uint(LayerOrder.HAT)], false);
            noHelmet = true;
          } else {
            layerContracts[uint(LayerOrder.HELMET)].selectOption(tokenId, randNums[uint(LayerOrder.HELMET)], false);
            noHat = true;
          }
          i++;
        }
        else if(i == uint(LayerOrder.GLASSES) || i == uint(LayerOrder.SPECIAL_GLASSES)){
          if (randNums[uint(LayerOrder.GLASSES)] % 100 < 90) {
            layerContracts[uint(LayerOrder.GLASSES)].selectOption(tokenId, randNums[i], false);
          } else {
            layerContracts[uint(LayerOrder.SPECIAL_GLASSES)].selectOption(tokenId, randNums[i], false);
            noEyes = true;
            noHelmet = true;
          }
          i++;
        }
        else if(i == uint(LayerOrder.BODY) || i == uint(LayerOrder.SPECIAL_BODY)){
          if (randNums[uint(LayerOrder.BODY)] % 100 < 95) {
            layerContracts[uint(LayerOrder.BODY)].selectOption(tokenId, randNums[i], false);
          } else {
            layerContracts[uint(LayerOrder.SPECIAL_BODY)].selectOption(tokenId, randNums[i], false);
            noOutfit = true;
          }
          i++;
        }
        else {
          layerContracts[i].selectOption(tokenId, randNums[i], false);
        }
      }

      if(noEyes) layerContracts[uint(LayerOrder.EYES)].selectOption(tokenId, 0, true);
      if(noHat) layerContracts[uint(LayerOrder.HAT)].selectOption(tokenId, 0, true);
      if(noHelmet) layerContracts[uint(LayerOrder.HELMET)].selectOption(tokenId, 0, true);
      if(noOutfit) layerContracts[uint(LayerOrder.OUTFIT)].selectOption(tokenId, 0, true);
    }
  }

  /// @notice Sets the contract paused or unpaused
  function setPaused(bool _val) public onlyOwner {
    isPaused = _val;
  }

  /// @notice Reveals the NFTs
  function reveal() external onlyOwner {
    isRevealed = true;
  }

  /// @notice Returns the NFT's metadata in JSON format for OpenSea compatibility
  /// @param tokenId ID of the NFT
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "Token not minted");

    string memory tokenName = string.concat("#", Strings.toString(tokenId));
    string memory image;
    string memory attributes;

    if(!isRevealed){
      image = string.concat(baseUri, "0");
      attributes = string.concat('"attributes": []');
    } else if(isSpecialNft(tokenId)){
      image = string.concat(baseUri, Strings.toString(tokenIdToSpecialTokenId[tokenId]));
      attributes = string.concat('"attributes": []');
    } else {
      image = string.concat("data:image/svg+xml;base64,", _generateBase64Image(tokenId));
      attributes = _generateAttributes(tokenId);
    }

    return
      string.concat(
        "data:application/json;base64,",
        Base64.encode(
          bytes(
            abi.encodePacked(
              '{"name":"',
              tokenName,
              '", "image": "',
              image,
              '",',
              attributes,
              "}"
            )
          )
        )
      );
  }

  /// @notice Generates the NFT's SVG image, as part of the JSON metadata object
  /// @param tokenId ID of the NFT
  function _generateBase64Image(uint256 tokenId)
    internal
    view
    returns (string memory)
  {
    return Base64.encode(bytes(_generateSVG(tokenId)));
  }

  /// @notice Generates the NFT's attributes, as part of the JSON metadata object
  /// @param tokenId ID of the NFT
  function _generateAttributes(uint256 tokenId)
    internal
    view
    returns (string memory)
  {
    if(tokenId == 0 || isSpecialNft(tokenId)){
      return string.concat('"attributes": []');
    }

    string memory attributes;
    
    for (uint i = 0; i < layerContracts.length; i++) {
      string memory attribute = layerContracts[i].getOptionMetadataByTokenId(tokenId);
      
      if(bytes(attribute).length != 0) {
        if(bytes(attributes).length == 0) {
          attributes = string.concat(attribute);
        } else {
          attributes = string.concat(attributes, ",", attribute);
        }
      }
    }

    return string.concat('"attributes": [', attributes, "]");
  }

  /// @notice Generates the NFT's SVG image, as part of the JSON metadata object
  /// @param tokenId ID of the NFT
  function _generateSVG(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    require(_exists(tokenId), "Token not minted");
    require(isRevealed, "NFT is not revealed yet");

    string memory svg = string.concat(
      '<svg id="',
        "nft",
        Strings.toString(tokenId),
        '" width="800" height="800" viewBox="0 0 800 800" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
        renderTokenById(tokenId),
      "</svg>"
    );

    return svg;
  }

  /// @notice Compiles each separate layer of the NFT's SVG and concatenates them together
  /// @param tokenId ID of the NFT
  function renderTokenById(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    require(_exists(tokenId), "Token not minted");
    require(isRevealed, "NFT is not revealed yet");

    string memory svgCombined;

    for (uint i = 0; i < layerContracts.length; i++) {
      string memory svgOption = layerContracts[i].renderOptionByTokenId(tokenId);
      if(bytes(svgOption).length != 0) {
        svgCombined = string(abi.encodePacked(
          svgCombined,
          svgOption
        ));
      }
    }

    return svgCombined;
  }

  /// @notice Generates a random number for each default layer; used during the minting process to select each layer's option
  function generateRandomNumbers()
    internal
    view
    returns (uint256[] memory randomValues)
  {
    uint pseudoRandomness = uint(
      keccak256(abi.encodePacked(
        tokenIds,
        blockhash(block.number),
        msg.sender
      )));

    randomValues = new uint256[](numDefaultLayers);

    for (uint256 i = 0; i < numDefaultLayers; i++) {
      randomValues[i] = uint256(keccak256(abi.encode(pseudoRandomness, i))) % 1000;
    }

    return randomValues;
  }

  /// @notice Add additional SVG layers into the Composable NFT
  function addLayers (Layer[] memory layerAddresses)
    public
    onlyOwner
  {
    for(uint i=0; i<layerAddresses.length; i++){
      if(layerContracts.length >= numDefaultLayers){
        require(Layer(layerAddresses[i]).isDefaultLayer() == false); // no revert message in order to reduce contract size
      }
      layerContracts.push(Layer(layerAddresses[i]));
    }
  }

  /// @notice Transfers ETH collected from minting to owner
  function collectMintFee()
    public
    onlyOwner
  {
    payable(msg.sender).transfer(address(this).balance);
  }

  /// @notice Fetches all of the individual Layer contracts' addresses
  function getLayerContractsLength() public view returns (uint) {
    return layerContracts.length;
  }
}