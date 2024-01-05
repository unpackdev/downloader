// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./SLA.sol";
import "./SLORegistry.sol";
import "./PeriodRegistry.sol";
import "./MessengerRegistry.sol";
import "./StakeRegistry.sol";
import "./IMessenger.sol";

/**
 * @title SLARegistry
 * @dev SLARegistry is a contract for handling creation of service level
 * agreements and keeping track of the created agreements
 */
contract SLARegistry {
    using SafeMath for uint256;

    /// @dev SLO registry
    SLORegistry public sloRegistry;
    /// @dev Periods registry
    PeriodRegistry public periodRegistry;
    /// @dev Messengers registry
    MessengerRegistry public messengerRegistry;
    /// @dev Stake registry
    StakeRegistry public stakeRegistry;
    /// @dev stores the addresses of created SLAs
    SLA[] public SLAs;
    /// @dev stores the indexes of service level agreements owned by an user
    mapping(address => uint256[]) private userToSLAIndexes;
    /// @dev to check if registered SLA
    mapping(address => bool) private registeredSLAs;
    // value to lock past periods on SLA deployment
    bool public immutable checkPastPeriod;

    /**
     * @dev event for service level agreement creation logging
     * @param sla 1. The address of the created service level agreement contract
     * @param owner 2. The address of the owner of the service level agreement
     */
    event SLACreated(SLA indexed sla, address indexed owner);

    /**
     * @dev event for service level agreement creation logging
     * @param periodId 1. -
     * @param sla 2. -
     * @param caller 3. -
     */
    event SLIRequested(
        uint256 periodId,
        address indexed sla,
        address indexed caller
    );

    /**
     * @dev event for service level agreement creation logging
     * @param sla 1. -
     * @param caller 2. -
     */
    event ReturnLockedValue(address indexed sla, address indexed caller);

    /**
     * @dev constructor
     * @param _sloRegistry 1. SLO Registry
     * @param _periodRegistry 2. Periods registry
     * @param _messengerRegistry 3. Messenger registry
     * @param _stakeRegistry 4. Stake registry
     * @param _checkPastPeriod 5. -
     */
    constructor(
        SLORegistry _sloRegistry,
        PeriodRegistry _periodRegistry,
        MessengerRegistry _messengerRegistry,
        StakeRegistry _stakeRegistry,
        bool _checkPastPeriod
    ) public {
        sloRegistry = _sloRegistry;
        sloRegistry.setSLARegistry();
        periodRegistry = _periodRegistry;
        stakeRegistry = _stakeRegistry;
        stakeRegistry.setSLARegistry();
        messengerRegistry = _messengerRegistry;
        messengerRegistry.setSLARegistry();
        checkPastPeriod = _checkPastPeriod;
    }

    /**
     * @dev public function for creating canonical service level agreements
     * @param _sloValue 1. -
     * @param _sloType 2. -
     * @param _ipfsHash 3. -
     * @param _periodType 4. -
     * @param _initialPeriodId 5. -
     * @param _finalPeriodId 6. -
     * @param _messengerAddress 7. -
     * @param _whitelisted 8. -
     * @param _extraData 9. -
     * @param _leverage 10. -
     */
    function createSLA(
        uint256 _sloValue,
        SLORegistry.SLOType _sloType,
        bool _whitelisted,
        address _messengerAddress,
        PeriodRegistry.PeriodType _periodType,
        uint128 _initialPeriodId,
        uint128 _finalPeriodId,
        string memory _ipfsHash,
        bytes32[] memory _extraData,
        uint64 _leverage
    ) public {
        bool validPeriod =
            periodRegistry.isValidPeriod(_periodType, _initialPeriodId);
        require(validPeriod, "First period id not valid");
        validPeriod = periodRegistry.isValidPeriod(_periodType, _finalPeriodId);
        require(validPeriod, "Final period id not valid");
        bool initializedPeriod =
            periodRegistry.isInitializedPeriod(_periodType);
        require(initializedPeriod, "Period type not initialized yet");
        require(
            _finalPeriodId >= _initialPeriodId,
            "invalid finalPeriodId and initialPeriodId"
        );

        if (checkPastPeriod) {
            bool periodHasStarted =
                periodRegistry.periodHasStarted(_periodType, _initialPeriodId);
            require(!periodHasStarted, "Period has started");
        }
        bool registeredMessenger =
            messengerRegistry.registeredMessengers(_messengerAddress);
        require(registeredMessenger == true, "messenger not registered");

        SLA sla =
            new SLA(
                msg.sender,
                _whitelisted,
                _periodType,
                _messengerAddress,
                _initialPeriodId,
                _finalPeriodId,
                uint128(SLAs.length),
                _ipfsHash,
                _extraData,
                _leverage
            );

        sloRegistry.registerSLO(_sloValue, _sloType, address(sla));
        stakeRegistry.lockDSLAValue(
            msg.sender,
            address(sla),
            _finalPeriodId - _initialPeriodId + 1
        );
        SLAs.push(sla);
        registeredSLAs[address(sla)] = true;
        uint256 index = SLAs.length.sub(1);
        userToSLAIndexes[msg.sender].push(index);
        emit SLACreated(sla, msg.sender);
    }

    /**
     * @dev Gets SLI information for the specified SLA and SLO
     * @param _periodId 1. id of the period
     * @param _sla 2. SLA Address
     * @param _ownerApproval 3. if approval by owner or msg.sender
     */
    function requestSLI(
        uint256 _periodId,
        SLA _sla,
        bool _ownerApproval
    ) public {
        require(isRegisteredSLA(address(_sla)), "invalid SLA");
        require(_periodId == _sla.nextVerifiablePeriod(), "invalid periodId");
        (, , SLA.Status status) = _sla.periodSLIs(_periodId);
        require(status == SLA.Status.NotVerified, "invalid SLA status");
        bool breachedContract = _sla.breachedContract();
        require(!breachedContract, "breached contract");
        bool slaAllowedPeriodId = _sla.isAllowedPeriod(_periodId);
        require(slaAllowedPeriodId, "invalid period Id");
        PeriodRegistry.PeriodType slaPeriodType = _sla.periodType();
        bool periodFinished =
            periodRegistry.periodIsFinished(slaPeriodType, _periodId);
        require(periodFinished, "period not finished");
        address slaMessenger = _sla.messengerAddress();
        SLIRequested(_periodId, address(_sla), msg.sender);
        IMessenger(slaMessenger).requestSLI(
            _periodId,
            address(_sla),
            _ownerApproval,
            msg.sender
        );
        stakeRegistry.distributeVerificationRewards(
            address(_sla),
            msg.sender,
            _periodId
        );
    }

    function returnLockedValue(SLA _sla) public {
        require(isRegisteredSLA(address(_sla)), "invalid SLA");
        require(msg.sender == _sla.owner(), "msg.sender not owner");
        uint256 lastValidPeriodId = _sla.finalPeriodId();
        PeriodRegistry.PeriodType periodType = _sla.periodType();
        (, uint256 endOfLastValidPeriod) =
            periodRegistry.getPeriodStartAndEnd(periodType, lastValidPeriodId);

        (, , SLA.Status lastPeriodStatus) = _sla.periodSLIs(lastValidPeriodId);
        require(
            _sla.breachedContract() ||
                (block.timestamp >= endOfLastValidPeriod &&
                    lastPeriodStatus != SLA.Status.NotVerified),
            "Should only withdraw for finished contracts"
        );
        ReturnLockedValue(address(_sla), msg.sender);
        stakeRegistry.returnLockedValue(address(_sla));
    }

    /**
     * @dev function to declare this SLARegistry contract as SLARegistry of _messengerAddress
     * @param _messengerAddress 1. address of the messenger
     */

    function registerMessenger(
        address _messengerAddress,
        string memory _specificationUrl
    ) public {
        IMessenger(_messengerAddress).setSLARegistry();
        messengerRegistry.registerMessenger(
            msg.sender,
            _messengerAddress,
            _specificationUrl
        );
    }

    /**
     * @dev public view function that returns the service level agreements that
     * the given user is the owner of
     * @param _user Address of the user for which to return the service level
     * agreements
     * @return array of SLAs
     */
    function userSLAs(address _user) public view returns (SLA[] memory) {
        uint256 count = userToSLAIndexes[_user].length;
        SLA[] memory SLAList = new SLA[](count);
        uint256[] memory userSLAIndexes = userToSLAIndexes[_user];

        for (uint256 i = 0; i < count; i++) {
            SLAList[i] = (SLAs[userSLAIndexes[i]]);
        }

        return (SLAList);
    }

    /**
     * @dev public view function that returns all the service level agreements
     * @return SLA[] array of SLAs
     */
    function allSLAs() public view returns (SLA[] memory) {
        return (SLAs);
    }

    /**
     * @dev public view function that returns true if _slaAddress was deployed using this SLARegistry
     * @param _slaAddress address of the SLA to be checked
     */
    function isRegisteredSLA(address _slaAddress) public view returns (bool) {
        return registeredSLAs[_slaAddress];
    }
}
