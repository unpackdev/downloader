// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ExchangeCore.sol";

contract Exchange is ExchangeCore {

    constructor(address _protocolFeeRecipient, uint _minimumProtocolFee) {
        require(_protocolFeeRecipient != address(0), "invalid recipient.");
        _transferOwnership(_protocolFeeRecipient);
        protocolFeeRecipient = _protocolFeeRecipient;
        minimumProtocolFee = _minimumProtocolFee;
    }

    /**
     * @dev Call hashOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function hashOrder_(
        address[4] calldata addrs,
        uint[] calldata nftIds,
        uint[5] calldata uints)
        external
        pure
        returns (bytes32)
    {
        return hashOrder(
          Order(addrs[0], addrs[1], addrs[2], addrs[3], nftIds, uints[0], uints[1], uints[2], uints[3], uints[4])
        );
    }

    /**
     * @dev Call hashToSign - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function hashToSign_(
        address[4] calldata addrs,
        uint[] calldata nftIds,
        uint[5] calldata uints)
        external
        pure
        returns (bytes32)
    { 
        return hashToSign(
          Order(addrs[0], addrs[1], addrs[2], addrs[3], nftIds, uints[0], uints[1], uints[2], uints[3], uints[4])
        );
    }

    /**
     * @dev Call validateOrderParameters - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrderParameters_ (
        address[4] calldata addrs,
        uint[] calldata nftIds,
        uint[5] calldata uints)
        external
        view
        returns (bool)
    {
        Order memory order = Order(addrs[0], addrs[1], addrs[2], addrs[3], nftIds, uints[0], uints[1], uints[2], uints[3], uints[4]);
        return validateOrderParameters(
          order
        );
    }

    /**
     * @dev Call validateOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrder_ (
        address[4] calldata addrs,
        uint[] calldata nftIds,
        uint[5] calldata uints,
        uint8 v,
        bytes32 r,
        bytes32 s)
        external
        view
        returns (bool)
    {
        Order memory order = Order(addrs[0], addrs[1], addrs[2], addrs[3], nftIds, uints[0], uints[1], uints[2], uints[3], uints[4]);
        return validateOrder(
          hashToSign(order),
          order,
          Sig(v, r, s)
        );
    }

    /**
     * @dev Call approveOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function approveOrder_ (
        address[4] calldata addrs,
        uint[] calldata nftIds,
        uint[5] calldata uints) 
        external
    {
        Order memory order = Order(addrs[0], addrs[1], addrs[2], addrs[3], nftIds, uints[0], uints[1], uints[2], uints[3], uints[4]);
        return approveOrder(order);
    }

    /**
     * @dev Call cancelOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function cancelOrder_(
        address[4] calldata addrs,
        uint[] calldata nftIds,
        uint[5] calldata uints,
        uint8 v,
        bytes32 r,
        bytes32 s)
        external
    {
        return cancelOrder(
          Order(addrs[0], addrs[1], addrs[2], addrs[3], nftIds, uints[0], uints[1], uints[2], uints[3], uints[4]),
          Sig(v, r, s)
        );
    }

    /**
     * @dev Call atomicMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function buy_(
        address[4] calldata addrs,
        uint[] calldata nftIds,
        uint[5] calldata uints,
        uint8 v,
        bytes32 r,
        bytes32 s)
        external
        payable
        
    {
        return buy(
            Order(addrs[0], addrs[1], addrs[2], addrs[3], nftIds, uints[0], uints[1], uints[2], uints[3], uints[4]),
            Sig(v, r, s)
        );
    }
}
