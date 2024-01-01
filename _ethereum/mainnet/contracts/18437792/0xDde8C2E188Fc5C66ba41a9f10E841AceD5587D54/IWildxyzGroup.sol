// SPDX-License-Identifier: GPL-3.0-or-later

// ░██╗░░░░░░░██╗░██╗░██╗░░░░░░██████╗░░██╗░░██╗░██╗░░░██╗░███████╗
// ░██║░░██╗░░██║░██║░██║░░░░░░██╔══██╗░╚██╗██╔╝░╚██╗░██╔╝░╚════██║
// ░╚██╗████╗██╔╝░██║░██║░░░░░░██║░░██║░░╚███╔╝░░░╚████╔╝░░░░███╔═╝
// ░░████╔═████║░░██║░██║░░░░░░██║░░██║░░██╔██╗░░░░╚██╔╝░░░██╔══╝░░
// ░░╚██╔╝░╚██╔╝░░██║░███████╗░██████╔╝░██╔╝╚██╗░░░░██║░░░░███████╗
// ░░░╚═╝░░░╚═╝░░░╚═╝░╚══════╝░╚═════╝░░╚═╝░░╚═╝░░░░╚═╝░░░░╚══════╝

pragma solidity ^0.8.17;

interface IWildxyzGroup {
    // enums

    /// @dev States for the minter
    enum State {
        Setup, // also "comingsoon"
        Live, // defer to phases for state name
        Complete, // also "soldout"
        Paused // temporary paused state
    }

    // structs

    /// @dev Represents a minting group
    struct Group {
        string name;
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256 price;

        uint256 reserveSupply; // supply reserved for this group until reserveEndTime (>= 0 and < maxSupply)
    }

    // events


    // errors

    /// @notice Emitted when trying to call setup twice
    error AlreadySetup();

    /// @notice Emitted when not in live state
    error NotLive();

    /// @notice Emitted when not in complete state
    error NotComplete();

    /// @notice Emitted when group is not allowed to mint yet
    error GroupNotLive(uint256 _groupId);

    /// @notice Emitted when given a zero address
    error ZeroAddress();

    /// @notice Emitted when given a zero amount
    error ZeroAmount();

    /// @notice Emitted when setting group start time to an invalid value
    error InvalidGroupStartTime(uint256 _startTime);

    /// @notice Emitted when an OFAC sanctioned address tries to interact with a function
    error SanctionedAddress(address _to);

    /// @notice Emitted when a function is called by a non-delegated address
    error NotDelegated(address _sender, address _vault, address _contract);

    /// @notice Emitted when failing to withdraw to wallet
    error FailedToWithdraw(string _walletName, address _wallet);

    /// @notice Emitted when given a non-existing groupId
    error GroupDoesNotExist(uint256 _groupId);

    /// @notice Emitted when amount requested exceeds nft max supply
    error MaxSupplyExceeded();

    /// @notice Emitted when the value provided is not enough for the function
    error InsufficientFunds();

    /// @notice Emitted when two or more arrays do not match in size
    error ArraySizeMismatch();

    error NotEnoughOasisMints(address _receiver);
    error ZeroOasisAllowance(address _receiver);

    error FailedToMint(address _receiver);

    /// @notice Emitted when a user tries to mint too many toksns
    error MaxPerAddressExceeded(address _receiver, uint256 _amount);

    /// @notice Emitted when a non-admin or non-manager tries to call an admin or manager function
    error OnlyAdminOrManager();

    error ReserveSupplyExceedsMaxSupply(uint256 reserveSupply, uint256 maxSupply);
}
