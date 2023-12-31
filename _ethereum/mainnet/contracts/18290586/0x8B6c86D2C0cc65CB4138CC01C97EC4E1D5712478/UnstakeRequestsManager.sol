// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Initializable.sol";
import {AccessControlEnumerableUpgradeable} from
    "openzeppelin-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./Address.sol";
import "./Math.sol";
import "./SafeERC20Upgradeable.sol";

import "./ProtocolEvents.sol";
import "./IMETH.sol";
import "./IOracle.sol";
import "./IUnstakeRequestsManager.sol";
import "./IStaking.sol";

/// @notice Events emitted by the unstake requests manager.
interface UnstakeRequestsManagerEvents {
    /// @notice Created emitted when an unstake request has been created.
    /// @param id The id of the unstake request.
    /// @param requester The address of the user who requested to unstake.
    /// @param mETHLocked The amount of mETH that will be burned when the request is claimed.
    /// @param ethRequested The amount of ETH that will be returned to the requester.
    /// @param cumulativeETHRequested The cumulative amount of ETH requested at the time of the unstake request.
    /// @param blockNumber The block number at the point at which the request was created.
    event UnstakeRequestCreated(
        uint256 indexed id,
        address indexed requester,
        uint256 mETHLocked,
        uint256 ethRequested,
        uint256 cumulativeETHRequested,
        uint256 blockNumber
    );

    /// @notice Claimed emitted when an unstake request has been claimed.
    /// @param id The id of the unstake request.
    /// @param requester The address of the user who requested to unstake.
    /// @param mETHLocked The amount of mETH that will be burned when the request is claimed.
    /// @param ethRequested The amount of ETH that will be returned to the requester.
    /// @param cumulativeETHRequested The cumulative amount of ETH requested at the time of the unstake request.
    /// @param blockNumber The block number at the point at which the request was created.
    event UnstakeRequestClaimed(
        uint256 indexed id,
        address indexed requester,
        uint256 mETHLocked,
        uint256 ethRequested,
        uint256 cumulativeETHRequested,
        uint256 blockNumber
    );

    /// @notice Cancelled emitted when an unstake request has been cancelled by an admin.
    /// @param id The id of the unstake request.
    /// @param requester The address of the user who requested to unstake.
    /// @param mETHLocked The amount of mETH that will be burned when the request is claimed.
    /// @param ethRequested The amount of ETH that will be returned to the requester.
    /// @param cumulativeETHRequested The cumulative amount of ETH requested at the time of the unstake request.
    /// @param blockNumber The block number at the point at which the request was created.
    event UnstakeRequestCancelled(
        uint256 indexed id,
        address indexed requester,
        uint256 mETHLocked,
        uint256 ethRequested,
        uint256 cumulativeETHRequested,
        uint256 blockNumber
    );
}

/// @title UnstakeRequestsManager
/// @notice Manages unstake requests from the staking contract.
contract UnstakeRequestsManager is
    Initializable,
    AccessControlEnumerableUpgradeable,
    IUnstakeRequestsManager,
    UnstakeRequestsManagerEvents,
    ProtocolEvents
{
    // Errors.
    error AlreadyClaimed();
    error DoesNotReceiveETH();
    error NotEnoughFunds(uint256 cumulativeETHOnRequest, uint256 allocatedETHForClaims);
    error NotFinalized();
    error NotRequester();
    error NotStakingContract();

    /// @notice Role allowed to set properties of the contract.
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /// @notice Role that is allowed to cancel unfinalized requests if the protocol is in emergency state.
    bytes32 public constant REQUEST_CANCELLER_ROLE = keccak256("REQUEST_CANCELLER_ROLE");

    /// @notice The staking contract to which the unstake requests manager accepts claims and new unstake requests from.
    IStakingReturnsWrite public stakingContract;

    /// @notice The oracle contract that the finalization criteria relies on.
    IOracleReadRecord public oracle;

    /// @notice The total amount of ether sent by the staking contract.
    /// @dev This value can be decreased when reclaiming surplus allocatedETHs.
    uint256 public allocatedETHForClaims;

    /// @notice The total amount of ether claimed by requesters.
    uint256 public totalClaimed;

    /// @notice A request's block number on creation plus numberOfBlocksToFinalize determines
    /// if the request is finalized.
    uint256 public numberOfBlocksToFinalize;

    /// @notice The mETH token contract.
    /// @dev Tokens will be minted / burned during staking / unstaking.
    IMETH public mETH;

    /// @dev Cache the latest cumulative ETH requested value instead of checking latest element in the array.
    /// This prevents encountering an invalid value if someone claims the request which resets it.
    uint128 public latestCumulativeETHRequested;

    /// @dev The internal queue of unstake requests.
    UnstakeRequest[] internal _unstakeRequests;

    /// @notice Configuration for contract initialization.
    struct Init {
        address admin;
        address manager;
        address requestCanceller;
        IMETH mETH;
        IStakingReturnsWrite stakingContract;
        IOracleReadRecord oracle;
        uint256 numberOfBlocksToFinalize;
    }

    constructor() {
        _disableInitializers();
    }

    /// @notice Inititalizes the contract.
    /// @dev MUST be called during the contract upgrade to set up the proxies state.
    function initialize(Init memory init) external initializer {
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, init.admin);
        numberOfBlocksToFinalize = init.numberOfBlocksToFinalize;
        stakingContract = init.stakingContract;
        oracle = init.oracle;
        mETH = init.mETH;

        _grantRole(MANAGER_ROLE, init.manager);
        _grantRole(REQUEST_CANCELLER_ROLE, init.requestCanceller);
    }

    /// @inheritdoc IUnstakeRequestsManagerWrite
    /// @dev Increases the cumulative ETH requested counter and pushes a new unstake request to the array. This function
    /// can only be called by the staking contract.
    function create(address requester, uint128 mETHLocked, uint128 ethRequested)
        external
        onlyStakingContract
        returns (uint256)
    {
        uint128 currentCumulativeETHRequested = latestCumulativeETHRequested + ethRequested;
        uint256 requestID = _unstakeRequests.length;
        UnstakeRequest memory unstakeRequest = UnstakeRequest({
            id: uint128(requestID),
            requester: requester,
            mETHLocked: mETHLocked,
            ethRequested: ethRequested,
            cumulativeETHRequested: currentCumulativeETHRequested,
            blockNumber: uint64(block.number)
        });
        _unstakeRequests.push(unstakeRequest);

        latestCumulativeETHRequested = currentCumulativeETHRequested;
        emit UnstakeRequestCreated(
            requestID, requester, mETHLocked, ethRequested, currentCumulativeETHRequested, block.number
        );
        return requestID;
    }

    /// @inheritdoc IUnstakeRequestsManagerWrite
    /// @dev Verifies the requester's identity, finality of the request, and availability of funds before transferring
    /// the requested ETH. The unstake request is then removed from the array.
    function claim(uint256 requestID, address requester) external onlyStakingContract {
        UnstakeRequest memory request = _unstakeRequests[requestID];

        if (request.requester == address(0)) {
            revert AlreadyClaimed();
        }

        if (requester != request.requester) {
            revert NotRequester();
        }

        if (!_isFinalized(request)) {
            revert NotFinalized();
        }

        if (request.cumulativeETHRequested > allocatedETHForClaims) {
            revert NotEnoughFunds(request.cumulativeETHRequested, allocatedETHForClaims);
        }

        delete _unstakeRequests[requestID];
        totalClaimed += request.ethRequested;

        emit UnstakeRequestClaimed({
            id: requestID,
            requester: requester,
            mETHLocked: request.mETHLocked,
            ethRequested: request.ethRequested,
            cumulativeETHRequested: request.cumulativeETHRequested,
            blockNumber: request.blockNumber
        });

        // Claiming the request burns the locked mETH tokens from this contract.
        // Note that it is intentional that burning happens here rather than at unstake time.
        // Please see the docs folder for more information.
        mETH.burn(request.mETHLocked);

        Address.sendValue(payable(requester), request.ethRequested);
    }

    /// @inheritdoc IUnstakeRequestsManagerWrite
    /// @dev Iteratively checks the finality of the latest requests and cancels the unfinalized ones until reaching a
    /// finalized request or the max loop bound. Adjusts the state of the latest cumulative ETH accordingly.
    function cancelUnfinalizedRequests(uint256 maxCancel) external onlyRole(REQUEST_CANCELLER_ROLE) returns (bool) {
        uint256 length = _unstakeRequests.length;
        if (length == 0) {
            return false;
        }

        if (length < maxCancel) {
            maxCancel = length;
        }

        // Cache all cancelled requests to perform the refunds after processing all local effects to strictly follow the
        // checks-effects-interaction pattern.
        UnstakeRequest[] memory requests = new UnstakeRequest[](maxCancel);

        // Find the number of requests that have not been finalized.
        uint256 numCancelled = 0;
        while (numCancelled < maxCancel) {
            UnstakeRequest memory request = _unstakeRequests[_unstakeRequests.length - 1];

            if (_isFinalized(request)) {
                break;
            }

            _unstakeRequests.pop();
            requests[numCancelled] = request;
            ++numCancelled;

            emit UnstakeRequestCancelled(
                request.id,
                request.requester,
                request.mETHLocked,
                request.ethRequested,
                request.cumulativeETHRequested,
                request.blockNumber
            );
        }

        // Reset the latest cumulative ETH state and check whether there are more unfinalized requests to cancel.
        bool hasMore;
        uint256 remainingRequestsLength = _unstakeRequests.length;
        if (remainingRequestsLength == 0) {
            latestCumulativeETHRequested = 0;
            hasMore = false;
        } else {
            UnstakeRequest memory latestRemainingRequest = _unstakeRequests[remainingRequestsLength - 1];
            latestCumulativeETHRequested = latestRemainingRequest.cumulativeETHRequested;
            hasMore = !_isFinalized(latestRemainingRequest);
        }

        // Return the locked mETH of all cancelled requests.
        for (uint256 i = 0; i < numCancelled; i++) {
            SafeERC20Upgradeable.safeTransfer(mETH, requests[i].requester, requests[i].mETHLocked);
        }

        return hasMore;
    }

    /// @inheritdoc IUnstakeRequestsManagerWrite
    /// @dev Handles incoming ether from the staking contract, increasing the allocatedETHForClaims counter by the value
    /// of the incoming allocatedETH.
    function allocateETH() external payable onlyStakingContract {
        allocatedETHForClaims += msg.value;
    }

    /// @inheritdoc IUnstakeRequestsManagerWrite
    /// @dev Helps during the emergency scenario where we cancel unstake requests and we want to move ether back into
    /// the staking contract.
    function withdrawAllocatedETHSurplus() external onlyStakingContract {
        uint256 toSend = allocatedETHSurplus();
        if (toSend == 0) {
            return;
        }
        allocatedETHForClaims -= toSend;
        stakingContract.receiveFromUnstakeRequestsManager{value: toSend}();
    }

    /// @notice Returns the ID of the next unstake requests to be created.
    function nextRequestId() external view returns (uint256) {
        return _unstakeRequests.length;
    }

    /// @inheritdoc IUnstakeRequestsManagerRead
    function requestByID(uint256 requestID) external view returns (UnstakeRequest memory) {
        return _unstakeRequests[requestID];
    }

    /// @inheritdoc IUnstakeRequestsManagerRead
    function requestInfo(uint256 requestID) external view returns (bool, uint256) {
        UnstakeRequest memory request = _unstakeRequests[requestID];

        bool isFinalized = _isFinalized(request);
        uint256 claimableAmount = 0;

        // The cumulative ETH requested also includes the ETH requested and must be subtracted from the cumulative total
        // to find partially filled amounts.
        uint256 allocatedEthRequired = request.cumulativeETHRequested - request.ethRequested;
        if (allocatedEthRequired < allocatedETHForClaims) {
            // The allocatedETHForClaims increases over time whereas the request's cumulative ETH requested stays the
            // same. This means the difference between the two will also increase over time. Given we only want to
            // return the partially filled amount up to the full ETH requested, we take the minimum of the two.
            claimableAmount = Math.min(allocatedETHForClaims - allocatedEthRequired, request.ethRequested);
        }
        return (isFinalized, claimableAmount);
    }

    /// @inheritdoc IUnstakeRequestsManagerRead
    /// @dev Compares the latest the allocatedETHForClaims value and the cumulative ETH requested value to determine if
    /// there's a surplus.
    function allocatedETHSurplus() public view returns (uint256) {
        if (allocatedETHForClaims > latestCumulativeETHRequested) {
            return allocatedETHForClaims - latestCumulativeETHRequested;
        }
        return 0;
    }

    /// @inheritdoc IUnstakeRequestsManagerRead
    /// @dev Compares the latest cumulative ETH requested value and the allocatedETHForClaims value to determine if
    /// there's a deficit.
    function allocatedETHDeficit() external view returns (uint256) {
        if (latestCumulativeETHRequested > allocatedETHForClaims) {
            return latestCumulativeETHRequested - allocatedETHForClaims;
        }
        return 0;
    }

    /// @inheritdoc IUnstakeRequestsManagerRead
    /// @dev The difference between allocatedETHForClaims and totalClaimed represents the amount of ether waiting to be
    /// claimed.
    function balance() external view returns (uint256) {
        if (allocatedETHForClaims > totalClaimed) {
            return allocatedETHForClaims - totalClaimed;
        }
        return 0;
    }

    /// @notice Updates the number of blocks required to finalize requests.
    /// @param numberOfBlocksToFinalize_ The number of blocks required to finalize requests.
    function setNumberOfBlocksToFinalize(uint256 numberOfBlocksToFinalize_) external onlyRole(MANAGER_ROLE) {
        numberOfBlocksToFinalize = numberOfBlocksToFinalize_;
        emit ProtocolConfigChanged(
            this.setNumberOfBlocksToFinalize.selector,
            "setNumberOfBlocksToFinalize(uint256)",
            abi.encode(numberOfBlocksToFinalize_)
        );
    }

    /// @notice Used by the claim function to check whether the request can be claimed (i.e. is finalized).
    /// @dev Finalization relies on the latest record of the oracle. This way, users can only claim their unstake
    /// requests in a period where the protocol has a valid record. We also use numberOfBlocksToFinalize as another
    /// safety buffer that can be set depending on the needs of the protocol.
    /// See also {claim}
    /// @return A boolean indicating whether the unstake request is finalized or not.
    function _isFinalized(UnstakeRequest memory request) internal view returns (bool) {
        return (request.blockNumber + numberOfBlocksToFinalize) <= oracle.latestRecord().updateEndBlock;
    }

    /// @dev Validates that the caller is the staking contract.
    modifier onlyStakingContract() {
        if (msg.sender != address(stakingContract)) {
            revert NotStakingContract();
        }
        _;
    }

    // Fallbacks.
    receive() external payable {
        revert DoesNotReceiveETH();
    }

    fallback() external payable {
        revert DoesNotReceiveETH();
    }
}
