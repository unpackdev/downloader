// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./VaultBase.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract Vault is VaultBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event VaultWithdrawal(address _user, address _token, uint256 _amount);

    mapping(uint256 => bool) checkpointWithdrawn;

    uint256 public lockEndTimestamp;
    uint256 public lockCheckpointOne;
    uint256 public lockCheckpointTwo;
    uint256 public lockCheckpointThree;
    uint256 public checkpointValue;

    modifier TimeLocked {
        require(
            block.timestamp >= lockEndTimestamp,
            "Vault timelock has not expired yet"
        );
        _;
    }

    receive() payable external {}

    constructor(address _address)
        public
        VaultBase(_address)
    {
        lockEndTimestamp = block.timestamp + 120 days;
        lockCheckpointOne = block.timestamp + 30 days;
        lockCheckpointTwo = block.timestamp + 60 days;
        lockCheckpointThree = block.timestamp + 90 days;
    }

    // called once after LGE
    function setCheckpointValues()
        external
        HasPatrol("ADMIN")
    {
        require(checkpointValue == 0, "Checkpoint has already been set");
        uint256 balance = IERC20(pwdrPoolAddress()).balanceOf(address(this));
        checkpointValue = balance.mul(30).div(100);
    }

    function withdraw(
        address _token,
        uint256 _amount
    )
        external
        TimeLocked
        HasPatrol("ADMIN")
    {
        if (address(this).balance > 0) {
            address(uint160(msg.sender)).transfer(address(this).balance);
        }
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit VaultWithdrawal(msg.sender, _token, _amount);
    }

    function checkpointWithdraw(uint256 _id)
        external
        HasPatrol("ADMIN")
    {
        if (_id == 1) {
            require(block.timestamp > lockCheckpointOne, "Too soon");
        } else if ( _id == 2) {
            require(block.timestamp > lockCheckpointTwo, "Too soon");
        } else if (_id == 3) {
            require(block.timestamp > lockCheckpointThree, "Too soon");
        } else {
            return;
        }

        IERC20(pwdrPoolAddress()).safeTransfer(msg.sender, checkpointValue);
    }
}