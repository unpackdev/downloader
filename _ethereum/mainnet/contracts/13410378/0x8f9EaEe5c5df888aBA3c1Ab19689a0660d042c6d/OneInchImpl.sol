// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MiddlewareImplBase.sol";
import "./errors.sol";

/**
// @title One Inch Swap Implementation
// @notice Called by the registry before cross chain transfers if the user requests
// for a swap
// @dev Follows the interface of Swap Impl Base
// @author Movr Network
*/
contract OneInchSwapImpl is MiddlewareImplBase {
    using SafeERC20 for IERC20;
    address payable public oneInchAggregator;

    /// one inch aggregator contract is payable to allow ethereum swaps
    constructor(address registry, address _oneInchAggregator)
        MiddlewareImplBase(registry)
    {
        oneInchAggregator = payable(_oneInchAggregator);
    }

    /// @notice Sets oneInchAggregator address
    /// @param _oneInchAggregator is the address for oneInchAggreagtor
    function setOneInchAggregator(address _oneInchAggregator)
        external
        onlyOwner
    {
        oneInchAggregator = payable(_oneInchAggregator);
    }

    /**
    // @notice Function responsible for swapping from one token to a different token
    // @dev This is called only when there is a request for a swap. 
    // @param from userAddress or sending address.
    // @param fromToken token to be swapped
    // @param amount amount to be swapped 
    // param to not required. This is there only to follow the MiddlewareImplBase
    // @param swapExtraData data required for the one inch aggregator to get the swap done
    */
    function performAction(
        address from,
        address fromToken,
        uint256 amount,
        address, // to
        bytes memory swapExtraData
    ) external payable override onlyRegistry returns (uint256) {
        IERC20(fromToken).safeTransferFrom(from, address(this), amount);
        IERC20(fromToken).safeIncreaseAllowance(oneInchAggregator, amount);
        {
            // solhint-disable-next-line
            (bool success, bytes memory result) =
                oneInchAggregator.call{value: msg.value}(swapExtraData);

            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
            (uint256 returnAmount, ) = abi.decode(result, (uint256, uint256));
            return returnAmount;
        }
    }
}
