// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IBinarySearch.sol";

/// @custom:security-contact lee@rand.network, adrian@rand.network
/// @title Middleware Security module for Rand Ecosystem
/// @author Lee Marreros <lee@rand.network>, Adrian Lenard <adrian@rand.network>
/// @notice Allows contracts to be proxied through this middleware to track function call counts and amounts transferred with thresholds
/// @dev Backend is calling contracts through this middleware, and if thresholds are exceeded the calls will be forwareded to a multisig for approval and resubmission
contract Middleware is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant MIDDLEWARE_ROLE = keccak256("MIDDLEWARE_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public constant MULTISIG_ROLE = keccak256("MULTISIG_ROLE");

    IBinarySearch binarySearch;
    address multisigAddress;

    struct Stat {
        // set up
        string functionName;
        string functionSignature;
        bytes4 functionId;
        address contractAddress;
        bool isTracked;
        // limiting function calls
        uint256 lastTimeCalled;
        uint256 limitCallsPerFrameTime;
        uint256 totalAmoutOfCalls;
        uint256 frameTimeCalls;
        uint256[] accumulatedCalls;
        uint256[] calledOnTimestamp;
        // limiting movement of funds
        uint256 frameTimeFunds;
        uint256 limitFundsPerFrameTime;
        uint256 totalFundsTransferred;
        uint256[] accumulatedFundsTransferred;
        uint256[] fundsdOnTimestamp;
        // function selector
    }
    // function ID => Stat
    mapping(bytes4 => Stat) stats;

    enum updateStatTypes {
        updateCalls,
        updateAmounts
    }
    // Queue for threshold exceeded functions
    struct Queue {
        address to;
        bytes data;
    }

    Queue[] functionQueue;

    // Function setting events
    event NewFunctionTracked(
        string indexed functionName,
        bytes4 indexed functionId,
        address contractAddress,
        uint256 limitCallsPerFrameTime,
        uint256 frameTimeCalls,
        uint256 frameTimeFunds,
        uint256 limitFundsPerFrameTime
    );
    event FunctionTrackingUpdated(
        string indexed functionName,
        string statType,
        uint256 newAmount
    );

    // Function Call Event
    event AmountFunctionCalls(
        string indexed functionName,
        uint256 timestamp,
        address caller,
        uint256 totalAmoutOfCalls
    );

    event AmountFundsTransferred(
        string indexed functionName,
        uint256 timestamp,
        address caller,
        uint256 amount,
        uint256 totalFundsTransferred
    );

    // Threshold events
    event ThresholdExceeded(
        string thresholdType,
        string functionName,
        uint256 amount
    );

    // Multisig queue events
    event ApprovalSubmitted(
        uint256 indexed idOfQueueElement,
        bool hasBeenApproved
    );
    event QueueAdded(uint256 maxIndex, address to, bytes payload);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Standard init function for proxy upgradability
    /// @dev Need to deploy the the Binary Search contract separately as a library, and need to define the multisig address as param
    /// @param _binarySearchAddress address of the deployed binary search library
    /// @param _multisigAddress address of the multisig owning the contract and allowed to approve calls which have exceeded limits
    function initialize(address _binarySearchAddress, address _multisigAddress)
        public
        initializer
    {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        // Tooling
        binarySearch = IBinarySearch(_binarySearchAddress);

        // External addresses
        multisigAddress = _multisigAddress;

        _grantRole(UPGRADER_ROLE, _multisigAddress);
        _grantRole(UPDATER_ROLE, _multisigAddress);
        _grantRole(PAUSER_ROLE, _multisigAddress);
        _grantRole(MULTISIG_ROLE, _multisigAddress);
        _grantRole(MIDDLEWARE_ROLE, _multisigAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, _multisigAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(UPDATER_ROLE, _msgSender());
    }

    ////////////////////////////////////////////////////////////////////
    ///////////////////  Forwarding Functions ///////////////////////////
    ////////////////////////////////////////////////////////////////////
    /// @notice Function that forwards all the calls with _payload to contracts based on _function name
    /// @dev This function must be automated to be used in the backend
    /// @param _amount main amount of the function e.g.: amount transferred, staked, claimed..etc
    /// @param _payload byte code to pass to the contract call containing the fn signature and parameters encoded
    function forwardCallToProxy(uint256 _amount, bytes calldata _payload)
        public
        onlyRole(MIDDLEWARE_ROLE)
    {
        bytes4 _functionId = getFunctionIdFromPayload(_payload);
        Stat storage _stat = stats[_functionId];

        // Require to be added to stats mapping otherwise no tracker inited
        require(_stat.isTracked, "Middleware: Function is not yet tracked");

        // If multisig calling the function, no validation is done
        if (_msgSender() != multisigAddress) {
            // If not multisig follow validation
            bool callsExceeded = validateLimitOfCallsPerFrameTime(_functionId);
            bool amountsExceeded = validateAmountTransferredPerFrameTime(
                _functionId,
                _amount
            );

            // If call count of amount is exceeded create an element for the function queue
            // so the multisig can approve this and create a new transaction
            if (callsExceeded || amountsExceeded) {
                Queue memory queue = Queue(_stat.contractAddress, _payload);
                functionQueue.push(queue);
                emit QueueAdded(
                    functionQueue.length - 1,
                    _stat.contractAddress,
                    _payload
                );
                return;
            }
        }
        // Updating stats
        updateStat(_functionId, updateStatTypes.updateAmounts, _amount);
        updateStat(_functionId, updateStatTypes.updateCalls, 0);

        // Forwarding call to contract
        (bool success, ) = address(_stat.contractAddress).call(_payload);
        require(
            success,
            "Middleware: Cannot forward call in forwardCallToProxy()"
        );
    }

    ////////////////////////////////////////////////////////////////////
    ///////////////////  Middleware Functions //////////////////////////
    ////////////////////////////////////////////////////////////////////
    /// @notice Create a new tracking for a function in the middleware
    /// @dev Required to add function otherwise not allowed to be called by `executeRemoteFunction()`, emits `NewFunctionTracked`
    /// @param _functionName simple function name without parameters e.g.: `transfer`
    /// @param _functionSignature signature of the function like `transfer(address,uint256)`
    /// @param _address contract address which hosts the function being added with `addNewTrackingForFunction`
    /// @param _limitCallsPerFrameTime amount of time frame for call number limits (rolling timeframe)
    /// @param _frameTimeCalls total number of calls can be called within the rolling time frame
    /// @param _frameTimeFunds total amount of function can be used e.g: transfer amount
    /// @param _limitFundsPerFrameTime amount of time frame for amount based limits (rolling timeframe)
    function addNewTrackingForFunction(
        string memory _functionName,
        string memory _functionSignature,
        address _address,
        uint256 _limitCallsPerFrameTime,
        uint256 _frameTimeCalls,
        uint256 _frameTimeFunds,
        uint256 _limitFundsPerFrameTime
    ) public onlyRole(UPDATER_ROLE) whenNotPaused {
        bytes4 _functionId = getStringEncoded(_functionSignature);

        Stat memory _stat = Stat({
            functionName: _functionName,
            functionSignature: _functionSignature,
            functionId: _functionId,
            contractAddress: _address,
            isTracked: true,
            lastTimeCalled: block.timestamp,
            limitCallsPerFrameTime: _limitCallsPerFrameTime,
            totalAmoutOfCalls: 0,
            frameTimeCalls: _frameTimeCalls,
            accumulatedCalls: new uint256[](0),
            calledOnTimestamp: new uint256[](0),
            frameTimeFunds: _frameTimeFunds,
            limitFundsPerFrameTime: _limitFundsPerFrameTime,
            totalFundsTransferred: 0,
            accumulatedFundsTransferred: new uint256[](0),
            fundsdOnTimestamp: new uint256[](0)
        });

        stats[_functionId] = _stat;

        emit NewFunctionTracked(
            _functionName,
            _functionId,
            _address,
            _limitCallsPerFrameTime,
            _frameTimeCalls,
            _frameTimeFunds,
            _limitFundsPerFrameTime
        );
    }

    /// @notice The treshold of each function id being tracked could be increased
    /// @param _functionId is a bytes4 representation from the function signature
    /// @param _statType one of two types for updating stats: limitCallsPerFrameTime | limitFundsPerFrameTime
    /// @param _newAmount new threshold for whichever stat type
    function updateTrackingThresholdForFunction(
        bytes4 _functionId,
        string memory _statType,
        uint256 _newAmount
    ) public onlyRole(UPDATER_ROLE) whenNotPaused {
        if (
            getStringEncoded(_statType) ==
            getStringEncoded("limitCallsPerFrameTime")
        ) {
            stats[_functionId].limitCallsPerFrameTime = _newAmount;
        }
        if (
            getStringEncoded(_statType) ==
            getStringEncoded("limitFundsPerFrameTime")
        ) {
            stats[_functionId].limitFundsPerFrameTime = _newAmount;
        }
        if (getStringEncoded(_statType) == getStringEncoded("frameTimeCalls")) {
            stats[_functionId].frameTimeCalls = _newAmount;
        }
        if (getStringEncoded(_statType) == getStringEncoded("frameTimeFunds")) {
            stats[_functionId].frameTimeFunds = _newAmount;
        }

        emit FunctionTrackingUpdated(
            stats[_functionId].functionName,
            _statType,
            _newAmount
        );
    }

    ////////////////////////////////////////////////////////////////////
    ///////////////////  Internal Functions ////////////////////////////
    ////////////////////////////////////////////////////////////////////

    /// @notice Updates the Stat of a particular function id whwnever it's called
    /// @dev Keeps up to date the amount of calls being made or the amount of funds being transferred
    /// @param _functionId is a bytes4 representation from the function signature
    /// @param _updateType one of two types for updating stats: calls or funds
    /// @param _amount is the nw given amount of funds being transferred or calls to be made as limits
    function updateStat(
        bytes4 _functionId,
        updateStatTypes _updateType,
        uint256 _amount
    ) internal {
        stats[_functionId].lastTimeCalled = block.timestamp;

        if (_updateType == updateStatTypes.updateAmounts) {
            // update stats for funds transferred
            stats[_functionId].fundsdOnTimestamp.push(block.timestamp);
            stats[_functionId].totalFundsTransferred += _amount;
            stats[_functionId].accumulatedFundsTransferred.push(
                stats[_functionId].totalFundsTransferred
            );
            emit AmountFundsTransferred(
                //_functionName,
                stats[_functionId].functionName,
                block.timestamp,
                _msgSender(),
                _amount,
                stats[_functionId].totalFundsTransferred
            );
        }
        if (_updateType == updateStatTypes.updateCalls) {
            // Update stats for function calls
            stats[_functionId].totalAmoutOfCalls++;
            stats[_functionId].calledOnTimestamp.push(block.timestamp);
            stats[_functionId].accumulatedCalls.push(
                stats[_functionId].totalAmoutOfCalls
            );
            emit AmountFunctionCalls(
                //_functionName,
                stats[_functionId].functionName,
                block.timestamp,
                _msgSender(),
                stats[_functionId].totalAmoutOfCalls
            );
        }
    }

    /// @notice Validation method regarding the amount of transferred funds within time frame
    /// @dev Validates whether a particular function id has transferred more funds than the limits
    /// @param _functionId is a bytes4 representation from the function signature
    /// @param _amount is a given amount of funds being transferred
    function validateAmountTransferredPerFrameTime(
        bytes4 _functionId,
        uint256 _amount
    ) internal returns (bool) {
        Stat memory _stat = stats[_functionId];

        // True when validating amount transferred is not needed
        if (_stat.limitFundsPerFrameTime == 0) {
            return false;
        }

        // Calculating amount transferred within time frame
        uint256 fundsTransferredWithinTimeFrame;

        if (_stat.fundsdOnTimestamp.length != 0) {
            uint256 callsBeforeFrameTimeIx = binarySearch.binarySearch(
                _stat.fundsdOnTimestamp,
                block.timestamp.sub(_stat.frameTimeCalls)
            );

            uint256 accumulatedCallsUntilTimeFrame = _stat
                .accumulatedFundsTransferred[callsBeforeFrameTimeIx];

            fundsTransferredWithinTimeFrame = _stat.totalFundsTransferred.sub(
                accumulatedCallsUntilTimeFrame
            );
        } else {
            fundsTransferredWithinTimeFrame = 0;
        }

        // validation
        if (
            fundsTransferredWithinTimeFrame.add(_amount) >
            _stat.limitFundsPerFrameTime
        ) {
            emit ThresholdExceeded(
                "amount",
                _stat.functionName,
                fundsTransferredWithinTimeFrame.add(_amount)
            );
            return true;
        }
        return false;
    }

    /// @notice Validation method regarding the amount of calls within time frame
    /// @dev Validates whether a particular function id has been called within limits or not
    /// @param _functionId is a bytes4 representation from the function signature
    function validateLimitOfCallsPerFrameTime(bytes4 _functionId)
        internal
        returns (bool)
    {
        Stat memory _stat = stats[_functionId];

        // True when validating amount of calls is not needed
        if (_stat.limitCallsPerFrameTime == 0) {
            return false;
        }

        if (_stat.totalAmoutOfCalls != 0) {
            // finding out amount of times called in the last frame time
            uint256 callsBeforeFrameTimeIx = binarySearch.binarySearch(
                _stat.calledOnTimestamp,
                block.timestamp.sub(_stat.frameTimeCalls)
            );
            uint256 accumulatedCallsUntilTimeFrame = _stat.accumulatedCalls[
                callsBeforeFrameTimeIx
            ];
            uint256 callsWithinTimeFrame = _stat.totalAmoutOfCalls.sub(
                accumulatedCallsUntilTimeFrame
            );

            // If validation calls fails
            if (callsWithinTimeFrame.add(1) > _stat.limitCallsPerFrameTime) {
                emit ThresholdExceeded(
                    "call",
                    _stat.functionName,
                    callsWithinTimeFrame.add(1)
                );
                return true;
            }
        }
        return false;
    }

    ////////////////////////////////////////////////////////////////////
    ///////////////////  Internal Util Functions ///////////////////////
    ////////////////////////////////////////////////////////////////////

    /// @notice Obtains a bytes4 type from _payload
    /// @dev _payload is built before calling this function
    /// @param _payload is the bytes formed by encoding function signtaure plus params
    function getFunctionIdFromPayload(bytes calldata _payload)
        public
        pure
        returns (bytes4)
    {
        bytes4 sig = _payload[0] |
            (bytes4(_payload[1]) >> 8) |
            (bytes4(_payload[2]) >> 16) |
            (bytes4(_payload[3]) >> 24);

        return sig;
    }

    /// @notice Obtains a bytes4 type from params
    /// @dev It's used as a look-up key for stats mapping and string comparisons
    /// @param _func is the function signature used to build the functionId or any string converted to bytes for comparing purposes
    function getStringEncoded(string memory _func)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(bytes(_func)));
    }

    ////////////////////////////////////////////////////////////////////
    ///////////////////  External Functions ////////////////////////////
    //////////////////////  Multisig only //////////////////////////////
    ////////////////////////////////////////////////////////////////////

    function approveQueueElement(
        uint256 _idOfQueueElement,
        bool _hasBeenApproved
    ) public whenNotPaused onlyRole(MULTISIG_ROLE) {
        if (_hasBeenApproved) {
            // fetch function from queue
            Queue memory queue = functionQueue[_idOfQueueElement];
            delete functionQueue[_idOfQueueElement];
            (bool _ret, ) = queue.to.call(queue.data);
            require(_ret, "Middleware: Approved function call returned false");
            // at the end of logic delete queue element
        } else {
            //_hasBeenApproved == false
            // dont execute just delete from queue
            delete functionQueue[_idOfQueueElement];
        }
        emit ApprovalSubmitted(_idOfQueueElement, _hasBeenApproved);
    }

    function getQueueData(uint256 _id)
        public
        view
        whenNotPaused
        onlyRole(MULTISIG_ROLE)
        returns (address, bytes memory)
    {
        return (functionQueue[_id].to, functionQueue[_id].data);
    }

    ////////////////////////////////////////////////////////////////////
    ///////////////////////////  Imports  //////////////////////////////
    ////////////////////////////////////////////////////////////////////

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}
