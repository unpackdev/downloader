pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./ChainlinkClient.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./StringUtils.sol";
import "./PeriodRegistry.sol";
import "./StakeRegistry.sol";

/**
 * @title NetworkAnalytics
 * @dev contract to get the network analytics for the staking efficiency use case
 */

contract NetworkAnalytics is Ownable, ChainlinkClient, ReentrancyGuard {
    using SafeERC20 for ERC20;

    struct AnalyticsRequest {
        bytes32 networkName;
        uint256 periodId;
        PeriodRegistry.PeriodType periodType;
    }

    /// @dev Period registry
    PeriodRegistry private periodRegistry;
    /// @dev StakeRegistry
    StakeRegistry private stakeRegistry;

    /// @dev bytes32 to store the available network names
    bytes32[] public networkNames;
    /// @dev (networkName=>periodType=>periodId=>bytes32) to store ipfsHash of the analytics corresponding to periodId
    mapping(bytes32 => mapping(PeriodRegistry.PeriodType => mapping(uint256 => bytes32)))
        public periodAnalytics;
    /// @dev (networkName=>periodType=>periodId=>bool) to state if a network-periodType-periodId was already requested
    mapping(bytes32 => mapping(PeriodRegistry.PeriodType => mapping(uint256 => bool)))
        public periodAnalyticsRequested;

    /// @dev Mapping that stores chainlink analytics request information
    mapping(bytes32 => AnalyticsRequest) public requestIdToAnalyticsRequest;
    /// @dev Array with all request IDs
    bytes32[] public requests;
    /// @dev Chainlink oracle address
    address private oracle;
    /// @dev chainlink jobId
    bytes32 private jobId;
    /// @dev fee for Chainlink querys. Currently 0.1 LINK
    uint256 private baseFee = 0.1 ether;
    /// @dev fee for Chainlink querys. Currently 0.1 LINK
    uint256 public fee;

    /**
     * @dev event emitted when modifying the callerReward
     * @param owner 1. -
     * @param newValue 2. -
     */
    event CallerRewardModified(address indexed owner, uint256 newValue);

    /**
     * @dev event emitted when modifying the jobId
     * @param owner 1. -
     * @param jobId 2. -
     * @param fee 3. -
     */
    event JobIdModified(address indexed owner, bytes32 jobId, uint256 fee);

    /**
     * @dev event emitted when having a response from Chainlink with the SLI
     * @param networkName 1. network name
     * @param periodType 2. id of the period
     * @param periodId 3. id of the period
     * @param ipfsHash 4. hash of the ipfs object
     */
    event AnalyticsReceived(
        bytes32 networkName,
        PeriodRegistry.PeriodType periodType,
        uint256 periodId,
        bytes32 ipfsHash
    );

    /**
     * @dev parameterize the variables according to network
     * @notice sets the Chainlink parameters (oracle address, token address, jobId) and sets the SLARegistry to 0x0 address
     * @param _chainlinkOracle 1. the address of the oracle to create requests to
     * @param _chainlinkToken 2. the address of LINK token contract
     * @param _jobId 3. the job id for the HTTPGet job
     * @param _periodRegistry 4. period registry
     * @param _stakeRegistry 5. stake registry
     * @param _feeMultiplier 6. states the amount of paid nodes running behind the precoordinator, to set the fee
     */
    constructor(
        address _chainlinkOracle,
        address _chainlinkToken,
        bytes32 _jobId,
        PeriodRegistry _periodRegistry,
        StakeRegistry _stakeRegistry,
        uint256 _feeMultiplier
    ) public {
        jobId = _jobId;
        setChainlinkToken(_chainlinkToken);
        oracle = _chainlinkOracle;
        periodRegistry = _periodRegistry;
        stakeRegistry = _stakeRegistry;
        fee = _feeMultiplier.mul(baseFee);
    }

    function isValidNetwork(bytes32 _networkName) public view returns (bool) {
        for (uint256 index; index < networkNames.length; index++) {
            if (networkNames[index] == _networkName) return true;
        }
        return false;
    }

    /**
     * @dev function to add a valid network name
     * @param _networkName 1. bytes32 network name
     */
    function addNetwork(bytes32 _networkName)
        external
        onlyOwner
        returns (bool)
    {
        require(
            isValidNetwork(_networkName) == false,
            "Network name already registered"
        );
        networkNames.push(_networkName);
        return false;
    }

    /**
     * @dev function to add multiple valid network names
     * @param _networkNames 1. bytes32[] network names
     */
    function addMultipleNetworks(bytes32[] calldata _networkNames)
        external
        onlyOwner
        returns (bool)
    {
        for (uint256 index = 0; index < _networkNames.length; index++) {
            if (!isValidNetwork(_networkNames[index])) {
                networkNames.push(_networkNames[index]);
            }
        }
        return false;
    }

    /**
     * @dev Request analytics object for the current period.
     * @param _periodId 1. id of the canonical period to be analyzed
     * @param _periodType 2. type of period to be queried
     * @param _networkName 3. network name to publish analytics
     * @param _ownerApproval 4. used to choose if the call is going to be funded by the contract owner, to avoid a block by contract owner
     */
    function requestAnalytics(
        uint256 _periodId,
        PeriodRegistry.PeriodType _periodType,
        bytes32 _networkName,
        bool _ownerApproval
    ) public nonReentrant {
        require(isValidNetwork(_networkName), "Invalid network name");
        bool periodIsFinished =
            periodRegistry.periodIsFinished(_periodType, _periodId);
        require(periodIsFinished == true, "Period has not finished yet");
        require(
            periodAnalyticsRequested[_networkName][_periodType][_periodId] ==
                false,
            "Analytics already requested"
        );
        if (_ownerApproval) {
            ERC20(chainlinkTokenAddress()).safeTransferFrom(
                owner(),
                address(this),
                fee
            );
        } else {
            ERC20(chainlinkTokenAddress()).safeTransferFrom(
                msg.sender,
                address(this),
                fee
            );
        }

        Chainlink.Request memory request =
            buildChainlinkRequest(
                jobId,
                address(this),
                this.fulFillAnalytics.selector
            );

        (uint256 start, uint256 end) =
            periodRegistry.getPeriodStartAndEnd(_periodType, _periodId);

        request.add("job_type", "staking_efficiency_analytics");
        request.add("network_name", StringUtils.bytes32ToStr(_networkName));
        request.add("period_id", StringUtils.uintToStr(_periodId));
        request.add(
            "period_type",
            StringUtils.uintToStr(uint256(uint8(_periodType)))
        );
        request.add("sla_monitoring_start", StringUtils.uintToStr(start));
        request.add("sla_monitoring_end", StringUtils.uintToStr(end));

        bytes32 requestId = sendChainlinkRequestTo(oracle, request, fee);
        requests.push(requestId);
        requestIdToAnalyticsRequest[requestId] = AnalyticsRequest({
            networkName: _networkName,
            periodId: _periodId,
            periodType: _periodType
        });
        periodAnalyticsRequested[_networkName][_periodType][_periodId] = true;
    }

    /**
     * @dev callback function for the Chainlink SLI request which stores
     * the SLI in the SLA contract
     * @param _requestId the ID of the ChainLink request
     * @param _chainlinkResponse response object from Chainlink Oracles
     */
    function fulFillAnalytics(bytes32 _requestId, bytes32 _chainlinkResponse)
        external
        recordChainlinkFulfillment(_requestId)
        nonReentrant
    {
        AnalyticsRequest memory request =
            requestIdToAnalyticsRequest[_requestId];

        emit AnalyticsReceived(
            request.networkName,
            request.periodType,
            request.periodId,
            _chainlinkResponse
        );

        periodAnalytics[request.networkName][request.periodType][
            request.periodId
        ] = _chainlinkResponse;
    }

    /**
     * @dev sets a new jobId, which is a agreement Id of a PreCoordinator contract
     * @param _jobId the id of the PreCoordinator agreement
     * @param _feeMultiplier how many Chainlink nodes would be paid on the agreement id, to set the fee value
     */
    function setChainlinkJobID(bytes32 _jobId, uint256 _feeMultiplier)
        external
        onlyOwner
    {
        jobId = _jobId;
        fee = _feeMultiplier.mul(baseFee);
        emit JobIdModified(msg.sender, _jobId, fee);
    }

    function getNetworkNames()
        external
        view
        returns (bytes32[] memory networks)
    {
        networks = networkNames;
    }
}
