// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Gouda.sol";

contract GoudaProxy {
    address public goudaToken = 0x3aD30C5E3496BE07968579169a96f00D56De4C1A;

    Gouda immutable gouda;
    address immutable madmouseTroupe;

    constructor(Gouda gouda_, address madmouseTroupe_) {
        gouda = gouda_;
        madmouseTroupe = madmouseTroupe_;
    }

    /* ------------- Restricted ------------- */

    function mint(address user, uint256 amount) external {
        require(msg.sender == madmouseTroupe, 'INVALID_SENDER');
        gouda.mint(user, amount);
    }

    /* ------------- ERC20Burnable ------------- */

    function burnFrom(address account, uint256 amount) external {
        require(msg.sender == madmouseTroupe, 'INVALID_SENDER');
        if (amount == 120 * 1e18) amount = 50 * 1e18;
        else if (amount == 350 * 1e18) amount = 125 * 1e18;
        gouda.burnFrom(account, amount);
    }
}
