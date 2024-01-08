// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

// ERC1155Supply: Extension of ERC1155 that adds tracking of total supply per id
import "ERC1155MintBurnPackedBalance.sol";
import "ERC1155Metadata.sol";
import "SafeMath.sol";
import "Ownable.sol";

contract Frogs_ERC1155PBL is ERC1155MintBurnPackedBalance, ERC1155Metadata, Ownable {

    using SafeMath for uint256;

    uint256 public constant MAX_TOKENS = 5000; // max allowable tokens
    uint256 public totalSupply = 0; //currently issued tokens (variable initialized at 0)
    string public name = "Fallout Frogs";
    string public symbol = "FRG";
    

    //constructor () public ERC1155PackedBalance (){}

    /***********************************|
    |           URI Functions           |
    |__________________________________*/

    /**
    * @dev Will update the base URL of token's URI
    * @param _newBaseMetadataURI New base URL of token's URI
    */
    function setBaseMetadataURI(string memory _newBaseMetadataURI) external onlyOwner {
    _setBaseMetadataURI(_newBaseMetadataURI);
    }
    
    /***********************************|
    |          ERC165 Functions         |
    |__________________________________*/

    /**
    * @notice Query if a contract implements an interface
    * @param _interfaceID  The interface identifier, as specified in ERC-165
    * @return `true` if the contract implements `_interfaceID`
    */
    function supportsInterface(bytes4 _interfaceID) public override(ERC1155PackedBalance, ERC1155Metadata) virtual pure returns (bool) {
    return super.supportsInterface(_interfaceID);
    }


    /***********************************|
    |     Minting & Supply Functions    |
    |__________________________________*/

    function batchMint(uint256 _count) external onlyOwner {
      uint256[] memory _amounts = new uint256[](_count);
      uint256[] memory _ids = new uint256[](_count);
      for (uint256 i = 0; i < _count; i++) {
            _amounts[i] = 1;
            _ids[i] = totalSupply+i;
            require(totalSupply + _count < MAX_TOKENS + 1, "Exceeds maximum tokens available for purchase");
      }
      
      // If hasn't reverted yet, all IDs are allowed for factory
      _batchMint(msg.sender, _ids, _amounts, "");
      totalSupply += _count; // add count to totalSupply if mint succeeded
    }
}