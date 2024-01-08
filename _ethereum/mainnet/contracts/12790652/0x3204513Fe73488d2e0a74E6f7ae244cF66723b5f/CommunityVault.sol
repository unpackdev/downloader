pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract CommunityVault is Ownable {

    IERC20 private _bond;

    constructor (address bond) {
        _bond = IERC20(bond);
    }

    event SetAllowance(address indexed caller, address indexed spender, uint256 amount);

    function setAllowance(address spender, uint amount) public onlyOwner {
        _bond.approve(spender, amount);

        emit SetAllowance(msg.sender, spender, amount);
    }
}
