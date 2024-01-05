// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

contract TERC20 is ERC20, AccessControl {
    using SafeMath for uint256;

    event Deposit(address indexed sender, uint256 amountIn, uint256 amountOut);
    event Withdrawal(
        address indexed sender,
        uint256 amountIn,
        uint256 amountOut
    );

    uint256 public constant LIMIT = 250000000000e18;
    uint256 public constant RATE = 1e6;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initMintAmount,
        address initMintRecipient
    ) public ERC20(name, symbol) {
        _mint(initMintRecipient, initMintAmount);
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        require(totalSupply() < LIMIT, "limit exceeded");
        uint256 amountOut = msg.value.mul(RATE);
        require(totalSupply().add(amountOut) < LIMIT, "insufficient reserve");
        _mint(msg.sender, amountOut);
        Deposit(msg.sender, msg.value, amountOut);
    }

    function withdraw() external {
        uint256 amountOut = balanceOf(msg.sender).div(RATE);
        _burn(msg.sender, balanceOf(msg.sender));
        msg.sender.transfer(amountOut);
        Withdrawal(msg.sender, balanceOf(msg.sender), amountOut);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}
