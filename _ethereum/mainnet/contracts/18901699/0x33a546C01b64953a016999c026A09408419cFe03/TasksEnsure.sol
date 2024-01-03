// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITasks.sol";
import "./Context.sol";

/*
  Functions to ensure a certain precondition is met.
*/
abstract contract TasksEnsure is ITasks, Context {
    function _ensureValidTimestamp(uint64 timestamp) internal pure {
        if (timestamp == 0) {
            revert InvalidTimestamp();
        }
    }

    function _ensureValidAddress(address addr) internal pure {
        if (addr == address(0)) {
            revert InvalidAddress();
        }
    }

    function _ensureTaskIsOpen(Task storage task) internal view {
        if (task.state != TaskState.Open) {
            revert TaskNotOpen();
        }
    }

    function _ensureTaskIsTaken(Task storage task) internal view {
        if (task.state != TaskState.Taken) {
            revert TaskNotTaken();
        }
    }

    function _ensureTaskNotClosed(Task storage task) internal view {
        if (task.state == TaskState.Closed) {
            revert TaskClosed();
        }
    }

    function _ensureSenderIsManager(Task storage task) internal view {
        if (task.manager != _msgSender()) {
            revert NotManager();
        }
    }

    ///@dev Should only be called is the task is not open!
    function _ensureSenderIsExecutor(Task storage task) internal view {
        if (
            task.applications[task.executorApplication].applicant !=
            _msgSender()
        ) {
            revert NotExecutor();
        }
    }

    function _ensureRewardEndsWithNextToken(
        Reward[] memory reward
    ) internal pure {
        unchecked {
            if (reward.length != 0 && !reward[reward.length - 1].nextToken) {
                revert RewardDoesntEndWithNewToken();
            }
        }
    }

    function _ensureApplicationExists(
        Task storage task,
        uint16 _applicationId
    ) internal view {
        if (_applicationId >= task.applicationCount) {
            revert ApplicationDoesNotExist();
        }
    }

    function _ensureSenderIsApplicant(
        Application storage application
    ) internal view {
        if (application.applicant != _msgSender()) {
            revert NotYourApplication();
        }
    }

    function _ensureApplicationIsAccepted(
        Application storage application
    ) internal view {
        if (!application.accepted) {
            revert ApplicationNotAccepted();
        }
    }

    function _ensureSubmissionExists(
        Task storage task,
        uint8 _submissionId
    ) internal view {
        if (_submissionId >= task.submissionCount) {
            revert SubmissionDoesNotExist();
        }
    }

    function _ensureSubmissionNotJudged(
        Submission storage submission
    ) internal view {
        if (submission.judgement != SubmissionJudgement.None) {
            revert SubmissionAlreadyJudged();
        }
    }

    function _ensureJudgementNotNone(
        SubmissionJudgement judgement
    ) internal pure {
        if (judgement == SubmissionJudgement.None) {
            revert JudgementNone();
        }
    }

    function _ensureCancelTaskRequestExists(
        Task storage task,
        uint8 _requestId
    ) internal view {
        if (_requestId >= task.cancelTaskRequestCount) {
            revert RequestDoesNotExist();
        }
    }

    function _ensureRequestNotAccepted(Request storage request) internal view {
        if (request.accepted) {
            revert RequestAlreadyAccepted();
        }
    }

    function _ensureRequestAccepted(Request storage request) internal view {
        if (!request.accepted) {
            revert RequestNotAccepted();
        }
    }

    function _ensureRequestNotExecuted(Request storage request) internal view {
        if (request.executed) {
            revert RequestAlreadyExecuted();
        }
    }
}
