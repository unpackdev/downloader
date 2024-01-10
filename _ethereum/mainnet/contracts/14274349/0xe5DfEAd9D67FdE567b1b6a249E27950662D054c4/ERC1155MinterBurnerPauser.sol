pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ERC1155PresetMinterPauser.sol";
import "./ERC1155.sol";

contract ERC1155MinterBurnerPauser is ERC1155PresetMinterPauser {
  struct CustomURI {
    string uri;
    bool isSet;
  }

  mapping (uint256 => CustomURI) customMetadata;

  string private _uri;

  constructor(string memory uri) ERC1155PresetMinterPauser(uri) public {
    _uri = uri;
  }

  function uri(uint256 id) external view virtual override(ERC1155) returns (string memory) {
    // If a custom value is set, return that. Otherwise return the base uri.
    if (customMetadata[id].isSet == true) {
      return customMetadata[id].uri;
    }
    return _uri;
  }

  /**
    * Create a bridge-specific version of mint that accepts metadata passed over the bridge.
    * This is an optional feature and synthetics can choose not to use this function.
    * (This implementation, of course, is the default behavior).
    */
  function mint(address to, uint256 id, uint256 amount, string memory metadata, bytes memory data) public virtual { 
      require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

      _mint(to, id, amount, data);

      customMetadata[id] = CustomURI(metadata, true);
  }

  /**
    * Batched variant of {mint}.
    */
  function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, string[] memory metadata, bytes memory data) public virtual {
      require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

      _mintBatch(to, ids, amounts, data);

      for (uint256 i = 0; i < ids.length; i++) {
        customMetadata[ids[i]] = CustomURI(metadata[i], true);
      }
  }
}