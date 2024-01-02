// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ECDSA.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ForwarderRecipientUpgradeable.sol";
import "./IStakingManagerPermissioned.sol";
import "./IEpochsManager.sol";
import "./ILendingManager.sol";
import "./IRegistrationManager.sol";
import "./IFeesManager.sol";
import "./IGovernanceMessageEmitter.sol";
import "./Roles.sol";
import "./Errors.sol";
import "./Constants.sol";
import "./Helpers.sol";

contract RegistrationManager is IRegistrationManager, Initializable, UUPSUpgradeable, ForwarderRecipientUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(address => Registration) private _registrations;
    mapping(address => address) private _ownersSentinel;
    mapping(address => address) private _ownersGuardian;
    mapping(address => uint256) private _ownersSignatureNonces;
    uint32[] private _sentinelsEpochsTotalStakedAmount;
    mapping(address => uint32[]) private _sentinelsEpochsStakedAmount;
    mapping(uint16 => uint16) private _epochsTotalNumberOfGuardians;
    mapping(uint16 => mapping(address => uint16)) private _pendingLightResumes;
    mapping(uint16 => mapping(address => uint16)) private _slashes;
    mapping(address => uint256) private _lastSlashTimestamp;
    mapping(address => uint256) private _lastResumeTimestamp;

    address public stakingManager;
    address public token;
    address public epochsManager;
    address public lendingManager;
    address public feesManager;
    address public governanceMessageEmitter;

    function initialize(
        address _token,
        address _stakingManager,
        address _epochsManager,
        address _lendingManager,
        address _forwarder
    ) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlEnumerable_init();
        __ForwarderRecipientUpgradeable_init(_forwarder);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(SET_FORWARDER_ROLE, _msgSender());

        stakingManager = _stakingManager;
        token = _token;
        epochsManager = _epochsManager;
        lendingManager = _lendingManager;

        _sentinelsEpochsTotalStakedAmount = new uint32[](Constants.AVAILABLE_EPOCHS);
    }

    // @inheritdoc IRegistrationManager
    function getSignatureNonceByOwner(address owner) external view returns (uint256) {
        return _ownersSignatureNonces[owner];
    }

    /// @inheritdoc IRegistrationManager
    function guardianOf(address owner) external view returns (address) {
        return _ownersGuardian[owner];
    }

    /// @inheritdoc IRegistrationManager
    function hardResume(uint256 amount, bytes calldata signature, uint256 nonce) external {
        address owner = _msgSender();
        uint16 currentEpoch = IEpochsManager(epochsManager).currentEpoch();
        address sentinel = _getActorAddressFromSignatureAndIncreaseSignatureNonce(owner, signature, nonce);

        Registration storage registration = _registrations[sentinel];
        bytes1 registrationKind = registration.kind;
        uint16 registrationEndEpoch = registration.endEpoch;

        if (registrationKind != Constants.REGISTRATION_SENTINEL_STAKING || registrationEndEpoch < currentEpoch) {
            revert Errors.InvalidRegistration();
        }

        if (amount == 0) {
            revert Errors.InvalidAmount();
        }

        uint32 truncatedAmount = Helpers.truncate(amount);
        for (uint16 epoch = currentEpoch; epoch <= registrationEndEpoch; ) {
            _sentinelsEpochsStakedAmount[sentinel][epoch] += truncatedAmount;

            if (
                _sentinelsEpochsStakedAmount[sentinel][epoch] <
                Constants.STAKING_MIN_AMOUT_FOR_SENTINEL_REGISTRATION_TRUNCATED
            ) {
                revert Errors.AmountNotAvailableInEpoch(epoch);
            }

            _sentinelsEpochsTotalStakedAmount[epoch] += truncatedAmount;

            unchecked {
                ++epoch;
            }
        }

        IERC20Upgradeable(token).safeTransferFrom(owner, address(this), amount);
        IERC20Upgradeable(token).approve(stakingManager, amount);
        // NOTE: since this fx will be called by staking sentinels that would want to increase their amount
        // at stake for example after a slashing in order to be resumable, they wont be able to do it
        // if the remaining staking time is less than 7 days in order to avoid abuses.
        IStakingManagerPermissioned(stakingManager).increaseAmount(owner, amount);

        _lastSlashTimestamp[sentinel] = 0;
        _lastResumeTimestamp[sentinel] = block.timestamp;

        IGovernanceMessageEmitter(governanceMessageEmitter).resumeActor(
            sentinel,
            Constants.REGISTRATION_SENTINEL_STAKING
        );
        emit SentinelHardResumed(sentinel);
    }

    /// @inheritdoc IRegistrationManager
    function increaseSentinelRegistrationDuration(uint64 duration) external {
        _increaseSentinelRegistrationDuration(_msgSender(), duration);
    }

    /// @inheritdoc IRegistrationManager
    function increaseSentinelRegistrationDuration(address owner, uint64 duration) external onlyForwarder {
        _increaseSentinelRegistrationDuration(owner, duration);
    }

    /// @inheritdoc IRegistrationManager
    function lightResume(bytes calldata signature, uint256 nonce) external {
        uint16 currentEpoch = IEpochsManager(epochsManager).currentEpoch();
        address actor = _getActorAddressFromSignatureAndIncreaseSignatureNonce(_msgSender(), signature, nonce);

        Registration storage registration = _registrations[actor];
        uint16 registrationEndEpoch = registration.endEpoch;

        // NOTE: avoid to resume a actor whose registration is expired or null
        if (registrationEndEpoch < currentEpoch || registrationEndEpoch == 0) {
            revert Errors.InvalidRegistration();
        }

        if (_pendingLightResumes[currentEpoch][actor] == 0) {
            revert Errors.NotResumable();
        }

        unchecked {
            --_pendingLightResumes[currentEpoch][actor];
        }

        _lastSlashTimestamp[actor] = 0;
        _lastResumeTimestamp[actor] = block.timestamp;

        bytes1 registrationKind = registration.kind;
        IGovernanceMessageEmitter(governanceMessageEmitter).resumeActor(actor, registrationKind);
        emit LightResumed(actor, registrationKind);
    }

    /// @inheritdoc IRegistrationManager
    function registrationOf(address actor) external view returns (Registration memory) {
        return _registrations[actor];
    }

    /// @inheritdoc IRegistrationManager
    function sentinelOf(address owner) external view returns (address) {
        return _ownersSentinel[owner];
    }

    /// @inheritdoc IRegistrationManager
    function sentinelStakedAmountByEpochOf(address sentinel, uint16 epoch) external view returns (uint256) {
        return _sentinelsEpochsStakedAmount[sentinel].length > 0 ? _sentinelsEpochsStakedAmount[sentinel][epoch] : 0;
    }

    /// @inheritdoc IRegistrationManager
    function slashesByEpochOf(uint16 epoch, address actor) external view returns (uint16) {
        return _slashes[epoch][actor];
    }

    /// @inheritdoc IRegistrationManager
    function setFeesManager(address feesManager_) external onlyRole(Roles.SET_FEES_MANAGER_ROLE) {
        feesManager = feesManager_;
    }

    /// @inheritdoc IRegistrationManager
    function setGovernanceMessageEmitter(
        address governanceMessageEmitter_
    ) external onlyRole(Roles.SET_GOVERNANCE_MESSAGE_EMITTER_ROLE) {
        governanceMessageEmitter = governanceMessageEmitter_;
    }

    /// @inheritdoc IRegistrationManager
    function slash(
        address actor,
        uint256 amount,
        address challenger,
        uint256 slashTimestamp
    ) external onlyRole(Roles.SLASH_ROLE) {
        uint16 currentEpoch = IEpochsManager(epochsManager).currentEpoch();
        uint256 lastSlashTimestamp = _lastSlashTimestamp[actor];
        uint256 lastResumeTimestamp = _lastResumeTimestamp[actor];

        // Accept one slash per hour for the same actor
        if (lastSlashTimestamp != 0 && slashTimestamp < lastSlashTimestamp + 1 hours)
            revert Errors.ActorAlreadySlashed(lastSlashTimestamp, slashTimestamp);

        // Do not slash actors who have already resumed after the slashing request was issued on PNetworkHub
        // Otherwise, due to propagation times, we may slash them erroneously
        if (lastResumeTimestamp != 0 && slashTimestamp < lastResumeTimestamp)
            revert Errors.ActorAlreadyResumed(lastResumeTimestamp, slashTimestamp);

        _lastSlashTimestamp[actor] = slashTimestamp;

        Registration storage registration = _registrations[actor];
        address registrationOwner = registration.owner;

        unchecked {
            ++_slashes[currentEpoch][actor];
        }

        bytes1 registrationKind = registration.kind;
        if (registrationKind == Constants.REGISTRATION_SENTINEL_STAKING) {
            IStakingManagerPermissioned.Stake memory stake = IStakingManagerPermissioned(stakingManager).stakeOf(
                registrationOwner
            );

            uint256 amountToSlash = amount;
            uint256 stakeAmount = stake.amount;
            if (stakeAmount < amount) {
                amountToSlash = stakeAmount;
            }

            uint16 registrationEndEpoch = registration.endEpoch;
            uint32 truncatedAmount = Helpers.truncate(amountToSlash);

            for (uint16 epoch = currentEpoch; epoch <= registrationEndEpoch; ) {
                _sentinelsEpochsTotalStakedAmount[epoch] -= truncatedAmount;
                _sentinelsEpochsStakedAmount[actor][epoch] -= truncatedAmount;
                unchecked {
                    ++epoch;
                }
            }

            if (stakeAmount - amountToSlash >= Constants.STAKING_MIN_AMOUT_FOR_SENTINEL_REGISTRATION) {
                unchecked {
                    ++_pendingLightResumes[currentEpoch][actor];
                }
            } else {
                // NOTE: in order to avoid to light-resume an hard-slashed sentinel
                _pendingLightResumes[currentEpoch][actor] == 0;
            }

            if (amount > 0) {
                IStakingManagerPermissioned(stakingManager).slash(registrationOwner, amountToSlash, challenger);
            }

            IGovernanceMessageEmitter(governanceMessageEmitter).slashActor(
                actor,
                Constants.REGISTRATION_SENTINEL_STAKING
            );
            emit StakingSentinelSlashed(actor, amount);
        } else if (registrationKind == Constants.REGISTRATION_SENTINEL_BORROWING) {
            uint16 actorSlashes = _slashes[currentEpoch][actor];
            if (actorSlashes == Constants.NUMBER_OF_ALLOWED_SLASHES + 1) {
                IFeesManager(feesManager).redirectClaimToChallengerByEpoch(actor, challenger, currentEpoch);

                uint16 registrationEndEpoch = registration.endEpoch;
                for (uint16 epoch = currentEpoch + 1; epoch <= registrationEndEpoch; ) {
                    ILendingManager(lendingManager).release(
                        actor,
                        epoch,
                        Constants.BORROW_AMOUNT_FOR_SENTINEL_REGISTRATION
                    );
                    unchecked {
                        ++epoch;
                    }
                }

                registration.endEpoch = currentEpoch; // NOTE: Registration ends here
                _pendingLightResumes[currentEpoch][actor] = 0;
            } else if (actorSlashes < Constants.NUMBER_OF_ALLOWED_SLASHES + 1) {
                unchecked {
                    ++_pendingLightResumes[currentEpoch][actor];
                }
            } else {
                return;
            }
            IGovernanceMessageEmitter(governanceMessageEmitter).slashActor(
                actor,
                Constants.REGISTRATION_SENTINEL_BORROWING
            );
            emit BorrowingSentinelSlashed(actor);
        } else if (registrationKind == Constants.REGISTRATION_GUARDIAN) {
            uint16 actorSlashes = _slashes[currentEpoch][actor];
            if (actorSlashes == Constants.NUMBER_OF_ALLOWED_SLASHES + 1) {
                IFeesManager(feesManager).redirectClaimToChallengerByEpoch(actor, challenger, currentEpoch);
                registration.endEpoch = currentEpoch; // NOTE: Registration ends here
                _pendingLightResumes[currentEpoch][actor] = 0;
            } else if (actorSlashes < Constants.NUMBER_OF_ALLOWED_SLASHES + 1) {
                unchecked {
                    ++_pendingLightResumes[currentEpoch][actor];
                }
            } else {
                return;
            }

            IGovernanceMessageEmitter(governanceMessageEmitter).slashActor(actor, Constants.REGISTRATION_GUARDIAN);
            emit GuardianSlashed(actor);
        } else {
            revert Errors.InvalidRegistration();
        }
    }

    /// @inheritdoc IRegistrationManager
    function totalNumberOfGuardiansByEpoch(uint16 epoch) external view returns (uint16) {
        return _epochsTotalNumberOfGuardians[epoch];
    }

    /// @inheritdoc IRegistrationManager
    function totalSentinelStakedAmountByEpoch(uint16 epoch) external view returns (uint256) {
        return _sentinelsEpochsTotalStakedAmount[epoch];
    }

    /// @inheritdoc IRegistrationManager
    function totalSentinelStakedAmountByEpochsRange(
        uint16 startEpoch,
        uint16 endEpoch
    ) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[]((endEpoch + 1) - startEpoch);
        for (uint16 epoch = startEpoch; epoch <= endEpoch; epoch++) {
            result[epoch - startEpoch] = _sentinelsEpochsTotalStakedAmount[epoch];
        }
        return result;
    }

    /// @inheritdoc IRegistrationManager
    function updateGuardiansRegistrations(
        address[] calldata owners,
        uint16[] calldata numbersOfEpochs,
        address[] calldata guardians
    ) external onlyRole(Roles.UPDATE_GUARDIAN_REGISTRATION_ROLE) {
        for (uint16 i = 0; i < owners.length; ) {
            _updateGuardianRegistration(owners[i], numbersOfEpochs[i], guardians[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IRegistrationManager
    function updateGuardianRegistration(
        address owner,
        uint16 numberOfEpochs,
        address guardian
    ) external onlyRole(Roles.UPDATE_GUARDIAN_REGISTRATION_ROLE) {
        _updateGuardianRegistration(owner, numberOfEpochs, guardian);
    }

    /// @inheritdoc IRegistrationManager
    function updateSentinelRegistrationByBorrowing(
        address owner,
        uint16 numberOfEpochs,
        bytes calldata signature,
        uint256 nonce
    ) external onlyForwarder {
        _updateSentinelRegistrationByBorrowing(owner, numberOfEpochs, signature, nonce);
    }

    /// @inheritdoc IRegistrationManager
    function updateSentinelRegistrationByBorrowing(
        uint16 numberOfEpochs,
        bytes calldata signature,
        uint256 nonce
    ) external {
        _updateSentinelRegistrationByBorrowing(_msgSender(), numberOfEpochs, signature, nonce);
    }

    /// @inheritdoc IRegistrationManager
    function updateSentinelRegistrationByStaking(
        address owner,
        uint256 amount,
        uint64 duration,
        bytes calldata signature,
        uint256 nonce
    ) external {
        address sentinel = _getActorAddressFromSignatureAndIncreaseSignatureNonce(owner, signature, nonce);

        // TODO: What does it happen if an user updateSentinelRegistrationByStaking in behalf of someone else using a wrong signature?

        Registration storage registration = _registrations[sentinel];
        bytes1 registrationKind = registration.kind;
        if (
            registrationKind == Constants.REGISTRATION_SENTINEL_BORROWING ||
            registrationKind == Constants.REGISTRATION_GUARDIAN
        ) {
            revert Errors.InvalidRegistration();
        }

        IERC20Upgradeable(token).safeTransferFrom(_msgSender(), address(this), amount);
        IERC20Upgradeable(token).approve(stakingManager, amount);
        IStakingManagerPermissioned(stakingManager).stake(owner, amount, duration);

        uint16 currentEpoch = IEpochsManager(epochsManager).currentEpoch();
        uint16 startEpoch = currentEpoch + 1;
        uint16 endEpoch = currentEpoch + uint16(duration / IEpochsManager(epochsManager).epochDuration()) - 1;
        uint16 registrationStartEpoch = registration.startEpoch;
        uint16 registrationEndEpoch = registration.endEpoch;

        if (_sentinelsEpochsStakedAmount[sentinel].length == 0) {
            _sentinelsEpochsStakedAmount[sentinel] = new uint32[](Constants.AVAILABLE_EPOCHS);
        }

        uint32 truncatedAmount = Helpers.truncate(amount);
        for (uint16 epoch = startEpoch; epoch <= endEpoch; ) {
            _sentinelsEpochsStakedAmount[sentinel][epoch] += truncatedAmount;
            if (
                _sentinelsEpochsStakedAmount[sentinel][epoch] <
                Constants.STAKING_MIN_AMOUT_FOR_SENTINEL_REGISTRATION_TRUNCATED
            ) {
                revert Errors.InvalidAmount();
            }

            _sentinelsEpochsTotalStakedAmount[epoch] += truncatedAmount;
            unchecked {
                ++epoch;
            }
        }

        if (startEpoch > registrationEndEpoch) {
            registrationStartEpoch = startEpoch;
        }

        if (endEpoch > registrationEndEpoch) {
            registrationEndEpoch = endEpoch;
        }

        _updateSentinelRegistration(
            sentinel,
            owner,
            registrationStartEpoch,
            registrationEndEpoch,
            Constants.REGISTRATION_SENTINEL_STAKING
        );

        emit SentinelRegistrationUpdated(
            owner,
            startEpoch,
            endEpoch,
            sentinel,
            Constants.REGISTRATION_SENTINEL_STAKING,
            amount
        );
    }

    function _increaseSentinelRegistrationDuration(address owner, uint64 duration) internal {
        address sentinel = _ownersSentinel[owner];
        Registration storage registration = _registrations[sentinel];
        bytes1 registrationKind = registration.kind;
        if (
            registrationKind == Constants.REGISTRATION_SENTINEL_BORROWING ||
            registrationKind == Constants.REGISTRATION_GUARDIAN
        ) {
            revert Errors.InvalidRegistration();
        }

        uint16 currentEpoch = IEpochsManager(epochsManager).currentEpoch();
        uint256 epochDuration = IEpochsManager(epochsManager).epochDuration();

        IStakingManagerPermissioned(stakingManager).increaseDuration(owner, duration);
        IStakingManagerPermissioned.Stake memory stake = IStakingManagerPermissioned(stakingManager).stakeOf(owner);

        uint64 blockTimestamp = uint64(block.timestamp);
        uint16 startEpoch = currentEpoch + 1;
        // if startDate hasn't just been reset(increasing duration where block.timestamp < oldEndDate) it means that we have to count the epoch next to the current endEpoch one
        uint16 numberOfEpochs = uint16((stake.endDate - blockTimestamp) / epochDuration) -
            (stake.startDate == blockTimestamp ? 1 : 0);
        uint16 endEpoch = uint16(startEpoch + numberOfEpochs - 1);
        uint32 truncatedAmount = Helpers.truncate(stake.amount);

        for (uint16 epoch = startEpoch; epoch <= endEpoch; ) {
            if (_sentinelsEpochsStakedAmount[sentinel][epoch] == 0) {
                _sentinelsEpochsStakedAmount[sentinel][epoch] += truncatedAmount;
                _sentinelsEpochsTotalStakedAmount[epoch] += truncatedAmount;
            }

            unchecked {
                ++epoch;
            }
        }

        if (stake.startDate == blockTimestamp) {
            registration.startEpoch = startEpoch;
        }
        registration.endEpoch = endEpoch;

        emit SentinelRegistrationUpdated(
            owner,
            registration.startEpoch,
            registration.endEpoch,
            sentinel,
            Constants.REGISTRATION_SENTINEL_STAKING,
            stake.amount
        );
    }

    function _getActorAddressFromSignatureAndIncreaseSignatureNonce(
        address owner,
        bytes memory signature,
        uint256 nonce
    ) internal returns (address) {
        uint256 expectedNonce = _ownersSignatureNonces[owner];
        if (nonce != expectedNonce) {
            revert Errors.InvalidSignatureNonce(nonce, expectedNonce);
        }

        bytes32 message = ECDSA.toEthSignedMessageHash(keccak256(abi.encode(owner, nonce)));
        address actor = ECDSA.recover(message, signature);
        unchecked {
            ++_ownersSignatureNonces[owner];
        }

        return actor;
    }

    function _updateGuardianRegistration(address owner, uint16 numberOfEpochs, address guardian) internal {
        if (numberOfEpochs == 0) {
            revert Errors.InvalidNumberOfEpochs(numberOfEpochs);
        }

        Registration storage currentRegistration = _registrations[guardian];
        bytes1 registrationKind = currentRegistration.kind;
        if (
            registrationKind == Constants.REGISTRATION_SENTINEL_STAKING ||
            registrationKind == Constants.REGISTRATION_SENTINEL_BORROWING
        ) {
            revert Errors.InvalidRegistration();
        }

        uint16 currentEpoch = IEpochsManager(epochsManager).currentEpoch();

        uint16 currentRegistrationEndEpoch = currentRegistration.endEpoch;
        uint16 startEpoch = currentEpoch + 1;
        uint16 endEpoch = startEpoch + numberOfEpochs - 1;

        // NOTE: reset _epochsTotalNumberOfGuardians if the guardian was already registered and if the current epoch is less than the
        // epoch in which the current registration ends.
        if (currentRegistration.owner != address(0) && currentEpoch < currentRegistrationEndEpoch) {
            for (uint16 epoch = startEpoch; epoch <= currentRegistrationEndEpoch; ) {
                unchecked {
                    --_epochsTotalNumberOfGuardians[epoch];
                    ++epoch;
                }
            }
        }

        _ownersGuardian[owner] = guardian;
        _registrations[guardian] = Registration(owner, startEpoch, endEpoch, Constants.REGISTRATION_GUARDIAN);

        for (uint16 epoch = startEpoch; epoch <= endEpoch; ) {
            unchecked {
                ++_epochsTotalNumberOfGuardians[epoch];
                ++epoch;
            }
        }

        emit GuardianRegistrationUpdated(owner, startEpoch, endEpoch, guardian, Constants.REGISTRATION_GUARDIAN);
    }

    function _updateSentinelRegistrationByBorrowing(
        address owner,
        uint16 numberOfEpochs,
        bytes calldata signature,
        uint256 nonce
    ) internal {
        if (numberOfEpochs == 0) {
            revert Errors.InvalidNumberOfEpochs(numberOfEpochs);
        }

        address sentinel = _getActorAddressFromSignatureAndIncreaseSignatureNonce(owner, signature, nonce);
        Registration storage registration = _registrations[sentinel];
        bytes1 registrationKind = registration.kind;
        if (
            registrationKind == Constants.REGISTRATION_SENTINEL_STAKING ||
            registrationKind == Constants.REGISTRATION_GUARDIAN
        ) {
            revert Errors.InvalidRegistration();
        }

        uint16 currentEpoch = IEpochsManager(epochsManager).currentEpoch();
        uint16 currentRegistrationStartEpoch = registration.startEpoch;
        uint16 currentRegistrationEndEpoch = registration.endEpoch;

        uint16 startEpoch = currentEpoch >= currentRegistrationEndEpoch
            ? currentEpoch + 1
            : currentRegistrationEndEpoch + 1;
        uint16 endEpoch = startEpoch + numberOfEpochs - 1;

        for (uint16 epoch = startEpoch; epoch <= endEpoch; ) {
            ILendingManager(lendingManager).borrow(Constants.BORROW_AMOUNT_FOR_SENTINEL_REGISTRATION, epoch, sentinel);
            unchecked {
                ++epoch;
            }
        }

        uint16 effectiveStartEpoch = currentEpoch >= currentRegistrationEndEpoch
            ? startEpoch
            : currentRegistrationStartEpoch;

        _updateSentinelRegistration(
            sentinel,
            owner,
            effectiveStartEpoch,
            endEpoch,
            Constants.REGISTRATION_SENTINEL_BORROWING
        );

        emit SentinelRegistrationUpdated(
            owner,
            effectiveStartEpoch,
            endEpoch,
            sentinel,
            Constants.REGISTRATION_SENTINEL_BORROWING,
            Constants.BORROW_AMOUNT_FOR_SENTINEL_REGISTRATION
        );
    }

    function _updateSentinelRegistration(
        address sentinel,
        address owner,
        uint16 startEpoch,
        uint16 endEpoch,
        bytes1 kind
    ) internal {
        _ownersSentinel[owner] = sentinel;
        _registrations[sentinel] = Registration(owner, startEpoch, endEpoch, kind);
    }

    function _authorizeUpgrade(address) internal override onlyRole(Roles.UPGRADE_ROLE) {}
}
