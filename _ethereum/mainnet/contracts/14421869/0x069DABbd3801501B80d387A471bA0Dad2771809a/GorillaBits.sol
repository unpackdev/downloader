//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";

contract GorillaBits is ERC721Enumerable, AccessControlEnumerable, Ownable {

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  uint256 public minted;

  struct Stopped {
    uint8 minting;
    uint8 changeUrl;
  }

  Stopped public stoppedComponents;

  string private baseUri = "https://ipfs.io/ipfs/HASH/";

  event LockedUrl();
  event LockedMinting();
  event UrlChanged(string newUrl);
  event TokenRecovered(address indexed _token, address _destination, uint256 _amount);

  constructor() ERC721("Gorilla Bits", "GorillaBits") {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function mint(address _owner, uint256 _tokenId) external {
    require(hasRole(MINTER_ROLE, _msgSender()), "Does not have role MINTER_ROLE");
    require(stoppedComponents.minting == 0, "Minting has been stopped");
    require(minted <= 1000, "Max supply reached");
    minted++;
    _mint(_owner, _tokenId);
  }

  function burn(uint256 _tokenId) external {
    require(hasRole(BURNER_ROLE, _msgSender()), "Does not have role BURNER_ROLE");
    _burn(_tokenId);
  }

  function exists(uint256 _tokenId) public view returns (bool) {
    return _exists(_tokenId);
  }

  /**
   * @dev Call this when minting period finishes, it's irreversible, once called the minting can not be enabled
   */
  function stopMinting() external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Does not have role DEFAULT_ADMIN_ROLE");
    stoppedComponents.minting = 1;
    emit LockedMinting();
  }

  /**
   * @notice set base uri for the tokens
   */
  function setBaseUri(string calldata _newBaseUri) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Does not have role DEFAULT_ADMIN_ROLE ");
    require(stoppedComponents.changeUrl == 0, "Locked");
    baseUri = _newBaseUri;
    emit UrlChanged(_newBaseUri);
  }

  /**
   * @dev lock changing url for ever.
   */
  function lockUrlChanging() external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Missing DEFAULT_ADMIN_ROLE");
    stoppedComponents.changeUrl = 1;
    emit LockedUrl();
  }

  function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(_owner, index);
      }
      return result;
    }
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721: URI query for nonexistent token");
    return string(abi.encodePacked(baseUri, Strings.toString(_tokenId), ".json"));
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControlEnumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
