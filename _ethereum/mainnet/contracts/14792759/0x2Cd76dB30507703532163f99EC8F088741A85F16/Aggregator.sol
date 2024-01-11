// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Ownable.sol";
import "./SafeERC20.sol";

import "./IAggregationRouterV4.sol";
import "./UniERC20.sol";

contract Aggregator is Ownable {
    using UniERC20 for IERC20;
    using SafeERC20 for IERC20;

    uint256 public feeAmount;
    address payable public feeAddress;

    IAggregationRouterV4 aggregationRouter;

    constructor(
        uint256 _feeAmount,
        address payable _feeAddress,
        address router
    ) {
        feeAmount = _feeAmount;
        feeAddress = _feeAddress;
        aggregationRouter = IAggregationRouterV4(router);
    }

    receive() external payable {}

    function setFeeAmount(uint256 _feeAmount) public onlyOwner {
        feeAmount = _feeAmount;
    }

    function setFeeAddress(address payable _feeAddress) public onlyOwner {
        feeAddress = _feeAddress;
    }

    function swap(
        IAggregationExecutor caller,
        IAggregationRouterV4.SwapDescription calldata desc,
        bytes calldata data
    ) external payable {
        require(msg.value >= feeAmount, "Aggregator: fee is not enough");
        feeAddress.transfer(feeAmount);

        IERC20 srcToken = desc.srcToken;
        bool srcETH = srcToken.isETH();

        if (!srcETH) {
            srcToken.safeTransferFrom(msg.sender, address(this), desc.amount);
            srcToken.approve(address(aggregationRouter), desc.amount);
        }

        aggregationRouter.swap{value: srcETH ? desc.amount : 0}(
            caller,
            desc,
            data
        );
    }
}
