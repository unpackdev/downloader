// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Owned.sol";
import "./ERC20.sol";
import "./ECDSA.sol";
import "./EIP712.sol";

import "./IArbitrator.sol";

contract Arbitrator is Owned, IArbitrator, EIP712 {
    using ECDSA for bytes32;

    /// Minimum random value
    uint256 private constant RAND_MIN = 1;
    /// Maximum random value
    uint256 private constant RAND_MAX = 25;
    /// Ante percentage e.g 1000 / 10000 = .1 = 10%
    uint128 private constant ANTE = 1000;
    /// Denominator for percentage values e.g 1000 / 10000 = .1 = 10%
    uint128 private constant DENOMINATOR = 10000;
    /// Maximum allowed fee percentage
    uint128 private constant MAX_FEE = 1000;
    /// Number of blocks before a given game can begin
    uint64 private constant START_DELAY = 99 seconds;
    /// TODO ? Time between turns ?
    uint64 private constant DEFAULT_CADENCE = 99 seconds;
    /// Minimum number of players in a given game
    uint8 private constant MIN_SEATS = 2;
    /// Maximum number of players in a given game
    uint8 private constant MAX_SEATS = 100;
    /// Randomness function signature
    bytes32 private constant RANDOMNESS_TYPEHASH =
        keccak256("Randomness(uint256 randomness,uint64 counter,uint256 id)");

    /// Fee receiver address
    address public feeController;
    /// Current fee percentage
    uint128 public fee = 500;
    /// Latest created game (array index)
    uint256 public currentId;
    /// Randomness supplier/signer address
    address public rngSource;

    /// Bitmasked of allowed game modes
    uint256 private modeAllowlist;
    /// Current game balances
    mapping(address => uint256) private balances;
    /// Arrays of participants based on tontine ID
    mapping(uint256 => address[]) private participants;
    /// Assets allowed for game use
    mapping(address => bool) private assetAllowlist;
    /// Tontines
    mapping(uint256 => Tontine) private tontines;
    /// Activity tracking
    mapping(bytes32 => bool) private activityLog;

    constructor(
        address _admin,
        address _feeController,
        address _rngSource
    ) Owned(_admin) EIP712("Tontine", "1") {
        feeController = _feeController;
        rngSource = _rngSource;
    }

    /// @notice Create a new Tontine
    /// @param _asset Game currency to be used
    /// @param _bet Starting bet amount
    /// @param _seats Number of players
    /// @param _betMode Lobby betting mode
    /// @param _rngMode Lobby RNG mode
    function create(
        address _asset,
        uint128 _bet,
        uint8 _seats,
        BetMode _betMode,
        RNGMode _rngMode
    ) external payable {
        if (tx.origin != msg.sender) revert NotEOA();
        if (_seats < MIN_SEATS || _seats > MAX_SEATS) revert InvalidSeatCount();
        if (_bet == 0) revert InvalidBet();
        if (!getBetModeAllowed(_betMode) || !getRNGModeAllowed(_rngMode))
            revert InvalidMode();
        if (!assetAllowlist[_asset]) revert InvalidAsset();

        Tontine storage tontine = tontines[currentId];
        tontine.asset = _asset;
        tontine.seats = _seats;
        tontine.betMode = _betMode;
        tontine.rngMode = _rngMode;
        tontine.bet = _bet;
        tontine.balance = _bet;
        tontine.participantState = 1 << 127;

        participants[currentId].push(msg.sender);
        unchecked {
            balances[_asset] += _bet;
            currentId++;
        }

        activityLog[
            _getParticipantIdentifier(msg.sender, currentId - 1)
        ] = true;

        if (_asset == address(0)) {
            if (msg.value != _bet) revert InvalidBet();
        } else {
            if (msg.value > 0) revert InvalidBet();
            ERC20(_asset).transferFrom(msg.sender, address(this), _bet);
        }

        emit Created(currentId - 1, _bet, _asset);
        emit Joined(currentId - 1, msg.sender);
    }

    /// @notice Join an existing Tontine
    /// @param _id Tontine ID
    function join(uint256 _id) external payable {
        Tontine storage tontine = tontines[_id];
        address asset = tontine.asset;
        uint128 bet = tontine.bet;

        if (tx.origin != msg.sender) revert NotEOA();
        if (tontine.lastBetTime != 0) revert AlreadyStarted();
        // If the ID doesn't exist it will revert as "Ended"
        if (tontine.participantState == 0) revert Ended();

        bytes32 participantId = _getParticipantIdentifier(msg.sender, _id);
        if (activityLog[participantId]) revert AlreadyJoined();

        uint8 participantLength = uint8(participants[_id].length);

        unchecked {
            tontine.participantState |= uint128(1 << (127 - participantLength));
            tontine.balance += bet;
            balances[asset] += bet;
        }

        participants[_id].push(msg.sender);
        activityLog[participantId] = true;

        // Start round if full
        if (++participantLength == tontine.seats) {
            // Schedule start time
            tontine.lastBetTime = uint64(block.timestamp) + START_DELAY;
            // Scramble order to keep odds uniform
            tontine.lastIndex = _scramble(tontine.seats);

            // Deduct fee on start such that participants are not charged fees when leaving
            uint128 feeDelta = tontine.balance -
                _getBetAfterFee(tontine.balance);
            unchecked {
                tontine.balance -= feeDelta;
                balances[asset] -= feeDelta;
            }

            emit Started(_id);
        }

        if (asset == address(0)) {
            if (msg.value != bet) revert InvalidBet();
        } else {
            if (msg.value != 0) revert InvalidBet();
            ERC20(asset).transferFrom(msg.sender, address(this), bet);
        }

        emit Joined(currentId, msg.sender);
    }

    /// @notice Leave a tontine lobby (that hasn't started yet)
    /// @param _id Tontine ID
    /// @param _index Participant array ID
    function leave(uint256 _id, uint8 _index) external {
        Tontine storage tontine = tontines[_id];
        address[] storage participantArray = participants[_id];

        if (tx.origin != msg.sender) revert NotEOA();
        if (tontine.lastBetTime != 0) revert AlreadyStarted();
        if (participantArray[_index] != msg.sender) revert NotJoined();

        uint128 bet = tontine.bet;
        address asset = tontine.asset;
        unchecked {
            balances[tontine.asset] -= bet;
            tontine.balance -= bet;
        }

        // Clear state
        if (participantArray.length <= 1) {
            delete participants[_id];
            delete tontines[_id];
            emit Claimed(_id, address(0), address(0), 0);
        } else {
            participantArray[_index] = participantArray[
                participantArray.length - 1
            ];
            participantArray.pop();
            tontine.participantState ^= uint128(
                1 << (127 - participantArray.length)
            );
        }

        delete activityLog[_getParticipantIdentifier(msg.sender, _id)];

        // Return funds
        if (asset == address(0)) {
            payable(msg.sender).transfer(bet);
        } else {
            ERC20(asset).transfer(msg.sender, bet);
        }

        emit Left(_id, msg.sender);
    }

    /// @notice Leave an already started game - funds will NOT be returned
    /// @param _id Tontine ID
    /// @param _index Participant array ID
    function fold(uint256 _id, uint8 _index) external {
        Tontine storage tontine = tontines[_id];
        uint64 lastBetTime = tontine.lastBetTime;

        if (tx.origin != msg.sender) revert NotEOA();
        if (lastBetTime == 0 || lastBetTime > block.timestamp)
            revert NotStarted();
        if (participants[_id][_index] != msg.sender) revert NotJoined();

        (
            uint128 participantState,
            bool ended,
            uint256 currentIndex
        ) = _updateParticipantState(
                tontine.participantState,
                tontine.lastIndex,
                lastBetTime,
                tontine.seats
            );

        if (currentIndex != _index) revert NotTurn();
        if (ended || _isLastAlive(participantState, _index)) revert Ended();
        if (!_isAlive(participantState, _index)) revert PlayerNotAlive();

        tontine.participantState = _killPlayer(participantState, _index);
        tontine.lastIndex = _index;
        tontine.lastBetTime = uint64(block.timestamp);
        ++tontine.counter;

        emit Folded(_id, msg.sender);
    }

    /// Play your turn
    /// @param _id Tontine ID
    /// @param _index Participant array ID
    /// @param _bet Bet amount in  wei
    /// @param _rng Randomness data
    /// @param _sig Signed randomness data
    function play(
        uint256 _id,
        uint8 _index,
        uint128 _bet,
        Randomness calldata _rng,
        bytes calldata _sig
    ) external payable {
        Tontine storage tontine = tontines[_id];
        uint64 lastBetTime = tontine.lastBetTime;

        if (tx.origin != msg.sender) revert NotEOA();
        if (lastBetTime == 0 || lastBetTime > block.timestamp)
            revert NotStarted();
        if (participants[_id][_index] != msg.sender) revert NotJoined();

        if (tontine.counter > 0 && tontine.rngMode == RNGMode.RANDOM) {
            uint32 counter = tontine.counter;
            if (_rng.id != _id) revert InvalidID();
            if (_rng.counter != counter) revert InvalidCounter();
            _validateRandomness(_rng, _sig);

            if (
                _shouldKillLastPlayer(
                    _id,
                    counter,
                    tontine.rngMode,
                    _rng.randomness
                )
            ) {
                tontine.participantState = _killPlayer(
                    tontine.participantState,
                    tontine.lastIndex
                );
            }
        }

        (
            uint128 participantState,
            bool ended,
            uint256 currentIndex
        ) = _updateParticipantState(
                tontine.participantState,
                tontine.lastIndex,
                lastBetTime,
                tontine.seats
            );

        if (currentIndex != _index) revert NotTurn();
        if (ended || _isLastAlive(participantState, _index)) revert Ended();

        // Handling for alternate bet modes
        if (_bet >= tontine.bet && tontine.betMode == BetMode.VARIABLE) {
            tontine.bet = _bet;
        } else if (tontine.betMode == BetMode.ANTE) {
            tontine.bet = (tontine.bet * (DENOMINATOR + ANTE)) / DENOMINATOR;
        }

        uint128 betAfterFee = _getBetAfterFee(tontine.bet);
        tontine.balance += betAfterFee;
        balances[tontine.asset] += betAfterFee;
        tontine.lastBetTime = uint64(block.timestamp);
        tontine.lastIndex = _index;
        tontine.participantState = participantState;
        ++tontine.counter;

        if (tontine.asset == address(0)) {
            if (msg.value != tontine.bet) revert InvalidBet();
        } else {
            if (msg.value > 0) revert InvalidBet();
            ERC20(tontine.asset).transferFrom(
                msg.sender,
                address(this),
                tontine.bet
            );
        }

        emit Played(_id, msg.sender, tontine.bet);
    }

    /// @notice Claim winnings when you're the last person standing
    /// @param _id Tontine ID
    /// @param _index Participant array ID
    /// @param _rng Randomness data
    /// @param _sig Signed randomness data
    function claim(
        uint256 _id,
        uint8 _index,
        Randomness calldata _rng,
        bytes calldata _sig
    ) external {
        Tontine storage tontine = tontines[_id];
        uint64 lastBetTime = tontine.lastBetTime;

        if (tx.origin != msg.sender) revert NotEOA();
        if (tontine.participantState == 0) revert AlreadyClaimed();
        if (lastBetTime == 0 || lastBetTime > block.timestamp)
            revert NotStarted();
        if (participants[_id][_index] != msg.sender) revert NotJoined();

        if (tontine.counter > 0 && tontine.rngMode == RNGMode.RANDOM) {
            uint32 counter = tontine.counter;
            if (_rng.id != _id) revert InvalidID();
            if (_rng.counter != counter) revert InvalidCounter();
            _validateRandomness(_rng, _sig);

            if (
                _shouldKillLastPlayer(
                    _id,
                    counter,
                    tontine.rngMode,
                    _rng.randomness
                )
            ) {
                tontine.participantState = _killPlayer(
                    tontine.participantState,
                    tontine.lastIndex
                );
            }
        }

        (uint128 participantState, bool ended, ) = _updateParticipantState(
            tontine.participantState,
            tontine.lastIndex,
            lastBetTime,
            tontine.seats
        );

        if (!_isAlive(participantState, _index)) revert PlayerNotAlive();
        if (!ended && !_isLastAlive(participantState, _index)) revert Running();

        uint128 amount = tontine.balance;

        tontine.balance = 0;
        unchecked {
            balances[tontine.asset] -= amount;
        }
        address asset = tontine.asset;

        delete tontines[_id];
        delete participants[_id];

        // Return funds
        if (asset == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            ERC20(asset).transfer(msg.sender, amount);
        }

        emit Claimed(_id, msg.sender, asset, amount);
    }

    /// @notice Collect and send held fees to controller
    /// @dev Use zero address for native currency
    /// @param _asset Asset to be collected
    function collectFees(address _asset) external {
        if (!assetAllowlist[_asset]) revert InvalidAsset();

        if (_asset == address(0)) {
            payable(feeController).transfer(
                address(this).balance - balances[_asset]
            );
        } else {
            ERC20(_asset).transfer(
                feeController,
                ERC20(_asset).balanceOf(address(this)) - balances[_asset]
            );
        }
    }

    /// @notice Sets a new controller address
    /// @param _feeController New controller address
    function setFeeController(address _feeController) external {
        if (msg.sender != feeController) revert InvalidCaller();
        feeController = _feeController;
    }

    /// @notice Sets a new fee
    /// @dev Fee is determined by division e.g 500 / 10000 = .05 = 5%
    /// @param _fee New fee percentage
    function setFee(uint128 _fee) external {
        if (msg.sender != feeController) revert InvalidCaller();
        if (_fee > MAX_FEE) revert MaxFeeExceeded();
        fee = _fee;
    }

    /// @notice White/blacklists a given asset
    /// @dev Use  zero address for native currency
    /// @param _asset Asset to be allowed/disallowed
    /// @param _allowed Is this asset allowed?
    function setAssetAllowlist(
        address _asset,
        bool _allowed
    ) external onlyOwner {
        assetAllowlist[_asset] = _allowed;
    }

    /// @notice Sets a new bitmask of allowed game modes
    /// @param _allowlist New mode allow list value
    function setModeAllowlist(uint256 _allowlist) external onlyOwner {
        modeAllowlist = _allowlist;
    }

    /// @notice Sets the signer that is in charge of supplying randomness
    /// @param _rngSource New signer address
    function setRNGSource(address _rngSource) external onlyOwner {
        rngSource = _rngSource;
    }

    /// @notice Helper to more easily determine if a bet mode is allowed as opposed to shifting bitmask
    /// @param _mode Betmode enum value
    /// @return Is the supplied mode allowed?
    function getBetModeAllowed(
        BetMode _mode
    ) public view override returns (bool) {
        return ((modeAllowlist >> uint8(_mode)) & 1) == 1;
    }

    /// @notice Helper to more easily determine if a bet mode is allowed as opposed to shifting bitmask
    /// @param _mode RNG enum value
    /// @return Is the supplied mode allowed?
    function getRNGModeAllowed(
        RNGMode _mode
    ) public view override returns (bool) {
        return ((modeAllowlist >> (uint8(_mode) + 128)) & 1) == 1;
    }

    /// TODO: Is this needed? Appears unused.  Document if needed
    function getRandomness(
        uint256 _id,
        uint64 _counter
    ) public pure override returns (uint256) {
        return (uint256(keccak256(abi.encodePacked(_id, _counter))) % RAND_MAX);
    }

    /// Participant state for a given lobby
    /// @param _id Tontine ID
    /// @param _rng Randomness data
    /// @return Participant state
    /// @return Last player index
    /// @return Seats in tontine
    function getParticipantState(
        uint256 _id,
        Randomness calldata _rng
    ) public view override returns (uint128, bool, uint256) {
        Tontine memory tontine = tontines[_id];
        uint64 lastBetTime = tontine.lastBetTime;

        if (lastBetTime == 0) {
            return (tontine.participantState, false, 0);
        }

        if (tontine.counter > 0 && tontine.rngMode == RNGMode.RANDOM) {
            if (
                _shouldKillLastPlayer(
                    _id,
                    tontine.counter,
                    tontine.rngMode,
                    _rng.randomness
                )
            ) {
                tontine.participantState = _killPlayer(
                    tontine.participantState,
                    tontine.lastIndex
                );
            }
        }

        return
            _updateParticipantState(
                tontine.participantState,
                tontine.lastIndex,
                lastBetTime,
                tontine.seats
            );
    }

    /// TODO: Duplicate function, not exactly necessary.  Change internal visibility on original (ln 600)
    function getParticipantIdentifier(
        address _participant,
        uint256 _id
    ) external pure override returns (bytes32) {
        return _getParticipantIdentifier(_participant, _id);
    }

    /// Gets amount after fees
    /// @dev Use WEI
    /// @param _amount Amount in
    /// @return Amount out
    function getAmountAfterFee(
        uint256 _amount
    ) external view override returns (uint256) {
        return (_amount * (DENOMINATOR - fee)) / DENOMINATOR;
    }

    /// Gets a tontine
    /// @param _id Tontine ID
    function getTontine(
        uint256 _id
    ) external view override returns (Tontine memory) {
        return (tontines[_id]);
    }

    /// Checks if a given address/participant is still active
    /// @param _participant Participant address
    /// @param _id Tontine ID
    /// @return Is participant active?
    function isActive(
        address _participant,
        uint256 _id
    ) external view override returns (bool) {
        return activityLog[_getParticipantIdentifier(_participant, _id)];
    }

    /// Gets balance of supplied token address (contract accounting)
    /// @dev Amount returned in WEI
    /// @dev Use zero address for base currency
    /// @param _token Token address
    function getBalance(
        address _token
    ) external view override returns (uint256) {
        return balances[_token];
    }

    /// Gets address for supplied IDs
    /// @param _id Tontine ID
    /// @param _index Participant array ID
    /// @return Participant address
    function getParticipant(
        uint256 _id,
        uint256 _index
    ) external view override returns (address) {
        return participants[_id][_index];
    }

    /// Gets all participants in a given lobby
    /// @param _id Tontine ID
    /// @return Array of participants
    function getParticipants(
        uint256 _id
    ) external view override returns (address[] memory) {
        return participants[_id];
    }

    /// Checks if an asset is allowed for game
    /// @dev Use zero address for base currency
    /// @param _asset Asset/token address
    /// @return Is asset allowed?
    function getAssetAllowed(
        address _asset
    ) external view override returns (bool) {
        return assetAllowlist[_asset];
    }

    /// Hashes randomness data
    /// @param _rng Randomness data
    /// @return Hashed randomness data
    function randomnessHash(
        Randomness memory _rng
    ) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        RANDOMNESS_TYPEHASH,
                        _rng.randomness,
                        _rng.counter,
                        _rng.id
                    )
                )
            );
    }

    /// Validates signed randomness data
    /// @param _rng Randomness data
    /// @param _sig Signed randomness data
    function _validateRandomness(
        Randomness memory _rng,
        bytes memory _sig
    ) internal view {
        bytes32 hash = randomnessHash(_rng);
        address signer = ECDSA.recover(hash, _sig);
        if (signer != rngSource) revert InvalidSigner();
    }

    /// Shuffle index
    /// @param _range Number of seats/players
    /// @return Shuffled index within bounds
    function _scramble(uint8 _range) internal view returns (uint8) {
        return
            uint8(
                uint256(
                    keccak256(
                        abi.encodePacked(block.prevrandao, block.timestamp)
                    )
                )
            ) % _range;
    }

    /// TODO: Same as ln 432.  Remove?
    function _getBetAfterFee(uint128 _amount) internal view returns (uint128) {
        return (_amount * (DENOMINATOR - fee)) / DENOMINATOR;
    }

    /// Checks if player is alive
    /// @param _participantState Participant state bitmask
    /// @param _index Participant array ID
    /// @return Is player alive?
    function _isAlive(
        uint128 _participantState,
        uint8 _index
    ) internal pure returns (bool) {
        uint128 liveMask = uint128(1 << (127 - _index));

        return (liveMask & _participantState) != 0;
    }

    /// Checks if player is last alive
    /// @param _participantState Participant state bitmask
    /// @param _index Participant array ID
    function _isLastAlive(
        uint128 _participantState,
        uint8 _index
    ) internal pure returns (bool) {
        return (_killPlayer(_participantState, _index) == 0);
    }

    /// Kills a designated player
    /// @param _participantState Participant state bitmask
    /// @param _index Participant array ID
    /// @return Updated state with designated player killed
    function _killPlayer(
        uint128 _participantState,
        uint8 _index
    ) internal pure returns (uint128) {
        uint128 deadMask = ~uint128(1 << (127 - _index));

        return deadMask & _participantState;
    }

    /// Updates tontine participants state
    /// @param _participantState Participant state bitmask
    /// @param _lastIndex Last player index on participant state
    /// @param _lastBetTime Last time a bet was received, or when game started
    /// @param _seats Number of players/seats in lobby
    /// @return Participant state
    /// @return Is last alive?
    /// @return Next player index
    function _updateParticipantState(
        uint128 _participantState,
        uint64 _lastIndex,
        uint64 _lastBetTime,
        uint8 _seats
    ) internal view returns (uint128, bool, uint256) {
        if (_seats == 0) return (0, false, 0);
        if (_lastBetTime > block.timestamp)
            return (_participantState, false, (_lastIndex + 1) % _seats);

        uint256 iterations = (block.timestamp - _lastBetTime) / DEFAULT_CADENCE;

        for (uint256 i = 1; i <= iterations; i++) {
            uint8 index = uint8((_lastIndex + i) % _seats);

            if (_isAlive(_participantState, index)) {
                if (_isLastAlive(_participantState, index)) {
                    return (_participantState, true, index);
                } else {
                    _participantState = _killPlayer(_participantState, index);
                }
            } else {
                unchecked {
                    ++iterations;
                }
            }
        }

        uint256 newIndex = (_lastIndex + iterations + 1) % _seats;

        // Assign index to next living player
        for (uint256 i = 0; i < _seats - 1; i++) {
            if (_isAlive(_participantState, uint8((newIndex + i) % _seats))) {
                newIndex = uint8((newIndex + i) % _seats);
                break;
            }
        }

        return (
            _participantState,
            _isLastAlive(_participantState, uint8(newIndex)),
            newIndex
        );
    }

    /// Check if last player should be killed
    /// @param _id Participant array ID
    /// @param _counter RNG counter
    /// @param _rngMode RNG enum value
    /// @param randomness Randomness int
    /// @return Should last player be killed?
    function _shouldKillLastPlayer(
        uint256 _id,
        uint64 _counter,
        RNGMode _rngMode,
        uint256 randomness
    ) internal pure returns (bool) {
        if (_rngMode == RNGMode.RANDOM) {
            uint256 seed = uint256(keccak256(abi.encodePacked(randomness)));

            uint256 range = (uint256(
                keccak256(abi.encodePacked(_id, _counter))
            ) % RAND_MAX);

            return (seed % 100) <= range;
        }

        return false;
    }

    /// Get hashed identifier
    /// @param _participant Participant/player address
    /// @param _id Participant array ID
    /// @return Participant identifier
    function _getParticipantIdentifier(
        address _participant,
        uint256 _id
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(_participant, _id));
    }

    /// @dev Prevent direct sending of funds
    receive() external payable {
        revert();
    }

    /// @dev default
    fallback() external {
        revert();
    }
}
