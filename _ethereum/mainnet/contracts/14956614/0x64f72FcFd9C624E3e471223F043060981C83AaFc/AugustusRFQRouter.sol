// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "./AugustusStorage.sol";
import "./IRouter.sol";
import "./IWETH.sol";
import "./Utils.sol";
import "./IAugustusRFQ.sol";

contract AugustusRFQRouter is AugustusStorage, IRouter {
    using SafeMath for uint256;

    address public immutable weth;
    address public immutable exchange;

    constructor(address _weth, address _exchange) public {
        weth = _weth;
        exchange = _exchange;
    }

    function initialize(bytes calldata) external override {
        revert("METHOD NOT IMPLEMENTED");
    }

    function getKey() external pure override returns (bytes32) {
        return keccak256(abi.encodePacked("AUGUSTUS_RFQ_ROUTER", "1.0.0"));
    }

    function swapOnAugustusRFQ(
        IAugustusRFQ.Order calldata order,
        bytes calldata signature,
        uint8 wrapETH // set 0 bit to wrap src, and 1 bit to wrap dst
    ) external payable {
        address userAddress = address(uint160(order.nonceAndMeta));
        require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");

        uint256 fromAmount = order.takerAmount;
        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            tokenTransferProxy.transferFrom(order.takerAsset, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, order.takerAsset, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).fillOrder(order, signature);
            uint256 receivedAmount = Utils.tokenBalance(order.makerAsset, address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).fillOrderWithTarget(order, signature, msg.sender);
        }
    }

    function swapOnAugustusRFQWithPermit(
        IAugustusRFQ.Order calldata order,
        bytes calldata signature,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        bytes calldata permit
    ) external payable {
        address userAddress = address(uint160(order.nonceAndMeta));
        require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");

        uint256 fromAmount = order.takerAmount;
        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            Utils.permit(order.takerAsset, permit);
            tokenTransferProxy.transferFrom(order.takerAsset, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, order.takerAsset, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).fillOrder(order, signature);
            uint256 receivedAmount = Utils.tokenBalance(order.makerAsset, address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).fillOrderWithTarget(order, signature, msg.sender);
        }
    }

    function swapOnAugustusRFQNFT(
        IAugustusRFQ.OrderNFT calldata order,
        bytes calldata signature,
        uint8 wrapETH // set 0 bit to wrap src, and 1 bit to wrap dst
    ) external payable {
        address userAddress = address(uint160(order.nonceAndMeta));
        require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");

        uint256 fromAmount = order.takerAmount;
        address fromToken = address(uint160(order.takerAsset));
        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            tokenTransferProxy.transferFrom(fromToken, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, fromToken, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).fillOrderNFT(order, signature);
            uint256 receivedAmount = Utils.tokenBalance(address(uint160(order.makerAsset)), address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).fillOrderWithTargetNFT(order, signature, msg.sender);
        }
    }

    function swapOnAugustusRFQNFTWithPermit(
        IAugustusRFQ.OrderNFT calldata order,
        bytes calldata signature,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        bytes calldata permit
    ) external payable {
        address userAddress = address(uint160(order.nonceAndMeta));
        require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");

        uint256 fromAmount = order.takerAmount;
        address fromToken = address(uint160(order.takerAsset));
        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            Utils.permit(fromToken, permit);
            tokenTransferProxy.transferFrom(fromToken, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, fromToken, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).fillOrderNFT(order, signature);
            uint256 receivedAmount = Utils.tokenBalance(address(uint160(order.makerAsset)), address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).fillOrderWithTargetNFT(order, signature, msg.sender);
        }
    }

    function partialSwapOnAugustusRFQ(
        IAugustusRFQ.Order calldata order,
        bytes calldata signature,
        bytes calldata makerPermit,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        uint256 fromAmount
    ) external payable {
        address userAddress = address(uint160(order.nonceAndMeta));
        require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");

        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            tokenTransferProxy.transferFrom(order.takerAsset, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, order.takerAsset, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).partialFillOrderWithTargetPermit(
                order,
                signature,
                fromAmount,
                address(this),
                bytes(""),
                makerPermit
            );
            uint256 receivedAmount = Utils.tokenBalance(order.makerAsset, address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).partialFillOrderWithTargetPermit(
                order,
                signature,
                fromAmount,
                msg.sender,
                bytes(""),
                makerPermit
            );
        }
    }

    function partialSwapOnAugustusRFQWithPermit(
        IAugustusRFQ.Order calldata order,
        bytes calldata signature,
        bytes calldata makerPermit,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        uint256 fromAmount,
        bytes calldata permit
    ) external payable {
        address userAddress = address(uint160(order.nonceAndMeta));
        require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");

        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            Utils.permit(order.takerAsset, permit);
            tokenTransferProxy.transferFrom(order.takerAsset, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, order.takerAsset, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).partialFillOrderWithTargetPermit(
                order,
                signature,
                fromAmount,
                address(this),
                bytes(""),
                makerPermit
            );
            uint256 receivedAmount = Utils.tokenBalance(order.makerAsset, address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).partialFillOrderWithTargetPermit(
                order,
                signature,
                fromAmount,
                msg.sender,
                bytes(""),
                makerPermit
            );
        }
    }

    function partialSwapOnAugustusRFQNFT(
        IAugustusRFQ.OrderNFT calldata order,
        bytes calldata signature,
        bytes calldata makerPermit,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        uint256 fromAmount
    ) external payable {
        address userAddress = address(uint160(order.nonceAndMeta));
        require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");

        address fromToken = address(uint160(order.takerAsset));
        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            tokenTransferProxy.transferFrom(fromToken, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, fromToken, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).partialFillOrderWithTargetPermitNFT(
                order,
                signature,
                fromAmount,
                address(this),
                bytes(""),
                makerPermit
            );
            uint256 receivedAmount = Utils.tokenBalance(address(uint160(order.makerAsset)), address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).partialFillOrderWithTargetPermitNFT(
                order,
                signature,
                fromAmount,
                msg.sender,
                bytes(""),
                makerPermit
            );
        }
    }

    function partialSwapOnAugustusRFQNFTWithPermit(
        IAugustusRFQ.OrderNFT calldata order,
        bytes calldata signature,
        bytes calldata makerPermit,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        uint256 fromAmount,
        bytes calldata permit
    ) external payable {
        address userAddress = address(uint160(order.nonceAndMeta));
        require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");

        address fromToken = address(uint160(order.takerAsset));
        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            Utils.permit(fromToken, permit);
            tokenTransferProxy.transferFrom(fromToken, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, fromToken, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).partialFillOrderWithTargetPermitNFT(
                order,
                signature,
                fromAmount,
                address(this),
                bytes(""),
                makerPermit
            );
            uint256 receivedAmount = Utils.tokenBalance(address(uint160(order.makerAsset)), address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).partialFillOrderWithTargetPermitNFT(
                order,
                signature,
                fromAmount,
                msg.sender,
                bytes(""),
                makerPermit
            );
        }
    }

    function swapOnAugustusRFQTryBatchFill(
        IAugustusRFQ.OrderInfo[] calldata orderInfos,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        uint256 fromAmount,
        uint256 toAmountMin
    ) external payable {
        uint256 orderCount = orderInfos.length;
        require(orderCount > 0, "missing orderInfos");
        for (uint256 i = 0; i < orderCount; ++i) {
            address userAddress = address(uint160(orderInfos[i].order.nonceAndMeta));
            require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");
        }

        address fromToken = orderInfos[0].order.takerAsset;
        address toToken = orderInfos[0].order.makerAsset;

        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            tokenTransferProxy.transferFrom(fromToken, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, fromToken, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).tryBatchFillOrderTakerAmount(orderInfos, fromAmount, address(this));
            uint256 receivedAmount = Utils.tokenBalance(toToken, address(this));
            require(receivedAmount >= toAmountMin, "Received amount of tokens are less then expected");
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            uint256 startBalance = Utils.tokenBalance(toToken, msg.sender);
            IAugustusRFQ(exchange).tryBatchFillOrderTakerAmount(orderInfos, fromAmount, msg.sender);
            uint256 receivedAmount = Utils.tokenBalance(toToken, msg.sender).sub(startBalance);
            require(receivedAmount >= toAmountMin, "Received amount of tokens are less then expected");
        }
    }

    function swapOnAugustusRFQTryBatchFillWithPermit(
        IAugustusRFQ.OrderInfo[] calldata orderInfos,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        uint256 fromAmount,
        uint256 toAmountMin,
        bytes calldata permit
    ) external payable {
        uint256 orderCount = orderInfos.length;
        require(orderCount > 0, "missing orderInfos");
        for (uint256 i = 0; i < orderCount; ++i) {
            address userAddress = address(uint160(orderInfos[i].order.nonceAndMeta));
            require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");
        }

        address fromToken = orderInfos[0].order.takerAsset;
        address toToken = orderInfos[0].order.makerAsset;

        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            Utils.permit(fromToken, permit);
            tokenTransferProxy.transferFrom(fromToken, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, fromToken, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).tryBatchFillOrderTakerAmount(orderInfos, fromAmount, address(this));
            uint256 receivedAmount = Utils.tokenBalance(toToken, address(this));
            require(receivedAmount >= toAmountMin, "Received amount of tokens are less then expected");
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            uint256 startBalance = Utils.tokenBalance(toToken, msg.sender);
            IAugustusRFQ(exchange).tryBatchFillOrderTakerAmount(orderInfos, fromAmount, msg.sender);
            uint256 receivedAmount = Utils.tokenBalance(toToken, msg.sender).sub(startBalance);
            require(receivedAmount >= toAmountMin, "Received amount of tokens are less then expected");
        }
    }

    function buyOnAugustusRFQTryBatchFill(
        IAugustusRFQ.OrderInfo[] calldata orderInfos,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        uint256 fromAmountMax,
        uint256 toAmount
    ) external payable {
        uint256 orderCount = orderInfos.length;
        require(orderCount > 0, "missing orderInfos");
        for (uint256 i = 0; i < orderCount; ++i) {
            address userAddress = address(uint160(orderInfos[i].order.nonceAndMeta));
            require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");
        }

        address fromToken = orderInfos[0].order.takerAsset;

        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmountMax, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmountMax }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            tokenTransferProxy.transferFrom(fromToken, msg.sender, address(this), fromAmountMax);
        }
        Utils.approve(exchange, fromToken, fromAmountMax);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).tryBatchFillOrderMakerAmount(orderInfos, toAmount, address(this));
            uint256 receivedAmount = Utils.tokenBalance(orderInfos[0].order.makerAsset, address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).tryBatchFillOrderMakerAmount(orderInfos, toAmount, msg.sender);
        }

        if (wrapETH & 1 != 0) {
            uint256 remainingAmount = Utils.tokenBalance(weth, address(this));
            if (remainingAmount > 0) {
                IWETH(weth).withdraw(remainingAmount);
                Utils.transferETH(msg.sender, remainingAmount);
            }
        } else {
            uint256 remainingAmount = Utils.tokenBalance(fromToken, address(this));
            Utils.transferTokens(fromToken, msg.sender, remainingAmount);
        }
    }

    function buyOnAugustusRFQTryBatchFillWithPermit(
        IAugustusRFQ.OrderInfo[] calldata orderInfos,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        uint256 fromAmountMax,
        uint256 toAmount,
        bytes calldata permit
    ) external payable {
        uint256 orderCount = orderInfos.length;
        require(orderCount > 0, "missing orderInfos");
        for (uint256 i = 0; i < orderCount; ++i) {
            address userAddress = address(uint160(orderInfos[i].order.nonceAndMeta));
            require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");
        }

        address fromToken = orderInfos[0].order.takerAsset;

        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmountMax, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmountMax }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            Utils.permit(fromToken, permit);
            tokenTransferProxy.transferFrom(fromToken, msg.sender, address(this), fromAmountMax);
        }
        Utils.approve(exchange, fromToken, fromAmountMax);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).tryBatchFillOrderMakerAmount(orderInfos, toAmount, address(this));
            uint256 receivedAmount = Utils.tokenBalance(orderInfos[0].order.makerAsset, address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).tryBatchFillOrderMakerAmount(orderInfos, toAmount, msg.sender);
        }

        if (wrapETH & 1 != 0) {
            uint256 remainingAmount = Utils.tokenBalance(weth, address(this));
            if (remainingAmount > 0) {
                IWETH(weth).withdraw(remainingAmount);
                Utils.transferETH(msg.sender, remainingAmount);
            }
        } else {
            uint256 remainingAmount = Utils.tokenBalance(fromToken, address(this));
            Utils.transferTokens(fromToken, msg.sender, remainingAmount);
        }
    }
}
