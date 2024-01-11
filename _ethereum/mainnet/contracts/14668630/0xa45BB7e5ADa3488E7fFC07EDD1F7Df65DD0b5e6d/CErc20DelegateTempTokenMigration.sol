pragma solidity ^0.5.16;

import "./CErc20Delegate.sol";

/**
 * @title Compound's CErc20Delegate Contract
 * @notice CTokens which wrap an EIP-20 underlying and are delegated to
 * @author Compound
 */
contract CErc20DelegateTempTokenMigration is CDelegateInterface, CTokenStorage, CErc20Storage, ExponentialNoError {
    /**
     * @notice Construct an empty delegate
     */
    constructor() public {}

    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes calldata data) external {
        // Shh -- currently unused
        data;

        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == address(this) || hasAdminRights(), "!self");

        // Get old cash
        uint256 oldCash = EIP20Interface(underlying).balanceOf(address(this));

        // Approve old underlying to migrator and migrate old underlying to new underlying
        (address migrator, bytes memory migrationData, address newUnderlying, string memory _name, string memory _symbol) = abi.decode(data, (address, bytes, address, string, string));
        if (underlying != migrator) _callOptionalReturn(abi.encodeWithSelector(EIP20NonStandardInterface(underlying).approve.selector, migrator, uint256(-1)), "TOKEN_APPROVAL_FAILED");
        _functionCall(migrator, migrationData, "Failed to call migration function.");
        
        // Make sure all was migrated
        require(EIP20Interface(underlying).balanceOf(address(this)) == 0, "Not all cash was migrated.");

        // Set new underlying
        underlying = newUnderlying;

        // Get new cash and update reserves, fees, and borrows
        uint newCash = EIP20Interface(underlying).balanceOf(address(this));
        require(EIP20Interface(underlying).balanceOf(address(this)) > 0, "No new cash found.");
        if (totalReserves > 0) totalReserves = div_(mul_(totalReserves, newCash), oldCash);
        if (totalAdminFees > 0) totalAdminFees = div_(mul_(totalAdminFees, newCash), oldCash);
        if (totalFuseFees > 0) totalFuseFees = div_(mul_(totalFuseFees, newCash), oldCash);

        if (totalBorrows > 0) {
            totalBorrows = div_(mul_(totalBorrows, newCash), oldCash);
            borrowIndex = div_(mul_(borrowIndex, newCash), oldCash);
        }

        // Set new cToken name and symbol
        name = _name;
        symbol = _symbol;
    }

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() internal {
        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }
    }

    /**
     * @dev Internal function to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementationInternal(address implementation_, bool allowResign, bytes memory becomeImplementationData) internal {
        // Check whitelist
        require(fuseAdmin.cErc20DelegateWhitelist(implementation, implementation_, allowResign), "!impl");

        // Call _resignImplementation internally (this delegate's code)
        if (allowResign) _resignImplementation();

        // Get old implementation
        address oldImplementation = implementation;

        // Store new implementation
        implementation = implementation_;

        // Call _becomeImplementation externally (delegating to new delegate's code)
        _functionCall(address(this), abi.encodeWithSignature("_becomeImplementation(bytes)", becomeImplementationData), "!become");

        // Emit event
        emit NewImplementation(oldImplementation, implementation);
    }

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementationSafe(address implementation_, bool allowResign, bytes calldata becomeImplementationData) external {
        // Check admin rights
        require(hasAdminRights(), "!admin");

        // Set implementation
        _setImplementationInternal(implementation_, allowResign, becomeImplementationData);
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * Copied from `CErc20.sol`.
     * @param data The call data (encoded using abi.encode or one of its variants).
     * @param errorMessage The revert string to return on failure.
     */
    function _callOptionalReturn(bytes memory data, string memory errorMessage) internal {
        bytes memory returndata = _functionCall(underlying, data, errorMessage);
        if (returndata.length > 0) require(abi.decode(returndata, (bool)), errorMessage);
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     * Copied from `CErc20.sol`.
     * @param data The call data (encoded using abi.encode or one of its variants).
     * @param errorMessage The revert string to return on failure.
     */
    function _functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.call(data);

        if (!success) {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }

        return returndata;
    }

    /**
     * @notice Function called before all delegator functions
     */
    function _prepare() external payable {}

    /**
     * @notice Returns a boolean indicating if the sender has admin rights
     */
    function hasAdminRights() internal view returns (bool) {
        ComptrollerV3Storage comptrollerStorage = ComptrollerV3Storage(address(comptroller));
        return (msg.sender == comptrollerStorage.admin() && comptrollerStorage.adminHasRights()) || (msg.sender == address(fuseAdmin) && comptrollerStorage.fuseAdminHasRights());
    }
}
