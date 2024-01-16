// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,_@       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at farmhand@thefarm.game
 * Found a broken egg in our contracts? We have a bug bounty program bugs@thefarm.game
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./NFTDescriptor.sol";

contract ImperialEggs is Ownable, ERC721AQueryable, ERC2981ContractWideRoyalties, Pausable {
  // Events
  event Mint(address indexed owner, uint16 indexed tokenId);
  event Burn(address indexed owner, uint16 indexed tokenId);
  event InitializedContract(address thisContract);

  // Max Supply of Imperial Eggs
  uint256 public maxSupply = 100;

  // Number of imperial egg tokens have been minted so far
  uint256 public minted;

  // ImperialEggs Color Palettes (Index => Hex Colors)
  mapping(uint8 => string[]) public palettes;

  // ImperialEggs Accessories (Custom RLE)
  // Storage of each image data
  struct ImperialEggsImage {
    string name;
    bytes rlePNG;
  }

  // Trait RLE Data for ImperialEggs Image
  mapping(uint256 => ImperialEggsImage) internal traitRLEData;

  // Common description that shows in all tokenUri
  string private metadataDescription =
    'Specialty Eggs & items can be bought from the Egg Shop. Fabled to hold special properties, only Season 1 Farm Game holders will know what they hold.'
    ' All images and metadata is generated and stored 100% on-chain. No IPFS, No API. Just the blockchain. https://thefarm.game';

  // address => allowedToCallFunctions
  mapping(address => bool) private controllers;

  /**
   * @dev Modifer to require _msgSender() to be a controller
   */
  modifier onlyController() {
    _isController();
    _;
  }

  // Optimize for bytecode size
  function _isController() internal view {
    require(controllers[_msgSender()], 'Only controllers');
  }

  constructor() ERC721A('TFG: Imperial Eggs', 'TFGIE') {
    controllers[_msgSender()] = true;
    emit InitializedContract(address(this));
  }

  /**
   * ██ ███    ██ ████████
   * ██ ████   ██    ██
   * ██ ██ ██  ██    ██
   * ██ ██  ██ ██    ██
   * ██ ██   ████    ██
   * This section has internal only functions
   */

  /**
   * @notice Upload a single image
   * @dev Only callable internally
   * @param typeId the typeID of the NFT
   * @param image calldata for image {name / RLE image rlePNG}
   */
  function _uploadRLEImage(uint256 typeId, ImperialEggsImage calldata image) internal {
    traitRLEData[typeId] = ImperialEggsImage(image.name, image.rlePNG);
  }

  /**
   * @notice Add a single color to a color palette
   * @param _paletteIndex index for current color
   * @param _color 6 character hex code for color
   */
  function _addColorToPalette(uint8 _paletteIndex, string calldata _color) internal {
    require(bytes(_color).length == 6 || bytes(_color).length == 0, 'Wrong lenght');
    palettes[_paletteIndex].push(_color);
  }

  /**
   * @notice Override _startTokenId function of ERC721A starndard contract
   */

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /**
   * @notice Given a typeId, construct a base64 encoded data URI for an official TheFarm DAO FabergeEggNFT.
   */
  function _dataURI(uint256 typeId) internal view returns (string memory) {
    string memory name = string(abi.encodePacked(traitRLEData[typeId].name));

    return _genericDataURI(name, metadataDescription, typeId);
  }

  /**
   * @notice Given a name, description, and typeId, construct a base64 encoded data URI
   */
  function _genericDataURI(
    string memory name,
    string memory description,
    uint256 typeId
  ) internal view returns (string memory) {
    NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
      name: name,
      description: description,
      background: '------',
      elements: _getElementsForTypeId(typeId),
      attributes: '',
      advantage: 0,
      width: uint8(32),
      height: uint8(32)
    });

    return NFTDescriptor.constructTokenURI(params, palettes);
  }

  /**
   * @notice Get all TheFarm elements for the passed `seed`.
   * @param typeId Seed string
   */
  function _getElementsForTypeId(uint256 typeId) internal view returns (bytes[] memory) {
    bytes[] memory _elements = new bytes[](1);
    _elements[0] = traitRLEData[typeId].rlePNG;
    return _elements;
  }

  /**
   * ███████ ██   ██ ████████
   * ██       ██ ██     ██
   * █████     ███      ██
   * ██       ██ ██     ██
   * ███████ ██   ██    ██
   * This section has external functions
   */

  function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
    require(_exists(tokenId), "Token doesn't exist");
    return _dataURI(tokenId);
  }

  /**
   *  ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████
   * ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   * ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████
   * ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   *  ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██
   * This section if for controllers (possibly Owner) only functions
   */

  /**
   * @notice Mint a single imperial egg token - All payment / game logic / quantity should be handled in the game contract.
   * @dev Only callable by a controller
   * @param _recipient The address to recieve the Imperial Egg
   * @param _quantity The mint amount of Imperial Eggs
   */

  function mint(address _recipient, uint256 _quantity) external whenNotPaused onlyController {
    require(_quantity > 0, 'Invalid mint amount');
    require(totalSupply() + _quantity <= maxSupply, 'Max supply exceeded');
    minted++;
    _safeMint(_recipient, _quantity);
  }

  /**
   * @notice Burn a token - any game logic / quantity should be handled before this function.
   * @param tokenId The token ID of the NFT to burn
   */
  function burn(uint16 tokenId) external whenNotPaused onlyController {
    require(ownerOf(tokenId) == tx.origin, 'Caller is not owner');
    _burn(tokenId);
    emit Burn(tx.origin, tokenId);
  }

  /**
   * @notice Add a single color to a color palette
   * @dev This function can only be called by the owner
   * @param _paletteIndex index for current color
   * @param _color 6 character hex code for color
   */
  function addColorToPalette(uint8 _paletteIndex, string calldata _color) external onlyController {
    require(palettes[_paletteIndex].length <= 255, 'Palettes can only hold 256 colors');
    _addColorToPalette(_paletteIndex, _color);
  }

  /**
   * @notice Add colors to a color palette
   * @dev This function can only be called by the owner
   * @param _paletteIndex index for colors
   * @param _colors Array of 6 character hex code for colors
   */
  function addManyColorsToPalette(uint8 _paletteIndex, string[] calldata _colors) external onlyController {
    require(palettes[_paletteIndex].length + _colors.length <= 256, 'Palettes can only hold 256 colors');
    for (uint256 i = 0; i < _colors.length; i++) {
      _addColorToPalette(_paletteIndex, _colors[i]);
    }
  }

  /**
   * @notice Upload a single Imperial Egg
   * @dev Only be callable by controllers
   * @param typeId the typeID of the NFT
   * @param image calldata for image {name / base64 base64PNG}
   */
  function uploadRLEImage(uint256 typeId, ImperialEggsImage calldata image) external onlyController {
    _uploadRLEImage(typeId, image);
  }

  /**
   * @notice Upload multiple EggShop types
   * @dev Only be callable by controllers
   * @param startTypeId the starting typeID of the NFT + 1 will be added for each array element
   * @param _images calldata for image {name / base64 base64PNG}
   */
  function uploadManyRLEImages(uint256 startTypeId, ImperialEggsImage[] calldata _images) external onlyController {
    for (uint256 i = 0; i < _images.length; i++) {
      _uploadRLEImage(startTypeId + i, _images[i]);
    }
  }

  /**
   * @notice Enables owner to pause / unpause minting
   */
  function setPaused(bool _paused) external onlyController {
    if (_paused) _pause();
    else _unpause();
  }

  /**
   * @notice Internal call to enable an address to call controller only functions
   * @param _address the address to enable
   */
  function _addController(address _address) internal {
    controllers[_address] = true;
  }

  /**
   * @notice enables multiple addresses to call controller only functions
   * @dev Only callable by the owner or existing controller
   * @param _addresses array of the address to enable
   */
  function addManyControllers(address[] memory _addresses) external onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _addController(_addresses[i]);
    }
  }

  /**
   * @notice removes an address from controller list and ability to call controller only functions
   * @dev Only callable by the owner or existing controller
   * @param _address the address to disable
   */
  function removeController(address _address) external onlyController {
    controllers[_address] = false;
  }

  /**
   * @notice set new max supply of the imperial eggs
   * @dev Only callable by the owner or existing controller
   * @param _maxSupply new max supply value of the imperial eggs
   */

  function setMaxSupply(uint256 _maxSupply) external onlyController {
    maxSupply = _maxSupply;
  }

  /**
   * @notice Set the _collectionName
   * @dev Only callable by the owner
   * @param _newName the NFT collection name
   * @param _newDesc the NFT collection description
   * @param _newImageUri the NFT collection impage URL (ipfs://folder/to/cid)
   * @param _newFee set the NFT royalty fee 10% max percentage (using 2 decimals - 10000 = 100, 0 = 0)
   * @param _newRecipient set the address of the royalty fee recipient
   */
  function setCollectionInfo(
    string memory _newName,
    string memory _newDesc,
    string memory _newImageUri,
    string memory _newExtLink,
    uint16 _newFee,
    address _newRecipient
  ) external onlyOwner {
    _collectionName = _newName;
    _collectionDescription = _newDesc;
    _imageUri = _newImageUri;
    _externalLink = _newExtLink;
    _sellerRoyaltyFee = _newFee;
    _recipient = _newRecipient;
    _setRoyalties(_newRecipient, _newFee);
  }

  /**
   * @notice Update the metadata description
   * @dev Only callable by the controller
   * @param _desc New description
   */

  function updateMetaDesc(string memory _desc) external onlyController {
    metadataDescription = _desc;
  }

  /// @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, ERC2981Base, IERC721A)
    returns (bool)
  {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165
      interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721
      interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata
      interfaceId == 0x2a55205a || // ERC165 interface ID for ERC2981
      super.supportsInterface(interfaceId);
  }
}
