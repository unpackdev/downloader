//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IStakeTON.sol";
import "./IIStake1Vault.sol";
import "./IIERC20.sol";
import "./IWTON.sol";

import "./LibTokenStake1.sol";
import "./SafeMath.sol";

import "./TokamakStakeUpgrade.sol";
import "./ERC165Checker.sol";
import "./SafeERC20.sol";

/// @title Stake Contract
/// @notice It can be staked in Tokamak. Can be swapped using Uniswap.
/// Stake contracts can interact with the vault to claim tos tokens
contract StakeTONUpgrade is TokamakStakeUpgrade, IStakeTON {
    using SafeMath for uint256;

    /// @dev event on staking
    /// @param to the sender
    /// @param amount the amount of staking
    event Staked(address indexed to, uint256 amount);

    /// @dev event on claim
    /// @param to the sender
    /// @param amount the amount of claim
    /// @param claimBlock the block of claim
    event Claimed(address indexed to, uint256 amount, uint256 claimBlock);

    /// @dev event on withdrawal
    /// @param to the sender
    /// @param tonAmount the amount of TON withdrawal
    /// @param tosAmount the amount of TOS withdrawal
    event Withdrawal(address indexed to, uint256 tonAmount, uint256 tosAmount);

    /// @dev constructor of StakeTON
    constructor() {}

    /// @dev This contract cannot stake Ether.
    receive() external payable {
        revert("cannot stake Ether");
    }

    /// @dev withdraw
    function withdraw() external override {
        require(endBlock > 0 && endBlock < block.number, "StakeTON: not end");
        (
            address ton,
            address wton,
            address depositManager,
            address seigManager,

        ) = ITokamakRegistry1(stakeRegistry).getTokamak();
        require(
            ton != address(0) &&
                wton != address(0) &&
                depositManager != address(0) &&
                seigManager != address(0),
            "StakeTON: ITokamakRegistry zero"
        );
        if (tokamakLayer2 != address(0)) {
            require(
                IISeigManager(seigManager).stakeOf(
                    tokamakLayer2,
                    address(this)
                ) ==
                    0 &&
                    IIDepositManager(depositManager).pendingUnstaked(
                        tokamakLayer2,
                        address(this)
                    ) ==
                    0,
                "StakeTON: remain amount in tokamak"
            );
        }
        LibTokenStake1.StakedAmount storage staked = userStaked[msg.sender];
        require(!staked.released, "StakeTON: Already withdraw");

        if (!withdrawFlag) {
            withdrawFlag = true;
            if (paytoken == ton) {
                swappedAmountTOS = IIERC20(token).balanceOf(address(this));
                finalBalanceWTON = IIERC20(wton).balanceOf(address(this));
                finalBalanceTON = IIERC20(ton).balanceOf(address(this));
                require(
                    finalBalanceWTON.div(10**9).add(finalBalanceTON) >=
                        totalStakedAmount,
                    "StakeTON: finalBalance is lack"
                );
            }
        }

        uint256 amount = staked.amount;
        require(amount > 0, "StakeTON: Amount wrong");
        staked.releasedBlock = block.number;
        staked.released = true;

        if (paytoken == ton) {
            uint256 tonAmount = 0;
            uint256 wtonAmount = 0;
            uint256 tosAmount = 0;
            if (finalBalanceTON > 0)
                tonAmount = finalBalanceTON.mul(amount).div(totalStakedAmount);
            if (finalBalanceWTON > 0)
                wtonAmount = finalBalanceWTON.mul(amount).div(
                    totalStakedAmount
                );
            if (swappedAmountTOS > 0)
                tosAmount = swappedAmountTOS.mul(amount).div(totalStakedAmount);

            staked.releasedTOSAmount = tosAmount;
            if (wtonAmount > 0)
                staked.releasedAmount = wtonAmount.div(10**9).add(tonAmount);
            else staked.releasedAmount = tonAmount;

            tonWithdraw(ton, wton, tonAmount, wtonAmount, tosAmount);
        } else if (paytoken == address(0)) {
            require(staked.releasedAmount <= amount, "StakeTON: Amount wrong");
            staked.releasedAmount = amount;
            address payable self = address(uint160(address(this)));
            require(self.balance >= amount, "StakeTON: insuffient ETH");
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "StakeTON: withdraw failed.");
        } else {
            require(staked.releasedAmount <= amount, "StakeTON: Amount wrong");
            staked.releasedAmount = amount;
            require(
                IIERC20(paytoken).transfer(msg.sender, amount),
                "StakeTON: transfer fail"
            );
        }

        emit Withdrawal(
            msg.sender,
            staked.releasedAmount,
            staked.releasedTOSAmount
        );
    }

    /// @dev withdraw TON
    /// @param ton  TON address
    /// @param wton  WTON address
    /// @param tonAmount  the amount of TON to be withdrawn to msg.sender
    /// @param wtonAmount  the amount of WTON to be withdrawn to msg.sender
    /// @param tosAmount  the amount of TOS to be withdrawn to msg.sender
    function tonWithdraw(
        address ton,
        address wton,
        uint256 tonAmount,
        uint256 wtonAmount,
        uint256 tosAmount
    ) internal {
        if (tonAmount > 0) {
            require(
                IIERC20(ton).balanceOf(address(this)) >= tonAmount,
                "StakeTON: ton balance is lack"
            );

            require(
                IIERC20(ton).transfer(msg.sender, tonAmount),
                "StakeTON: transfer ton fail"
            );
        }
        if (wtonAmount > 0) {
            require(
                IIERC20(wton).balanceOf(address(this)) >= wtonAmount,
                "StakeTON: wton balance is lack"
            );
            require(
                IWTON(wton).swapToTONAndTransfer(msg.sender, wtonAmount),
                "StakeTON: transfer wton fail"
            );
        }
        if (tosAmount > 0) {
            require(
                IIERC20(token).balanceOf(address(this)) >= tosAmount,
                "StakeTON: tos balance is lack"
            );
            require(
                IIERC20(token).transfer(msg.sender, tosAmount),
                "StakeTON: transfer tos fail"
            );
        }
    }

    /// @dev Claim for reward
    function claim() external override lock {
        require(IIStake1Vault(vault).saleClosed(), "StakeTON: not closed");
        uint256 rewardClaim = 0;

        LibTokenStake1.StakedAmount storage staked = userStaked[msg.sender];
        require(staked.claimedBlock < endBlock, "StakeTON: claimed");

        rewardClaim = canRewardAmount(msg.sender, block.number);

        require(rewardClaim > 0, "StakeTON: reward is zero");

        uint256 rewardTotal =
            IIStake1Vault(vault).totalRewardAmount(address(this));
        require(
            rewardClaimedTotal.add(rewardClaim) <= rewardTotal,
            "StakeTON: total reward exceeds"
        );

        staked.claimedBlock = block.number;
        staked.claimedAmount = staked.claimedAmount.add(rewardClaim);
        rewardClaimedTotal = rewardClaimedTotal.add(rewardClaim);

        require(
            IIStake1Vault(vault).claim(msg.sender, rewardClaim),
            "StakeTON: fail claim from vault"
        );

        emit Claimed(msg.sender, rewardClaim, block.number);
    }

    /// @dev Returns the amount that can be rewarded
    /// @param account  the account that claimed reward
    /// @param specificBlock the block that claimed reward
    /// @return reward the reward amount that can be taken
    function canRewardAmount(address account, uint256 specificBlock)
        public
        view
        override
        returns (uint256)
    {
        uint256 reward = 0;
        if (specificBlock > endBlock) specificBlock = endBlock;

        if (
            specificBlock < startBlock ||
            userStaked[account].amount == 0 ||
            userStaked[account].claimedBlock > endBlock ||
            userStaked[account].claimedBlock > specificBlock
        ) {
            reward = 0;
        } else {
            uint256 startR = startBlock;
            uint256 endR = endBlock;
            if (startR < userStaked[account].claimedBlock)
                startR = userStaked[account].claimedBlock;
            if (specificBlock < endR) endR = specificBlock;

            uint256[] memory orderedEndBlocks =
                IIStake1Vault(vault).orderedEndBlocksAll();

            if (orderedEndBlocks.length > 0) {
                uint256 _end = 0;
                uint256 _start = startR;
                uint256 _total = 0;
                uint256 blockTotalReward = 0;
                blockTotalReward = IIStake1Vault(vault).blockTotalReward();

                address user = account;
                uint256 amount = userStaked[user].amount;

                for (uint256 i = 0; i < orderedEndBlocks.length; i++) {
                    _end = orderedEndBlocks[i];
                    _total = IIStake1Vault(vault).stakeEndBlockTotal(_end);

                    if (_start > _end) {} else if (endR <= _end) {
                        if (_total > 0) {
                            uint256 _period1 = endR.sub(startR);
                            reward = reward.add(
                                blockTotalReward.mul(_period1).mul(amount).div(
                                    _total
                                )
                            );
                        }
                        break;
                    } else {
                        if (_total > 0) {
                            uint256 _period2 = _end.sub(startR);
                            reward = reward.add(
                                blockTotalReward.mul(_period2).mul(amount).div(
                                    _total
                                )
                            );
                        }
                        startR = _end;
                    }
                }
            }
        }
        return reward;
    }
    /*
    function canRewardAmountTest(address account, uint256 specificBlock)
        public view
        returns (uint256, uint256, uint256, uint256)
    {
        uint256 reward = 0;
        uint256 startR = 0;
        uint256 endR = 0;
        uint256 blockTotalReward = 0;
        if(specificBlock > endBlock ) specificBlock = endBlock;

        if (
            specificBlock < startBlock ||
            userStaked[account].amount == 0 ||
            userStaked[account].claimedBlock > endBlock ||
            userStaked[account].claimedBlock > specificBlock
        ) {
            reward = 0;
        } else {
            startR = startBlock;
            endR = endBlock;
            if (startR < userStaked[account].claimedBlock)
                startR = userStaked[account].claimedBlock;
            if (specificBlock < endR) endR = specificBlock;

            uint256[] memory orderedEndBlocks =
                IIStake1Vault(vault).orderedEndBlocksAll();

            if (orderedEndBlocks.length > 0) {
                uint256 _end = 0;
                uint256 _start = startR;
                uint256 _total = 0;
                //uint256 blockTotalReward = 0;
                blockTotalReward = IIStake1Vault(vault).blockTotalReward();

                address user = account;
                uint256 amount = userStaked[user].amount;

                for (uint256 i = 0; i < orderedEndBlocks.length; i++) {
                    _end = orderedEndBlocks[i];
                    _total = IIStake1Vault(vault).stakeEndBlockTotal(_end);

                    if (_start > _end) {

                    } else if (endR <= _end) {
                        reward +=
                            (blockTotalReward *
                                (endR - startR) * amount) /
                            _total;
                        break;
                    } else {
                        reward +=
                            (blockTotalReward *
                                (_end - startR) *
                                amount) /
                            _total;
                        startR = _end;
                    }
                }
            }
        }
        return (reward, startR, endR, blockTotalReward);
    }
    */
}
