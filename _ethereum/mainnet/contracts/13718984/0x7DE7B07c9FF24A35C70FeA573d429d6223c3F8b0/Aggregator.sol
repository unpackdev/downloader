// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { Address } from "Address.sol";
import "SafeERC20.sol";
import "ERC20.sol";
import "SafeMath.sol";
import "AccessControl.sol";
import "ReentrancyGuard.sol";
import "IAggregator.sol";


/// @title Library for unifying getting balance in one interface
/// @notice Use `uniBalanceOf` to get amount of the desired token or native token balance
library UniERC20 {

    // native token addresses
    address private constant _ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant _ZERO_ADDRESS = address(0);

    /// @notice Check if the given token address is native token
    /// @param token The token address to be checked
    /// @return `true` if native token, otherwise `false`
    function isETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == _ZERO_ADDRESS || address(token) == _ETH_ADDRESS);
    }

    /// @notice Get balance of the desired account address of the given token
    /// @param token The token address to be checked
    /// @param account The address to be checked
    /// @return The token balance of the desired account address
    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }
}

/// @title Aggregator is to help exchange assets based on swap description struct
/// @notice Users can call `swap` method to swap assets
/// Aggregator will forward the swap description to `caller` contract to perform multi-swap of assets
contract Aggregator is IAggregator, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using UniERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    // ROLE_OWNER is superior to ROLE_STAFF
    bytes32 public constant ROLE_OWNER = keccak256("ROLE_OWNER");
    bytes32 public constant ROLE_STAFF = keccak256("ROLE_STAFF");

    /// A contract that performs multi-swap according to given input data
    /// See Multicaller.sol for more info
    address payable public caller;

    /* ========== CONSTRUCTOR ========== */

    /// @dev Constuctor with owner / staff / caller
    /// @param owner The owner address
    /// @param staff The staff address
    /// @param _caller The caller contract address (MUST be a contract)
    constructor(address owner, address staff, address payable _caller) {
        _setRoleAdmin(ROLE_OWNER, ROLE_OWNER);
        _setRoleAdmin(ROLE_STAFF, ROLE_OWNER);
        _setupRole(ROLE_OWNER, owner);
        _setupRole(ROLE_STAFF, staff);

        require(Address.isContract(_caller), "ERR_MULTICALLER_NOT_CONTRACT");
        caller = _caller;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice Set caller address (could be set only by staff)
    /// @param _caller The multicaller contract address that performs multi-swap
    function setCaller(address payable _caller) external onlyRole(ROLE_STAFF) {
        require(Address.isContract(_caller), "ERR_MULTICALLER_NOT_CONTRACT");
        caller = _caller;
    }

    /* ========== WRITE FUNCTIONS ========== */

    /// @notice Swap and check if it's done correctly according to swap description `desc`
    /// This function transfers asset from sender `msg.sender` and then call multicaller contract `caller` to perform multi-swap,
    /// and checks `minReturnAmount` in `desc` to ensure enough amount of desired token `toToken` is received after the swap.
    /// @param desc The description of the swap. See IAggregator.sol for more info.
    /// @param data Bytecode to execute the swap, forwarded to `caller`
    /// @return Received amount of `toToken` after the swap
    function swap(
        SwapDescription calldata desc,
        bytes calldata data
    )
        external
        override
        payable
        nonReentrant
        returns (uint256)
    {
        require(desc.minReturnAmount > 0, "Min return should not be 0");
        require(data.length > 0, "data should be not zero");

        IERC20 fromToken = desc.fromToken;
        IERC20 toToken = desc.toToken;

        require(msg.value == (fromToken.isETH() ? desc.amount : 0), "Invalid msg.value");

        uint256 amount = desc.amount;
        if (!fromToken.isETH()) {
            amount = fromToken.balanceOf(caller);
            fromToken.safeTransferFrom(msg.sender, caller, desc.amount);
            amount = fromToken.balanceOf(caller) - amount;
        }

        require(desc.receiver != address(0), "Invalid receiver");
        address receiver = desc.receiver;
        uint256 toTokenBalance = toToken.uniBalanceOf(receiver);

        Address.functionCallWithValue(caller, data, msg.value, "Caller multiswap failed");

        uint256 returnAmount = toToken.uniBalanceOf(receiver) - toTokenBalance;
        require(returnAmount >= desc.minReturnAmount, "Return amount is not enough");

        emit Swapped(
            msg.sender,
            fromToken,
            toToken,
            receiver,
            amount,
            returnAmount
        );
        return returnAmount;
    }

    /* ========== EVENTS ========== */

    event Swapped(
        address sender,
        IERC20 fromToken,
        IERC20 toToken,
        address receiver,
        uint256 spentAmount,
        uint256 returnAmount
    );
}
