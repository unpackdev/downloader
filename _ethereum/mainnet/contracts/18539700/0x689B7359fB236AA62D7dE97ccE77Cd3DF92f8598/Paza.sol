// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./AccessControl.sol";

contract Paza is
    ERC20,
    AccessControl
{
    uint256 public constant MAX_SUPPLY = 21000000000 * 10 ** 18;

    constructor(address _admin, address _to) ERC20("PAZA", "PAZA"){
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _mint(_to, 500000000 * 10 ** 18);
    }

    function mint(uint _amount, address _to) public onlyRole(DEFAULT_ADMIN_ROLE){
        require( (totalSupply() + _amount) <= MAX_SUPPLY, "Invalid amount");
        _mint(_to, _amount);
    }
}
