// Jinoro Eth2 Batch Deposit contract
//
// This contract allows deposit of multiple validators in one transaction
// This contract also builds Jinoro MEV Vaults for a user if Vault is Unbuilt
//
// This contract is forked from StakeFish batch deposit contract
// Original contract can be found here https://github.com/stakefish/eth2-batch-deposit/blob/main/contracts/BatchDeposits.sol
//
// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.21;

import "./Pausable.sol";
import "./Ownable.sol";
import "./IVaultManager.sol";

// Deposit contract interface
interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}


contract BatchDeposit is Pausable, Ownable {

    address public depositContract;
    address public vaultManager;

    uint256 constant PUBKEY_LENGTH = 48;
    uint256 constant SIGNATURE_LENGTH = 96;
    uint256 constant CREDENTIALS_LENGTH = 32;
    uint256 constant MAX_VALIDATORS = 100;
    uint256 constant DEPOSIT_AMOUNT = 32 ether;

    constructor(address depositContractAddr, address _vaultManager) {
        depositContract = depositContractAddr;
        vaultManager = _vaultManager;
    }

    /**
     * @dev Performs a batch deposit
     */
    function batchDeposit(
        bytes calldata pubkeys,
        bytes calldata withdrawal_credentials,
        bytes calldata signatures,
        bytes32[] calldata deposit_data_roots
    )
    external payable whenNotPaused
    {
        // sanity checks
        require(msg.value % 1 gwei == 0, "BatchDeposit: Deposit value not multiple of GWEI");
        require(msg.value >= DEPOSIT_AMOUNT, "BatchDeposit: Amount is too low");

        uint256 count = deposit_data_roots.length;
        require(count > 0, "BatchDeposit: You should deposit at least one validator");
        require(count <= MAX_VALIDATORS, "BatchDeposit: You can deposit max 100 validators at a time");

        require(pubkeys.length == count * PUBKEY_LENGTH, "BatchDeposit: Pubkey count don't match");
        require(signatures.length == count * SIGNATURE_LENGTH, "BatchDeposit: Signatures count don't match");
        require(withdrawal_credentials.length == 1 * CREDENTIALS_LENGTH, "BatchDeposit: Withdrawal Credentials count don't match");

        uint256 expectedAmount = DEPOSIT_AMOUNT * count;
        require(msg.value == expectedAmount, "BatchDeposit: Amount is not aligned with pubkeys number");

        for (uint256 i = 0; i < count; ++i) {
            bytes memory pubkey = bytes(pubkeys[i*PUBKEY_LENGTH:(i+1)*PUBKEY_LENGTH]);
            bytes memory signature = bytes(signatures[i*SIGNATURE_LENGTH:(i+1)*SIGNATURE_LENGTH]);

            IDepositContract(depositContract).deposit{value: DEPOSIT_AMOUNT}(
                pubkey,
                withdrawal_credentials,
                signature,
                deposit_data_roots[i]
            );
        }

        if(!IVaultManager(vaultManager).checkIfVaultBuilt(msg.sender)){
            IVaultManager(vaultManager).buildVault(msg.sender);
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * Disable renounce ownership
     * This doesn't actually disable renouncing ownership, since you can transfer ownership to a burn address
     * But it does help prevent admin error
     */
    function renounceOwnership() public override onlyOwner {
        revert("Ownable: renounceOwnership is disabled");
    }
}
