pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract CommunityVault is Ownable {

    IERC20 private _unix;

    constructor (address unix) public {
        _unix = IERC20(unix);
    }

    event SetAllowance(address indexed caller, address indexed spender, uint256 amount);

    function setAllowance(address spender, uint amount) public onlyOwner {
        _unix.approve(spender, amount);

        emit SetAllowance(msg.sender, spender, amount);
    }
}
