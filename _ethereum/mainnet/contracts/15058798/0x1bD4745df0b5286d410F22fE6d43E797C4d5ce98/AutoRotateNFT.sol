//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./base64.sol";
import "./Strings.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract AutoRotateNFT is ERC721, Ownable {
  using Strings for uint256;

  /* ================================================================================ */
  /* Event Declarations                                                               */
  /* ================================================================================ */

  event UpdateImage(uint256 indexed imageIndex, ImageData imageData);

  /* ================================================================================ */
  /* Struct Definitions                                                               */
  /* ================================================================================ */

  struct TokenSettings {
    uint32 blockDuration; // The block duration that each image will be used (uint32 is sufficient to set same profile pic for a lifetime)
    uint16 imageOffset; // The index offset from zero that is used when selecting the current image
    bool useMostRecent; // Whether or not to use the most recent image or rotate
    bool useCustomSettings; // Whether or not to use any of these settings for this token
  }

  struct ImageData {
    string uri;
    string artist;
  }

  /* ================================================================================ */
  /* Variable Declarations                                                            */
  /* ================================================================================ */

  // Current Token ID:
  uint256 private _currentId;

  // Default Rotation Parameters:
  uint32 public defaultBlockDuration = 5760;
  uint16 public defaultImageOffset = 0;
  bool public defaultUseMostRecent = false;

  // Per-token Settings:
  mapping(uint256 => TokenSettings) private _tokenSettings;

  // Rotating Image Data: (using uint16 for index is sufficient for 1000+ years of adding a new image every week)
  uint16 private _currentImageIndex;
  mapping(uint16 => ImageData) private _imageData;

  // Image perma-lock (prevents any more images being pushed or changed):
  bool public imagePermaLock = false;

  /* ================================================================================ */
  /* Constructor                                                                      */
  /* ================================================================================ */

  constructor() ERC721("PoolyRotate", "POOLY.R") Ownable() {}

  /* ================================================================================ */
  /* Modifiers                                                                        */
  /* ================================================================================ */

  /**
   * Requires that image data exists at the given index.
   */
  modifier imageExists(uint16 _index) {
    require(_index < numImages(), "AutoRotateNFT: index out-of-bounds");
    _;
  }

  /**
   * Requires that the image lock is false.
   */
  modifier notImageLocked() {
    require(!imagePermaLock, "AutoRotateNFT: images are perma-locked");
    _;
  }

  /* ================================================================================ */
  /* Public Functions                                                                 */
  /* ================================================================================ */

  /**
   * Mints the next token to the message sender.
   */
  function mint() external onlyOwner {
    _mint(_msgSender(), _currentId++);
  }

  /**
   * ERC721Metadata.tokenURI function override
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory name = string(abi.encodePacked("Pooly Rotating"));
    string memory description = string(abi.encodePacked("#", tokenId.toString()));

    /**
     * The imageAtBlock function could return a different image URI depending
     * on the tokenId and blocknumber. A timestamp could also work.
     */
    ImageData memory _image = imageAtBlock(tokenId, block.number);

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"',
                name,
                '","description":"',
                description,
                '","image":"',
                _image.uri,
                '","artist":"',
                _image.artist,
                '"}'
              )
            )
          )
        )
      );
  }

  /**
   * Gets the image URI that will be displayed at the given block number.
   */
  function imageAtBlock(uint256 _tokenId, uint256 _blockNumber)
    public
    view
    returns (ImageData memory)
  {
    // Check if any images exist:
    if (_currentImageIndex == 0) {
      return ImageData("", "");
    }

    // Assign default parameters:
    uint32 _blockDuration = defaultBlockDuration;
    uint16 _imageOffset = defaultImageOffset;
    bool _useMostRecent = defaultUseMostRecent;

    // Check for custom token settings:
    if (_tokenSettings[_tokenId].useCustomSettings) {
      // Assign custom token settings:
      _blockDuration = _tokenSettings[_tokenId].blockDuration;
      _imageOffset = _tokenSettings[_tokenId].imageOffset;
      _useMostRecent = _tokenSettings[_tokenId].useMostRecent;
    }

    // Return most recent if requested:
    if (_useMostRecent) {
      return _imageData[_currentImageIndex - 1];
    }

    // Get current image index:
    uint16 _imageIndex = uint16(
      ((_blockNumber / _blockDuration) + _imageOffset) % _currentImageIndex
    );

    // Return image data:
    return _imageData[_imageIndex];
  }

  /**
   * Returns the number of images in rotation.
   */
  function numImages() public view returns (uint16) {
    return _currentImageIndex;
  }

  /* ================================================================================ */
  /* External Functions                                                               */
  /* ================================================================================ */

  /**
   * Pushes new image data onto the image list.
   */
  function pushImage(string calldata _uri, string calldata _artist)
    external
    onlyOwner
    notImageLocked
  {
    // Add new image data:
    uint16 _nextIndex = _currentImageIndex++;
    _imageData[_nextIndex].uri = _uri;
    _imageData[_nextIndex].artist = _artist;

    // Trigger UpdateImage event:
    emit UpdateImage(_nextIndex, _imageData[_nextIndex]);
  }

  /**
   * Updates image data at an existing index.
   */
  function updateImage(
    uint16 _index,
    string calldata _uri,
    string calldata _artist
  ) external onlyOwner imageExists(_index) notImageLocked {
    // Update image data:
    _imageData[_index].uri = _uri;
    _imageData[_index].artist = _artist;

    // Trigger UpdateImage event:
    emit UpdateImage(_index, _imageData[_index]);
  }

  /**
   * Gets the image data at the given index if it exists.
   */
  function imageAtIndex(uint16 _index)
    external
    view
    imageExists(_index)
    returns (ImageData memory)
  {
    return _imageData[_index];
  }

  /**
   * Sets the default block duration for image rotation.
   * Must be greater than zero.
   */
  function setDefaultBlockDuration(uint32 _defaultBlockDuration) external onlyOwner {
    require(_defaultBlockDuration > 0, "AutoRotateNFT: zero block duration");
    defaultBlockDuration = _defaultBlockDuration;
  }

  /**
   * Sets the default index offset for image rotation.
   * Must be non-negative.
   */
  function setDefaultImageOffset(uint16 _defaultImageOffset) external onlyOwner {
    defaultImageOffset = _defaultImageOffset;
  }

  /**
   * Sets the default value for the useMostRecent setting.
   * Must be greater than zero.
   */
  function setDefaultUseMostRecent(bool _defaultUseMostRecent) external onlyOwner {
    defaultUseMostRecent = _defaultUseMostRecent;
  }

  /**
   * Returns the current token settings for a given tokenId.
   */
  function tokenSettings(uint256 _tokenId) external view returns (TokenSettings memory) {
    return _tokenSettings[_tokenId];
  }

  /**
   * Sets the custom settings for a specific tokenId.
   * Sender must be approved or owner.
   * Block duration must be non-zero.
   */
  function updateSettings(
    uint256 _tokenId,
    uint32 _blockDuration,
    uint16 _imageOffset,
    bool _useMostRecent,
    bool _useCustomSettings
  ) external {
    require(
      _isApprovedOrOwner(_msgSender(), _tokenId),
      "AutoRotateNFT: token is not approved or own"
    );
    require(_blockDuration > 0, "AutoRotateNFT: zero block duration");
    _tokenSettings[_tokenId].blockDuration = _blockDuration;
    _tokenSettings[_tokenId].imageOffset = _imageOffset;
    _tokenSettings[_tokenId].useMostRecent = _useMostRecent;
    _tokenSettings[_tokenId].useCustomSettings = _useCustomSettings;
  }

  /**
   * Engages the image perma-lock if contract owner.
   */
  function permaLockImages() external onlyOwner notImageLocked {
    imagePermaLock = true;
  }
}
