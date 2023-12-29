// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ITransferManager.sol";
import "./TokenType.sol";
import "./IERC20.sol";
import "./SignatureCheckerMemory.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

import "./LowLevelWETH.sol";
import "./LowLevelERC20Transfer.sol";
import "./LowLevelERC721Transfer.sol";

import "./AccessControl.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

import "./IYolo.sol";
import "./IPriceOracle.sol";
import "./Arrays.sol";

/**
 * @title Yolo
 * @notice This contract permissionlessly hosts yolos on LooksRare.
 * @author LooksRare protocol team (👀,💎)
 */
contract Yolo is
    IYolo,
    AccessControl,
    VRFConsumerBaseV2,
    LowLevelWETH,
    LowLevelERC20Transfer,
    LowLevelERC721Transfer,
    ReentrancyGuard,
    Pausable
{
    using Arrays for uint256[];

    /**
     * @notice Operators are allowed to add/remove allowed ERC-20 and ERC-721 tokens.
     */
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
     * @notice The maximum protocol fee in basis points, which is 25%.
     */
    uint16 public constant MAXIMUM_PROTOCOL_FEE_BP = 2_500;

    /**
     * @notice Reservoir oracle's message typehash.
     * @dev It is used to compute the hash of the message using the (message) id, the payload, and the timestamp.
     */
    bytes32 private constant RESERVOIR_ORACLE_MESSAGE_TYPEHASH =
        keccak256("Message(bytes32 id,bytes payload,uint256 timestamp,uint256 chainId)");

    /**
     * @notice Reservoir oracle's ID typehash.
     * @dev It is used to compute the hash of the ID using price kind, TWAP seconds, and the contract address.
     */
    bytes32 private constant RESERVOIR_ORACLE_ID_TYPEHASH =
        keccak256(
            "ContractWideCollectionPrice(uint8 kind,uint256 twapSeconds,address contract,bool onlyNonFlaggedTokens)"
        );

    /**
     * @notice Wrapped Ether address.
     */
    address private immutable WETH;

    /**
     * @notice The key hash of the Chainlink VRF.
     */
    bytes32 private immutable KEY_HASH;

    /**
     * @notice The subscription ID of the Chainlink VRF.
     */
    uint64 public immutable SUBSCRIPTION_ID;

    /**
     * @notice The Chainlink VRF coordinator.
     */
    VRFCoordinatorV2Interface private immutable VRF_COORDINATOR;

    /**
     * @notice Transfer manager faciliates token transfers.
     */
    ITransferManager private immutable transferManager;

    /**
     * @notice The value of each entry in ETH.
     */
    uint256 public valuePerEntry;

    /**
     * @notice The duration of each round.
     */
    uint40 public roundDuration;

    /**
     * @notice The address of the protocol fee recipient.
     */
    address public protocolFeeRecipient;

    /**
     * @notice The protocol fee basis points.
     */
    uint16 public protocolFeeBp;

    /**
     * @notice Number of rounds that have been created.
     * @dev In this smart contract, roundId is an uint256 but its
     *      max value can only be 2^40 - 1. Realistically we will still
     *      not reach this number.
     */
    uint40 public roundsCount;

    /**
     * @notice The maximum number of participants per round.
     */
    uint40 public maximumNumberOfParticipantsPerRound;

    /**
     * @notice The maximum number of deposits per round.
     */
    uint40 public maximumNumberOfDepositsPerRound;

    /**
     * @notice ERC-20 oracle address.
     */
    IPriceOracle public erc20Oracle;

    /**
     * @notice Reservoir oracle address.
     */
    address public reservoirOracle;

    /**
     * @notice Reservoir oracle's signature validity period.
     */
    uint40 public signatureValidityPeriod;

    /**
     * @notice It checks whether the currency is allowed.
     * @dev 0 is not allowed, 1 is allowed.
     */
    mapping(address => uint256) public isCurrencyAllowed;

    /**
     * @dev roundId => Round
     */
    mapping(uint256 => Round) public rounds;

    /**
     * @dev roundId => depositor => depositCount
     */
    mapping(uint256 => mapping(address => uint256)) public depositCount;

    /**
     * @notice The randomness requests.
     * @dev The key is the request ID returned by Chainlink.
     */
    mapping(uint256 => RandomnessRequest) public randomnessRequests;

    /**
     * @dev Token/collection => round ID => price.
     */
    mapping(address => mapping(uint256 => uint256)) public prices;

    /**
     * @param params The constructor params.
     */
    constructor(ConstructorCalldata memory params) VRFConsumerBaseV2(params.vrfCoordinator) {
        _grantRole(DEFAULT_ADMIN_ROLE, params.owner);
        _grantRole(OPERATOR_ROLE, params.operator);
        _updateRoundDuration(params.roundDuration);
        _updateProtocolFeeRecipient(params.protocolFeeRecipient);
        _updateProtocolFeeBp(params.protocolFeeBp);
        _updateValuePerEntry(params.valuePerEntry);
        _updateERC20Oracle(params.erc20Oracle);
        _updateMaximumNumberOfDepositsPerRound(params.maximumNumberOfDepositsPerRound);
        _updateMaximumNumberOfParticipantsPerRound(params.maximumNumberOfParticipantsPerRound);
        _updateReservoirOracle(params.reservoirOracle);
        _updateSignatureValidityPeriod(params.signatureValidityPeriod);

        WETH = params.weth;
        KEY_HASH = params.keyHash;
        VRF_COORDINATOR = VRFCoordinatorV2Interface(params.vrfCoordinator);
        SUBSCRIPTION_ID = params.subscriptionId;

        transferManager = ITransferManager(params.transferManager);

        _startRound({_roundsCount: 0});
    }

    /**
     * @inheritdoc IYolo
     */
    function cancelCurrentRoundAndDepositToTheNextRound(
        DepositCalldata[] calldata deposits
    ) external payable nonReentrant whenNotPaused {
        uint256 roundId = roundsCount;
        _cancel(roundId);
        _deposit(_unsafeAdd(roundId, 1), deposits);
    }

    /**
     * @inheritdoc IYolo
     */
    function deposit(uint256 roundId, DepositCalldata[] calldata deposits) external payable nonReentrant whenNotPaused {
        _deposit(roundId, deposits);
    }

    /**
     * @inheritdoc IYolo
     */
    function getDeposits(uint256 roundId) external view returns (Deposit[] memory) {
        return rounds[roundId].deposits;
    }

    function drawWinner() external nonReentrant whenNotPaused {
        uint256 roundId = roundsCount;
        Round storage round = rounds[roundId];

        _validateRoundStatus(round, RoundStatus.Open);

        if (block.timestamp < round.cutoffTime) {
            revert CutoffTimeNotReached();
        }

        if (round.numberOfParticipants < 2) {
            revert InsufficientParticipants();
        }

        _drawWinner(round, roundId);
    }

    function cancel() external nonReentrant whenNotPaused {
        _cancel({roundId: roundsCount});
    }

    /**
     * @inheritdoc IYolo
     */
    function cancelAfterRandomnessRequest() external nonReentrant whenNotPaused {
        uint256 roundId = roundsCount;
        Round storage round = rounds[roundId];

        _validateRoundStatus(round, RoundStatus.Drawing);

        if (block.timestamp < round.drawnAt + 1 days) {
            revert DrawExpirationTimeNotReached();
        }

        round.status = RoundStatus.Cancelled;

        emit RoundStatusUpdated(roundId, RoundStatus.Cancelled);

        _startRound({_roundsCount: roundId});
    }

    /**
     * @inheritdoc IYolo
     */
    function claimPrizes(
        ClaimPrizesCalldata[] calldata claimPrizesCalldata
    ) external payable nonReentrant whenNotPaused {
        TransferAccumulator memory transferAccumulator;
        uint256 ethAmount;
        uint256 protocolFeeOwed;

        for (uint256 i; i < claimPrizesCalldata.length; ) {
            ClaimPrizesCalldata calldata perRoundClaimPrizesCalldata = claimPrizesCalldata[i];

            Round storage round = rounds[perRoundClaimPrizesCalldata.roundId];

            _validateRoundStatus(round, RoundStatus.Drawn);

            if (msg.sender != round.winner) {
                revert NotWinner();
            }

            uint256[] calldata prizeIndices = perRoundClaimPrizesCalldata.prizeIndices;

            for (uint256 j; j < prizeIndices.length; ) {
                uint256 index = prizeIndices[j];
                if (index >= round.deposits.length) {
                    revert InvalidIndex();
                }

                Deposit storage prize = round.deposits[index];

                if (prize.withdrawn) {
                    revert AlreadyWithdrawn();
                }

                prize.withdrawn = true;

                TokenType tokenType = prize.tokenType;
                if (tokenType == TokenType.ETH) {
                    ethAmount += prize.tokenAmount;
                } else if (tokenType == TokenType.ERC721) {
                    _executeERC721TransferFrom(prize.tokenAddress, address(this), msg.sender, prize.tokenId);
                } else if (tokenType == TokenType.ERC20) {
                    address prizeAddress = prize.tokenAddress;
                    if (prizeAddress == transferAccumulator.tokenAddress) {
                        transferAccumulator.amount += prize.tokenAmount;
                    } else {
                        if (transferAccumulator.amount != 0) {
                            _executeERC20DirectTransfer(
                                transferAccumulator.tokenAddress,
                                msg.sender,
                                transferAccumulator.amount
                            );
                        }

                        transferAccumulator.tokenAddress = prizeAddress;
                        transferAccumulator.amount = prize.tokenAmount;
                    }
                }

                unchecked {
                    ++j;
                }
            }

            protocolFeeOwed += round.protocolFeeOwed;
            round.protocolFeeOwed = 0;

            emit PrizesClaimed(perRoundClaimPrizesCalldata.roundId, msg.sender, prizeIndices);

            unchecked {
                ++i;
            }
        }

        if (protocolFeeOwed != 0) {
            _transferETHAndWrapIfFailWithGasLimit(WETH, protocolFeeRecipient, protocolFeeOwed, gasleft());

            protocolFeeOwed -= msg.value;
            if (protocolFeeOwed < ethAmount) {
                unchecked {
                    ethAmount -= protocolFeeOwed;
                }
                protocolFeeOwed = 0;
            } else {
                unchecked {
                    protocolFeeOwed -= ethAmount;
                }
                ethAmount = 0;
            }

            if (protocolFeeOwed != 0) {
                revert ProtocolFeeNotPaid();
            }
        }

        if (transferAccumulator.amount != 0) {
            _executeERC20DirectTransfer(transferAccumulator.tokenAddress, msg.sender, transferAccumulator.amount);
        }

        if (ethAmount != 0) {
            _transferETHAndWrapIfFailWithGasLimit(WETH, msg.sender, ethAmount, gasleft());
        }
    }

    /**
     * @inheritdoc IYolo
     * @dev This function does not validate claimPrizesCalldata to not contain duplicate round IDs and prize indices.
     *      It is the responsibility of the caller to ensure that. Otherwise, the returned protocol fee owed will be incorrect.
     */
    function getClaimPrizesPaymentRequired(
        ClaimPrizesCalldata[] calldata claimPrizesCalldata
    ) external view returns (uint256 protocolFeeOwed) {
        uint256 ethAmount;

        for (uint256 i; i < claimPrizesCalldata.length; ) {
            ClaimPrizesCalldata calldata perRoundClaimPrizesCalldata = claimPrizesCalldata[i];
            Round storage round = rounds[perRoundClaimPrizesCalldata.roundId];

            _validateRoundStatus(round, RoundStatus.Drawn);

            uint256[] calldata prizeIndices = perRoundClaimPrizesCalldata.prizeIndices;
            uint256 numberOfPrizes = prizeIndices.length;
            uint256 prizesCount = round.deposits.length;

            for (uint256 j; j < numberOfPrizes; ) {
                uint256 index = prizeIndices[j];
                if (index >= prizesCount) {
                    revert InvalidIndex();
                }

                Deposit storage prize = round.deposits[index];
                if (prize.tokenType == TokenType.ETH) {
                    ethAmount += prize.tokenAmount;
                }

                unchecked {
                    ++j;
                }
            }

            protocolFeeOwed += round.protocolFeeOwed;

            unchecked {
                ++i;
            }
        }

        if (protocolFeeOwed < ethAmount) {
            protocolFeeOwed = 0;
        } else {
            unchecked {
                protocolFeeOwed -= ethAmount;
            }
        }
    }

    /**
     * @inheritdoc IYolo
     */
    function withdrawDeposits(uint256 roundId, uint256[] calldata depositIndices) external nonReentrant whenNotPaused {
        Round storage round = rounds[roundId];

        _validateRoundStatus(round, RoundStatus.Cancelled);

        uint256 numberOfDeposits = depositIndices.length;
        uint256 depositsCount = round.deposits.length;
        uint256 ethAmount;

        for (uint256 i; i < numberOfDeposits; ) {
            uint256 index = depositIndices[i];
            if (index >= depositsCount) {
                revert InvalidIndex();
            }

            Deposit storage depositedToken = round.deposits[index];
            if (depositedToken.depositor != msg.sender) {
                revert NotDepositor();
            }

            if (depositedToken.withdrawn) {
                revert AlreadyWithdrawn();
            }

            depositedToken.withdrawn = true;

            TokenType tokenType = depositedToken.tokenType;
            if (tokenType == TokenType.ETH) {
                ethAmount += depositedToken.tokenAmount;
            } else if (tokenType == TokenType.ERC721) {
                _executeERC721TransferFrom(
                    depositedToken.tokenAddress,
                    address(this),
                    msg.sender,
                    depositedToken.tokenId
                );
            } else if (tokenType == TokenType.ERC20) {
                _executeERC20DirectTransfer(depositedToken.tokenAddress, msg.sender, depositedToken.tokenAmount);
            }

            unchecked {
                ++i;
            }
        }

        if (ethAmount != 0) {
            _transferETHAndWrapIfFailWithGasLimit(WETH, msg.sender, ethAmount, gasleft());
        }

        emit DepositsWithdrawn(roundId, msg.sender, depositIndices);
    }

    /**
     * @inheritdoc IYolo
     */
    function togglePaused() external {
        _validateIsOwner();
        paused() ? _unpause() : _pause();
    }

    /**
     * @inheritdoc IYolo
     */
    function updateCurrenciesStatus(address[] calldata currencies, bool isAllowed) external {
        _validateIsOperator();

        uint256 count = currencies.length;
        for (uint256 i; i < count; ) {
            isCurrencyAllowed[currencies[i]] = (isAllowed ? 1 : 0);
            unchecked {
                ++i;
            }
        }
        emit CurrenciesStatusUpdated(currencies, isAllowed);
    }

    /**
     * @inheritdoc IYolo
     */
    function updateRoundDuration(uint40 _roundDuration) external {
        _validateIsOwner();
        _updateRoundDuration(_roundDuration);
    }

    /**
     * @inheritdoc IYolo
     */
    function updateSignatureValidityPeriod(uint40 _signatureValidityPeriod) external {
        _validateIsOwner();
        _updateSignatureValidityPeriod(_signatureValidityPeriod);
    }

    /**
     * @inheritdoc IYolo
     */
    function updateValuePerEntry(uint256 _valuePerEntry) external {
        _validateIsOwner();
        _updateValuePerEntry(_valuePerEntry);
    }

    /**
     * @inheritdoc IYolo
     */
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external {
        _validateIsOwner();
        _updateProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @inheritdoc IYolo
     */
    function updateProtocolFeeBp(uint16 _protocolFeeBp) external {
        _validateIsOwner();
        _updateProtocolFeeBp(_protocolFeeBp);
    }

    /**
     * @inheritdoc IYolo
     */
    function updateMaximumNumberOfDepositsPerRound(uint40 _maximumNumberOfDepositsPerRound) external {
        _validateIsOwner();
        _updateMaximumNumberOfDepositsPerRound(_maximumNumberOfDepositsPerRound);
    }

    /**
     * @inheritdoc IYolo
     */
    function updateMaximumNumberOfParticipantsPerRound(uint40 _maximumNumberOfParticipantsPerRound) external {
        _validateIsOwner();
        _updateMaximumNumberOfParticipantsPerRound(_maximumNumberOfParticipantsPerRound);
    }

    /**
     * @inheritdoc IYolo
     */
    function updateReservoirOracle(address _reservoirOracle) external {
        _validateIsOwner();
        _updateReservoirOracle(_reservoirOracle);
    }

    /**
     * @inheritdoc IYolo
     */
    function updateERC20Oracle(address _erc20Oracle) external {
        _validateIsOwner();
        _updateERC20Oracle(_erc20Oracle);
    }

    function _validateIsOwner() private view {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert NotOwner();
        }
    }

    function _validateIsOperator() private view {
        if (!hasRole(OPERATOR_ROLE, msg.sender)) {
            revert NotOperator();
        }
    }

    /**
     * @param _roundDuration The duration of each round.
     */
    function _updateRoundDuration(uint40 _roundDuration) private {
        if (_roundDuration > 1 hours) {
            revert InvalidRoundDuration();
        }

        roundDuration = _roundDuration;
        emit RoundDurationUpdated(_roundDuration);
    }

    /**
     * @param _signatureValidityPeriod The validity period of a Reservoir signature.
     */
    function _updateSignatureValidityPeriod(uint40 _signatureValidityPeriod) private {
        signatureValidityPeriod = _signatureValidityPeriod;
        emit SignatureValidityPeriodUpdated(_signatureValidityPeriod);
    }

    /**
     * @param _valuePerEntry The value of each entry in ETH.
     */
    function _updateValuePerEntry(uint256 _valuePerEntry) private {
        if (_valuePerEntry == 0) {
            revert InvalidValue();
        }
        valuePerEntry = _valuePerEntry;
        emit ValuePerEntryUpdated(_valuePerEntry);
    }

    /**
     * @param _protocolFeeRecipient The new protocol fee recipient address
     */
    function _updateProtocolFeeRecipient(address _protocolFeeRecipient) private {
        if (_protocolFeeRecipient == address(0)) {
            revert InvalidValue();
        }
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
    }

    /**
     * @param _protocolFeeBp The new protocol fee in basis points
     */
    function _updateProtocolFeeBp(uint16 _protocolFeeBp) private {
        if (_protocolFeeBp > MAXIMUM_PROTOCOL_FEE_BP) {
            revert InvalidValue();
        }
        protocolFeeBp = _protocolFeeBp;
        emit ProtocolFeeBpUpdated(_protocolFeeBp);
    }

    /**
     * @param _maximumNumberOfDepositsPerRound The new maximum number of deposits per round
     */
    function _updateMaximumNumberOfDepositsPerRound(uint40 _maximumNumberOfDepositsPerRound) private {
        maximumNumberOfDepositsPerRound = _maximumNumberOfDepositsPerRound;
        emit MaximumNumberOfDepositsPerRoundUpdated(_maximumNumberOfDepositsPerRound);
    }

    /**
     * @param _maximumNumberOfParticipantsPerRound The new maximum number of participants per round
     */
    function _updateMaximumNumberOfParticipantsPerRound(uint40 _maximumNumberOfParticipantsPerRound) private {
        if (_maximumNumberOfParticipantsPerRound < 2) {
            revert InvalidValue();
        }
        maximumNumberOfParticipantsPerRound = _maximumNumberOfParticipantsPerRound;
        emit MaximumNumberOfParticipantsPerRoundUpdated(_maximumNumberOfParticipantsPerRound);
    }

    /**
     * @param _reservoirOracle The new Reservoir oracle address
     */
    function _updateReservoirOracle(address _reservoirOracle) private {
        if (_reservoirOracle == address(0)) {
            revert InvalidValue();
        }
        reservoirOracle = _reservoirOracle;
        emit ReservoirOracleUpdated(_reservoirOracle);
    }

    /**
     * @param _erc20Oracle The new ERC-20 oracle address
     */
    function _updateERC20Oracle(address _erc20Oracle) private {
        if (_erc20Oracle == address(0)) {
            revert InvalidValue();
        }
        erc20Oracle = IPriceOracle(_erc20Oracle);
        emit ERC20OracleUpdated(_erc20Oracle);
    }

    /**
     * @param _roundsCount The current rounds count
     */
    function _startRound(uint256 _roundsCount) private returns (uint256 roundId) {
        unchecked {
            roundId = _roundsCount + 1;
        }
        roundsCount = uint40(roundId);
        rounds[roundId].status = RoundStatus.Open;
        rounds[roundId].protocolFeeBp = protocolFeeBp;
        rounds[roundId].cutoffTime = uint40(block.timestamp) + roundDuration;
        rounds[roundId].maximumNumberOfDeposits = maximumNumberOfDepositsPerRound;
        rounds[roundId].maximumNumberOfParticipants = maximumNumberOfParticipantsPerRound;
        rounds[roundId].valuePerEntry = valuePerEntry;

        emit RoundStatusUpdated(roundId, RoundStatus.Open);
    }

    /**
     * @param round The open round.
     * @param roundId The open round ID.
     */
    function _drawWinner(Round storage round, uint256 roundId) private {
        round.status = RoundStatus.Drawing;
        round.drawnAt = uint40(block.timestamp);

        uint256 requestId = VRF_COORDINATOR.requestRandomWords({
            keyHash: KEY_HASH,
            subId: SUBSCRIPTION_ID,
            minimumRequestConfirmations: uint16(3),
            callbackGasLimit: uint32(500_000),
            numWords: uint32(1)
        });

        if (randomnessRequests[requestId].exists) {
            revert RandomnessRequestAlreadyExists();
        }

        randomnessRequests[requestId].exists = true;
        randomnessRequests[requestId].roundId = uint40(roundId);

        emit RandomnessRequested(roundId, requestId);
        emit RoundStatusUpdated(roundId, RoundStatus.Drawing);
    }

    /**
     * @param roundId The open round ID.
     * @param deposits The ERC-20/ERC-721 deposits to be made.
     */
    function _deposit(uint256 roundId, DepositCalldata[] calldata deposits) private {
        Round storage round = rounds[roundId];
        if (round.status != RoundStatus.Open || block.timestamp >= round.cutoffTime) {
            revert InvalidStatus();
        }

        uint256 userDepositCount = depositCount[roundId][msg.sender];
        if (userDepositCount == 0) {
            unchecked {
                ++round.numberOfParticipants;
            }
        }
        uint256 roundDepositCount = round.deposits.length;
        uint40 currentEntryIndex;
        uint256 totalEntriesCount;

        uint256 depositsCalldataLength = deposits.length;
        if (msg.value == 0) {
            if (depositsCalldataLength == 0) {
                revert ZeroDeposits();
            }
        } else {
            uint256 roundValuePerEntry = round.valuePerEntry;
            if (msg.value % roundValuePerEntry != 0) {
                revert InvalidValue();
            }
            uint256 entriesCount = msg.value / roundValuePerEntry;
            totalEntriesCount += entriesCount;

            currentEntryIndex = _getCurrentEntryIndexWithoutAccrual(round, roundDepositCount, entriesCount);

            round.deposits.push(
                Deposit({
                    tokenType: TokenType.ETH,
                    tokenAddress: address(0),
                    tokenId: 0,
                    tokenAmount: msg.value,
                    depositor: msg.sender,
                    withdrawn: false,
                    currentEntryIndex: currentEntryIndex
                })
            );

            unchecked {
                roundDepositCount += 1;
            }
        }

        if (depositsCalldataLength != 0) {
            ITransferManager.BatchTransferItem[] memory batchTransferItems = new ITransferManager.BatchTransferItem[](
                depositsCalldataLength
            );
            for (uint256 i; i < depositsCalldataLength; ) {
                DepositCalldata calldata singleDeposit = deposits[i];
                if (isCurrencyAllowed[singleDeposit.tokenAddress] != 1) {
                    revert InvalidCollection();
                }
                uint256 price = prices[singleDeposit.tokenAddress][roundId];
                if (singleDeposit.tokenType == TokenType.ERC721) {
                    if (price == 0) {
                        price = _getReservoirPrice(singleDeposit);
                        prices[singleDeposit.tokenAddress][roundId] = price;
                    }

                    uint256 entriesCount = price / round.valuePerEntry;
                    if (entriesCount == 0) {
                        revert InvalidValue();
                    }

                    uint256 tokenIdsLength = singleDeposit.tokenIdsOrAmounts.length;
                    uint256[] memory amounts = new uint256[](tokenIdsLength);
                    for (uint256 j; j < tokenIdsLength; ) {
                        totalEntriesCount += entriesCount;

                        if (currentEntryIndex != 0) {
                            currentEntryIndex += uint40(entriesCount);
                        } else {
                            currentEntryIndex = _getCurrentEntryIndexWithoutAccrual(
                                round,
                                roundDepositCount,
                                entriesCount
                            );
                        }

                        // tokenAmount is in reality 1, but we never use it and it is cheaper to set it as 0.
                        round.deposits.push(
                            Deposit({
                                tokenType: TokenType.ERC721,
                                tokenAddress: singleDeposit.tokenAddress,
                                tokenId: singleDeposit.tokenIdsOrAmounts[j],
                                tokenAmount: 0,
                                depositor: msg.sender,
                                withdrawn: false,
                                currentEntryIndex: currentEntryIndex
                            })
                        );

                        amounts[j] = 1;

                        unchecked {
                            ++j;
                        }
                    }

                    unchecked {
                        roundDepositCount += tokenIdsLength;
                    }

                    batchTransferItems[i].tokenAddress = singleDeposit.tokenAddress;
                    batchTransferItems[i].tokenType = TransferManagerTokenType.ERC721;
                    batchTransferItems[i].itemIds = singleDeposit.tokenIdsOrAmounts;
                    batchTransferItems[i].amounts = amounts;
                } else if (singleDeposit.tokenType == TokenType.ERC20) {
                    if (price == 0) {
                        price = erc20Oracle.getTWAP(singleDeposit.tokenAddress, uint32(3_600));
                        prices[singleDeposit.tokenAddress][roundId] = price;
                    }

                    uint256[] memory amounts = singleDeposit.tokenIdsOrAmounts;
                    if (amounts.length != 1) {
                        revert InvalidLength();
                    }

                    uint256 amount = amounts[0];

                    uint256 entriesCount = ((price * amount) / (10 ** IERC20(singleDeposit.tokenAddress).decimals())) /
                        round.valuePerEntry;
                    if (entriesCount == 0) {
                        revert InvalidValue();
                    }

                    totalEntriesCount += entriesCount;

                    if (currentEntryIndex != 0) {
                        currentEntryIndex += uint40(entriesCount);
                    } else {
                        currentEntryIndex = _getCurrentEntryIndexWithoutAccrual(round, roundDepositCount, entriesCount);
                    }

                    round.deposits.push(
                        Deposit({
                            tokenType: TokenType.ERC20,
                            tokenAddress: singleDeposit.tokenAddress,
                            tokenId: 0,
                            tokenAmount: amount,
                            depositor: msg.sender,
                            withdrawn: false,
                            currentEntryIndex: currentEntryIndex
                        })
                    );

                    unchecked {
                        roundDepositCount += 1;
                    }

                    batchTransferItems[i].tokenAddress = singleDeposit.tokenAddress;
                    batchTransferItems[i].tokenType = TransferManagerTokenType.ERC20;
                    batchTransferItems[i].amounts = singleDeposit.tokenIdsOrAmounts;
                } else {
                    revert InvalidTokenType();
                }

                unchecked {
                    ++i;
                }
            }

            transferManager.transferBatchItemsAcrossCollections(batchTransferItems, msg.sender, address(this));
        }

        {
            uint256 maximumNumberOfDeposits = round.maximumNumberOfDeposits;
            if (roundDepositCount > maximumNumberOfDeposits) {
                revert MaximumNumberOfDepositsReached();
            }

            uint256 numberOfParticipants = round.numberOfParticipants;

            if (
                numberOfParticipants == round.maximumNumberOfParticipants ||
                (numberOfParticipants > 1 && roundDepositCount == maximumNumberOfDeposits)
            ) {
                _drawWinner(round, roundId);
            }
        }

        unchecked {
            depositCount[roundId][msg.sender] = userDepositCount + 1;
        }

        emit Deposited(msg.sender, roundId, totalEntriesCount);
    }

    /**
     * @param roundId The ID of the round to be cancelled.
     */
    function _cancel(uint256 roundId) private {
        Round storage round = rounds[roundId];

        _validateRoundStatus(round, RoundStatus.Open);

        if (block.timestamp < round.cutoffTime) {
            revert CutoffTimeNotReached();
        }

        if (round.numberOfParticipants > 1) {
            revert RoundCannotBeClosed();
        }

        round.status = RoundStatus.Cancelled;

        emit RoundStatusUpdated(roundId, RoundStatus.Cancelled);

        _startRound({_roundsCount: roundId});
    }

    /**
     * @param requestId The ID of the request
     * @param randomWords The random words returned by Chainlink
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        if (randomnessRequests[requestId].exists) {
            uint256 roundId = randomnessRequests[requestId].roundId;
            Round storage round = rounds[roundId];

            if (round.status == RoundStatus.Drawing) {
                round.status = RoundStatus.Drawn;
                uint256 randomWord = randomWords[0];
                randomnessRequests[requestId].randomWord = randomWord;

                uint256 count = round.deposits.length;
                uint256[] memory currentEntryIndexArray = new uint256[](count);
                for (uint256 i; i < count; ) {
                    currentEntryIndexArray[i] = uint256(round.deposits[i].currentEntryIndex);
                    unchecked {
                        ++i;
                    }
                }

                uint256 currentEntryIndex = currentEntryIndexArray[_unsafeSubtract(count, 1)];
                uint256 entriesSold = _unsafeAdd(currentEntryIndex, 1);
                uint256 winningEntry = uint256(randomWord) % entriesSold;
                round.winner = round.deposits[currentEntryIndexArray.findUpperBound(winningEntry)].depositor;
                round.protocolFeeOwed = (round.valuePerEntry * entriesSold * round.protocolFeeBp) / 10_000;

                emit RoundStatusUpdated(roundId, RoundStatus.Drawn);

                _startRound({_roundsCount: roundId});
            }
        }
    }

    /**
     * @param round The round to check the status of.
     * @param status The expected status of the round
     */
    function _validateRoundStatus(Round storage round, RoundStatus status) private view {
        if (round.status != status) {
            revert InvalidStatus();
        }
    }

    /**
     * @param collection The collection address.
     * @param floorPrice The floor price response from Reservoir oracle.
     */
    function _verifyReservoirSignature(address collection, ReservoirOracleFloorPrice calldata floorPrice) private view {
        if (block.timestamp > floorPrice.timestamp + uint256(signatureValidityPeriod)) {
            revert SignatureExpired();
        }

        bytes32 expectedMessageId = keccak256(
            abi.encode(RESERVOIR_ORACLE_ID_TYPEHASH, uint8(1), 86_400, collection, false)
        );

        if (expectedMessageId != floorPrice.id) {
            revert MessageIdInvalid();
        }

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(
                        RESERVOIR_ORACLE_MESSAGE_TYPEHASH,
                        expectedMessageId,
                        keccak256(floorPrice.payload),
                        floorPrice.timestamp,
                        block.chainid
                    )
                )
            )
        );

        SignatureCheckerMemory.verify(messageHash, reservoirOracle, floorPrice.signature);
    }

    function _getReservoirPrice(DepositCalldata calldata singleDeposit) private view returns (uint256 price) {
        address currency;
        _verifyReservoirSignature(singleDeposit.tokenAddress, singleDeposit.reservoirOracleFloorPrice);
        (currency, price) = abi.decode(singleDeposit.reservoirOracleFloorPrice.payload, (address, uint256));
        if (currency != address(0)) {
            revert InvalidCurrency();
        }
    }

    /**
     * @param round The open round.
     * @param roundDepositCount The number of deposits in the round.
     * @param entriesCount The number of entries to be added.
     */
    function _getCurrentEntryIndexWithoutAccrual(
        Round storage round,
        uint256 roundDepositCount,
        uint256 entriesCount
    ) private view returns (uint40 currentEntryIndex) {
        if (roundDepositCount == 0) {
            currentEntryIndex = uint40(_unsafeSubtract(entriesCount, 1));
        } else {
            currentEntryIndex = uint40(
                round.deposits[_unsafeSubtract(roundDepositCount, 1)].currentEntryIndex + entriesCount
            );
        }
    }

    /**
     * Unsafe math functions.
     */

    function _unsafeAdd(uint256 a, uint256 b) private pure returns (uint256) {
        unchecked {
            return a + b;
        }
    }

    function _unsafeSubtract(uint256 a, uint256 b) private pure returns (uint256) {
        unchecked {
            return a - b;
        }
    }
}
