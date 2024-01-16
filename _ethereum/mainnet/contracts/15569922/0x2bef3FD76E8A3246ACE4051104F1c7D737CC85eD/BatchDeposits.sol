pragma solidity 0.6.11;

import "./IDepositContract.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract BatchDeposit is Pausable, Ownable {
    using SafeMath for uint256;

    address depositContract;

    uint256 constant PUBKEY_LENGTH = 48;
    uint256 constant SIGNATURE_LENGTH = 96;
    uint256 constant CREDENTIALS_LENGTH = 32;
    uint256 constant DEPOSIT_AMOUNT = 32 ether;

    uint256 max_validators;

    address newOwnerAddress;
    bool ownershipTransferAccepted;

    constructor(address depositContractAddr) public {

        depositContract = depositContractAddr;
        max_validators = 100;
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

        uint256 count = deposit_data_roots.length;
        require(msg.value == DEPOSIT_AMOUNT.mul(count), "BatchDeposit: Amount is not aligned with pubkeys number");
        require(count > 0, "BatchDeposit: You should deposit at least one validator");
        require(count <= max_validators, "BatchDeposit: Validator amount exceeds limit.");

        require(pubkeys.length == count * PUBKEY_LENGTH, "BatchDeposit: Pubkey count don't match");
        require(signatures.length == count * SIGNATURE_LENGTH, "BatchDeposit: Signatures count don't match");
        require(withdrawal_credentials.length == CREDENTIALS_LENGTH, "BatchDeposit: Withdrawal Credentials count don't match");

        for (uint256 i; i < count; ++i) {
            bytes memory pubkey = bytes(pubkeys[i*PUBKEY_LENGTH:(i+1)*PUBKEY_LENGTH]);
            bytes memory signature = bytes(signatures[i*SIGNATURE_LENGTH:(i+1)*SIGNATURE_LENGTH]);

            IDepositContract(depositContract).deposit{value: DEPOSIT_AMOUNT}(
                pubkey,
                withdrawal_credentials,
                signature,
                deposit_data_roots[i]
            );
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
     * Disable renunce ownership
     */
    function renounceOwnership() public override onlyOwner {
        revert("Ownable: renounceOwnership is disabled");
    }

    /**
     * Finalize transfer of ownership to passed addresss
     * If proposeTransferOwnership() and acceptOwnership() have not been called first, this will fail
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        require(ownershipTransferAccepted == true, "Ownable: Transfer not confirmed by new address");
        require(newOwnerAddress == newOwner, "Ownable: Accepted address is different from passed address");
        super.transferOwnership(newOwnerAddress);
        ownershipTransferAccepted = false;
    }

    /**
     * Initialize transfer of ownership to passed addresss
     */
    function proposeTransferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: New owner is the zero address");
        newOwnerAddress = newOwner;
    }

    /**
     * Accept ownership transfer to calling address
     */
    function acceptOwnership() external {
        require(msg.sender == newOwnerAddress, "Ownable: Only the proposed owner address can call this");
        ownershipTransferAccepted = true;
    }

    /**
     * @dev Resets maximum amount of validators allowed
     *
     * Requirements:
     *
     * - The contract must be paused.
     * @param new_deposit_max The new maximum amount of validaters this contract is allowed to create at one time.
     * Can only be called by the current owner.
     */
    function setMaxValidators(uint256 new_deposit_max) external onlyOwner whenPaused {
        require(new_deposit_max > 0, "New maximum amount of validators cannot be 0.");
        max_validators = new_deposit_max;
    }
}
