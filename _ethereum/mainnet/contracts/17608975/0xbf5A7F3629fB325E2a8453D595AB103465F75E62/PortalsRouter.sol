/// SPDX-License-Identifier: GPL-3.0

/// Copyright (C) 2023 Portals.fi

/// @author Portals.fi
/// @notice This contract routes ERC20 and native tokens to the Portals Multicall contract to
/// transform an input token into a minimum quantity of an output token.

pragma solidity 0.8.19;

import "./IPortalsRouter.sol";
import { IPortalsMulticall } from
    "../multicall/interface/IPortalsMulticall.sol";
import "./RouterBase.sol";

contract PortalsRouter is RouterBase {
    constructor(address _admin, IPortalsMulticall _multicall)
        RouterBase(_admin, _multicall)
    { }

    /// @notice This function is the simplest entry point for the Portals Router. It is intended
    /// to be called by the sender of the order (i.e. msg.sender).
    /// @param orderPayload The order payload containing the details of the trade
    /// @param partner The front end operator address
    /// @return outputAmount The quantity of outputToken received after validation of the order
    function portal(
        IPortalsRouter.OrderPayload calldata orderPayload,
        address partner
    ) public payable whenNotPaused returns (uint256 outputAmount) {
        return _execute(
            msg.sender,
            orderPayload.order,
            orderPayload.calls,
            _transferFromSender(
                msg.sender,
                orderPayload.order.inputToken,
                orderPayload.order.inputAmount
            ),
            partner
        );
    }

    /// @notice This function calls permit prior to the portal function for gasless approvals. It is intended
    /// to be called by the sender of the order (i.e. msg.sender).
    /// @param orderPayload The order payload containing the details of the trade
    /// @param permitPayload The permit payload struct containing the details of the permit
    /// @param partner The front end operator address
    /// @return outputAmount The quantity of outputToken received after validation of the order
    function portalWithPermit(
        IPortalsRouter.OrderPayload calldata orderPayload,
        IPortalsRouter.PermitPayload calldata permitPayload,
        address partner
    ) external whenNotPaused returns (uint256 outputAmount) {
        _permit(
            msg.sender, orderPayload.order.inputToken, permitPayload
        );
        return portal(orderPayload, partner);
    }

    /// This function uses Portals signed orders to facilitate gasless portals. It is intended
    /// to be called by a broadcaster (i.e. msg.sender != order.sender).
    /// @param signedOrderPayload The signed order payload containing the details of the signed order
    /// @param partner The front end operator address
    /// @return outputAmount The quantity of outputToken received after validation of the order
    function portalWithSignature(
        IPortalsRouter.SignedOrderPayload calldata signedOrderPayload,
        address partner
    ) public whenNotPaused returns (uint256 outputAmount) {
        _verify(signedOrderPayload);
        return _execute(
            signedOrderPayload.signedOrder.sender,
            signedOrderPayload.signedOrder.order,
            signedOrderPayload.calls,
            _transferFromSender(
                signedOrderPayload.signedOrder.sender,
                signedOrderPayload.signedOrder.order.inputToken,
                signedOrderPayload.signedOrder.order.inputAmount
            ),
            partner
        );
    }

    /// @notice This function calls permit prior to the portalWithSignature function for gasless approvals,
    /// in addition to gassless Portals. It is intended to be called by a broadcaster (i.e. msg.sender != order.sender).
    /// @param signedOrderPayload The signed order payload containing the details of the signed order
    /// @param permitPayload The permit payload struct containing the details of the permit
    /// @param partner The front end operator address
    /// @return outputAmount The quantity of outputToken received after validation of the order
    function portalWithSignatureAndPermit(
        IPortalsRouter.SignedOrderPayload calldata signedOrderPayload,
        IPortalsRouter.PermitPayload calldata permitPayload,
        address partner
    ) external whenNotPaused returns (uint256 outputAmount) {
        _permit(
            signedOrderPayload.signedOrder.sender,
            signedOrderPayload.signedOrder.order.inputToken,
            permitPayload
        );

        return portalWithSignature(signedOrderPayload, partner);
    }

    /// @notice This function executes calls to transform a sell token into a buy token.
    /// The outputAmount of the outputToken specified in the order is validated against the minOutputAmount following the
    /// aggregate call of Portals Multicall.
    /// @param sender The sender(signer) of the order
    /// @param order The order struct containing the details of the trade
    /// @param calls The array of calls to be executed by the Portals Multicall
    /// @param value The value of native tokens to be sent to the Portals Multicall
    /// @param partner The front end operator address
    /// @return outputAmount The quantity of outputToken received after validation of the order
    function _execute(
        address sender,
        IPortalsRouter.Order calldata order,
        IPortalsMulticall.Call[] calldata calls,
        uint256 value,
        address partner
    ) private returns (uint256 outputAmount) {
        outputAmount = _getBalance(order.recipient, order.outputToken);

        PORTALS_MULTICALL.aggregate{ value: value }(calls);

        outputAmount = _getBalance(order.recipient, order.outputToken)
            - outputAmount;

        if (outputAmount < order.minOutputAmount) {
            revert InsufficientBuy(
                outputAmount, order.minOutputAmount
            );
        }

        emit Portal(
            order.inputToken,
            order.inputAmount,
            order.outputToken,
            outputAmount,
            sender,
            msg.sender,
            order.recipient,
            partner
        );
    }
}
