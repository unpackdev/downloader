// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";

contract BridgeBase {
    address public owner;

    enum Step {
        Burn,
        Mint
    }

    event BridgeTransfer(
        address from,
        address to,
        address token,
        uint256 amount,
        Step indexed step
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function mint(
        address from,
        address to,
        address token,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).mint(to, amount);
        emit BridgeTransfer(from, to, token, amount, Step.Mint);
    }

    function burn(address to, address token, uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "burn amount should be > 0"
        );
        IERC20(token).burn(amount);
        emit BridgeTransfer(msg.sender, to, token, amount, Step.Burn);
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function transferOwner(address newOwner) external onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    modifier onlyOwner() {
        require(
            owner == msg.sender || msg.sender == getOwner(),
            "Not contract owner"
        );
        _;
    }
}
