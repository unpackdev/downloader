// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IMintPayoutEvents {
    /// @notice Emitted when a deposit has been made.
    /// @param from The depositor's address.
    /// @param to The address receiving the deposit.
    /// @param reason The reason code for the deposit.
    /// @param amount The deposit amount.
    event Deposit(address from, address to, bytes4 reason, uint256 amount);

    /// @notice Emitted when a withdrawal has been made.
    /// @param from The address withdrawing.
    /// @param to The address receiving the withdrawn funds.
    /// @param amount The withdrawal amount.
    event Withdraw(address from, address to, uint256 amount);

    /// @notice Emitted during a mint deposit to provide additional context.
    /// @param depositedBy The address of the mint initiator.
    /// @param mintContract The mint contract address this mint deposit refers to.
    /// @param minter The address of the person minting.
    /// @param referrer The address of the referrer, or the zero address for no referrer.
    /// @param creator The address of the contract creator, or the protocol fee recipient if none.
    /// @param creatorPayout The amount being paid to the creator.
    /// @param referralPayout The amount being paid to the referrer.
    /// @param protocolPayout The amount being paid to the protocol.
    /// @param totalAmount The total deposit amount.
    /// @param quantity The number of tokens being minted.
    /// @param protocolFee The per-mint fee for the protocol.
    event MintDeposit(
        address depositedBy,
        address mintContract,
        address minter,
        address referrer,
        address creator,
        uint256 creatorPayout,
        uint256 referralPayout,
        uint256 protocolPayout,
        uint256 totalAmount,
        uint256 quantity,
        uint256 protocolFee
    );

    /// @notice Emitted when the protocol fee is updated.
    /// @param fee The new protocol fee.
    event ProtocolFeeUpdated(uint256 fee);
}

interface IMintPayout is IMintPayoutEvents {
    function balanceOf(address owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);

    /// @notice The current protocol fee per-mint.
    function protocolFee() external view returns (uint256 fee);

    /// @notice Sets the protocol fee per-mint.
    /// @dev Only callable by the owner.
    /// @param fee The new protocol fee.
    function setProtocolFee(uint256 fee) external;

    /// @notice Magic value used to represent the fees belonging to the protocol.
    function protocolFeeRecipientAccount() external view returns (address);

    /// @notice Withdraws from the protocol fee balance.
    /// @dev Only callable by the owner.
    /// @param to The address receiving the withdrawn funds.
    /// @param amount The withdrawal amount.
    function withdrawProtocolFee(address to, uint256 amount) external;

    /// @notice Deposits ether for a mint.
    /// @dev Ensure that `quantity` is > 0. The `protocolFee` should be per-mint, not the total taken.
    /// Will trigger a `MintDeposit` event, followed by `Deposit` events for:
    /// creator payout, protocol payout, and referrer payout (if a referrer is specified).
    /// @param mintContract The mint contract address this mint deposit refers to.
    /// @param minter The address of the minter.
    /// @param referrer The address of the referrer, or the zero address for no referrer.
    /// @param quantity The amount being minted.
    function mintDeposit(address mintContract, address minter, address referrer, uint256 quantity) external payable;

    /// @notice Deposits ether to an address.
    /// @param to The address receiving the deposit.
    /// @param reason The reason code for the deposit.
    function deposit(address to, bytes4 reason) external payable;

    /// @notice Deposits ether to multiple addresses.
    /// @dev The length of `recipients`, `amounts`, and `reasons` must be the same.
    /// @param recipients List of addresses receiving the deposits.
    /// @param amounts List of deposit amounts.
    /// @param reasons List of reason codes for the deposits.
    function depositBatch(address[] calldata recipients, uint256[] calldata amounts, bytes4[] calldata reasons)
        external
        payable;

    /// @notice Withdraws ether from the `msg.sender`'s account to a specified address.
    /// @param to The address receiving the withdrawn funds.
    /// @param amount The withdrawal amount.
    function withdraw(address to, uint256 amount) external;

    /// @notice Withdraws all ether from the `msg.sender`'s account to a specified address.
    /// @param to The address receiving the withdrawn funds.
    function withdrawAll(address to) external;
}
