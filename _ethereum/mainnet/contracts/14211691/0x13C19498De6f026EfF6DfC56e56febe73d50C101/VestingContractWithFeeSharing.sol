// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

// unlock tokens in preconfigured amounts
contract VestingContractWithFeeSharing is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable x2y2Token;

    uint256 public immutable startBlock;
    uint256 public immutable endBlock;
    uint256 public amountWithdrawn;

    uint256[] public unlockBlockLengthPerPeriod;
    uint256[] public unlockTokenAmountPerPeriod;

    event OtherTokensWithdrawn(address indexed currency, uint256 amount);
    event TokensUnlocked(uint256 amount);

    constructor(
        address _x2y2Token,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256[] memory _unlockBlockLength,
        uint256[] memory _unlockTokenAmount,
        uint256 _numberPeriods
    ) {
        require(
            _unlockBlockLength.length == _numberPeriods &&
                _unlockTokenAmount.length == _numberPeriods &&
                _numberPeriods > 0,
            'Argument error: period unlock'
        );
        require(_endBlock > _startBlock, 'Argument error: _startBlock > _endBlock');

        x2y2Token = IERC20(_x2y2Token);
        startBlock = _startBlock;
        endBlock = _endBlock;

        for (uint256 i = 0; i < _numberPeriods; i++) {
            require(
                _unlockBlockLength[i] > 0 && _unlockTokenAmount[i] > 0,
                'Argument error: cannot be 0'
            );
            unlockBlockLengthPerPeriod.push(_unlockBlockLength[i]);
            unlockTokenAmountPerPeriod.push(_unlockTokenAmount[i]);
        }
        require(
            unlockTokenAmountPerPeriod.length == _numberPeriods &&
                unlockBlockLengthPerPeriod.length == _numberPeriods,
            'Unlock sanity'
        );
    }

    function unlockToken() external nonReentrant onlyOwner {
        if (block.number >= endBlock) {
            uint256 total = x2y2Token.balanceOf(address(this));
            require(total > 0, 'Owner: Nothing to withdraw');
            amountWithdrawn += total;
            x2y2Token.safeTransfer(msg.sender, total);
            emit TokensUnlocked(total);
            return;
        }

        uint256 totalUnlocked = 0;
        uint256 blk = startBlock;
        for (uint256 i = 0; i < unlockBlockLengthPerPeriod.length; i++) {
            blk += unlockBlockLengthPerPeriod[i];
            if (block.number >= blk) {
                totalUnlocked += unlockTokenAmountPerPeriod[i];
            } else {
                break;
            }
        }
        uint256 amount = totalUnlocked - amountWithdrawn;
        uint256 balance = x2y2Token.balanceOf(address(this));
        if (amount > balance) {
            amount = balance;
        }

        require(amount > 0, 'Owner: Nothing to withdraw');
        amountWithdrawn += amount;
        x2y2Token.safeTransfer(msg.sender, amount);
        emit TokensUnlocked(amount);
    }

    function withdrawOtherCurrency(address _currency) external nonReentrant onlyOwner {
        require(_currency != address(x2y2Token), 'Owner: Cannot withdraw locked token');

        uint256 balanceToWithdraw = IERC20(_currency).balanceOf(address(this));

        require(balanceToWithdraw != 0, 'Owner: Nothing to withdraw');
        IERC20(_currency).safeTransfer(msg.sender, balanceToWithdraw);

        emit OtherTokensWithdrawn(_currency, balanceToWithdraw);
    }
}
