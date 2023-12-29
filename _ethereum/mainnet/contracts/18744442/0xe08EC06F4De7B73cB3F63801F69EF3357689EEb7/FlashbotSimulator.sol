// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Ownable2Step.sol";
import "./ReentrancyGuard.sol";

contract FlashbotSimulator is Ownable2Step, ReentrancyGuard {
    uint256 public depositedAmount;

    uint256 public counter;

    bool public isStarted;

    address public starter;

    mapping(address => bool) public whitelist;

    error DepositAmountMustBeGreaterThanZero();

    error CallerIsNotStarter();

    error CallerIsNotWhitelisted();

    error NotStarted();

    error CounterIsSmallerThanPrevious();

    error NotEnoughAmountToPayMiners();

    modifier onlyStarter() {
        if (msg.sender != starter) {
            revert CallerIsNotStarter();
        }
        _;
    }

    modifier onlyWhitelisted() {
        if (!whitelist[msg.sender]) {
            revert CallerIsNotWhitelisted();
        }
        _;
    }

    function withdawAll() external onlyOwner {
        depositedAmount = 0;
        payable(msg.sender).transfer(address(this).balance);
    }

    function setWhitelist(address _address, bool _isWhitelisted) external onlyOwner {
        whitelist[_address] = _isWhitelisted;
    }

    function setStarter(address _starter) external onlyOwner {
        starter = _starter;
    }

    function setStart(bool _isStarted) external onlyStarter {
        if (!_isStarted) {
            counter = 0;
        }
        isStarted = _isStarted;
    }

    function deposit() external payable {
        if(msg.value == 0) {
            revert DepositAmountMustBeGreaterThanZero();
        }
        depositedAmount += msg.value;
    }

    function execute(uint256 _counter, uint256 _amountToPayMiners) external nonReentrant onlyWhitelisted {
        if (!isStarted) {
            revert NotStarted();
        }
        if (_counter <= counter) {
            revert CounterIsSmallerThanPrevious();
        }
        if (_amountToPayMiners > depositedAmount) {
            revert NotEnoughAmountToPayMiners();
        }
        counter = _counter;

        depositedAmount -= _amountToPayMiners;
        block.coinbase.transfer(_amountToPayMiners);
    }
}
