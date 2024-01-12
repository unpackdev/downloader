// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeCollector {
    struct Vault {
        uint256 eventId;
        address owner;
        address token;
        uint128 fee;
        uint128 collected;
        mapping(address => bool) paid;
    }

    /// @notice Registers a POAP drop and it's fee.
    /// @param eventId The id of the POAP drop.
    /// @param owner The address that receives the fees from the drop.
    /// @param token The zero address for Ether, otherwise an ERC20 token.
    /// @param fee The amount of fee to pay in wei.
    function registerVault(
        uint256 eventId,
        address owner,
        address token,
        uint128 fee
    ) external;

    /// @notice Registers the paid fee, both in Ether or ERC20.
    /// @param vaultId The id of the vault to pay to.
    function payFee(uint256 vaultId) external payable;

    /// @notice Sets the address that receives Guild's share from the funds.
    /// @dev Callable only by the current Guild fee collector.
    /// @param newFeeCollector The new address of guildFeeCollector.
    function setGuildFeeCollector(address payable newFeeCollector) external;

    /// @notice Sets Guild's share from the funds.
    /// @dev Callable only by the Guild fee collector.
    /// @param newShare The percentual value multiplied by 100.
    function setGuildSharex100(uint96 newShare) external;

    /// @notice Sets the address that receives POAP's share from the funds.
    /// @dev Callable only by the current POAP fee collector.
    /// @param newFeeCollector The new address of poapFeeCollector.
    function setPoapFeeCollector(address payable newFeeCollector) external;

    /// @notice Sets POAP's share from the funds.
    /// @dev Callable only by the POAP fee collector.
    /// @param newShare The percentual value multiplied by 100.
    function setPoapSharex100(uint96 newShare) external;

    /// @notice Distributes the funds from a vault to the fee collectors and the owner.
    /// @param vaultId The id of the vault whose funds should be distributed.
    function withdraw(uint256 vaultId) external;

    /// @notice Returns a vault's details.
    /// @param vaultId The id of the queried vault.
    /// @return eventId The id of the POAP drop.
    /// @return owner The owner of the vault who recieves the funds.
    /// @return token The address of the token to receive funds in (the zero address in case of Ether).
    /// @return fee The amount of required funds in wei.
    /// @return collected The amount of already collected funds.
    function getVault(uint256 vaultId)
        external
        view
        returns (
            uint256 eventId,
            address owner,
            address token,
            uint128 fee,
            uint128 collected
        );

    /// @notice Returns if an account has paid the fee to a vault.
    /// @param vaultId The id of the queried vault.
    /// @param account The address of the queried account.
    function hasPaid(uint256 vaultId, address account) external view returns (bool paid);

    /// @notice Returns the address that receives Guild's share from the funds.
    function guildFeeCollector() external view returns (address payable);

    /// @notice Returns the percentage of Guild's share multiplied by 100.
    function guildSharex100() external view returns (uint96);

    /// @notice Returns the address that receives POAP's share from the funds.
    function poapFeeCollector() external view returns (address payable);

    /// @notice Returns the percentage of POAP's share multiplied by 100.
    function poapSharex100() external view returns (uint96);

    /// @notice Event emitted when a call to {payFee} succeeds.
    /// @param vaultId The id of the vault that received the payment.
    /// @param account The address of the account that paid.
    /// @param amount The amount of fee received in wei.
    event FeeReceived(uint256 indexed vaultId, address indexed account, uint256 amount);

    /// @notice Event emitted when the Guild fee collector address is changed.
    /// @param newFeeCollector The address to change guildFeeCollector to.
    event GuildFeeCollectorChanged(address newFeeCollector);

    /// @notice Event emitted when the share of the Guild fee collector changes.
    /// @param newShare The new value of guildSharex100.
    event GuildSharex100Changed(uint96 newShare);

    /// @notice Event emitted when the POAP fee collector address is changed.
    /// @param newFeeCollector The address to change poapFeeCollector to.
    event PoapFeeCollectorChanged(address newFeeCollector);

    /// @notice Event emitted when the share of the POAP fee collector changes.
    /// @param newShare The new value of poapSharex100.
    event PoapSharex100Changed(uint96 newShare);

    /// @notice Event emitted when a new vault is registered.
    /// @param eventId The id of the POAP drop.
    /// @param owner The address that receives the fees from the drop.
    /// @param token The zero address for Ether, otherwise an ERC20 token.
    /// @param fee The amount of fee to pay in wei.
    event VaultRegistered(
        uint256 vaultId,
        uint256 indexed eventId,
        address indexed owner,
        address indexed token,
        uint256 fee
    );

    /// @notice Event emitted when funds are withdrawn by a vault owner.
    /// @param vaultId The id of the vault.
    /// @param guildAmount The amount received by the Guild fee collector in wei.
    /// @param poapAmount The amount received by the POAP fee collector in wei.
    /// @param ownerAmount The amount received by the vault's owner in wei.
    event Withdrawn(uint256 indexed vaultId, uint256 guildAmount, uint256 poapAmount, uint256 ownerAmount);

    /// @notice Error thrown when an incorrect amount of fee is attempted to be paid.
    /// @dev requiredAmount might be 0 in cases when an ERC20 payment was expected but Ether was received, too.
    /// @param vaultId The id of the vault.
    /// @param paid The amount of funds received.
    /// @param requiredAmount The amount of fees required by the vault.
    error IncorrectFee(uint256 vaultId, uint256 paid, uint256 requiredAmount);

    /// @notice Error thrown when a function is attempted to be called by the wrong address.
    /// @param sender The address that sent the transaction.
    /// @param owner The address that is allowed to call the function.
    error AccessDenied(address sender, address owner);

    /// @notice Error thrown when an ERC20 transfer failed.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    error TransferFailed(address from, address to);

    /// @notice Error thrown when a vault does not exist.
    /// @param vaultId The id of the requested vault.
    error VaultDoesNotExist(uint256 vaultId);
}
