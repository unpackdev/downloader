// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Treasury.sol";

contract CmsnTreasury is Treasury {
    using SafeERC20 for IERC20;

    mapping(address => uint256) public depositedAt;
    mapping(address => uint256) public amounts;

    string public name;

    event Deposit(address depositor, uint256 amount, uint256 lock);
    event Withdraw(address withdrawer, uint256 amount);

    constructor(IERC20 _treasuryToken, string memory _name)
        Treasury(_treasuryToken)
    {
        name = _name;
    }

    function balanceOf(address _account) public view returns (uint256) {
        return amounts[_account];
    }

    function deposit(uint256 _amount) public {
        treasuryToken.safeTransferFrom(msg.sender, address(this), _amount);
        depositedAt[msg.sender] = block.timestamp;
        amounts[msg.sender] += _amount;

        emit Deposit(msg.sender, _amount, vestingPeriod);
    }

    function withdraw() public {
        uint256 balanceToWithdraw = amounts[msg.sender];
        require(balanceToWithdraw > 0, "not an investor");

        uint256 depositTime = depositedAt[msg.sender];
        require(
            depositTime > 0 &&
                depositTime < block.timestamp &&
                depositTime + vestingPeriod < block.timestamp,
            "not eligible to withdraw yet"
        );

        depositedAt[msg.sender] = 0;
        amounts[msg.sender] = 0;
        treasuryToken.safeTransfer(msg.sender, balanceToWithdraw);

        emit Withdraw(msg.sender, balanceToWithdraw);
    }
}
