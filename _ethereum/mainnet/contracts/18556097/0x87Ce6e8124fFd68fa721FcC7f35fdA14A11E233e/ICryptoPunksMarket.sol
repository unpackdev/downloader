// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.20;

/// @dev CryptoPunksMarket interface. Copied from etherscan: https://etherscan.io/token/0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb#code
interface ICryptoPunksMarket {
    struct Bid {
        bool hasBid;
        uint256 punkIndex;
        address bidder;
        uint256 value;
    }

    /// @notice Transfer a punk that `msg.sender` owns.
    /// @param to The address to transfer the punk to.
    /// @param punkIndex The index of the punk to transfer.
    function transferPunk(address to, uint256 punkIndex) external;

    /// @notice Withdraw available balance for `msg.sender`
    function withdraw() external;

    /// @notice Get owner of punk by punk index.
    /// @param punkIndex The index of the punk.
    /// @return The address of the owner.
    function punkIndexToAddress(uint256 punkIndex) external view returns (address);

    /// @notice Get the balance of `user`.
    /// @param user The address of the user.
    /// @return The balance of the user.
    function pendingWithdrawals(address user) external view returns (uint256);

    /// @notice Get the bid for a punk.
    /// @param punkIndex The index of the punk.
    /// @return The bid.
    function punkBids(uint256 punkIndex) external view returns (Bid memory);
}
