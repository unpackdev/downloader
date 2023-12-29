// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "./ReentrancyGuard.sol";
import "./ERC4626.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IMinter.sol";
import "./Errors.sol";

/// @author 0xtekgrinder
/// @title Zap contract
/// @notice Contract to zap tokens to mint WAR and deposit it into the vault
contract Zap is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Event emitted when a zap happens
     */
    event ZapHappened(address indexed sender, address indexed receiver, uint256 shares);

    /*//////////////////////////////////////////////////////////////
                            MUTABLE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Address of war token
     */
    address public immutable asset;
    /**
     * @notice Address of the auto compounding war vault
     */
    address public immutable vault;
    /**
     * @notice Address of the war minter
     */
    address public immutable minter;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address definitiveAsset, address definitiveVault, address definitiveMinter) {
        if (definitiveAsset == address(0) || definitiveVault == address(0) || definitiveMinter == address(0)) {
            revert Errors.ZeroAddress();
        }
        asset = definitiveAsset;
        vault = definitiveVault;
        minter = definitiveMinter;

        IERC20(asset).safeApprove(vault, type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                              ZAP LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Zaps a given amount of tokens to mint WAR and deposit it
     * @param token Address of the token to deposit
     * @param amount Amount to deposit
     * @param receiver Address to stake for
     * @return uint256 : Amount of shares minted
     */
    function zap(address token, uint256 amount, address receiver) external nonReentrant returns (uint256) {
        if (amount == 0) revert Errors.ZeroValue();
        if (token == address(0) || receiver == address(0)) revert Errors.ZeroAddress();

        uint256 prevBalance = IERC20(asset).balanceOf(address(this));

        // Pull the token
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Mint WAR
        IERC20(token).safeIncreaseAllowance(address(minter), amount);
        IMinter(minter).mint(token, amount);

        uint256 mintedAmount = IERC20(asset).balanceOf(address(this)) - prevBalance;

        // Stake the WAR tokens for the receiver
        uint256 depositedAmount = ERC4626(vault).deposit(mintedAmount, receiver);

        emit ZapHappened(msg.sender, receiver, depositedAmount);

        return depositedAmount;
    }

    /**
     * @notice Zaps given amounts of tokens to mint WAR and deposit it
     * @param vlTokens List of token addresses to deposit
     * @param amounts Amounts to deposit for each token
     * @param receiver Address to stake for
     * @return uint256 : Amount of shares minted
     */
    function zapMultiple(address[] calldata vlTokens, uint256[] calldata amounts, address receiver)
        external
        nonReentrant
        returns (uint256)
    {
        if (receiver == address(0)) revert Errors.ZeroAddress();
        uint256 length = vlTokens.length;
        if (length != amounts.length) revert Errors.DifferentSizeArrays(length, amounts.length);
        if (length == 0) revert Errors.EmptyArray();

        uint256 prevBalance = IERC20(asset).balanceOf(address(this));

        // for each token in the list
        for (uint256 i; i < length;) {
            address token = vlTokens[i];
            uint256 amount = amounts[i];
            if (amount == 0) revert Errors.ZeroValue();
            if (token == address(0)) revert Errors.ZeroAddress();

            // Pull the token
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

            // Mint WAR
            IERC20(token).safeIncreaseAllowance(address(minter), amount);
            IMinter(minter).mint(token, amount);

            unchecked {
                i++;
            }
        }

        // Get the total amount of WAR minted
        uint256 mintedAmount = IERC20(asset).balanceOf(address(this)) - prevBalance;

        // Stake the WAR tokens for the receiver
        uint256 depositeddAmount = ERC4626(vault).deposit(mintedAmount, receiver);

        emit ZapHappened(msg.sender, receiver, depositeddAmount);

        return depositeddAmount;
    }
}
