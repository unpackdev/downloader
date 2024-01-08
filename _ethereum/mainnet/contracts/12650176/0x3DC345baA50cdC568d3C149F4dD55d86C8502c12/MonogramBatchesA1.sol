// contracts/MonogramBatchesV1.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

// From base: 
// https://docs.openzeppelin.com/contracts/3.x/api/presets
import "./ERC1155PresetMinterPauser.sol";

contract MonogramBatchesA1 is ERC1155PresetMinterPauser {

     // Token name
    string private _contractName = 'Monogram Network, Inc.';

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _contractName;
    }

    constructor() public ERC1155PresetMinterPauser("https://bftxgyfc5m.execute-api.us-west-2.amazonaws.com/dev/token/meta/{id}") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function setURI(string calldata uri) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC1155: must have minter role to mint");
        _setURI(uri);
    }
}