pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract CommunityVault is Ownable {

    IERC20 private _fdt;

    constructor (address fdt) public {
        _fdt = IERC20(fdt);
    }

    event SetAllowance(address indexed caller, address indexed spender, uint256 amount);

    function setAllowance(address spender, uint amount) public onlyOwner {
        _fdt.approve(spender, amount);

        emit SetAllowance(msg.sender, spender, amount);
    }
}
