// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IEpochsManager.sol";
import "./IFeesManager.sol";
import "./MerkleProof.sol";
import "./ECDSA.sol";
import "./GovernanceMessageHandler.sol";
import "./IPToken.sol";
import "./IPFactory.sol";
import "./IPNetworkHub.sol";
import "./IPReceiver.sol";
import "./Utils.sol";
import "./Network.sol";

error InvalidOperationStatus(IPNetworkHub.OperationStatus status, IPNetworkHub.OperationStatus expectedStatus);
error ActorAlreadyChallenged();
error ActorAlreadyCancelledOperation(
    IPNetworkHub.Operation operation,
    address actor,
    IPNetworkHub.ActorTypes actorType
);
error ChallengePeriodNotTerminated(uint64 startTimestamp, uint64 endTimestamp);
error InvalidAssetParameters(uint256 assetAmount, address assetTokenAddress);
error InvalidUserOperation();
error PTokenNotCreated(address pTokenAddress);
error InvalidNetwork(bytes4 networkId, bytes4 expectedNetworkId);
error NotContract(address addr);
error LockDown();
error InvalidGovernanceMessage(bytes message);
error InvalidLockedAmountChallengePeriod(
    uint256 lockedAmountChallengePeriod,
    uint256 expectedLockedAmountChallengePeriod
);
error QueueFull();
error InvalidNetworkFeeAssetAmount();
error InvalidActor(address actor, IPNetworkHub.ActorTypes actorType);
error InvalidLockedAmountStartChallenge(uint256 lockedAmountStartChallenge, uint256 expectedLockedAmountStartChallenge);
error InvalidChallengeStatus(IPNetworkHub.ChallengeStatus status, IPNetworkHub.ChallengeStatus expectedStatus);
error NearToEpochEnd();
error ChallengeDurationPassed();
error MaxChallengeDurationNotPassed();
error ChallengeNotFound(IPNetworkHub.Challenge challenge);
error ChallengeDurationMustBeLessOrEqualThanMaxChallengePeriodDuration(
    uint64 challengeDuration,
    uint64 maxChallengePeriodDuration
);
error InvalidEpoch(uint16 epoch, uint16 maxEpoch);
error Inactive();
error NotDandelionVoting(address dandelionVoting, address expectedDandelionVoting);

contract PNetworkHub is IPNetworkHub, GovernanceMessageHandler, ReentrancyGuardUpgradeable {
    uint8 constant STATUS_INACTIVE = 0x1;
    uint8 constant STATUS_CHALLENGED = 0x2;

    bytes32 public constant GOVERNANCE_MESSAGE_ACTORS = keccak256("GOVERNANCE_MESSAGE_ACTORS");
    bytes32 public constant GOVERNANCE_MESSAGE_SLASH_ACTOR = keccak256("GOVERNANCE_MESSAGE_SLASH_ACTOR");
    bytes32 public constant GOVERNANCE_MESSAGE_RESUME_ACTOR = keccak256("GOVERNANCE_MESSAGE_RESUME_ACTOR");
    bytes32 public constant GOVERNANCE_MESSAGE_PROTOCOL_GOVERNANCE_CANCEL_OPERATION =
        keccak256("GOVERNANCE_MESSAGE_PROTOCOL_GOVERNANCE_CANCEL_OPERATION");
    address public constant GOVERNANCE_MESSAGE_RELAYER_ADDRESS = 0x0Ef13B2668dbE1b3eDfe9fFb7CbC398363b50f79;
    uint256 public constant FEE_BASIS_POINTS_DIVISOR = 10000;

    address public constant UNDERLYING_ASSET_TOKEN_ADDRESS_USER_DATA_PROTOCOL_FEE =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    bytes4 public constant UNDERLYING_ASSET_NETWORK_ID_USER_DATA_PROTOCOL_FEE = 0x60ef5904;
    uint256 public constant UNDERLYING_ASSET_DECIMALS_USER_DATA_PROTOCOL_FEE = 18;
    string public constant UNDERLYING_ASSET_NAME_USER_DATA_PROTOCOL_FEE = "Dai Stablecoin";
    string public constant UNDERLYING_ASSET_SYMBOL_USER_DATA_PROTOCOL_FEE = "DAI";

    address public factory;
    address public epochsManager;
    address public feesManager;
    address public slasher;
    address public dandelionVoting;
    uint32 public baseChallengePeriodDuration;
    uint32 public maxChallengePeriodDuration;
    uint16 public kChallengePeriod;
    uint16 public maxOperationsInQueue;
    bytes4 public interimChainNetworkId;
    uint256 public lockedAmountChallengePeriod;
    uint256 public lockedAmountStartChallenge;
    uint64 public challengeDuration;

    mapping(bytes32 => Action) private _operationsRelayerQueueAction;
    mapping(bytes32 => Action) private _operationsGovernanceCancelAction;
    mapping(bytes32 => Action) private _operationsGuardianCancelAction;
    mapping(bytes32 => Action) private _operationsSentinelCancelAction;
    mapping(bytes32 => uint8) private _operationsTotalCancelActions;
    mapping(bytes32 => OperationStatus) private _operationsStatus;
    mapping(uint16 => bytes32) private _epochsActorsMerkleRoot;
    mapping(uint16 => mapping(ActorTypes => uint16)) private _epochsTotalNumberOfActors;
    mapping(uint16 => mapping(bytes32 => Challenge)) private _epochsChallenges;
    mapping(uint16 => mapping(bytes32 => ChallengeStatus)) private _epochsChallengesStatus;
    mapping(uint16 => mapping(address => ActorStatus)) private _epochsActorsStatus;
    mapping(uint16 => mapping(ActorTypes => uint16)) private _epochsTotalNumberOfInactiveActors;
    mapping(uint16 => mapping(address => bytes32)) private _epochsActorsPendingChallengeId;
    uint256 public challengesNonce;
    uint16 public numberOfOperationsInQueue;
    mapping(uint16 => mapping(address => uint8)) private _epochsActorsStatusNew;

    function initialize(
        address factory_,
        uint32 baseChallengePeriodDuration_,
        address epochsManager_,
        address feesManager_,
        address telepathyRouter,
        address governanceMessageVerifier,
        address slasher_,
        address dandelionVoting_,
        uint256 lockedAmountChallengePeriod_,
        uint16 kChallengePeriod_,
        uint16 maxOperationsInQueue_,
        bytes4 interimChainNetworkId_,
        uint256 lockedAmountOpenChallenge_,
        uint64 challengeDuration_,
        uint32 expectedSourceChainId
    ) public initializer {
        _initialize(telepathyRouter, governanceMessageVerifier, expectedSourceChainId);
        __ReentrancyGuard_init();
        maxChallengePeriodDuration =
            baseChallengePeriodDuration_ +
            ((maxOperationsInQueue_ ** 2) * kChallengePeriod_) -
            kChallengePeriod_;

        // Queue operations are not allowed in lockdown mode, meaning when
        //
        // block.timestamp >= currentEpochEndTimestamp - 1 hours - maxChallengePeriodDuration
        //
        // We want the challenge mechanism enabled also when the system is in lockdown mode,
        // but challenges shouldn't be started and eventually solved when it's less than one hour to
        // the epoch's ending, to permit slashing messages to be propagated to the other chains.
        //
        // This means that the following condition should hold:
        //
        // currentEpochEndTimestamp - 1 hours - maxChallengePeriodDuration < currentEpochEndTimestamp - 1 hours - challengeDuration
        //
        // This implies:
        //
        // challengeDuration <=  maxChallengePeriodDuration (see reverting condition in the constructor)
        //
        if (challengeDuration_ > maxChallengePeriodDuration) {
            revert ChallengeDurationMustBeLessOrEqualThanMaxChallengePeriodDuration(
                challengeDuration_,
                maxChallengePeriodDuration
            );
        }

        factory = factory_;
        epochsManager = epochsManager_;
        feesManager = feesManager_;
        slasher = slasher_;
        dandelionVoting = dandelionVoting_;
        baseChallengePeriodDuration = baseChallengePeriodDuration_;
        lockedAmountChallengePeriod = lockedAmountChallengePeriod_;
        kChallengePeriod = kChallengePeriod_;
        maxOperationsInQueue = maxOperationsInQueue_;
        interimChainNetworkId = interimChainNetworkId_;
        lockedAmountStartChallenge = lockedAmountOpenChallenge_;
        challengeDuration = challengeDuration_;
    }

    /// @inheritdoc IPNetworkHub
    function challengeIdOf(Challenge memory challenge) public pure returns (bytes32) {
        return sha256(abi.encode(challenge));
    }

    /// @inheritdoc IPNetworkHub
    function challengePeriodOf(Operation calldata operation) public view returns (uint64, uint64) {
        bytes32 operationId = operationIdOf(operation);
        OperationStatus operationStatus = _operationsStatus[operationId];
        return _challengePeriodOf(operationId, operationStatus);
    }

    /// @inheritdoc IPNetworkHub
    function claimLockedAmountStartChallenge(Challenge calldata challenge) external {
        bytes32 challengeId = challengeIdOf(challenge);
        uint16 currentEpoch = IEpochsManager(epochsManager).currentEpoch();
        uint16 challengeEpoch = getChallengeEpoch(challenge);

        if (challengeEpoch >= currentEpoch) {
            revert InvalidEpoch(challengeEpoch, currentEpoch);
        }

        ChallengeStatus challengeStatus = _epochsChallengesStatus[challengeEpoch][challengeId];
        if (challengeStatus == ChallengeStatus.Null) {
            revert ChallengeNotFound(challenge);
        }

        if (challengeStatus != ChallengeStatus.Pending) {
            revert InvalidChallengeStatus(challengeStatus, ChallengeStatus.Pending);
        }

        _epochsChallengesStatus[challengeEpoch][challengeId] = ChallengeStatus.PartiallyUnsolved;
        Utils.sendEther(challenge.challenger, lockedAmountStartChallenge);

        emit ChallengePartiallyUnsolved(challenge);
    }

    /// @inheritdoc IPNetworkHub
    function getChallengeEpoch(Challenge calldata challenge) public view returns (uint16) {
        uint256 epochDuration = IEpochsManager(epochsManager).epochDuration();
        uint256 startFirstEpochTimestamp = IEpochsManager(epochsManager).startFirstEpochTimestamp();
        return uint16((challenge.timestamp - startFirstEpochTimestamp) / epochDuration);
    }

    /// @inheritdoc IPNetworkHub
    function getChallengeStatus(Challenge calldata challenge) external view returns (ChallengeStatus) {
        return _epochsChallengesStatus[getChallengeEpoch(challenge)][challengeIdOf(challenge)];
    }

    /// @inheritdoc IPNetworkHub
    function getCurrentChallengePeriodDuration() public view returns (uint64) {
        return /*getCurrentActiveActorsAdjustmentDuration() +*/ getCurrentQueuedOperationsAdjustmentDuration();
    }

    /// @inheritdoc IPNetworkHub
    function getCurrentQueuedOperationsAdjustmentDuration() public view returns (uint64) {
        uint32 localNumberOfOperationsInQueue = numberOfOperationsInQueue;
        if (localNumberOfOperationsInQueue == 0) return baseChallengePeriodDuration;

        return
            baseChallengePeriodDuration + ((localNumberOfOperationsInQueue ** 2) * kChallengePeriod) - kChallengePeriod;
    }

    /// @inheritdoc IPNetworkHub
    function getPendingChallengeIdByEpochOf(uint16 epoch, address actor) external view returns (bytes32) {
        return _epochsActorsPendingChallengeId[epoch][actor];
    }

    /// @inheritdoc IPNetworkHub
    function getTotalNumberOfActorsByEpochAndType(uint16 epoch, ActorTypes actorType) external view returns (uint16) {
        return _epochsTotalNumberOfActors[epoch][actorType];
    }

    /// @inheritdoc IPNetworkHub
    function getTotalNumberOfInactiveActorsByEpochAndType(
        uint16 epoch,
        ActorTypes actorType
    ) external view returns (uint16) {
        return _epochsTotalNumberOfInactiveActors[epoch][actorType];
    }

    /// @inheritdoc IPNetworkHub
    function isLockedDown() public view returns (bool) {
        if (!_isActorsStatusValid()) return true;

        uint16 currentEpoch = IEpochsManager(epochsManager).currentEpoch();
        uint256 epochDuration = IEpochsManager(epochsManager).epochDuration();
        uint256 startFirstEpochTimestamp = IEpochsManager(epochsManager).startFirstEpochTimestamp();
        uint256 currentEpochEndTimestamp = startFirstEpochTimestamp + ((currentEpoch + 1) * epochDuration);

        // This is to allow executions up to 1 hour earlier than the epoch's ending
        return block.timestamp + maxChallengePeriodDuration >= currentEpochEndTimestamp - 1 hours;
    }

    /// @inheritdoc IPNetworkHub
    function operationIdOf(Operation memory operation) public pure returns (bytes32) {
        return sha256(abi.encode(operation));
    }

    /// @inheritdoc IPNetworkHub
    function operationStatusOf(Operation calldata operation) external view returns (OperationStatus) {
        return _operationsStatus[operationIdOf(operation)];
    }

    /// @inheritdoc IPNetworkHub
    function protocolCancelOperation(
        Operation calldata operation,
        ActorTypes actorType,
        bytes32[] calldata proof,
        bytes calldata signature
    ) external {
        if (!_isActorsStatusValid()) revert LockDown();

        bytes32 operationId = operationIdOf(operation);
        address actor = ECDSA.recover(ECDSA.toEthSignedMessageHash(operationId), signature);
        if (!_isActor(actor, actorType, proof)) {
            revert InvalidActor(actor, actorType);
        }

        uint16 currentEpoch = IEpochsManager(epochsManager).currentEpoch();
        if ((_epochsActorsStatusNew[currentEpoch][actor] & STATUS_INACTIVE) != 0) {
            revert Inactive();
        }

        _protocolCancelOperation(operation, operationId, actor, actorType);
    }

    /// @inheritdoc IPNetworkHub
    function protocolExecuteOperation(Operation calldata operation) external payable nonReentrant {
        if (isLockedDown()) revert LockDown();
        bytes32 operationId = operationIdOf(operation);
        OperationStatus operationStatus = _operationsStatus[operationId];
        if (operationStatus != OperationStatus.Queued) {
            revert InvalidOperationStatus(operationStatus, OperationStatus.Queued);
        }

        (uint64 startTimestamp, uint64 endTimestamp) = _challengePeriodOf(operationId, operationStatus);
        if (uint64(block.timestamp) < endTimestamp) {
            revert ChallengePeriodNotTerminated(startTimestamp, endTimestamp);
        }

        address pTokenAddress = IPFactory(factory).getPTokenAddress(
            operation.underlyingAssetName,
            operation.underlyingAssetSymbol,
            operation.underlyingAssetDecimals,
            operation.underlyingAssetTokenAddress,
            operation.underlyingAssetNetworkId
        );

        uint256 effectiveOperationAssetAmount = operation.assetAmount;

        // NOTE: if we are on the interim chain we must take the fee
        bytes4 currentNetworkId = Network.getCurrentNetworkId();
        if (interimChainNetworkId == currentNetworkId) {
            effectiveOperationAssetAmount = _takeProtocolFee(operation, pTokenAddress);

            // NOTE: if we are on interim chain but the effective destination chain (forwardDestinationNetworkId) is another one
            // we have to emit an user Operation without protocol fee and with effectiveOperationAssetAmount and forwardDestinationNetworkId as
            // destinationNetworkId in order to proxy the Operation on the destination chain.
            if (
                interimChainNetworkId != operation.forwardDestinationNetworkId &&
                operation.forwardDestinationNetworkId != bytes4(0)
            ) {
                effectiveOperationAssetAmount = _takeNetworkFee(
                    effectiveOperationAssetAmount,
                    operation.networkFeeAssetAmount,
                    operationId,
                    pTokenAddress
                );

                _releaseOperationLockedAmountChallengePeriod(operationId);
                emit UserOperation(
                    gasleft(),
                    operation.originAccount,
                    operation.destinationAccount,
                    operation.forwardDestinationNetworkId,
                    operation.underlyingAssetName,
                    operation.underlyingAssetSymbol,
                    operation.underlyingAssetDecimals,
                    operation.underlyingAssetTokenAddress,
                    operation.underlyingAssetNetworkId,
                    pTokenAddress,
                    effectiveOperationAssetAmount,
                    0,
                    operation.forwardNetworkFeeAssetAmount,
                    0,
                    bytes4(0),
                    currentNetworkId,
                    operation.userData,
                    operation.optionsMask,
                    operation.isForProtocol
                );

                emit OperationExecuted(operation);
                return;
            }
        }

        effectiveOperationAssetAmount = _takeNetworkFee(
            effectiveOperationAssetAmount,
            operation.networkFeeAssetAmount,
            operationId,
            pTokenAddress
        );

        // NOTE: Execute the operation on the target blockchain. If destinationNetworkId is equivalent to
        // interimChainNetworkId, then the effectiveOperationAssetAmount would be the result of operation.assetAmount minus
        // the associated fee. However, if destinationNetworkId is not the same as interimChainNetworkId, the effectiveOperationAssetAmount
        // is equivalent to operation.assetAmount. In this case, as the operation originates from the interim chain, the operation.assetAmount
        // doesn't include the fee. This is because when the UserOperation event is triggered, and the interimChainNetworkId
        // does not equal operation.destinationNetworkId, the event contains the effectiveOperationAssetAmount.
        address destinationAddress = Utils.hexStringToAddress(operation.destinationAccount);
        if (effectiveOperationAssetAmount > 0) {
            IPToken(pTokenAddress).protocolMint(destinationAddress, effectiveOperationAssetAmount);

            if (Utils.isBitSet(operation.optionsMask, 0)) {
                if (!Network.isCurrentNetwork(operation.underlyingAssetNetworkId)) {
                    revert InvalidNetwork(operation.underlyingAssetNetworkId, Network.getCurrentNetworkId());
                }
                IPToken(pTokenAddress).protocolBurn(destinationAddress, effectiveOperationAssetAmount);
            }
        }

        if (operation.userData.length > 0) {
            if (destinationAddress.code.length == 0) revert NotContract(destinationAddress);

            try
                IPReceiver(destinationAddress).receiveUserData(
                    operation.originNetworkId,
                    operation.originAccount,
                    operation.userData
                )
            {} catch {}
        }

        _releaseOperationLockedAmountChallengePeriod(operationId);
        emit OperationExecuted(operation);
    }

    /// @inheritdoc IPNetworkHub
    function protocolGovernanceCancelOperation(Operation calldata operation) external {
        bytes4 networkId = Network.getCurrentNetworkId();
        if (networkId != interimChainNetworkId) {
            revert InvalidNetwork(networkId, interimChainNetworkId);
        }

        address msgSender = _msgSender();
        if (msgSender != dandelionVoting) {
            revert NotDandelionVoting(msgSender, dandelionVoting);
        }

        _protocolCancelOperation(operation, operationIdOf(operation), msgSender, ActorTypes.Governance);
    }

    /// @inheritdoc IPNetworkHub
    function protocolQueueOperation(Operation calldata operation) external payable {
        if (isLockedDown()) revert LockDown();

        if (msg.value != lockedAmountChallengePeriod) {
            revert InvalidLockedAmountChallengePeriod(msg.value, lockedAmountChallengePeriod);
        }

        if (numberOfOperationsInQueue >= maxOperationsInQueue) {
            revert QueueFull();
        }

        bytes32 operationId = operationIdOf(operation);

        OperationStatus operationStatus = _operationsStatus[operationId];
        if (operationStatus != OperationStatus.NotQueued) {
            revert InvalidOperationStatus(operationStatus, OperationStatus.NotQueued);
        }

        _operationsRelayerQueueAction[operationId] = Action({actor: _msgSender(), timestamp: uint64(block.timestamp)});
        _operationsStatus[operationId] = OperationStatus.Queued;
        unchecked {
            ++numberOfOperationsInQueue;
        }

        emit OperationQueued(operation);
    }

    /// @inheritdoc IPNetworkHub
    function slashByChallenge(Challenge calldata challenge) external {
        bytes32 challengeId = challengeIdOf(challenge);
        uint16 currentEpoch = IEpochsManager(epochsManager).currentEpoch();
        ChallengeStatus challengeStatus = _epochsChallengesStatus[currentEpoch][challengeId];

        // NOTE: avoid to slash by challenges opened in previous epochs
        if (challengeStatus == ChallengeStatus.Null) {
            revert ChallengeNotFound(challenge);
        }

        if (challengeStatus != ChallengeStatus.Pending) {
            revert InvalidChallengeStatus(challengeStatus, ChallengeStatus.Pending);
        }

        if (block.timestamp <= challenge.timestamp + challengeDuration) {
            revert MaxChallengeDurationNotPassed();
        }

        _epochsChallengesStatus[currentEpoch][challengeId] = ChallengeStatus.Unsolved;
        delete _epochsActorsPendingChallengeId[currentEpoch][challenge.actor];

        Utils.sendEther(challenge.challenger, lockedAmountStartChallenge);

        _setActorInactive(currentEpoch, challenge.actor, challenge.actorType);

        // reset the challenged bit
        _epochsActorsStatusNew[currentEpoch][challenge.actor] &= ~STATUS_CHALLENGED;

        // Encode block.timestamp in userData because slashing requests may arrive at
        // the RegistrationManager at different times (due to propagation time),
        // and from different hubs, so it needs to filter out multiple requests (max 1 per hour),
        // or discard them if the actor has already resumed in the meantime.
        bytes4 currentNetworkId = Network.getCurrentNetworkId();
        if (currentNetworkId == interimChainNetworkId) {
            // NOTE: If a slash happens on the interim chain we can avoid to emit the UserOperation
            //  in order to speed up the slashing process
            IPReceiver(slasher).receiveUserData(
                currentNetworkId,
                Utils.addressToHexString(address(this)),
                abi.encode(currentEpoch, challenge.actor, challenge.challenger, block.timestamp)
            );
        } else {
            emit UserOperation(
                gasleft(),
                Utils.addressToHexString(address(this)),
                Utils.addressToHexString(slasher),
                interimChainNetworkId,
                "",
                "",
                0,
                address(0),
                bytes4(0),
                address(0),
                0,
                0,
                0,
                0,
                0,
                currentNetworkId,
                abi.encode(currentEpoch, challenge.actor, challenge.challenger, block.timestamp),
                bytes32(0),
                true // isForProtocol
            );
        }

        emit ChallengeUnsolved(challenge);
    }

    /// @inheritdoc IPNetworkHub
    function solveChallenge(
        Challenge calldata challenge,
        ActorTypes actorType,
        bytes32[] calldata proof,
        bytes calldata signature
    ) external {
        bytes32 challengeId = challengeIdOf(challenge);
        address actor = ECDSA.recover(ECDSA.toEthSignedMessageHash(challengeId), signature);
        if (actor != challenge.actor || !_isActor(actor, actorType, proof)) {
            revert InvalidActor(actor, actorType);
        }

        _solveChallenge(challenge, challengeId);
    }

    /// @inheritdoc IPNetworkHub
    function startChallenge(address actor, ActorTypes actorType, bytes32[] calldata proof) external payable {
        _checkNearEndOfEpochStartChallenge();
        if (!_isActor(actor, actorType, proof)) {
            revert InvalidActor(actor, actorType);
        }

        _startChallenge(actor, actorType);
    }

    /// @inheritdoc IPNetworkHub
    function userSend(
        string calldata destinationAccount,
        bytes4 destinationNetworkId,
        string calldata underlyingAssetName,
        string calldata underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId,
        address assetTokenAddress,
        uint256 assetAmount,
        uint256 networkFeeAssetAmount,
        uint256 forwardNetworkFeeAssetAmount,
        bytes calldata userData,
        bytes32 optionsMask
    ) external {
        address msgSender = _msgSender();

        if (
            (assetAmount > 0 && assetTokenAddress == address(0)) ||
            (assetAmount == 0 && assetTokenAddress != address(0))
        ) {
            revert InvalidAssetParameters(assetAmount, assetTokenAddress);
        }

        if (networkFeeAssetAmount > assetAmount) {
            revert InvalidNetworkFeeAssetAmount();
        }

        if (assetAmount == 0 && userData.length == 0) {
            revert InvalidUserOperation();
        }

        bool isSendingOnCurrentNetwork = Network.isCurrentNetwork(destinationNetworkId);

        if (assetAmount > 0) {
            address pTokenAddress = IPFactory(factory).getPTokenAddress(
                underlyingAssetName,
                underlyingAssetSymbol,
                underlyingAssetDecimals,
                underlyingAssetTokenAddress,
                underlyingAssetNetworkId
            );
            if (pTokenAddress.code.length == 0) {
                revert PTokenNotCreated(pTokenAddress);
            }

            if (underlyingAssetTokenAddress == assetTokenAddress && isSendingOnCurrentNetwork && userData.length == 0) {
                // mint new tokens and return as we do not want a new UserOperation in this case,
                // otherwise it will be processed in the interim chain as usual, resulting in a double minting
                IPToken(pTokenAddress).userMint(msgSender, assetAmount);
                return;
            } else if (underlyingAssetTokenAddress == assetTokenAddress && !isSendingOnCurrentNetwork) {
                IPToken(pTokenAddress).userMintAndBurn(msgSender, assetAmount);
            } else if (pTokenAddress == assetTokenAddress && !isSendingOnCurrentNetwork) {
                IPToken(pTokenAddress).userBurn(msgSender, assetAmount);
            } else {
                revert InvalidUserOperation();
            }
        }

        uint256 userDataProtocolFeeAssetAmount = 0;
        if (userData.length > 0) {
            userDataProtocolFeeAssetAmount = 1; // TODO: calculate it based on user data length

            address pTokenAddressUserDataProtocolFee = IPFactory(factory).getPTokenAddress(
                UNDERLYING_ASSET_NAME_USER_DATA_PROTOCOL_FEE,
                UNDERLYING_ASSET_SYMBOL_USER_DATA_PROTOCOL_FEE,
                UNDERLYING_ASSET_DECIMALS_USER_DATA_PROTOCOL_FEE,
                UNDERLYING_ASSET_TOKEN_ADDRESS_USER_DATA_PROTOCOL_FEE,
                UNDERLYING_ASSET_NETWORK_ID_USER_DATA_PROTOCOL_FEE
            );
            if (pTokenAddressUserDataProtocolFee.code.length == 0) {
                revert PTokenNotCreated(pTokenAddressUserDataProtocolFee);
            }

            bytes4 currentNetworkId = Network.getCurrentNetworkId();
            if (UNDERLYING_ASSET_NETWORK_ID_USER_DATA_PROTOCOL_FEE == currentNetworkId && !isSendingOnCurrentNetwork) {
                IPToken(pTokenAddressUserDataProtocolFee).userMintAndBurn(msgSender, userDataProtocolFeeAssetAmount);
            } else if (
                UNDERLYING_ASSET_NETWORK_ID_USER_DATA_PROTOCOL_FEE != currentNetworkId && !isSendingOnCurrentNetwork
            ) {
                IPToken(pTokenAddressUserDataProtocolFee).userBurn(msgSender, userDataProtocolFeeAssetAmount);
            } else {
                revert InvalidUserOperation();
            }
        }

        emit UserOperation(
            gasleft(),
            Utils.addressToHexString(msgSender),
            destinationAccount,
            interimChainNetworkId,
            underlyingAssetName,
            underlyingAssetSymbol,
            underlyingAssetDecimals,
            underlyingAssetTokenAddress,
            underlyingAssetNetworkId,
            assetTokenAddress,
            // NOTE: pTokens on host chains have always 18 decimals.
            Utils.normalizeAmountToProtocolFormatOnCurrentNetwork(
                assetAmount,
                underlyingAssetDecimals,
                underlyingAssetNetworkId
            ),
            Utils.normalizeAmountToProtocolFormatOnCurrentNetwork(
                userDataProtocolFeeAssetAmount,
                UNDERLYING_ASSET_DECIMALS_USER_DATA_PROTOCOL_FEE,
                UNDERLYING_ASSET_NETWORK_ID_USER_DATA_PROTOCOL_FEE
            ),
            Utils.normalizeAmountToProtocolFormatOnCurrentNetwork(
                networkFeeAssetAmount,
                underlyingAssetDecimals,
                underlyingAssetNetworkId
            ),
            Utils.normalizeAmountToProtocolFormatOnCurrentNetwork(
                forwardNetworkFeeAssetAmount,
                underlyingAssetDecimals,
                underlyingAssetNetworkId
            ),
            destinationNetworkId,
            Network.getCurrentNetworkId(),
            userData,
            optionsMask,
            false // isForProtocol
        );
    }

    function _challengePeriodOf(
        bytes32 operationId,
        OperationStatus operationStatus
    ) internal view returns (uint64, uint64) {
        if (operationStatus != OperationStatus.Queued) return (0, 0);

        Action storage queueAction = _operationsRelayerQueueAction[operationId];
        uint64 startTimestamp = queueAction.timestamp;
        uint64 endTimestamp = startTimestamp + getCurrentChallengePeriodDuration();
        if (_operationsTotalCancelActions[operationId] == 0) {
            return (startTimestamp, endTimestamp);
        }

        if (_operationsGuardianCancelAction[operationId].actor != address(0)) {
            endTimestamp += 5 days;
        }

        if (_operationsSentinelCancelAction[operationId].actor != address(0)) {
            endTimestamp += 5 days;
        }

        return (startTimestamp, endTimestamp);
    }

    function _checkNearEndOfEpochStartChallenge() internal view {
        uint256 epochDuration = IEpochsManager(epochsManager).epochDuration();
        uint16 currentEpoch = IEpochsManager(epochsManager).currentEpoch();
        uint256 startFirstEpochTimestamp = IEpochsManager(epochsManager).startFirstEpochTimestamp();
        uint256 currentEpochEndTimestamp = startFirstEpochTimestamp + ((currentEpoch + 1) * epochDuration);

        // This is to allow solving challenges up to one hour earlier than the epoch's ending
        if (block.timestamp + challengeDuration > currentEpochEndTimestamp - 1 hours) {
            revert NearToEpochEnd();
        }
    }

    function _isActor(address actor, ActorTypes actorType, bytes32[] calldata proof) internal view returns (bool) {
        return
            MerkleProof.verify(
                proof,
                _epochsActorsMerkleRoot[IEpochsManager(epochsManager).currentEpoch()],
                keccak256(abi.encodePacked(actor, actorType))
            );
    }

    function _isActorsStatusValid() internal view returns (bool) {
        uint16 currentEpoch = IEpochsManager(epochsManager).currentEpoch();
        if (
            _epochsActorsMerkleRoot[currentEpoch] == bytes32(0) ||
            _epochsTotalNumberOfInactiveActors[currentEpoch][ActorTypes.Guardian] ==
            _epochsTotalNumberOfActors[currentEpoch][ActorTypes.Guardian] ||
            _epochsTotalNumberOfInactiveActors[currentEpoch][ActorTypes.Sentinel] ==
            _epochsTotalNumberOfActors[currentEpoch][ActorTypes.Sentinel]
        ) {
            return false;
        }
        return true;
    }

    function _maybeCancelPendingChallenge(uint16 epoch, address actor) internal {
        bytes32 pendingChallengeId = _epochsActorsPendingChallengeId[epoch][actor];
        if (pendingChallengeId != bytes32(0)) {
            Challenge storage challenge = _epochsChallenges[epoch][pendingChallengeId];
            delete _epochsActorsPendingChallengeId[epoch][actor];
            _epochsChallengesStatus[epoch][pendingChallengeId] = ChallengeStatus.Cancelled;
            // reset the challenged bit
            _epochsActorsStatusNew[epoch][challenge.actor] &= ~STATUS_CHALLENGED;
            Utils.sendEther(challenge.challenger, lockedAmountStartChallenge);

            emit ChallengeCancelled(challenge);
        }
    }

    function _onGovernanceMessage(bytes memory message) internal override {
        (bytes32 messageType, bytes memory messageData) = abi.decode(message, (bytes32, bytes));

        if (messageType == GOVERNANCE_MESSAGE_ACTORS) {
            (uint16 epoch, uint16 totalNumberOfGuardians, uint16 totalNumberOfSentinels, bytes32 actorsMerkleRoot) = abi
                .decode(messageData, (uint16, uint16, uint16, bytes32));

            _epochsActorsMerkleRoot[epoch] = actorsMerkleRoot;
            _epochsTotalNumberOfActors[epoch][ActorTypes.Guardian] = totalNumberOfGuardians;
            _epochsTotalNumberOfActors[epoch][ActorTypes.Sentinel] = totalNumberOfSentinels;
            return;
        }

        if (messageType == GOVERNANCE_MESSAGE_SLASH_ACTOR) {
            (uint16 epoch, address actor, ActorTypes actorType) = abi.decode(
                messageData,
                (uint16, address, ActorTypes)
            );
            // NOTE: Consider the scenario where a actor's status is 'Challenged', and a GOVERNANCE_MESSAGE_SLASH_ACTOR is received
            // for the same actor before the challenge is resolved or the actor is slashed.
            // If a actor is already 'Challenged', we should:
            // - cancel the current challenge
            // - set to active the state of the actor
            // - send to the challenger the bond
            // - slash it
            _maybeCancelPendingChallenge(epoch, actor);
            _setActorInactive(epoch, actor, actorType);
            return;
        }

        if (messageType == GOVERNANCE_MESSAGE_RESUME_ACTOR) {
            (uint16 epoch, address actor, ActorTypes actorType) = abi.decode(
                messageData,
                (uint16, address, ActorTypes)
            );
            _setActorActive(epoch, actor, actorType);
            return;
        }

        if (messageType == GOVERNANCE_MESSAGE_PROTOCOL_GOVERNANCE_CANCEL_OPERATION) {
            Operation memory operation = abi.decode(messageData, (Operation));
            // TODO; What should i use ad actor address? address(this) ???
            _protocolCancelOperation(operation, operationIdOf(operation), address(this), ActorTypes.Governance);
            return;
        }

        revert InvalidGovernanceMessage(message);
    }

    function _protocolCancelOperation(
        Operation memory operation,
        bytes32 operationId,
        address actor,
        ActorTypes actorType
    ) internal {
        OperationStatus operationStatus = _operationsStatus[operationId];
        if (operationStatus != OperationStatus.Queued) {
            revert InvalidOperationStatus(operationStatus, OperationStatus.Queued);
        }

        Action memory action = Action({actor: actor, timestamp: uint64(block.timestamp)});
        if (actorType == ActorTypes.Governance) {
            address governance = _operationsGovernanceCancelAction[operationId].actor;
            if (governance != address(0)) {
                revert ActorAlreadyCancelledOperation(operation, governance, actorType);
            }

            _operationsGovernanceCancelAction[operationId] = action;
        }
        if (actorType == ActorTypes.Guardian) {
            address guardian = _operationsGuardianCancelAction[operationId].actor;
            if (guardian != address(0)) {
                revert ActorAlreadyCancelledOperation(operation, guardian, actorType);
            }

            _operationsGuardianCancelAction[operationId] = action;
        }
        if (actorType == ActorTypes.Sentinel) {
            address sentinel = _operationsSentinelCancelAction[operationId].actor;
            if (sentinel != address(0)) {
                revert ActorAlreadyCancelledOperation(operation, sentinel, actorType);
            }

            _operationsSentinelCancelAction[operationId] = action;
        }
        emit OperationCancelled(operation, actor, actorType);

        (, uint64 endTimestamp) = _challengePeriodOf(operationId, operationStatus);

        unchecked {
            ++_operationsTotalCancelActions[operationId];
        }

        // finalize cancel operation if the challenge period has expired and just one actor has requested cancellation (to ease queue clean up), or
        // in the case of a cancellation requests coming from two actors of different classes (multi-prover approach)
        if (uint64(block.timestamp) >= endTimestamp || _operationsTotalCancelActions[operationId] == 2) {
            unchecked {
                --numberOfOperationsInQueue;
            }
            _operationsStatus[operationId] = OperationStatus.Cancelled;

            // TODO: here we should send the lockedAmountChallengePeriod to the DAO,
            // however the DAO is not ready to welcome that change yet, so we forward
            // the funds to the GovernanceMessage relayer for now
            Utils.sendEther(GOVERNANCE_MESSAGE_RELAYER_ADDRESS, lockedAmountChallengePeriod);

            emit OperationCancelFinalized(operation);
        }
    }

    function _releaseOperationLockedAmountChallengePeriod(bytes32 operationId) internal {
        _operationsStatus[operationId] = OperationStatus.Executed;
        Action storage queuedAction = _operationsRelayerQueueAction[operationId];
        Utils.sendEther(queuedAction.actor, lockedAmountChallengePeriod);

        unchecked {
            --numberOfOperationsInQueue;
        }
    }

    function _setActorInactive(uint16 epoch, address actor, ActorTypes actorType) internal {
        if ((_epochsActorsStatusNew[epoch][actor] & STATUS_INACTIVE) == 0) {
            unchecked {
                ++_epochsTotalNumberOfInactiveActors[epoch][actorType];
            }
            // set the inactive bit
            _epochsActorsStatusNew[epoch][actor] |= STATUS_INACTIVE;
            emit ActorSlashed(epoch, actor);
        }
    }

    function _setActorActive(uint16 epoch, address actor, ActorTypes actorType) internal {
        if ((_epochsActorsStatusNew[epoch][actor] & STATUS_INACTIVE) != 0) {
            unchecked {
                --_epochsTotalNumberOfInactiveActors[epoch][actorType];
            }
            // reset the inactive bit
            _epochsActorsStatusNew[epoch][actor] &= ~STATUS_INACTIVE;
            emit ActorResumed(epoch, actor);
        }
    }

    function _solveChallenge(Challenge calldata challenge, bytes32 challengeId) internal {
        uint16 currentEpoch = IEpochsManager(epochsManager).currentEpoch();
        ChallengeStatus challengeStatus = _epochsChallengesStatus[currentEpoch][challengeId];

        if (challengeStatus == ChallengeStatus.Null) {
            revert ChallengeNotFound(challenge);
        }

        if (challengeStatus != ChallengeStatus.Pending) {
            revert InvalidChallengeStatus(challengeStatus, ChallengeStatus.Pending);
        }

        if (block.timestamp > challenge.timestamp + challengeDuration) {
            revert ChallengeDurationPassed();
        }

        // TODO: here we should send the lockedAmountChallengePeriod to the DAO,
        // however the DAO is not ready to welcome that change yet, so we forward
        // the funds to the GovernanceMessage relayer for now
        Utils.sendEther(GOVERNANCE_MESSAGE_RELAYER_ADDRESS, lockedAmountStartChallenge);

        _epochsChallengesStatus[currentEpoch][challengeId] = ChallengeStatus.Solved;
        _setActorActive(currentEpoch, challenge.actor, challenge.actorType);
        // reset the challenged bit
        _epochsActorsStatusNew[currentEpoch][challenge.actor] &= ~STATUS_CHALLENGED;
        delete _epochsActorsPendingChallengeId[currentEpoch][challenge.actor];
        emit ChallengeSolved(challenge);
    }

    function _startChallenge(address actor, ActorTypes actorType) internal {
        address challenger = _msgSender();
        uint16 currentEpoch = IEpochsManager(epochsManager).currentEpoch();

        if (msg.value != lockedAmountStartChallenge) {
            revert InvalidLockedAmountStartChallenge(msg.value, lockedAmountStartChallenge);
        }

        // We allow challenges also against inactive actors since
        // they will earn protocol fees until they are hard-slashed
        // (that is when a minimum amount of slashes is reached).
        // This is why here we revert only if there is a pending
        // challenge, while other statuses are fine to be challenged.
        uint8 actorStatus = _epochsActorsStatusNew[currentEpoch][actor];
        if ((actorStatus & STATUS_CHALLENGED) != 0) {
            revert ActorAlreadyChallenged();
        }

        Challenge memory challenge = Challenge({
            nonce: challengesNonce,
            actor: actor,
            challenger: challenger,
            actorType: actorType,
            timestamp: uint64(block.timestamp),
            networkId: Network.getCurrentNetworkId()
        });
        bytes32 challengeId = challengeIdOf(challenge);
        _epochsChallenges[currentEpoch][challengeId] = challenge;
        _epochsChallengesStatus[currentEpoch][challengeId] = ChallengeStatus.Pending;
        // set the challenged bit
        _epochsActorsStatusNew[currentEpoch][actor] |= STATUS_CHALLENGED;
        _epochsActorsPendingChallengeId[currentEpoch][actor] = challengeId;

        unchecked {
            ++challengesNonce;
        }

        emit ChallengePending(challenge);
    }

    function _takeNetworkFee(
        uint256 operationAmount,
        uint256 operationNetworkFeeAssetAmount,
        bytes32 operationId,
        address pTokenAddress
    ) internal returns (uint256) {
        if (operationNetworkFeeAssetAmount == 0) return operationAmount;

        Action storage queuedAction = _operationsRelayerQueueAction[operationId];

        address queuedActionActor = queuedAction.actor;
        address executedActionActor = _msgSender();
        if (queuedActionActor == executedActionActor) {
            IPToken(pTokenAddress).protocolMint(queuedActionActor, operationNetworkFeeAssetAmount);
            return operationAmount - operationNetworkFeeAssetAmount;
        }

        // NOTE: protocolQueueOperation consumes in avg 117988. protocolExecuteOperation consumes in avg 198928.
        // which results in 37% to networkFeeQueueActor and 63% to networkFeeExecuteActor
        uint256 networkFeeQueueActor = (operationNetworkFeeAssetAmount * 3700) / FEE_BASIS_POINTS_DIVISOR; // 37%
        uint256 networkFeeExecuteActor = (operationNetworkFeeAssetAmount * 6300) / FEE_BASIS_POINTS_DIVISOR; // 63%
        IPToken(pTokenAddress).protocolMint(queuedActionActor, networkFeeQueueActor);
        IPToken(pTokenAddress).protocolMint(executedActionActor, networkFeeExecuteActor);

        return operationAmount - operationNetworkFeeAssetAmount;
    }

    function _takeProtocolFee(Operation calldata operation, address pTokenAddress) internal returns (uint256) {
        if (operation.isForProtocol) {
            return 0;
        }

        uint256 fee = 0;
        if (operation.assetAmount > 0) {
            uint256 feeBps = 20; // 0.2%
            fee = (operation.assetAmount * feeBps) / FEE_BASIS_POINTS_DIVISOR;
            IPToken(pTokenAddress).protocolMint(address(this), fee);
            IPToken(pTokenAddress).approve(feesManager, fee);
            IFeesManager(feesManager).depositFee(pTokenAddress, fee);
        }

        if (operation.userData.length > 0) {
            address pTokenAddressUserDataProtocolFee = IPFactory(factory).getPTokenAddress(
                UNDERLYING_ASSET_NAME_USER_DATA_PROTOCOL_FEE,
                UNDERLYING_ASSET_SYMBOL_USER_DATA_PROTOCOL_FEE,
                UNDERLYING_ASSET_DECIMALS_USER_DATA_PROTOCOL_FEE,
                UNDERLYING_ASSET_TOKEN_ADDRESS_USER_DATA_PROTOCOL_FEE,
                UNDERLYING_ASSET_NETWORK_ID_USER_DATA_PROTOCOL_FEE
            );

            IPToken(pTokenAddressUserDataProtocolFee).protocolMint(
                address(this),
                operation.userDataProtocolFeeAssetAmount
            );
            IPToken(pTokenAddressUserDataProtocolFee).approve(feesManager, operation.userDataProtocolFeeAssetAmount);
            IFeesManager(feesManager).depositFee(
                pTokenAddressUserDataProtocolFee,
                operation.userDataProtocolFeeAssetAmount
            );
        }

        return operation.assetAmount - fee;
    }
}
