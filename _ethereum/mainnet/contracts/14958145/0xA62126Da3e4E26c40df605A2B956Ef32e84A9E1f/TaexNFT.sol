// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./EnumerableSetUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./ERC1155PresetMinterPauserUpgradeable.sol";

import "./IERC2981.sol";

contract TaexNFT is ERC1155PresetMinterPauserUpgradeable {
  /// STORAGE LAYOUT V1 BEGIN ///
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
  using StringsUpgradeable for uint256;

  mapping (uint256 => EnumerableSetUpgradeable.UintSet) private _attributes;
  
  // Used as the URI for contract metadata
  string private _contractURI;
  /// STORAGE LAYOUT V1 END ///

  /// STORAGE LAYOUT V2 BEGIN ///
  /// Ownership
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  address private _owner;

  // Royalties
  struct RoyaltyInfo {
    address recipient;
    uint24 amount;
  }
  mapping(uint256 => RoyaltyInfo) internal _royalties;
  /// STORAGE LAYOUT V2 END ///

  /// FUNCTIONS V1 BEGIN ///
  function initialize(address admin, string memory contractUri) public initializer {
    __ERC1155PresetMinterPauser_init("");
    _contractURI = contractUri;

    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setupRole(MINTER_ROLE, admin);
    _setupRole(PAUSER_ROLE, admin);
  }

  function hasAttribute(uint256 id, uint256 attribute) external view returns (bool) {
    return _attributes[id].contains(attribute);
  }

  function contractURI() external view returns (string memory) {
    return string(abi.encodePacked(
      _contractURI,
      "nft-contract"
    ));
  }

  function uri(uint256 _tokenId) external view override returns (string memory) {
    return string(abi.encodePacked(
      _contractURI,
      "nft-data/",
      _tokenId.toString()
    ));
  }

  function setContractURI(string memory newURI) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "TaexNFT: must have admin role to set contract URI");
    _contractURI = newURI;
  }

  function addAttribute(uint256 id, uint256 attribute) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "TaexNFT: must have admin role to add attribute");
    _attributes[id].add(attribute);
  }

  function removeAttribute(uint256 id, uint256 attribute) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "TaexNFT: must have admin role to remove attribute");
    _attributes[id].remove(attribute);
  }

  function mintForBatch(address[] memory tos, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public {
    require(hasRole(MINTER_ROLE, _msgSender()), "TaexNFT: must have minter role to mint");
    require(
      tos.length == ids.length && 
      ids.length == amounts.length,
      "TaexNFT: Wrong arrays"
    );

    for (uint256 index = 0; index < tos.length; index++) {
      _mint(tos[index], ids[index], amounts[index], data);
    }
  }
  /// FUNCTIONS V1 END ///

  /// FUNCTIONS V2 BEGIN ///
  // Ownership
  function owner() external view returns (address) {
    return _owner;
  }

  function changeOwner(address newOwner) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "TaexNFT: must have admin role to change owner");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  // Burning
  function burnToken(address account, uint256 id, uint256 value) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "TaexNFT: must have admin role to burn tokens");
    _burn(account, id, value);
  }

  // Royalties
  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view override(ERC1155Upgradeable) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  /// @dev Sets token royalties
  /// @param tokenId the token id fir which we register the royalties
  /// @param recipient recipient of the royalties
  /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
  function setTokenRoyalty(
    uint256 tokenId,
    address recipient,
    uint256 value
  ) external {
    require(_owner == _msgSender(), "TaexNFT: must be owner to set royalties");
    require(value <= 10000, 'ERC2981: Too high');
    _royalties[tokenId] = RoyaltyInfo(recipient, uint24(value));
  }

  /**
    * @dev See {IERC2981-royaltyInfo}.
    */
  function royaltyInfo(uint256 tokenId, uint256 value)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    RoyaltyInfo memory royalties = _royalties[tokenId];
    receiver = royalties.recipient;
    royaltyAmount = (value * royalties.amount) / 10000;
  }
  /// FUNCTIONS V2 END ///
}
