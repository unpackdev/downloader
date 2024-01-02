// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./L1SwapVaultStorage.sol";

import "./ERC20.sol";
import "./IL1ERC20Bridge.sol";
import "./SafeTransferLib.sol";

/// @title L1SwapVault
/// @notice Custodies reserves for executing swaps on L1
/// @dev Completed swaps are automatically bridged back to L1
contract L1SwapVault is OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable, L1SwapVaultStorage {
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The name of the contract
    string public constant name = "L1SwapVault";

    /// @notice The L2 gas when depositing tokens
    uint32 public constant l2Gas = 400000;

    /// @notice The L1 bridge contract
    IL1ERC20Bridge public immutable l1Bridge;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Constructor
    /// @param _l1Bridge The L1 bridge
    constructor(address _l1Bridge) {
        _disableInitializers();

        l1Bridge = IL1ERC20Bridge(_l1Bridge);
    }

    /// @notice Initializes the proxy with the sender as the owner
    /// @param _dedicated The dedication flag

    function initialize(bool _dedicated) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        dedicated = _dedicated;
    }

    /*//////////////////////////////////////////////////////////////
                            OWNER OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Updates a keeper
    /// @dev Can only be called by the owner
    /// @param keeper The address of the keeper
    /// @param allowed True if the address is authorized, false otherwise
    function updateKeeper(address keeper, bool allowed) external onlyOwner {
        require(keeper != address(0), "ZERO_ADDRESS");

        keepers[keeper] = allowed;

        emit KeeperUpdated(keeper, allowed);
    }

    /// @notice Updates a whitelisted target swap contract
    /// @dev Can only be called by the owner
    /// @param target The address of the target swap
    /// @param allowed True if the address is authorized, false otherwise
    function updateWhitelisted(address target, bool allowed) external onlyOwner {
        require(target != address(0), "ZERO_ADDRESS");

        whitelisted[target] = allowed;

        emit WhitelistUpdated(target, allowed);
    }

    /// @notice Updates a whitelisted token
    /// @dev Can only be called by the owner
    /// @param token The address of the token
    /// @param allowed True if the address is authorized, false otherwise
    function updateWhitelistedToken(address token, bool allowed) external onlyOwner {
        require(token != address(0), "ZERO_ADDRESS");

        whitelistedToken[token] = allowed;

        emit WhitelistTokenUpdated(token, allowed);
    }

    /// @notice Updates a recipient
    /// @dev Can only be called by the owner
    /// @param recipient The address of the recipient on L2
    /// @param allowed True if the address is authorized, false otherwise
    function updateRecipient(address recipient, bool allowed) external onlyOwner {
        require(recipient != address(0), "ZERO_ADDRESS");

        recipients[recipient] = allowed;

        emit RecipientUpdated(recipient, allowed);
    }

    /// @notice Updates the dedication flag
    /// @dev Can only be called by the owner
    /// @param _dedicated True if the contract is dedicated, false otherwise
    function updateDedication(bool _dedicated) external onlyOwner {
        dedicated = _dedicated;

        emit DedicationUpdated(_dedicated);
    }

    /// @notice Withdraws deposited token reserves
    /// @dev Can only be called by the owner
    /// @param token The address of the token
    /// @param amount The amount to withdraw
    function withdrawReserves(address token, uint256 amount) external onlyOwner {
        ERC20(token).safeTransfer(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                           KEEPER OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Reverts if the caller is not a keeper
    modifier onlyKeeper() {
        require(keepers[msg.sender], "NOT_KEEPER");

        _;
    }

    /// @notice Execute an L2 swap on L1
    /// @dev Can only be called by a keeper
    /// @param executeSwap The data to execute the swap
    /// @return amountOut The amount received from the swap
    function swap(ExecuteSwap calldata executeSwap) external onlyKeeper nonReentrant returns (uint256 amountOut) {
        require(whitelisted[executeSwap.target], "NOT_WHITELISTED");
        require(whitelistedToken[executeSwap.tokenIn], "NOT_WHITELISTED_TOKEN_IN");
        require(whitelistedToken[executeSwap.tokenOut], "NOT_WHITELISTED_TOKEN_OUT");

        require(!dedicated || recipients[executeSwap.account], "NOT_RECIPIENT");

        // Block the same swap from getting executed twice
        bytes memory swapKey = abi.encodePacked(executeSwap.withdrawProxy, executeSwap.id);
        require(!executed[bytes32(swapKey)], "EXECUTED");
        executed[bytes32(swapKey)] = true;

        uint256 balanceOf = ERC20(executeSwap.tokenOut).balanceOf(address(this));

        ERC20(executeSwap.tokenIn).safeApprove(executeSwap.target, 0);
        ERC20(executeSwap.tokenIn).safeApprove(executeSwap.target, executeSwap.amountIn);
        (bool success,) = executeSwap.target.call(executeSwap.data);
        require(success, "SWAP_FAILED");

        amountOut = ERC20(executeSwap.tokenOut).balanceOf(address(this)) - balanceOf;
        require(amountOut >= executeSwap.amountOutMinimum, "INSUFFICIENT_OUTPUT_AMOUNT");

        // Deposit the tokens to the accounts balance on L2
        ERC20(executeSwap.tokenOut).safeApprove(address(l1Bridge), amountOut);
        l1Bridge.depositERC20To(
            executeSwap.tokenOut,
            executeSwap.l2TokenOut,
            executeSwap.account,
            amountOut,
            l2Gas,
            swapKey // The ABI-encoded data is only for observability
        );

        emit Swapped(
            executeSwap.id,
            executeSwap.withdrawProxy,
            executeSwap.account,
            executeSwap.tokenIn,
            executeSwap.amountIn,
            executeSwap.tokenOut,
            executeSwap.l2TokenOut,
            executeSwap.amountOutMinimum,
            amountOut
        );
    }

    /*//////////////////////////////////////////////////////////////
                             UPGRADE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Authorizes an upgrade, ensuring that the owner is performing the upgrade
    /// @param newImplementation The new contract implementation to upgrade to
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
