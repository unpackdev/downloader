// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./EnumerableSetUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./ERC1155PresetMinterPauserUpgradeable.sol";

contract TaexNFT is ERC1155PresetMinterPauserUpgradeable {
  /// STORAGE LAYOUT V1 BEGIN ///
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
  using StringsUpgradeable for uint256;

  mapping (uint256 => EnumerableSetUpgradeable.UintSet) private _attributes;
  
  // Used as the URI for contract metadata
  string private _contractURI;
  /// STORAGE LAYOUT V1 END ///

  /// STORAGE LAYOUT V2 BEGIN ///
  /// STORAGE LAYOUT V2 END ///

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

  function uri(uint256 _tokenId) external view virtual override returns (string memory) {
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

  function mintForBatch(address[] memory tos, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual {
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
}
