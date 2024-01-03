// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITasks.sol";
import "./Context.sol";

/*
  Higher level functions to allow the Tasks file to be more readable.
*/
abstract contract TasksUtils is ITasks, Context {
    function _toOffchainTask(
        Task storage task
    ) internal view returns (OffChainTask memory offchainTask) {
        offchainTask.metadata = task.metadata;
        offchainTask.deadline = task.deadline;
        offchainTask.executorApplication = task.executorApplication;
        offchainTask.creator = task.creator;
        offchainTask.manager = task.manager;
        offchainTask.state = task.state;
        offchainTask.escrow = task.escrow;

        offchainTask.budget = new ERC20Transfer[](task.budgetCount);
        for (uint8 i; i < offchainTask.budget.length; ) {
            offchainTask.budget[i] = task.budget[i];
            unchecked {
                ++i;
            }
        }

        offchainTask.applications = new OffChainApplication[](
            task.applicationCount
        );
        for (uint8 i; i < offchainTask.applications.length; ) {
            Application storage application = task.applications[i];
            offchainTask.applications[i].metadata = application.metadata;
            offchainTask.applications[i].applicant = application.applicant;
            offchainTask.applications[i].accepted = application.accepted;
            offchainTask.applications[i].reward = new Reward[](
                application.rewardCount
            );
            for (uint8 j; j < offchainTask.applications[i].reward.length; ) {
                offchainTask.applications[i].reward[j] = application.reward[j];
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        offchainTask.submissions = new Submission[](task.submissionCount);
        for (uint8 i; i < offchainTask.submissions.length; ) {
            offchainTask.submissions[i] = task.submissions[i];
            unchecked {
                ++i;
            }
        }

        offchainTask.cancelTaskRequests = new CancelTaskRequest[](
            task.cancelTaskRequestCount
        );
        for (uint8 i; i < offchainTask.cancelTaskRequests.length; ) {
            offchainTask.cancelTaskRequests[i] = task.cancelTaskRequests[i];
            unchecked {
                ++i;
            }
        }
    }

    function _increaseBudgetToReward(
        Task storage task,
        uint8 _length,
        mapping(uint8 => Reward) storage _reward
    ) internal {
        uint8 j;
        ERC20Transfer memory erc20Transfer = task.budget[0];
        uint256 needed;
        for (uint8 i; i < _length; ) {
            unchecked {
                needed += _reward[i].amount;
            }

            if (_reward[i].nextToken) {
                if (needed > erc20Transfer.amount) {
                    // Existing budget in escrow doesnt cover the needed reward
                    erc20Transfer.tokenContract.transferFrom(
                        _msgSender(),
                        address(task.escrow),
                        needed - erc20Transfer.amount
                    );

                    if (
                        erc20Transfer.tokenContract.balanceOf(
                            address(task.escrow)
                        ) < needed
                    ) {
                        // transferFrom returns less funds than send, use increaseBudget to increase balance to wanted reward.
                        revert ManualBudgetIncreaseRequired();
                    }

                    // (2^88-1) * 2^8 = 2^96-2^8, needed cannot be more than 2^96-1, so fits in uint96
                    task.budget[j].amount = uint96(needed);
                }

                needed = 0;
                unchecked {
                    erc20Transfer = task.budget[++j];
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function _setRewardBellowBudget(
        Task storage task,
        Application storage application,
        Reward[] calldata _reward
    ) internal {
        if (_reward.length >= type(uint8).max) {
            revert ArrayLargerThanSupported();
        }
        application.rewardCount = uint8(_reward.length);

        uint8 j;
        ERC20Transfer memory erc20Transfer = task.budget[0];
        uint256 alreadyReserved;
        for (uint8 i; i < uint8(_reward.length); ) {
            // erc20Transfer.amount -= _reward[i].amount (underflow error, but that is not a nice custom once)
            unchecked {
                alreadyReserved += _reward[i].amount;
            }
            if (alreadyReserved > erc20Transfer.amount) {
                revert RewardAboveBudget();
            }

            application.reward[i] = _reward[i];

            if (_reward[i].nextToken) {
                alreadyReserved = 0;
                unchecked {
                    erc20Transfer = task.budget[++j];
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function _payoutTask(Task storage task) internal {
        Application storage executor = task.applications[
            task.executorApplication
        ];
        address creator = task.creator;
        Escrow escrow = task.escrow;

        uint8 j;
        uint8 rewardCount = executor.rewardCount;
        uint8 budgetCount = task.budgetCount;
        for (uint8 i; i < budgetCount; ) {
            ERC20Transfer memory erc20Transfer = task.budget[i];
            while (j < rewardCount) {
                Reward memory reward = executor.reward[j];
                escrow.transfer(
                    erc20Transfer.tokenContract,
                    reward.to,
                    reward.amount
                );
                unchecked {
                    erc20Transfer.amount -= reward.amount;
                    ++j;
                }

                if (reward.nextToken) {
                    break;
                }
            }

            // Gas optimization
            if (erc20Transfer.amount != 0) {
                escrow.transfer(
                    erc20Transfer.tokenContract,
                    creator,
                    erc20Transfer.amount
                );
            }

            unchecked {
                ++i;
            }
        }

        task.state = TaskState.Closed;
    }

    function _refundCreator(Task storage task) internal {
        uint8 budgetCount = task.budgetCount;
        address creator = task.creator;
        Escrow escrow = task.escrow;
        for (uint8 i; i < budgetCount; ) {
            ERC20Transfer memory erc20Transfer = task.budget[i];
            escrow.transfer(
                erc20Transfer.tokenContract,
                creator,
                erc20Transfer.amount
            );

            unchecked {
                ++i;
            }
        }

        task.state = TaskState.Closed;
    }
}
