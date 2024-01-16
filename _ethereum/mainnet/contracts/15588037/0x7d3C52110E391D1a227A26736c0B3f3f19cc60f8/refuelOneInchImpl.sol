// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MiddlewareImplBase.sol";
import "./refuel.sol";
import "./errors.sol";

/**
// @title One Inch Swap Implementation
// @notice Called by the registry before cross chain transfers if the user requests
// for a swap
// @dev Follows the interface of Swap Impl Base
// @author Movr Network
*/
contract OneInchRefuelSwapImpl is MiddlewareImplBase {
    using SafeERC20 for IERC20;
    address payable public oneInchAggregator;
    IRefuel public router;
    event UpdateOneInchAggregatorAddress(address indexed oneInchAggregator);
    event AmountRecieved(
        uint256 amount,
        address tokenAddress,
        address receiver
    );
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// one inch aggregator contract is payable to allow ethereum swaps
    constructor(
        address registry,
        address _oneInchAggregator,
        IRefuel _router
    ) MiddlewareImplBase(registry) {
        oneInchAggregator = payable(_oneInchAggregator);
        router = _router;
    }

    /// @notice Sets oneInchAggregator address
    /// @param _oneInchAggregator is the address for oneInchAggreagtor
    function setOneInchAggregator(address _oneInchAggregator)
        external
        onlyOwner
    {
        oneInchAggregator = payable(_oneInchAggregator);
        emit UpdateOneInchAggregatorAddress(_oneInchAggregator);
    }

    /**
    // @notice Function responsible for swapping from one token to a different token
    // @dev This is called only when there is a request for a swap. 
    // @param from userAddress or sending address.
    // @param fromToken token to be swapped
    // @param amount amount to be swapped 
    // param to not required. This is there only to follow the MiddlewareImplBase
    // @param extraData data required for the one inch aggregator to get the swap done
    */
    function performAction(
        address from,
        address fromToken,
        uint256 amount,
        address,
        bytes calldata extraData
    ) external payable override onlyRegistry returns (uint256) {
        require(fromToken != address(0), MovrErrors.ADDRESS_0_PROVIDED);
        (
            uint256 _destinationChainId,
            address _destionationReceiverAddress,
            uint256 _refuelAmount,
            bytes memory swapExtraData
        ) = abi.decode(extraData, (uint256, address, uint256, bytes));

        // if _refuelAmount is greater than 0, then we perform refuel step

        if (_refuelAmount > 0)
            router.depositNativeToken{value: _refuelAmount}(
                _destinationChainId,
                _destionationReceiverAddress
            );

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            IERC20 fromTokenInstance = IERC20(fromToken);
            fromTokenInstance.safeTransferFrom(from, address(this), amount);
            fromTokenInstance.safeIncreaseAllowance(oneInchAggregator, amount);
            {
                // solhint-disable-next-line
                (bool success, bytes memory result) = oneInchAggregator.call(
                    swapExtraData
                );
                fromTokenInstance.safeApprove(oneInchAggregator, 0);
                require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
                (uint256 returnAmount, ) = abi.decode(
                    result,
                    (uint256, uint256)
                );
                return returnAmount;
            }
        } else {
            (bool success, bytes memory result) = oneInchAggregator.call{
                value: amount
            }(swapExtraData);
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
            (uint256 returnAmount, ) = abi.decode(result, (uint256, uint256));
            return returnAmount;
        }
    }

    /**
    // @notice Function responsible for swapping from one token to a different token directly
    // @dev This is called only when there is a request for a swap. 
    // @param fromToken token to be swapped
    // @param amount amount to be swapped 
    // @param extraData data required for the one inch aggregator to get the swap done
    */
    function performDirectAction(
        address fromToken,
        address toToken,
        address receiver,
        uint256 amount,
        bytes calldata extraData
    ) external payable {
        (
            uint256 _destinationChainId,
            uint256 _refuelAmount,
            bytes memory swapExtraData
        ) = abi.decode(extraData, (uint256, uint256, bytes));

        // if _refuelAmount is greater than 0, then we perform refuel step

        if (_refuelAmount > 0)
            router.depositNativeToken{value: _refuelAmount}(
                _destinationChainId,
                receiver
            );

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            IERC20 fromTokenInstance = IERC20(fromToken);
            fromTokenInstance.safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
            fromTokenInstance.safeIncreaseAllowance(oneInchAggregator, amount);
            {
                // solhint-disable-next-line
                (bool success, bytes memory result) = oneInchAggregator.call(
                    swapExtraData
                );
                fromTokenInstance.safeApprove(oneInchAggregator, 0);
                require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
                (uint256 returnAmount, ) = abi.decode(
                    result,
                    (uint256, uint256)
                );
                emit AmountRecieved(returnAmount, toToken, receiver);
            }
        } else {
            (bool success, bytes memory result) = oneInchAggregator.call{
                value: amount
            }(swapExtraData);
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
            (uint256 returnAmount, ) = abi.decode(result, (uint256, uint256));
            emit AmountRecieved(returnAmount, toToken, receiver);
        }
    }
}
