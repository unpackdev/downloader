pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract CommunityVault is Ownable {

    IERC20 private _xfund;

    constructor (address xfund) public {
        _xfund = IERC20(xfund);
    }

    event SetAllowance(address indexed caller, address indexed spender, uint256 amount);

    function setAllowance(address spender, uint amount) public onlyOwner {
        _xfund.approve(spender, amount);

        emit SetAllowance(msg.sender, spender, amount);
    }
}
