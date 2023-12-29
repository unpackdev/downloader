// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// ====================================================================
// ======================= BaseSweep.sol ==============================
// ====================================================================

import "./ITransferApprover.sol";
import "./OFTUpgradeable.sol";
import "./PausableUpgradeable.sol";

contract BaseSweep is Initializable, OFTUpgradeable, PausableUpgradeable {
    ITransferApprover private transferApprover;
    address public fastMultisig;

    // Structs
    struct Minter {
        uint256 maxAmount;
        uint256 mintedAmount;
        bool isListed;
        bool isEnabled;
    }

    // Minters
    mapping(address => Minter) public minters;
    // Minter Addresses
    address[] public minterAddresses;

    /* ========== Events ========== */

    event TokenBurned(address indexed from, uint256 amount);
    event TokenMinted(address indexed to, uint256 amount);
    event MinterAdded(address indexed minterAddress, Minter minter);
    event MinterUpdated(address indexed minterAddress, Minter minter);
    event MinterRemoved(address indexed minterAddress);
    event ApproverSet(address indexed approver);
    event FastMultisigSet(address indexed multisig);

    /* ========== Errors ========== */

    error InvalidMinter();
    error NotGovernance();
    error NotMultisigOrGov();
    error ZeroAmountDetected();
    error ZeroAddressDetected();
    error MintDisabled();
    error MintCapReached();
    error ExceedBurnAmount();
    error MinterExist();
    error TransferNotAllowed();

    /* ========== MODIFIERS ========== */

    modifier validMinter(address addr) {
        if (!minters[addr].isListed) revert InvalidMinter();
        _;
    }

    modifier onlyGov() {
        if (msg.sender != owner()) revert NotGovernance();
        _;
    }

    modifier onlyMultisigOrGov() {
        if (msg.sender != owner() && msg.sender != fastMultisig)
            revert NotMultisigOrGov();
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    function __Sweep_init(
        string memory name,
        string memory symbol,
        address lzEndpoint,
        address fastMultisig_
    ) public onlyInitializing {
        __OFTUpgradeable_init(name, symbol, lzEndpoint);
        __Pausable_init();

        fastMultisig = fastMultisig_;
    }

    /* ========== VIEWS ========== */

    function isValidMinter(address minter) external view returns (bool) {
        return minters[minter].isListed && minters[minter].maxAmount > 0;
    }

    /* ========== Settings ========== */

    /**
     * @notice Pause Sweep
     */
    function pause() external onlyMultisigOrGov whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpause Sweep
     */
    function unpause() external onlyMultisigOrGov whenPaused {
        _unpause();
    }

    /**
     * @notice Unpause Sweep
     */
    function setFastMultisig(address multisig) external onlyGov {
        if (multisig == address(0)) revert ZeroAddressDetected();
        fastMultisig = multisig;
        emit FastMultisigSet(multisig);
    }

    /**
     * @notice Get Minters
     * @return list of whitelisted minter addresses
     */
    function getMinters() external view returns (address[] memory) {
        return minterAddresses;
    }

    /**
     * @notice Add Minter
     * Adds whitelisted minters.
     * @param minter Address to be added.
     * @param amount Max Amount for mint.
     */
    function addMinter(address minter, uint256 amount) external onlyGov {
        if (minter == address(0)) revert ZeroAddressDetected();
        if (amount == 0) revert ZeroAmountDetected();
        if (minters[minter].isListed) revert MinterExist();

        minterAddresses.push(minter);

        Minter memory newMinter = Minter({
            maxAmount: amount,
            mintedAmount: 0,
            isListed: true,
            isEnabled: true
        });
        minters[minter] = newMinter;

        emit MinterAdded(minter, newMinter);
    }

    /**
     * @notice Remove Minter
     * A minter will be removed from the list.
     * @param minter Address to be removed.
     */
    function removeMinter(address minter) external onlyGov validMinter(minter) {
        delete minters[minter]; // Delete minter from the mapping

        for (uint256 i = 0; i < minterAddresses.length; i++) {
            if (minterAddresses[i] == minter) {
                minterAddresses[i] = minterAddresses[
                    minterAddresses.length - 1
                ];
                minterAddresses.pop();
                break;
            }
        }

        emit MinterRemoved(minter);
    }

    /**
     * @notice Set Max Amount of a Minter
     * Update the max mint amount of a user.
     * @param minter Address of a user.
     * @param amount Max Mint Amount .
     */
    function setMinterMaxAmount(
        address minter,
        uint256 amount
    ) external onlyGov validMinter(minter) {
        minters[minter].maxAmount = amount;

        emit MinterUpdated(minter, minters[minter]);
    }

    /**
     * @notice Minter Enable
     * Enable a user to mint.
     * @param minter Address of a user.
     * @param isEnabled True: enabled, False: disabled.
     */
    function setMinterEnabled(
        address minter,
        bool isEnabled
    ) external onlyGov validMinter(minter) {
        minters[minter].isEnabled = isEnabled;

        emit MinterUpdated(minter, minters[minter]);
    }

    /**
     * @notice Set Transfer Approver
     * @param newApprover Address of a Approver.
     */
    function setTransferApprover(address newApprover) external onlyGov {
        if (newApprover == address(0)) revert ZeroAddressDetected();
        transferApprover = ITransferApprover(newApprover);

        emit ApproverSet(newApprover);
    }

    /* ========== Actions ========== */

    /**
     * @notice Mint
     * This function is what other minters will call to mint new tokens
     * @param amount Amount for mint.
     */
    function mint(
        uint256 amount
    ) public virtual validMinter(msg.sender) whenNotPaused {
        if (!minters[msg.sender].isEnabled) revert MintDisabled();
        if (
            minters[msg.sender].mintedAmount + amount >
            minters[msg.sender].maxAmount
        ) revert MintCapReached();

        minters[msg.sender].mintedAmount += amount;
        super._mint(msg.sender, amount);

        emit TokenMinted(msg.sender, amount);
    }

    /**
     * @notice Burn
     * Used by minters when user redeems
     * @param amount Amount for burn.
     */
    function burn(
        uint256 amount
    ) external validMinter(msg.sender) whenNotPaused {
        if (minters[msg.sender].mintedAmount < amount)
            revert ExceedBurnAmount();

        super._burn(msg.sender, amount);
        minters[msg.sender].mintedAmount -= amount;

        emit TokenBurned(msg.sender, amount);
    }

    /**
     * @notice Hook that is called before any transfer of Tokens
     * @param from sender address
     * @param to beneficiary address
     * @param amount token amount
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        if (
            address(transferApprover) != address(0) &&
            !transferApprover.checkTransfer(from, to, amount)
        ) revert TransferNotAllowed();

        super._beforeTokenTransfer(from, to, amount);
    }

    function _debitFrom(
        address from,
        uint16 dstChainId,
        bytes memory to,
        uint amount
    ) internal override returns (uint) {
        address toAddress;
        assembly {
            toAddress := mload(add(to, 20))
        }

        if (
            address(transferApprover) != address(0) &&
            !transferApprover.checkTransfer(from, toAddress, amount)
        ) revert TransferNotAllowed();

        super._debitFrom(from, dstChainId, to, amount);
        return amount;
    }

    function _creditTo(
        uint16 srcChainId,
        address toAddress,
        uint amount
    ) internal override returns (uint) {
        if (
            address(transferApprover) != address(0) &&
            !transferApprover.checkTransfer(toAddress, toAddress, amount)
        ) revert TransferNotAllowed();

        super._creditTo(srcChainId, toAddress, amount);
        return amount;
    }
}
