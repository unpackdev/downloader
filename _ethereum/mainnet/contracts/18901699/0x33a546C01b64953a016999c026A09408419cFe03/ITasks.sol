// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Escrow.sol";

/*
  Some of the functionality in this contract will be removed in the next version.
  This functionality will be provided by off-chain indexing instead.
  Therefore this functionality might be implemented in a more dirty way to make it easier to remove.
  This is true for:
  - taskStatistics
  - getManagingTasks
  - getExecutingTasks
  - manager and executor/applicant in all events (except first introduction)

  Seperation of manager and creator is also a recent change. The frontend will currently use creator == manager.
  Hence there is also no getCreatedTasks.
*/
interface ITasks {
    error InvalidTimestamp();
    error InvalidAddress();
    error PointlessOperation();
    error ArrayLargerThanSupported();

    error TaskDoesNotExist();
    error TaskNotOpen();
    error TaskNotTaken();
    error TaskNotClosed();
    error TaskClosed();

    error NotManager();
    error NotExecutor();

    error RewardAboveBudget();
    error RewardDoesntEndWithNewToken();
    error ApplicationDoesNotExist();
    error NotYourApplication();
    error ApplicationNotAccepted();
    error SubmissionDoesNotExist();
    error SubmissionAlreadyJudged();
    error JudgementNone();

    error RequestDoesNotExist();
    error RequestAlreadyAccepted();
    error RequestNotAccepted();
    error RequestAlreadyExecuted();

    error ManualBudgetIncreaseRequired();

    event TaskCreated(
        uint256 indexed taskId,
        string metadata,
        uint64 deadline,
        ERC20Transfer[] budget,
        address creator,
        address manager
    );
    event ApplicationCreated(
        uint256 indexed taskId,
        uint16 applicationId,
        string metadata,
        Reward[] reward,
        address manager,
        address applicant
    );
    event ApplicationAccepted(
        uint256 indexed taskId,
        uint16 applicationId,
        address manager,
        address applicant
    );
    event TaskTaken(
        uint256 indexed taskId,
        uint16 applicationId,
        address manager,
        address executor
    );
    event SubmissionCreated(
        uint256 indexed taskId,
        uint8 submissionId,
        string metadata,
        address manager,
        address executor
    );
    event SubmissionReviewed(
        uint256 indexed taskId,
        uint8 submissionId,
        SubmissionJudgement judgement,
        string feedback,
        address manager,
        address executor
    );
    event TaskCompleted(
        uint256 indexed taskId,
        address manager,
        address executor
    );

    event CancelTaskRequested(
        uint256 indexed taskId,
        uint8 requestId,
        string explanation,
        address manager,
        address executor
    );
    event TaskCancelled(
        uint256 indexed taskId,
        address manager,
        address executor
    );
    event RequestAccepted(
        uint256 indexed taskId,
        RequestType requestType,
        uint8 requestId,
        address manager,
        address executor
    );
    event RequestExecuted(
        uint256 indexed taskId,
        RequestType requestType,
        uint8 requestId,
        address by,
        address manager,
        address executor
    );

    event DeadlineExtended(
        uint256 indexed taskId,
        uint64 extension,
        address manager,
        address executor
    );
    event BudgetIncreased(
        uint256 indexed taskId,
        uint96[] increase,
        address manager
    );
    event MetadataEditted(
        uint256 indexed taskId,
        string newMetadata,
        address manager
    );

    /// @notice A container for ERC20 transfer information.
    /// @param tokenContract ERC20 token to transfer.
    /// @param amount How much of this token should be transfered.
    struct ERC20Transfer {
        IERC20 tokenContract;
        uint96 amount;
    }

    /// @notice A container for a reward payout.
    /// @param nextToken If this reward is payed out in the next ERC20 token.
    /// @dev IERC20 (address) is a lot of storage, rather just keep those only in budget.
    /// @notice nextToken should always be true for the last entry
    /// @param to Whom this token should be transfered to.
    /// @param amount How much of this token should be transfered.
    struct Reward {
        bool nextToken;
        address to;
        uint88 amount;
    }

    /// @notice A container for a task application.
    /// @param metadata Metadata of the application. (IPFS hash)
    /// @param applicant Who has submitted this application.
    /// @param accepted If the application has been accepted by the manager.
    /// @param reward How much rewards the applicant wants for completion.
    struct Application {
        string metadata;
        address applicant;
        bool accepted;
        uint8 rewardCount;
        mapping(uint8 => Reward) reward;
    }

    struct OffChainApplication {
        string metadata;
        address applicant;
        bool accepted;
        Reward[] reward;
    }

    /// @notice For approving people on task creation (they are not required to make an application)
    struct PreapprovedApplication {
        address applicant;
        Reward[] reward;
    }

    enum SubmissionJudgement {
        None,
        Accepted,
        Rejected
    }
    /// @notice A container for a task submission.
    /// @param metadata Metadata of the submission. (IPFS hash)
    /// @param judgement Judgement cast on the submission.
    /// @param feedback A response from the manager. (IPFS hash)
    struct Submission {
        string metadata;
        string feedback;
        SubmissionJudgement judgement;
    }

    enum RequestType {
        CancelTask
    }

    /// @notice A container for shared request information.
    /// @param accepted If the request was accepted.
    /// @param executed If the request was executed.
    struct Request {
        bool accepted;
        bool executed;
    }

    /// @notice A container for a request to cancel the task.
    /// @param request Request information.
    /// @param explanation Why the task should be cancelled.
    struct CancelTaskRequest {
        Request request;
        string explanation;
    }

    enum TaskState {
        Open,
        Taken,
        Closed
    }
    /// @notice A container for task-related information.
    /// @param metadata Metadata of the task. (IPFS hash)
    /// @param deadline Block timestamp at which the task expires if not completed.
    /// @param budget Maximum ERC20 rewards that can be earned by completing the task.
    /// @param manager Who has created the task.
    /// @param state Current state the task is in.
    /// @param applications Applications to take the job.
    /// @param executorApplication Index of the application that will execture the task.
    /// @param submissions Submission made to finish the task.
    /// @dev Storage blocks seperated by newlines.
    struct Task {
        string metadata;
        uint64 deadline;
        Escrow escrow;
        address creator;
        address manager;
        TaskState state;
        uint16 executorApplication;
        uint8 budgetCount;
        uint16 applicationCount;
        uint8 submissionCount;
        uint8 cancelTaskRequestCount;
        mapping(uint8 => ERC20Transfer) budget;
        mapping(uint16 => Application) applications;
        mapping(uint8 => Submission) submissions;
        mapping(uint8 => CancelTaskRequest) cancelTaskRequests;
    }

    struct OffChainTask {
        string metadata;
        uint64 deadline;
        uint16 executorApplication;
        address creator;
        address manager;
        TaskState state;
        Escrow escrow;
        ERC20Transfer[] budget;
        OffChainApplication[] applications;
        Submission[] submissions;
        CancelTaskRequest[] cancelTaskRequests;
    }

    /// @notice Retrieves the current amount of created tasks.
    function taskCount() external view returns (uint256);

    /// @notice Retrieves the current statistics of created tasks.
    function taskStatistics()
        external
        view
        returns (
            uint256 openTasks,
            uint256 takenTasks,
            uint256 successfulTasks
        );

    /// @notice Retrieves all task information by id.
    /// @param _taskId Id of the task.
    function getTask(
        uint256 _taskId
    ) external view returns (OffChainTask memory);

    /// @notice Retrieves multiple tasks.
    /// @param _taskIds Ids of the tasks.
    function getTasks(
        uint256[] calldata _taskIds
    ) external view returns (OffChainTask[] memory);

    /// @notice Retrieves all tasks of a manager. Most recent ones first.
    /// @param _manager The manager to fetch tasks of.
    /// @param _fromTaskId What taskId to start from. 0 for most recent task.
    /// @param _max The maximum amount of tasks to return. 0 for no max.
    function getManagingTasks(
        address _manager,
        uint256 _fromTaskId,
        uint256 _max
    ) external view returns (OffChainTask[] memory);

    /// @notice Retrieves all tasks of an executor. Most recent ones first.
    /// @param _executor The executor to fetch tasks of.
    /// @param _fromTaskId What taskId to start from. 0 for most recent task.
    /// @param _max The maximum amount of tasks to return. 0 for no max.
    function getExecutingTasks(
        address _executor,
        uint256 _fromTaskId,
        uint256 _max
    ) external view returns (OffChainTask[] memory);

    /// @notice Create a new task.
    /// @param _metadata Metadata of the task. (IPFS hash)
    /// @param _deadline Block timestamp at which the task expires if not completed.
    /// @param _budget Maximum ERC20 rewards that can be earned by completing the task.
    /// @param _manager Who will manage the task (become the manager).
    /// @return taskId Id of the newly created task.
    function createTask(
        string calldata _metadata,
        uint64 _deadline,
        ERC20Transfer[] calldata _budget,
        address _manager,
        PreapprovedApplication[] calldata _preapprove
    ) external returns (uint256 taskId);

    /// @notice Apply to take the task.
    /// @param _taskId Id of the task.
    /// @param _metadata Metadata of your application.
    /// @param _reward Wanted rewards for completing the task.
    function applyForTask(
        uint256 _taskId,
        string calldata _metadata,
        Reward[] calldata _reward
    ) external returns (uint16 applicationId);

    /// @notice Accept application to allow them to take the task.
    /// @param _taskId Id of the task.
    /// @param _applicationIds Indexes of the applications to accept.
    function acceptApplications(
        uint256 _taskId,
        uint16[] calldata _applicationIds
    ) external;

    /// @notice Take the task after your application has been accepted.
    /// @param _taskId Id of the task.
    /// @param _applicationId Index of application you made that has been accepted.
    function takeTask(uint256 _taskId, uint16 _applicationId) external;

    /// @notice Create a submission.
    /// @param _taskId Id of the task.
    /// @param _metadata Metadata of the submission. (IPFS hash)
    function createSubmission(
        uint256 _taskId,
        string calldata _metadata
    ) external returns (uint8 submissionId);

    /// @notice Review a submission.
    /// @param _taskId Id of the task.
    /// @param _submissionId Index of the submission that is reviewed.
    /// @param _judgement Outcome of the review.
    /// @param _feedback Reasoning of the reviewer. (IPFS hash)
    function reviewSubmission(
        uint256 _taskId,
        uint8 _submissionId,
        SubmissionJudgement _judgement,
        string calldata _feedback
    ) external;

    /// @notice Cancels a task. This can be used to close a task and receive back the budget.
    /// @param _taskId Id of the task.
    /// @param _explanation Why the task was cancelled. (IPFS hash)
    function cancelTask(
        uint256 _taskId,
        string calldata _explanation
    ) external returns (uint8 cancelTaskRequestId);

    /// @notice Accepts a request, executing the proposed action.
    /// @param _taskId Id of the task.
    /// @param _requestType What kind of request it is.
    /// @param _requestId Id of the request.
    /// @param _execute If the request should also be executed in this transaction.
    function acceptRequest(
        uint256 _taskId,
        RequestType _requestType,
        uint8 _requestId,
        bool _execute
    ) external;

    /// @notice Exectued an accepted request, allows anyone to pay for the gas costs of the execution.
    /// @param _taskId Id of the task.
    /// @param _requestType What kind of request it is.
    /// @param _requestId Id of the request.
    function executeRequest(
        uint256 _taskId,
        RequestType _requestType,
        uint8 _requestId
    ) external;

    /// @notice Extend the deadline of a task.
    /// @param _taskId Id of the task.
    /// @param _extension How much to extend the deadline by.
    function extendDeadline(uint256 _taskId, uint64 _extension) external;

    /// @notice Increase the budget of the task.
    /// @param _taskId Id of the task.
    /// @param _increase How much to increase each tokens amount by.
    function increaseBudget(
        uint256 _taskId,
        uint96[] calldata _increase
    ) external;

    /// @notice Edit the metadata of a task.
    /// @param _taskId Id of the task.
    /// @param _newMetadata New metadata of the task.
    /// @dev This metadata update might change the task completely. Show a warning to people who applied before the change.
    function editMetadata(
        uint256 _taskId,
        string calldata _newMetadata
    ) external;
}
