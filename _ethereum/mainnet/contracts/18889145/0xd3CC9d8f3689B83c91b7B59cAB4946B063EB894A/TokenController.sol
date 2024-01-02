// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;
import "./IAccessControlManagerV8.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./validators.sol";

/**
 * @title TokenController
 * @author Venus
 * @notice TokenController contract acts as a governance and access control mechanism,
 * allowing the owner to manage minting restrictions and blacklist certain addresses to maintain control and security within the token ecosystem.
 * It provides a flexible framework for token-related operations.
 */

contract TokenController is Ownable, Pausable {
    /**
     * @notice Access control manager contract address.
     */
    address public accessControlManager;
    /**
     * @notice A Mapping used to keep track of the blacklist status of addresses.
     */
    mapping(address => bool) internal _blacklist;
    /**
     * @notice A mapping is used to keep track of the maximum amount a minter is permitted to mint.
     */
    mapping(address => uint256) public minterToCap;
    /**
     * @notice A Mapping used to keep track of the amount i.e already minted by minter.
     */
    mapping(address => uint256) public minterToMintedAmount;

    /**
     * @notice Emitted when the blacklist status of a user is updated.
     */
    event BlacklistUpdated(address indexed user, bool value);
    /**
     * @notice Emitted when the minting limit for a minter is increased.
     */
    event MintLimitIncreased(address indexed minter, uint256 newLimit);
    /**
     * @notice Emitted when the minting limit for a minter is decreased.
     */
    event MintLimitDecreased(address indexed minter, uint256 newLimit);
    /**
     * @notice Emitted when the minting cap for a minter is changed.
     */
    event MintCapChanged(address indexed minter, uint256 amount);
    /**
     * @notice Emitted when the address of the access control manager of the contract is updated.
     */
    event NewAccessControlManager(address indexed oldAccessControlManager, address indexed newAccessControlManager);
    /**
     * @notice Emitted when all minted tokens are migrated from one minter to another.
     */
    event MintedTokensMigrated(address indexed source, address indexed destination);

    /**
     * @notice This error is used to indicate that the minting limit has been exceeded. It is typically thrown when a minting operation would surpass the defined cap.
     */
    error MintLimitExceed();
    /**
     * @notice This error is used to indicate that `mint` `burn` and `transfer` actions are not allowed for the user address.
     */
    error AccountBlacklisted(address user);
    /**
     * @notice This error is used to indicate that sender is not allowed to perform this action.
     */
    error Unauthorized();
    /**
     * @notice This error is used to indicate that the new cap is greater than the previously minted tokens for the minter.
     */
    error NewCapNotGreaterThanMintedTokens();
    /**
     * @notice This error is used to indicate that the addresses must be different.
     */
    error AddressesMustDiffer();
    /**
     * @notice This error is used to indicate that the minter did not mint the required amount of tokens.
     */
    error MintedAmountExceed();

    /**
     * @param accessControlManager_ Address of access control manager contract.
     * @custom:error ZeroAddressNotAllowed is thrown when accessControlManager contract address is zero.
     */
    constructor(address accessControlManager_) {
        ensureNonzeroAddress(accessControlManager_);
        accessControlManager = accessControlManager_;
    }

    /**
     * @notice Pauses Token
     * @custom:access Controlled by AccessControlManager.
     */
    function pause() external {
        _ensureAllowed("pause()");
        _pause();
    }

    /**
     * @notice Resumes Token
     * @custom:access Controlled by AccessControlManager.
     */
    function unpause() external {
        _ensureAllowed("unpause()");
        _unpause();
    }

    /**
     * @notice Function to update blacklist.
     * @param user_ User address to be affected.
     * @param value_ Boolean to toggle value.
     * @custom:access Controlled by AccessControlManager.
     * @custom:event Emits BlacklistUpdated event.
     */
    function updateBlacklist(address user_, bool value_) external {
        _ensureAllowed("updateBlacklist(address,bool)");
        _blacklist[user_] = value_;
        emit BlacklistUpdated(user_, value_);
    }

    /**
     * @notice Sets the minting cap for minter.
     * @param minter_ Minter address.
     * @param amount_ Cap for the minter.
     * @custom:access Controlled by AccessControlManager.
     * @custom:event Emits MintCapChanged.
     */
    function setMintCap(address minter_, uint256 amount_) external {
        _ensureAllowed("setMintCap(address,uint256)");

        if (amount_ < minterToMintedAmount[minter_]) {
            revert NewCapNotGreaterThanMintedTokens();
        }

        minterToCap[minter_] = amount_;
        emit MintCapChanged(minter_, amount_);
    }

    /**
     * @notice Sets the address of the access control manager of this contract.
     * @dev Admin function to set the access control address.
     * @param newAccessControlAddress_ New address for the access control.
     * @custom:access Only owner.
     * @custom:event Emits NewAccessControlManager.
     * @custom:error ZeroAddressNotAllowed is thrown when newAccessControlAddress_ contract address is zero.
     */
    function setAccessControlManager(address newAccessControlAddress_) external onlyOwner {
        ensureNonzeroAddress(newAccessControlAddress_);
        emit NewAccessControlManager(accessControlManager, newAccessControlAddress_);
        accessControlManager = newAccessControlAddress_;
    }

    /**
     * @notice Migrates all minted tokens from one minter to another. This function is useful when we want to permanent take down a bridge.
     * @param source_ Minter address to migrate tokens from.
     * @param destination_ Minter address to migrate tokens to.
     * @custom:access Controlled by AccessControlManager.
     * @custom:error MintLimitExceed is thrown when the minting limit exceeds the cap after migration.
     * @custom:error AddressesMustDiffer is thrown when the source_ and destination_ addresses are the same.
     * @custom:event Emits MintLimitIncreased and MintLimitDecreased events for 'source' and 'destination'.
     * @custom:event Emits MintedTokensMigrated.
     */
    function migrateMinterTokens(address source_, address destination_) external {
        _ensureAllowed("migrateMinterTokens(address,address)");

        if (source_ == destination_) {
            revert AddressesMustDiffer();
        }

        uint256 sourceCap = minterToCap[source_];
        uint256 destinationCap = minterToCap[destination_];

        uint256 sourceMinted = minterToMintedAmount[source_];
        uint256 destinationMinted = minterToMintedAmount[destination_];
        uint256 newDestinationMinted = destinationMinted + sourceMinted;

        if (newDestinationMinted > destinationCap) {
            revert MintLimitExceed();
        }

        minterToMintedAmount[source_] = 0;
        minterToMintedAmount[destination_] = newDestinationMinted;
        uint256 availableLimit;
        unchecked {
            availableLimit = destinationCap - newDestinationMinted;
        }

        emit MintLimitDecreased(destination_, availableLimit);
        emit MintLimitIncreased(source_, sourceCap);
        emit MintedTokensMigrated(source_, destination_);
    }

    /**
     * @notice Returns the blacklist status of the address.
     * @param user_ Address of user to check blacklist status.
     * @return bool status of blacklist.
     */
    function isBlackListed(address user_) external view returns (bool) {
        return _blacklist[user_];
    }

    /**
     * @dev Checks the minter cap and eligibility of receiver to receive tokens.
     * @param from_  Minter address.
     * @param to_  Receiver address.
     * @param amount_  Amount to be mint.
     * @custom:error MintLimitExceed is thrown when minting limit exceeds the cap.
     * @custom:event Emits MintLimitDecreased with minter address and available limits.
     */
    function _isEligibleToMint(address from_, address to_, uint256 amount_) internal {
        uint256 mintingCap = minterToCap[from_];
        uint256 totalMintedOld = minterToMintedAmount[from_];
        uint256 totalMintedNew = totalMintedOld + amount_;

        if (totalMintedNew > mintingCap) {
            revert MintLimitExceed();
        }
        minterToMintedAmount[from_] = totalMintedNew;
        uint256 availableLimit;
        unchecked {
            availableLimit = mintingCap - totalMintedNew;
        }
        emit MintLimitDecreased(from_, availableLimit);
    }

    /**
     * @dev This is post hook of burn function, increases minting limit of the minter.
     * @param from_ Minter address.
     * @param amount_  Amount burned.
     * @custom:error MintedAmountExceed is thrown when `amount_` is greater than the tokens minted by `from_`.
     * @custom:event Emits MintLimitIncreased with minter address and availabe limit.
     */
    function _increaseMintLimit(address from_, uint256 amount_) internal {
        uint256 totalMintedOld = minterToMintedAmount[from_];

        if (totalMintedOld < amount_) {
            revert MintedAmountExceed();
        }

        uint256 totalMintedNew;
        unchecked {
            totalMintedNew = totalMintedOld - amount_;
        }
        minterToMintedAmount[from_] = totalMintedNew;
        uint256 availableLimit = minterToCap[from_] - totalMintedNew;
        emit MintLimitIncreased(from_, availableLimit);
    }

    /**
     * @dev Checks the caller is allowed to call the specified fuction.
     * @param functionSig_ Function signatureon which access is to be checked.
     * @custom:error Unauthorized, thrown when unauthorised user try to access function.
     */
    function _ensureAllowed(string memory functionSig_) internal view {
        if (!IAccessControlManagerV8(accessControlManager).isAllowedToCall(msg.sender, functionSig_)) {
            revert Unauthorized();
        }
    }
}
