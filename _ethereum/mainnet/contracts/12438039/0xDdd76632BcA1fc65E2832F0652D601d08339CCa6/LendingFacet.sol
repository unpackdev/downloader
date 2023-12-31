// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./PausableMods.sol";
import "./ReentryMods.sol";
import "./RolesMods.sol";
import "./roles.sol";

// Interfaces
import "./ITToken.sol";

// Libraries
import "./SafeERC20.sol";
import "./SafeERC20Upgradeable.sol";
import "./MaxTVLLib.sol";
import "./LendingLib.sol";

// Storage
import "./app.sol";

contract LendingFacet is RolesMods, ReentryMods, PausableMods {
    /**
     * @notice This event is emitted when a new lending pool is initialized.
     * @param sender address.
     * @param asset Token address the pool was initialized for.
     */
    event LendingPoolInitialized(address indexed sender, address asset);

    /**
     * @notice Get the Teller Token address for an underlying asset.
     * @param asset Address to get a Teller Token for.
     */
    function getTTokenFor(address asset)
        external
        view
        returns (address tToken_)
    {
        tToken_ = address(LendingLib.tToken(asset));
    }

    /**
     * @notice It allows users to deposit tokens into the pool.
     * @dev the user must call ERC20.approve function previously.
     * @dev If the cToken is available (not 0x0), it deposits the lending asset amount into Compound directly.
     * @param asset Token address to deposit into the lending pool.
     * @param amount Amount of {asset} to deposit in the pool.
     */
    function lendingPoolDeposit(address asset, uint256 amount)
        external
        paused(LendingLib.ID, false)
        authorized(AUTHORIZED, msg.sender)
        nonReentry(LendingLib.ID)
    {
        ITToken tToken = LendingLib.tToken(asset);
        require(
            address(tToken) != address(0),
            "Teller: lending pool not initialized"
        );

        require(
            tToken.currentTVL() + amount <= MaxTVLLib.get(asset),
            "Teller: deposit TVL exceeded"
        );

        // Transfer tokens from lender
        SafeERC20.safeTransferFrom(
            IERC20(asset),
            msg.sender,
            address(this),
            amount
        );
        // Set allowance for Teller token to pull funds to mint
        SafeERC20.safeIncreaseAllowance(IERC20(asset), address(tToken), amount);
        // Mint Teller tokens, then transfer to lender
        SafeERC20Upgradeable.safeTransfer(
            tToken,
            msg.sender,
            // Minting returns the amount of Teller tokens minted
            tToken.mint(amount)
        );
    }

    /**
     * @notice Initialized a new lending pool for {asset}
     * @param asset Token address to initialize the lending pool for.
     */
    function initLendingPool(address asset)
        external
        authorized(ADMIN, msg.sender)
    {
        require(
            address(LendingLib.tToken(asset)) == address(0),
            "Teller: lending pool already initialized"
        );

        // Create a new Teller Token
        address tToken = AppStorageLib.store().tTokenBeacon.cloneProxy("");
        // Set the Teller Token to the asset mapping
        LendingLib.s().tTokens[asset] = ITToken(tToken);
        // Initialize the Teller Token
        LendingLib.s().tTokens[asset].initialize(msg.sender, asset);

        // Emit event
        emit LendingPoolInitialized(msg.sender, asset);
    }
}
