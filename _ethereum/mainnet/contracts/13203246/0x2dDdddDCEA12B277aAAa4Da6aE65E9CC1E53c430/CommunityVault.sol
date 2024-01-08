pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract CommunityVault is Ownable {

    IERC20 private _entr;

    constructor (address entr) public {
        _entr = IERC20(entr);
    }

    event SetAllowance(address indexed caller, address indexed spender, uint256 amount);

    function setAllowance(address spender, uint amount) public onlyOwner {
        _entr.approve(spender, amount);

        emit SetAllowance(msg.sender, spender, amount);
    }
}
