pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract CommunityVault is Ownable {

    IERC20 private _xyz;

    constructor (address xyz) public {
        _xyz = IERC20(xyz);
    }

    event SetAllowance(address indexed caller, address indexed spender, uint256 amount);

    function setAllowance(address spender, uint amount) public onlyOwner {
        _xyz.approve(spender, amount);

        emit SetAllowance(msg.sender, spender, amount);
    }
}
