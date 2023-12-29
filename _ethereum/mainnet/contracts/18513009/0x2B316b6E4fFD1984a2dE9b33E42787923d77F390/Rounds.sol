// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./IERC20.sol";
import "./Ownable.sol";

import "./TokensRegistry.sol";
import "./IRounds.sol";

import "./Common.sol";

/// @title Rounds contract
/// @notice Implements the Round creation and updating of presale
/// @dev The Rounds contract allows you to create a round, update a round

abstract contract Rounds is IRounds, Ownable, TokensRegistry {
    /// @notice Thrown when round time is not started
    error RoundNotStarted();

    /// @notice Thrown when round time is ended
    error RoundEnded();

    /// @notice Thrown when Round is not created
    error IncorrectRound();

    /// @notice Thrown when new round price is less than previous round price
    error PriceLessThanOldRound();

    /// @notice Thrown when round start time is invalid
    error InvalidStartTime();

    /// @notice Thrown when round end time is invalid
    error InvalidEndTime();

    /// @notice Thrown when new price is invalid
    error PriceInvalid();

    /// @notice Thrown when startTime is incorrect when updating round
    error IncorrectStartTime();

    /// @notice Thrown when endTime is incorrect when updating round
    error IncorrectEndTime();

    /// @notice Thrown when round price is greater than next round while updating
    error PriceGreaterThanNextRound();

    /// @notice Thrown when Token is restricted in given round
    error TokenDisallowed();

    /// @notice The round index of last round created
    uint32 internal immutable _startRound;

    /// @notice The count of rounds created
    uint32 internal _roundIndex;

    /// @notice mapping gives us access info of the token in a given round
    mapping(uint32 => mapping(IERC20 => AllowedToken)) public allowedTokens;

    /// @notice mapping gives Round Data of each round
    mapping(uint32 => RoundData) public rounds;

    /// @member access The access of the token
    /// @member customPrice The customPrice price in the round for the token
    struct AllowedToken {
        bool access;
        uint256 customPrice;
    }

    /// @member startTime The start time of round
    /// @member endTime The end time of round
    /// @member price The price in usd per DOP
    struct RoundData {
        uint256 startTime;
        uint256 endTime;
        uint256 price;
    }
    /// @dev Emitted when creating a new round
    event RoundCreated(uint32 indexed newRound, RoundData roundData);

    /// @dev Emitted when round is updated
    event RoundUpdated(uint32 indexed round, RoundData roundData);

    /// @dev Emitted when token access is updated
    event TokensAccessUpdated(
        uint32 indexed round,
        IERC20 indexed token,
        bool indexed access,
        uint256 customPrice
    );

    /// @dev Constructor.
    /// @param lastRound The last round created
    constructor(uint32 lastRound) {
        _startRound = lastRound;
        _roundIndex = lastRound;
    }

    /// @notice Creates a new Round
    /// @param startTime The startTime of the round
    /// @param endTime The endTime of the round
    /// @param price The dopToken price in 18 decimals, because our calculations returns a value in 36 decimals and toget returning value in 18 decimals we divide by round price
    function createNewRound(
        uint256 startTime,
        uint256 endTime,
        uint256 price
    ) external onlyOwner {
        RoundData memory prevRoundData = rounds[_roundIndex];
        uint32 newRound = ++_roundIndex;
        if (price < prevRoundData.price) {
            revert PriceLessThanOldRound();
        }
        if (startTime < prevRoundData.endTime) {
            revert InvalidStartTime();
        }
        _verifyRound(startTime, endTime, price);
        prevRoundData = RoundData({
            startTime: startTime,
            endTime: endTime,
            price: price
        });
        rounds[newRound] = prevRoundData;
        emit RoundCreated({newRound: newRound, roundData: prevRoundData});
    }

    /// @notice Updates the access of tokens in a given round
    /// @param round The round in which you want to update
    /// @param tokens addresses of the tokens
    /// @param accesses The access for the tokens
    /// @param customPrices The customPrice prices if any for the tokens
    function updateAllowedTokens(
        uint32 round,
        IERC20[] calldata tokens,
        bool[] memory accesses,
        uint256[] memory customPrices
    ) external onlyOwner {
        if (tokens.length == 0) {
            revert ZeroLengthArray();
        }
        if (
            tokens.length != accesses.length ||
            accesses.length != customPrices.length
        ) {
            revert ArrayLengthMismatch();
        }
        mapping(IERC20 => AllowedToken) storage selectedRound = allowedTokens[
            round
        ];
        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];

            if (address(token) == address(0)) {
                revert ZeroAddress();
            }
            AllowedToken memory allowedToken = AllowedToken({
                access: accesses[i],
                customPrice: customPrices[i]
            });
            selectedRound[token] = allowedToken;

            emit TokensAccessUpdated({
                round: round,
                token: token,
                access: allowedToken.access,
                customPrice: allowedToken.customPrice
            });
        }
    }

    /// @notice Updates round data
    /// @param round The Round that will be updated
    /// @param startTime The StartTime of the round
    /// @param endTime The EndTime of the round
    /// @param price The price of the round in 18 decimals
    function updateRound(
        uint32 round,
        uint256 startTime,
        uint256 endTime,
        uint256 price
    ) external onlyOwner {
        if (round <= _startRound || round > _roundIndex) {
            revert IncorrectRound();
        }
        RoundData memory previousRound = rounds[round - 1];
        RoundData memory nextRound = rounds[round + 1];
        if (startTime < previousRound.endTime) {
            revert IncorrectStartTime();
        }
        if (round != _roundIndex && endTime > nextRound.startTime) {
            revert IncorrectEndTime();
        }
        if (price < previousRound.price) {
            revert PriceLessThanOldRound();
        }
        if (round != _roundIndex && price > nextRound.price) {
            revert PriceGreaterThanNextRound();
        }
        _verifyRound(startTime, endTime, price);
        rounds[round] = RoundData({
            startTime: startTime,
            endTime: endTime,
            price: price
        });
        emit RoundUpdated({round: round, roundData: rounds[round]});
    }

    /// @notice Returns total rounds created
    /// @return The Round count
    function getRoundCount() external view returns (uint32) {
        return _roundIndex;
    }

    /// @notice Validates array length and values
    function _validateArrays(
        uint256 firstLength,
        uint256 secondLength
    ) internal pure {
        if (firstLength == 0) {
            revert ZeroLengthArray();
        }
        if (firstLength != secondLength) {
            revert ArrayLengthMismatch();
        }
    }

    /// @notice Checks round start and end time, reverts if Invalid
    function _verifyInRound(uint32 round) internal view {
        RoundData memory dataRound = rounds[round];
        if (block.timestamp < dataRound.startTime) {
            revert RoundNotStarted();
        }
        if (block.timestamp >= dataRound.endTime) {
            revert RoundEnded();
        }
    }

    /// @notice Checks the validity of startTime, endTime and price
    function _verifyRound(
        uint256 startTime,
        uint256 endTime,
        uint256 price
    ) internal view {
        if (startTime < block.timestamp) {
            revert InvalidStartTime();
        }
        if (endTime <= startTime) {
            revert InvalidEndTime();
        }
        if (price == 0) {
            revert PriceInvalid();
        }
    }
}
