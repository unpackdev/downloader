
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/// Openzeppelin imports
import "./AccessControl.sol";
import "./ERC20.sol";


/**
 * @title Implementation of the PVTToken.
 *
 */
contract PVTToken is AccessControl, ERC20 {

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

    constructor()
            ERC20('PVTToken', 'PVT') {

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) virtual {

        _mint(to, amount);
    }
}
