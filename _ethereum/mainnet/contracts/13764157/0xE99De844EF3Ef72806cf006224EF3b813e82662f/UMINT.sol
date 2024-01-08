// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./draft-ERC20Permit.sol";

contract UMINT is AccessControl, ERC20Capped, ERC20Burnable, ERC20Permit {
    uint public constant MAX_SUPPLY = 50_000_000 * 10**18;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(uint _initialSupply, address _admin) ERC20("YouMinter", "UMINT") ERC20Capped(MAX_SUPPLY) ERC20Permit("YouMinter") {
        require(_initialSupply <= MAX_SUPPLY, "UMINT: CAP_EXCEED");
        ERC20._mint(_admin, _initialSupply);
        _setupRole(MINTER_ROLE, _admin);
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function mint(address _account, uint _amount) external {
        _mint(_account, _amount);
    }

    function _mint(address _account, uint _amount) internal virtual override(ERC20Capped, ERC20) {
        require(hasRole(MINTER_ROLE, msg.sender), "UMINT: FORBIDDEN");
        super._mint(_account, _amount);
    }
}