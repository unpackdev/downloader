// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IVault.sol";
import "./IAsset.sol";

/// @title Coordinates ERC20 swap on balancer executed on behalf of another account.
///
/// @notice
/// Nomenclature:
///
/// fundsOwner: The address holding the the tokens to be swapped. This could
/// be a vault contract, or an msig wallet. Swap proceeds always go back to the fundsOwner.
///
/// executor: the EOA or contract which triggers swap operations. This will typically
/// be an automation task.
///
contract Swapper is Ownable {
    using SafeERC20 for IERC20;

    struct Balances {
        uint256 tokenIn;
        uint256 tokenOut;
    }
   
    IVault public immutable balancerVault;
    address public immutable zeroExProxy;

    /// @notice
    /// Mapping to control which swap executors are allowed
    /// to swap assets for which fund owners.
    ///
    /// The owner can change this mapping. If ownership is revoked,
    /// then the mapping becomes immutable, which would be appropriate
    /// if we deploy one of these contracts per funds owner. Or, 
    /// it could remaining mutable if we want to have a single Swapper
    /// contract deployed, with appropriate security kept over the contract
    /// owner.
    ///
    mapping(address => mapping(address => bool)) public executorsForFundsOwners;

    event EnableExecutor(address indexed executor, address indexed fundsOwner, bool enabled);
    event Swap(address indexed executor, address indexed fundsOwner);

    error InvalidEnableExecutor();
    error ExecutorNotEnabled();
    error InvalidSwap();

    constructor(address _balancerVault, address _zeroExProxy) {
        balancerVault = IVault(_balancerVault);
        zeroExProxy = _zeroExProxy;
    }

    /// @notice
    /// Configure whether a given executor can swap funds for the
    /// specified funds owner.
    function enableExecutorForFundsOwner(
        address executor,
        address fundsOwner,
        bool enabled
    ) external {
        // Only the contract owner or the funds owner can enable an
        // executor.
        if (msg.sender != owner() && msg.sender != fundsOwner) {
            revert InvalidEnableExecutor();
        }

        executorsForFundsOwners[executor][fundsOwner] = enabled;
        emit EnableExecutor(executor, fundsOwner, enabled);
    }

    /// @notice
    /// Perform a single pool swap on Balancer, on behalf of some funds owner. The
    /// funds owner must have set up an appropriate allowance to this
    /// contract.
    function swapBalancer(
        IVault.SingleSwap calldata singleSwap,
        address fundsOwner, 
        uint256 limit,
        uint256 deadline
    ) external returns (uint256) {
        // The executor must be permitted to swap tokens for the specified
        // funds owner
        if(!executorsForFundsOwners[msg.sender][fundsOwner]) {
            revert ExecutorNotEnabled();
        }

        // We have to transfer the in amount to this contract before swapping,
        // so we can only work for swaps with fixed in amounts of ERC20 tokens.
        if(singleSwap.kind != IVault.SwapKind.GIVEN_IN) {
            revert InvalidSwap();
        }
        if(address(singleSwap.assetIn) == address(0) || address(singleSwap.assetOut) == address(0)) {
            revert InvalidSwap();
        }

        IERC20 assetIn = IERC20(address(singleSwap.assetIn));

        // Transfer the funds from the owner to this contract
        assetIn.safeTransferFrom(
            fundsOwner,
            address(this),
            singleSwap.amount
        );

        // Increase the allowance so the balancer vault can access them
        assetIn.safeIncreaseAllowance(address(balancerVault), singleSwap.amount);

        // Then execute the swap on balancer, returning the funds to the
        // owner
        IVault.FundManagement memory funds;
        funds.sender = address(this);
        funds.recipient = payable(fundsOwner);

        uint256 result = balancerVault.swap(
            singleSwap,
            funds,
            limit,
            deadline
        );

        emit Swap(msg.sender, fundsOwner);

        return result;
    }

    /// @notice
    /// Perform a GIVEN_IN batch swap on Balancer, on behalf of some funds owner. 
    /// The funds owner must have set up an appropriate allowance to this
    /// contract.
    function swapBalancerBatch(
        IVault.BatchSwapStep[] calldata swaps,
        IAsset[] calldata assets,
        address fundsOwner, 
        int256[] calldata limits,
        uint256 deadline
    ) external returns (int256[] memory result) {
        // The executor must be permitted to swap tokens for the specified
        // funds owner
        if(!executorsForFundsOwners[msg.sender][fundsOwner]) {
            revert ExecutorNotEnabled();
        }

        IERC20 assetIn;
        uint256 amount;
        for(uint256 i; i < swaps.length; ++i) {
            amount = swaps[i].amount;
            if (amount != 0) {
                // We have to transfer the in amounts to this contract before swapping,
                // so we can only work for swaps with fixed amounts of ERC20 tokens.
                if(address(assets[swaps[i].assetInIndex]) == address(0)) {
                    revert InvalidSwap();
                }
                if(address(assets[swaps[i].assetOutIndex]) == address(0)) {
                    revert InvalidSwap();
                }

                assetIn = IERC20(address(assets[swaps[i].assetInIndex]));

                // Transfer the funds from the owner to this contract
                assetIn.safeTransferFrom(
                    fundsOwner,
                    address(this),
                    amount
                );

                // Increase the allowance so the balancer vault can access them
                assetIn.safeIncreaseAllowance(address(balancerVault), amount);
            }
        }

        // Then execute the swap on balancer, returning the funds to the
        // owner
        {
            IVault.FundManagement memory funds;
            funds.sender = address(this);
            funds.recipient = payable(fundsOwner);

            result = balancerVault.batchSwap(
                IVault.SwapKind.GIVEN_IN,
                swaps,
                assets,
                funds,
                limits,
                deadline
            );
        }

        emit Swap(msg.sender, fundsOwner);
    }

    function swapZeroEx(
        address fundsOwner, 
        address tokenInAddr,
        address tokenOutAddr,
        uint256 tokenInAmount,
        bytes calldata swapData
    ) external {

        // The sender must be permitted to swap tokens for the specified
        // funds owner
        if(!executorsForFundsOwners[msg.sender][fundsOwner]) {
            revert ExecutorNotEnabled();
        }

        IERC20 tokenIn = IERC20(address(tokenInAddr));
        IERC20 tokenOut = IERC20(address(tokenOutAddr));

        
        Balances memory initial = Balances({
            tokenIn: tokenIn.balanceOf(address(this)),
            tokenOut: tokenOut.balanceOf(address(this))
        });

        // Transfer the funds from the owner to this contract
        tokenIn.safeTransferFrom(
            fundsOwner,
            address(this),
            tokenInAmount
        );

        // Increase the allowance so the zeroex proxy can access them
        tokenIn.safeIncreaseAllowance(address(zeroExProxy), tokenInAmount);

        // Execute the swap on zeroEx
        (bool success, bytes memory returndata) = zeroExProxy.call(swapData);
        if (!success) {
            if (returndata.length != 0) {
                // Look for revert reason and bubble it up if present
                // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L232
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            }
            revert InvalidSwap();
        }

        // Verify that we have spent the expected amount, and have received some proceeds
        Balances memory current = Balances({
            tokenIn: tokenIn.balanceOf(address(this)),
            tokenOut: tokenOut.balanceOf(address(this))
        });

        if (current.tokenIn != initial.tokenIn) {
            revert InvalidSwap();
        }

        if(!(current.tokenOut > initial.tokenOut)) {
            revert InvalidSwap();
        }

        // Transfer the proceeds back to the funds owner
        tokenOut.safeTransfer(
            fundsOwner,
            current.tokenOut - initial.tokenOut
        );
        
        emit Swap(msg.sender, fundsOwner);
    }
}
