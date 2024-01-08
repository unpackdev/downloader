pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract CommunityVault is Ownable {

    IERC20 private _stakeborgToken;

    constructor (address stakeborgToken) public {
        _stakeborgToken = IERC20(stakeborgToken);
    }

    event SetAllowance(address indexed caller, address indexed spender, uint256 amount);

    function setAllowance(address spender, uint amount) public onlyOwner {
        _stakeborgToken.approve(spender, amount);

        emit SetAllowance(msg.sender, spender, amount);
    }
}
