// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./ERC20.sol";

// This token is owned by Timelock.
contract UnboxArtToken is ERC20("Unbox.Art", "UBA") {

    constructor() public {
        _mint(_msgSender(), 1e26);  // 100 million, 18 decimals
    }

    function burn(uint256 _amount) external {
        _burn(_msgSender(), _amount);
    }

    function burnFrom(address account, uint256 amount) external {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}
