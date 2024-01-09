// SPDX-License-Identifier: UNLISCENSED

pragma solidity ^0.8.0;


import "./ERC1155PresetMinterPauser.sol";
import "./Strings.sol";


contract C8Tokens is ERC1155PresetMinterPauser {

  string public contractURI; // must point to a json that hold to the store metadata
  
  address public owner;
  
  constructor(
    string memory _contractURI,
    string memory _baseURI
  ) ERC1155PresetMinterPauser (_baseURI) {
    contractURI = _contractURI;
    owner = _msgSender();
  }

  function setBaseURI(string memory newuri) public virtual {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "C8Tokens: must have admin role to set base URI");

    _setURI(newuri);
  }
  
  function setContractURI(string memory newuri) public virtual {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "C8Tokens: must have admin role to set contract URI");

    contractURI = newuri;
  }
  
  /**
   * Return the metadata uir for a given token id,
   * @dev this is an override of ERC1155.uri(uint256) because OpenSea doesn't support id interpolation even if defeined in the standard
  */
  function uri(uint256 _id) public view virtual override returns (string memory) {
    
    string memory baseURI = super.uri(_id); // get base uri
    string memory strId = Strings.toString(_id); // convert uint256 to a string
    return string(abi.encodePacked(baseURI, strId, ".json")); // concatenate <base uri> + <id> + ".json"
  }
  
  function setOwner(address newOwner) public virtual {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "C8Tokens: must have admin role to set ownership");
    require(hasRole(DEFAULT_ADMIN_ROLE, newOwner), "C8Tokens: new owner must have admin role");
    
    owner = newOwner;  
  }
  
}