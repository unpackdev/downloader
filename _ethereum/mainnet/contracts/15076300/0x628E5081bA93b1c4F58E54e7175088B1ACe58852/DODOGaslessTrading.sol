/*
    Copyright 2021 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.4;

import "./Ownable.sol";
import "./IDODOApproveProxy.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

/**
 * @title DODOGaslessTrading
 * @author DODO Breeder
 * @notice DODO Gasless Trading is an insurance service. It is part of DLOP, DODO Limit Order Protocol.
 * The trader signs the order and sends it to DODO's backend service. DODO guarantees that the order
 * will be submitted and filled without any slippage.
 * DODO does not act directly as a counterparty to the trader, but integrates all the on-chain liquidity
 * through DODO's routing system. If the final result is better than the original order, DODO collects
 * these additional token as a premium. Otherwise DODO compensates the difference to the trader.
 * When compensating, DODO will try to pay toToken first. If the insurance inventory is not enough
 * to pay, then the compensation will be paid in the fromToken.
 */

struct GaslessOrder {
    address signer;
    address fromToken;
    address toToken;
    uint256 fromAmount;
    uint256 toAmount;
    uint256 expiration;
    uint256 slot;
}

contract DODOGaslessTrading is
    EIP712("DODO Limit Order Protocol", "1"),
    Ownable
{
    using SafeERC20 for IERC20;

    bytes32 public constant GASLESS_ORDER_TYPEHASH =
        keccak256(
            "Order(address signer,address fromToken,address toToken,uint256 fromAmount,uint256 toAmount,uint256 expiration,uint256 slot)"
        );

    //=============== Storage ===============

    address public _INSURANCE_;
    address public immutable _DODO_APPROVE_;
    address public immutable _DODO_APPROVE_PROXY_;
    mapping(address => bool) public _IS_ADMIN_;
    mapping(bytes32 => bool) public _IS_FILLED_;

    //=============== Events ===============

    event AddAdmin(address admin);

    event RemoveAdmin(address admin);

    event ChangeInsurance(address newInsurance);

    event GaslessOrderFilled(bytes32 orderHash);

    //=============== Functions ===============

    constructor(
        address owner,
        address insurance,
        address dodoApprove,
        address dodoApproveProxy
    ) {
        transferOwnership(owner);
        _INSURANCE_ = insurance;
        _DODO_APPROVE_ = dodoApprove;
        _DODO_APPROVE_PROXY_ = dodoApproveProxy;
    }

    function matchingRFQByPlatform(
        GaslessOrder calldata order,
        bytes calldata signature,
        bytes calldata routeData,
        address route,
        uint256 maxCompensation
    ) external {
        require(_IS_ADMIN_[msg.sender], "ACCESS_DENIED");

        // verify order
        bytes32 orderHash = _hashOrder(order);
        require(
            ECDSA.recover(orderHash, signature) == order.signer,
            "DLOP:INVALID_SIGNATURE"
        );
        require(order.expiration > block.timestamp, "DLOP:ORDER_EXPIRED");
        require(!_IS_FILLED_[orderHash], "DLOP:ORDER_FILLED");

        // flash swap: transfer trader's FROM token in
        IDODOApproveProxy(_DODO_APPROVE_PROXY_).claimTokens(
            order.fromToken,
            order.signer,
            address(this),
            order.fromAmount
        );

        // swap using DODO Route
        uint256 swapResult;
        {
            uint256 originToTokenBalance = IERC20(order.toToken).balanceOf(
                address(this)
            );
            _approveMax(
                IERC20(order.fromToken),
                _DODO_APPROVE_,
                order.fromAmount
            );
            require(route != _DODO_APPROVE_PROXY_, "DLOP:ROUTE_ADDRESS_REJECT");
            (bool success, ) = route.call(routeData);
            require(success, "DLOP:DODO_ROUTE_FAILED");
            uint256 toTokenBalance = IERC20(order.toToken).balanceOf(
                address(this)
            );
            swapResult = toTokenBalance - originToTokenBalance;
        }

        // pay trader TO token
        if (swapResult >= order.toAmount) {
            // fund extra TO token to insurance
            IERC20(order.toToken).safeTransfer(order.signer, order.toAmount);
            IERC20(order.toToken).safeTransfer(
                _INSURANCE_,
                IERC20(order.toToken).balanceOf(address(this))
            );
        } else {
            IERC20(order.toToken).safeTransfer(order.signer, swapResult);
            // compensate the trader
            uint256 compensation = order.toAmount - swapResult;
            require(
                compensation <= maxCompensation,
                "DLOP:COMPENSATION_EXCEED"
            );
            if (IERC20(order.toToken).balanceOf(_INSURANCE_) >= compensation) {
                // compensate TO token if balance enough
                IDODOApproveProxy(_DODO_APPROVE_PROXY_).claimTokens(
                    order.toToken,
                    _INSURANCE_,
                    order.signer,
                    compensation
                );
            } else {
                // otherwise compensate FROM token with the price signed in order
                IDODOApproveProxy(_DODO_APPROVE_PROXY_).claimTokens(
                    order.fromToken,
                    _INSURANCE_,
                    order.signer,
                    (compensation * order.fromAmount) / order.toAmount
                );
            }
        }

        _IS_FILLED_[orderHash] = true;
        emit GaslessOrderFilled(orderHash);
    }

    //============ Ownable ============

    function addAdmin(address userAddr) external onlyOwner {
        _IS_ADMIN_[userAddr] = true;
        emit AddAdmin(userAddr);
    }

    function removeAdmin(address userAddr) external onlyOwner {
        _IS_ADMIN_[userAddr] = false;
        emit RemoveAdmin(userAddr);
    }

    function changeInsurance(address newInsurance) external onlyOwner {
        _INSURANCE_ = newInsurance;
        emit ChangeInsurance(newInsurance);
    }

    //============ Private ============

    function _approveMax(
        IERC20 token,
        address to,
        uint256 amount
    ) private {
        uint256 allowance = token.allowance(address(this), to);
        if (allowance < amount) {
            if (allowance > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, type(uint256).max);
        }
    }

    function _hashOrder(GaslessOrder memory order)
        private
        view
        returns (bytes32)
    {
        // keccak256(
        //     abi.encode(
        //         GASLESS_ORDER_TYPEHASH,
        //         order.signer,
        //         order.fromToken,
        //         order.toToken,
        //         order.fromAmount,
        //         order.toAmount
        //         order.expiration,
        //         order.slot
        //     )
        // )
        bytes32 structHash;
        bytes32 orderTypeHash = GASLESS_ORDER_TYPEHASH;
        assembly {
            let start := sub(order, 32)
            let tmp := mload(start)
            // 256 = (1+7)*32
            // [0...32)   bytes: GASLESS_ORDER_TYPEHASH
            // [32...256) bytes: order
            mstore(start, orderTypeHash)
            structHash := keccak256(start, 256)
            mstore(start, tmp)
        }
        return _hashTypedDataV4(structHash);
    }
}
