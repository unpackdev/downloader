/*
  
  Exchange contract. This is an outer contract with public or convenience functions and includes no state-modifying functions.
 
*/
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "./ExchangeCore.sol";

/**
 * @title Exchange
 * @author Project Wyvern Developers, JungleNFT Developers
 */
contract Exchange is ExchangeCore {
    /**
     * @dev Calculate the settlement price of an order
     * @dev Precondition: parameters have passed validateParameters.
     * @param side Order side
     * @param saleKind Method of sale
     * @param basePrice Order base price
     * @param extra Order extra price data
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function calculateFinalPrice(
        SaleKindLibrary.Side side,
        SaleKindLibrary.SaleKind saleKind,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime
    ) external view returns (uint256) {
        return
            SaleKindLibrary.calculateFinalPrice(
                side,
                saleKind,
                basePrice,
                extra,
                listingTime,
                expirationTime
            );
    }

    /**
     * @dev Hash an order, returning the canonical EIP-712 order hash without the domain separator
     * @param order Order to hash
     * @return hash Hash of order
     */
    function hashOrder_(
        Order calldata order
    ) external view returns (bytes32) {
        return
            hashOrder(
                order,
                nonces[order.maker]
            );
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign via EIP-712 including the message prefix
     * @param order Order to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function hashToSign_(
        Order calldata order
    ) external view returns (bytes32) {
        return
            hashToSign(
                order,
                nonces[order.maker]
            );
    }

    /**
     * @dev Validate order parameters (does *not* check signature validity)
     * @param order Order to validate
     * @return if order parameters are valid or not
     */
    function validateOrderParameters_(
        Order calldata order
    ) external view returns (bool) {
        return validateOrderParameters(order);
    }

    /**
     * @dev Validate a provided previously approved / signed order, hash, and signature.
     * @param order Order to validate
     * @param v v of ECDSA signature
     * @param r r of ECDSA signature
     * @param s s of ECDSA signature
     */
    function validateOrder_(
        Order calldata order,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool) {
        return
            validateOrder(
                hashToSign(order, nonces[order.maker]),
                order,
                Sig(v, r, s)
            );
    }

    /**
     * @dev Approve an order and optionally mark it for orderbook inclusion. Must be called by the maker of the order
     * @param order Order to approve
     * @param orderbookInclusionDesired Whether orderbook providers should include the order in their orderbooks
     */
    function approveOrder_(
        Order calldata order,
        bool orderbookInclusionDesired
    ) external {
        return approveOrder(order, orderbookInclusionDesired);
    }

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     * @param v v of the signature
     * @param r r of the siganture
     * @param s s of the signature
     */
    function cancelOrder_(
        Order calldata order,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        return cancelOrder(order, Sig(v, r, s), nonces[order.maker]);
    }

    /**
     * @dev Call cancelOrder, supplying a specific nonce — enables cancelling orders
            that were signed with nonces greater than the current nonce.
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     * @param v v of the signature
     * @param r r of the siganture
     * @param s s of the signature
     * @param nonce Nonce to cancel
     */
    function cancelOrderWithNonce_(
        Order calldata order,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 nonce
    ) external {
        return cancelOrder(order, Sig(v, r, s), nonce);
    }

    /**
     * @dev Calculate the current price of an order
     * @param order Order to calculate the price of
     * @return The current price of the order
     */
    function calculateCurrentPrice_(
        Order calldata order
    ) external view returns (uint256) {
        return
            calculateCurrentPrice(order);
    }

    /**
     * @dev Return whether or not two orders can be matched with each other by basic parameters (does not check order signatures / calldata or perform static calls)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Whether or not the two orders can be matched
     */
    function ordersCanMatch_(
        Order calldata buy,
        Order calldata sell
    ) external view returns (bool) {
        return ordersCanMatch(buy, sell);
    }

    /**
     * @dev Return whether or not two orders' calldata specifications can match
     * @param buyCalldata Buy-side order calldata
     * @param buyReplacementPattern Buy-side order calldata replacement mask
     * @param sellCalldata Sell-side order calldata
     * @param sellReplacementPattern Sell-side order calldata replacement mask
     * @return Whether the orders' calldata can be matched
     */
    function orderCalldataCanMatch(
        bytes calldata buyCalldata,
        bytes calldata buyReplacementPattern,
        bytes calldata sellCalldata,
        bytes calldata sellReplacementPattern
    ) external pure returns (bool) {
        bytes memory _buyCalldata = buyCalldata;
        bytes memory _sellCalldata = sellCalldata;
        if (buyReplacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(
                _buyCalldata,
                _sellCalldata,
                buyReplacementPattern
            );
        }
        if (sellReplacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(
                _sellCalldata,
                _buyCalldata,
                sellReplacementPattern
            );
        }
        return ArrayUtils.arrayEq(_buyCalldata, _sellCalldata);
    }

    /**
     * @dev Calculate the price two orders would match at, if in fact they would match (otherwise fail)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Match price
     */
    function calculateMatchPrice_(
        Order calldata buy,
        Order calldata sell
    ) external view returns (uint256) {
        return calculateMatchPrice(buy, sell);
    }

    /**
     * @dev Atomically match two orders, ensuring validity of the match, and execute all associated state transitions. Protected against reentrancy by a contract-global lock.
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @param vs vs of orders
     * @param rssMetadata rss of Orders
     */
    function atomicMatch_(
        Order calldata buy,
        Order calldata sell,
        uint8[2] calldata vs,
        bytes32[5] calldata rssMetadata
    ) external payable {
        return
            atomicMatch(
                buy,
                Sig(vs[0], rssMetadata[0], rssMetadata[1]),
                sell,
                Sig(vs[1], rssMetadata[2], rssMetadata[3]),
                rssMetadata[4]
            );
    }

    /**
     * @dev Mask must be the size of the byte array. A nonzero byte means the byte array can be changed.
     * @param array The original array
     * @param desired The target array
     * @param mask The mask specifying which bits can be changed
     The updated byte array (the parameter will be modified inplace)
     */
    function guardedArrayReplace(
        bytes memory array,
        bytes memory desired,
        bytes memory mask
    ) external pure returns (bytes memory) {
        ArrayUtils.guardedArrayReplace(array, desired, mask);
        return array;
    }
}
