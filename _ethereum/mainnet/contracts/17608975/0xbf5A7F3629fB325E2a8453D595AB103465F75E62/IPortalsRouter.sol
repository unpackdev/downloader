/// SPDX-License-Identifier: GPL-3.0

/// Copyright (C) 2023 Portals.fi

/// @author Portals.fi
/// @notice Interface for the Portals Router contract

pragma solidity 0.8.19;

import { IPortalsMulticall } from
    "../..//multicall/interface/IPortalsMulticall.sol";

interface IPortalsRouter {
    /// @param inputToken The ERC20 token address to spend (address(0) if network token)
    /// @param inputAmount The quantity of inputToken to Portal
    /// @param outputToken The ERC20 token address to buy (address(0) if network token)
    /// @param minOutputAmount The minimum acceptable quantity of outputToken to receive. Reverts otherwise.
    /// @param recipient The recipient of the outputToken
    struct Order {
        address inputToken;
        uint256 inputAmount;
        address outputToken;
        uint256 minOutputAmount;
        address recipient;
    }

    /// @param order The order containing the details of the trade
    /// @param calls The calls to be executed in the aggregate function of PortalsMulticall.sol to transform
    /// inputToken to outputToken
    struct OrderPayload {
        Order order;
        IPortalsMulticall.Call[] calls;
    }

    /// @param order The order containing the details of the trade
    /// @param routeHash The hash of the abi encoded calls array
    /// @param sender The signer of the order and the sender of the inputToken
    /// @param deadline The deadline after which the order is no longer valid
    /// @param nonce The nonce of the sender(signer)
    struct SignedOrder {
        Order order;
        bytes32 routeHash;
        address sender;
        uint64 deadline;
        uint64 nonce;
    }

    /// @param signedOrder The signed order containing the details of the trade
    /// @param signature The signature of the signed order
    /// @param calls The calls to be executed in the aggregate function of PortalsMulticall.sol to transform
    /// inputToken to outputToken
    struct SignedOrderPayload {
        SignedOrder signedOrder;
        bytes signature;
        IPortalsMulticall.Call[] calls;
    }

    /// @dev The signer of the permit message must be the msg.sender of the Order or signer of the SignedOrder
    /// @param amount The quantity of tokens to be spent
    /// @param deadline The timestamp after which the Permit is no longer valid
    /// @param signature The signature of the Permit
    /// @param splitSignature Whether the signature is split into r, s, and v
    /// @param daiPermit Whether the Permit is a DAI Permit (i.e not  EIP-2612)
    struct PermitPayload {
        uint256 amount;
        uint256 deadline;
        bytes signature;
        bool splitSignature;
        bool daiPermit;
    }
}
