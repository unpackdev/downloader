// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MiddlewareImplBase.sol";
import "./refuel.sol";
import "./errors.sol";

/**
// @title Refuel Implementation
// @notice Called by the registry before cross chain transfers if the user requests
// for a refuel
// @dev Follows the interface of Swap Impl Base
// @author Socket Technology
*/
contract RefuelImpl is MiddlewareImplBase {
    IRefuel public router;
    using SafeERC20 for IERC20;
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    constructor(IRefuel _router, address registry)
        MiddlewareImplBase(registry)
    {
        router = _router;
    }

    function performAction(
        address from,
        address fromToken,
        uint256 amount,
        address registry,
        bytes calldata extraData
    ) external payable override onlyRegistry returns (uint256) {
        if (fromToken != NATIVE_TOKEN_ADDRESS)
            IERC20(fromToken).safeTransferFrom(from, registry, amount);
        else payable(registry).transfer(amount);

        (
            uint256 refuelAmount,
            uint256 destinationChainId,
            address receiverAddress
        ) = abi.decode(extraData, (uint256, uint256, address));
        router.depositNativeToken{value: refuelAmount}(
            destinationChainId,
            receiverAddress
        );
        return amount;
    }
}
