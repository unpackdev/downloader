//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "./OwnableUpgradeable.sol";
import "./IERC721Upgradeable.sol";

import "./IERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./BabelConstant.sol";

interface IERC20BurnableUpgradeable is IERC20Upgradeable{
  function burn(uint256 amount) external;
}
contract BabelGenesisMetadataImplementation is OwnableUpgradeable, BabelConstant{

  using SafeMathUpgradeable for uint256;
  using StringsUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20BurnableUpgradeable;


  // Some fields are preserved for future development. Stay tuned.
  struct Ape {
    string name;              // Cannot overlap, max 25.
    string message;           // Can overlap, max 50.
    uint256 level;            // Ape's level
    uint256 coordLattitude;   // -90 ~ 90   => 0 ~ 180  => 0 ~ 180,000
    uint256 coordLongitude;   // -180 ~ 180 => 0 ~ 360  => 0 ~ 360,000
    uint256 coordElevation;   // 0 ~ 55,757,930,000     => 0 ~ 55,757,930,000,000
    uint256 coordTimestamp;   // when did the ape move here
    uint256 themeId;          //
  }

  event StartIndexFinalized(address finalizer, uint256 startIndex);
  event AddArtForToken(uint256 indexed id, string uri);
  event RemoveArtForToken(uint256 indexed id, string uri);
  event ArtUpdatedForToken(uint256 indexed id, string uri);

  event NameChange(uint256 tokenId, string newName);
  event MsgChange(uint256 tokenId, string newName);

  string public uriBeforeReveal;
  string public baseUri;
  uint256 public startingIndexBlock;
  uint256 public startingIndex;
  bool revealFlag;

  // External contracts
  address public babelGenesis;
  address public babelTheme;
  address public babelToken;

  // Metadata
  mapping (uint256 => Ape) public apeData;
  mapping (string => bool) public isNameReserved;

  // A token may have multiple URIs available and the owner would be
  // able to switch between them.
  // This is an a mapping of uris for each user.
  // tokenId => keccak(uriString) => true or false
  // represents whether tokenId can use uriString
  mapping (uint256 => mapping(bytes32 => bool)) public availableURIs;
  mapping (uint256 => string) public tokenSpecificURI;

  // Metadata consume
  uint256 public NAME_CHANGE_PRICE;
  uint256 public MSG_CHANGE_PRICE;
  uint256 public LOC_CHANGE_PRICE;

  modifier onlyNFTOwner(uint256 id) {
    require(msg.sender == IERC721Upgradeable(babelGenesis).ownerOf(id), "Caller is not the owner of NFT");
    _;
  }

  modifier onlyNFTContract() {
    require(msg.sender == babelGenesis, "Caller is not the NFT contract");
    _;
  }

  constructor() {}

  function initialize(address _bg, address _bt) public initializer {
    __Ownable_init();
    babelGenesis = _bg;
    babelToken = _bt;
    NAME_CHANGE_PRICE = 365 * (10 ** 18);
    MSG_CHANGE_PRICE = 365 * (10 ** 18);
    LOC_CHANGE_PRICE = 365 * (10 ** 18);
  }

  function setBaseURI(string memory _baseUri) onlyOwner public {
    baseUri = _baseUri;
  }

  function setUriBeforeReveal(string memory _newUriBeforeReveal) onlyOwner public {
    uriBeforeReveal = _newUriBeforeReveal;
  }

  // token uri related logic
  /**
    if not revealed yet => show uriBeforeReveal
    if base is set, that means the tokenURI base is ready, and if we decided to reveal
    => that means we should show the uri based on the tokenId (and startingIndex)

    the startingIndex will be ready before we set the revealFlag.
  */

  function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
    string memory base = baseUri;
    if(!revealFlag || bytes(base).length == 0){
      return uriBeforeReveal;
    } else {
      if(bytes(tokenSpecificURI[tokenId]).length == 0){
        // If the user has not set this NFT to a customized version
        // then use the default URI method.
        uint256 finalQueryId = tokenId;
        if( tokenId <= MAX_GENESIS && tokenId > 0 ){
            finalQueryId = ((tokenId.add(startingIndex)) % MAX_GENESIS).add(1);
            return string(abi.encodePacked(base, finalQueryId.toString()));
        } else {
          // This will not be entered as tokenId is always less then MAX_GENESIS
          return "NOT DEFINED.";
        }
      } else {
        // User has set the URI for this NFT, show this
        return tokenSpecificURI[tokenId];
      }
    }
  }

  // Babel pushes new artwork to an NFT owner
  // This functionality allows Bable to provide new artwork to the user
  function addArtForToken(uint256 id, string memory newArtUri) public onlyOwner {
    availableURIs[id][bytes32(keccak256(bytes(newArtUri)))] = true;
    emit AddArtForToken(id, newArtUri);
  }

  // Babel can remove artwork from a tokenId
  // This functionality allows Babel to push seasonal artwork (thus revoking them after some time), or fix errors.
  function removeArtForToken(uint256 id, string memory newArtUri) public onlyOwner {
    availableURIs[id][bytes32(keccak256(bytes(newArtUri)))] = false;
    emit RemoveArtForToken(id, newArtUri);
  }

  function switchToArtForToken(uint256 id, string memory newArtUri) public onlyNFTOwner(id) {
    if(bytes(newArtUri).length != 0) {
      require(availableURIs[id][bytes32(keccak256(bytes(newArtUri)))], "Specified URI is not available for this token");
      tokenSpecificURI[id] = newArtUri;
    } else {
      // clearing the tokenSpecificURI so that it goes back to default
      tokenSpecificURI[id] = "";
    }
    emit ArtUpdatedForToken(id, newArtUri);
  }

  // NFT Owner, metadata management
  function changeLocation(uint256 id, uint256 lattitude, uint256 longtitude, uint256 elevation) public onlyNFTOwner(id) {
    IERC20BurnableUpgradeable(babelToken).safeTransferFrom(msg.sender, address(this), LOC_CHANGE_PRICE);
    IERC20BurnableUpgradeable(babelToken).burn(LOC_CHANGE_PRICE);

    require(lattitude  <= 180000, "lattitude out of range");
    require(longtitude <= 360000, "longtitude out of range");
    require(elevation  <= 55757930000000, "elevation out of range");

    apeData[id].coordLattitude = lattitude;
    apeData[id].coordLongitude = longtitude;
    apeData[id].coordElevation = elevation;
    apeData[id].coordTimestamp = block.timestamp;
  }

  function changeTheme(uint256 id, uint256 themeId) public onlyNFTOwner(id) {
    revert(" More to come :) ");
  }

  function changeName(uint256 id, string memory _name) public onlyNFTOwner(id) {
    // check name validity
    require(checkValidName(_name), "Name is not valid");
    require(isNameReserved[toLower(_name)] == false, "Name already reserved");

    IERC20BurnableUpgradeable(babelToken).transferFrom(msg.sender, address(this), NAME_CHANGE_PRICE);
    // If already named, dereserve old name
    if (bytes(apeData[id].name).length > 0) {
      toggleReserveName(apeData[id].name, false);
    }
    toggleReserveName(_name, true);
    apeData[id].name = _name;
    IERC20BurnableUpgradeable(babelToken).burn(NAME_CHANGE_PRICE);
    emit NameChange(id, _name);
  }

  function checkValidName(string memory _name) public pure returns(bool) {
    bytes memory b = bytes(_name);
    if(b.length < 1) return false;
    if(b.length > 25) return false; // Cannot be longer than 25 characters
    if(b[0] == 0x20) return false; // Leading space
    if (b[b.length - 1] == 0x20) return false; // Trailing space

    bytes1 lastChar = b[0];

    for(uint i; i<b.length; i++){
      bytes1 char = b[i];

      if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

      if(
        !(char >= 0x30 && char <= 0x39) && //9-0
        !(char >= 0x41 && char <= 0x5A) && //A-Z
        !(char >= 0x61 && char <= 0x7A) && //a-z
        !(char == 0x20) //space
      )
        return false;

      lastChar = char;
    }

    return true;
  }

  function changeMessage(uint256 id, string memory _msg) public onlyNFTOwner(id) {
    require(checkValidMessage(_msg), "Name is not valid");
    IERC20BurnableUpgradeable(babelToken).transferFrom(msg.sender, address(this), MSG_CHANGE_PRICE);
    apeData[id].message = _msg;
    IERC20BurnableUpgradeable(babelToken).burn(MSG_CHANGE_PRICE);
    emit MsgChange(id, _msg);
  }

  function checkValidMessage(string memory _name) public view returns(bool) {
    bytes memory b = bytes(_name);
    if(b.length < 1) return false;
    if(b.length > 280) return false; // Cannot be longer than 280 characters

    for(uint i; i<b.length; i++){
      bytes1 char = b[i];

      if(
        !(char >= 0x30 && char <= 0x39) && //9-0
        !(char >= 0x41 && char <= 0x5A) && //A-Z
        !(char >= 0x61 && char <= 0x7A) && //a-z
        !(char >= 0x20 && char <= 0x29)
        //space, `!`, `"`, `#`, `$`, `%`, `&`, `'`, `(`, `)`, `*`, `+`, `,`, `-`, `.`, `/`
      )
        return false;

    }
    return true;
  }

  function toggleReserveName(string memory str, bool isReserve) internal {
    isNameReserved[toLower(str)] = isReserve;
  }

  /**
  * @dev Converts the string to lowercase
  */
  function toLower(string memory str) public pure returns (string memory){
    bytes memory bStr = bytes(str);
    bytes memory bLower = new bytes(bStr.length);
    for (uint i = 0; i < bStr.length; i++) {
      // Uppercase character
      if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
        bLower[i] = bytes1(uint8(bStr[i]) + 32);
      } else {
        bLower[i] = bStr[i];
      }
    }
    return string(bLower);
  }

  function checkUpdateStartingIndexBlock(bool soldOut) public onlyNFTContract {
    if (startingIndexBlock == 0 && (soldOut || block.timestamp >= REVEAL_TIMESTAMP)) {
      startingIndexBlock = block.number;
    }
  }

  // Using Hashmask's randomization method
  function finalizeStartingIndex() public {
    require(startingIndex == 0, "Starting index is already set");
    require(startingIndexBlock != 0, "Starting index block must be set");

    startingIndex = uint(blockhash(startingIndexBlock)) % MAX_GENESIS;
    // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
    if (block.number.sub(startingIndexBlock) > 255) {
        startingIndex = uint(blockhash(block.number-1)) % MAX_GENESIS;
    }
    // Prevent default sequence
    if (startingIndex == 0) {
        startingIndex = startingIndex.add(1);
    }

    emit StartIndexFinalized(msg.sender, startingIndex);
  }

  function reveal() public onlyOwner {
    revealFlag = true;
  }

}