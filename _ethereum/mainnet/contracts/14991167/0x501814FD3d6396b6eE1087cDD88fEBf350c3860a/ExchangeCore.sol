// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./ArrayUtils.sol";


/**
 * @title ExchangeCore
 */
contract ExchangeCore is Ownable, ReentrancyGuard, IERC721Receiver {
    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;

    /* Orders verified by on-chain approval (alternative to ECDSA signatures so that smart contracts can place orders directly). */
    mapping(bytes32 => bool) public approvedOrders;

    /* Recipient of protocol fees. */
    address public protocolFeeRecipient;

    uint public minimumProtocolFee;

    /* Inverse basis point. */
    uint public constant INVERSE_BASIS_POINT = 10000;

    /* An ECDSA signature. */ 
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    /* An order on the exchange. */
    struct Order {
        /* Exchange address, intended as a versioning mechanism. */
        address exchange;
        /* Order maker address. */
        address maker;
        /* Order taker address, if specified. */
        address taker;
        /* Target. */
        address target;
        /* NFT ids. */
        uint[] nftIds;
        /* Price of the order (in eth). */
        uint price;
        /* Listing timestamp. */
        uint listingTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint expirationTime;
        /* Protocol fee. */
        uint protocolFee;
        /* Order salt, used to prevent duplicate hashes. */
        uint salt;
    }
    
    event OrderCancelled               (bytes32 indexed hash);
    event OrdersMatched                (bytes32 indexed orderHash, address indexed maker, address indexed taker, uint price, uint totalProtocolFee);
    event MinimumProtocolFeeChanged    (uint indexed newFee, uint oldFee);
    event ProtocolFeeRecipientChanged  (address indexed newRecipient, address indexed oldRecipient);


    /**
     * @dev Change the protocol fee recipient (owner only)
     * @param newProtocolFeeRecipient New protocol fee recipient address
     */
    function changeProtocolFeeRecipient(address newProtocolFeeRecipient)
        external
        onlyOwner
    {
        require(newProtocolFeeRecipient != address(0), "invalid recipient.");
        emit ProtocolFeeRecipientChanged(newProtocolFeeRecipient, protocolFeeRecipient);
        protocolFeeRecipient = newProtocolFeeRecipient;
    }

    function changeMinimumProtocolFee(uint8 newMinimumProtocolFee)
        external
        onlyOwner
    {
        require(newMinimumProtocolFee <= INVERSE_BASIS_POINT, "fee err.");
        emit MinimumProtocolFeeChanged(newMinimumProtocolFee, minimumProtocolFee);
        minimumProtocolFee = newMinimumProtocolFee;
    }    

    /**
     * Calculate size of an order struct when tightly packed
     *
     * @param order Order to calculate size of
     * @return Size in bytes
     */
    function sizeOf(Order memory order)
        internal
        pure
        returns (uint)
    {
        return (0x14 * 4) + (0x20 * 5) + (0x20 * order.nftIds.length);
    }

    function hashOrder(Order memory order)
        internal
        pure
        returns (bytes32 hash)
    {
        /* Unfortunately abi.encodePacked doesn't work here, stack size constraints. */
        uint size = sizeOf(order);
        bytes memory array = new bytes(size);
        uint index;
        assembly {
            index := add(array, 0x20)
        }
        index = ArrayUtils.unsafeWriteAddress(index, order.exchange);//1/7
        index = ArrayUtils.unsafeWriteAddress(index, order.maker);//2/7
        index = ArrayUtils.unsafeWriteAddress(index, order.taker);//3/7
        index = ArrayUtils.unsafeWriteAddress(index, order.target);//4/7
        for (uint i=0; i < order.nftIds.length; i++) {
            index = ArrayUtils.unsafeWriteUint(index, order.nftIds[i]);
        }
        index = ArrayUtils.unsafeWriteUint(index, order.price);//1/9
        index = ArrayUtils.unsafeWriteUint(index, order.listingTime);//2/9
        index = ArrayUtils.unsafeWriteUint(index, order.expirationTime);//3/9
        index = ArrayUtils.unsafeWriteUint(index, order.protocolFee);//4/9
        index = ArrayUtils.unsafeWriteUint(index, order.salt);//5/9
        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
        return hash;
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @param order Order to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function hashToSign(Order memory order)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashOrder(order)));
    }

    /**
     * @dev Assert an order is valid and return its hash
     * @param order Order to validate
     * @param sig ECDSA signature
     */
    function requireValidOrder(Order memory order, Sig memory sig)
        internal
        view
        returns (bytes32)
    {
        bytes32 hash = hashToSign(order);
        require(validateOrder(hash, order, sig), "Order invalied");
        return hash;
    }

    /**
     * @dev Validate order parameters (does *not* check signature validity)
     * @param order Order to validate
     */
    function validateOrderParameters(Order memory order)
        internal
        view
        returns (bool)
    {
        /* Order must be targeted at this protocol version (this Exchange contract). */
        if (order.exchange != address(this)) {
            return false;
        }

        if (order.nftIds.length < 1) {
            return false;
        }

        if (order.protocolFee < minimumProtocolFee || order.protocolFee >= INVERSE_BASIS_POINT) {
            return false;
        }

        return true;
    }

    /**
     * @dev Validate a provided previously approved / signed order, hash, and signature.
     * @param hash Order hash (already calculated, passed to avoid recalculation)
     * @param order Order to validate
     * @param sig ECDSA signature
     */
    function validateOrder(bytes32 hash, Order memory order, Sig memory sig) 
        internal
        view
        returns (bool)
    {
        /* Not done in an if-conditional to prevent unnecessary ecrecover evaluation, which seems to happen even though it should short-circuit. */

        /* Order must have valid parameters. */
        if (!validateOrderParameters(order)) {
            return false;
        }
        
        /* Order must have not been canceled or already filled. */
        if (cancelledOrFinalized[hash]) {
            return false;
        }
        
        /* Order authentication. Order must be either:
        /* (a) previously approved */
        if (approvedOrders[hash]) {
            return true;
        }

        /* or (b) ECDSA-signed by maker. */
        if (ecrecover(hash, sig.v, sig.r, sig.s) == order.maker) {
            return true;
        }

        return false;
    }

    function approveOrder(Order memory order)
        internal
    {
        /* CHECKS */
        require(validateOrderParameters(order), "invalid order.");

        /* Assert sender is authorized to approve order. */
        require(msg.sender == order.maker, "invalid sender.");

        /* Calculate order hash. */
        bytes32 hash = hashToSign(order);

        /* Assert order has not already been approved. */
        require(!approvedOrders[hash], "approved.");

        /* EFFECTS */
    
        /* Mark order as approved. */
        approvedOrders[hash] = true;
    }

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     * @param sig ECDSA signature
     */
    function cancelOrder(Order memory order, Sig memory sig) 
        internal
    {
        /* CHECKS */

        /* Calculate order hash. */
        bytes32 hash = requireValidOrder(order, sig);

        /* Assert sender is authorized to cancel order. */
        require(msg.sender == order.maker, "invalid sender.");
  
        /* EFFECTS */
      
        /* Mark order as cancelled, preventing it from being matched. */
        cancelledOrFinalized[hash] = true;

        /* Log cancel event. */
        emit OrderCancelled(hash);
    }
    event DebugInfo(address target, address maker, address buyer, uint nft0, uint nft1, uint nft2);

    function executeFundsTransfer(address payable buyer, Order memory sell)
        internal
        returns (uint)
    {
        require(msg.value >= sell.price, "payment err.");
        
        uint price = sell.price;
        uint protocolFee = sell.protocolFee;
        uint totalProtocolFee;
        assembly {
            totalProtocolFee := div(mul(price, protocolFee), INVERSE_BASIS_POINT)
        }

        /* Amount that will be received by seller (for Ether). */
        uint receiveAmount = SafeMath.sub(price, totalProtocolFee);

        payable(sell.maker).transfer(receiveAmount);
        payable(protocolFeeRecipient).transfer(totalProtocolFee);

        /* Allow overshoot for variable-price auctions, refund difference. */
        uint diff = SafeMath.sub(msg.value, price);
        if (diff > 0) {
            buyer.transfer(diff);
        }
        
        IERC721 nft721 = IERC721(sell.target);
        for (uint i = 0; i < sell.nftIds.length; i++) {
            nft721.transferFrom(sell.maker, buyer, sell.nftIds[i]);
        }

        /* This contract should never hold Ether, however, we cannot assert this, since it is impossible to prevent anyone from sending Ether e.g. with selfdestruct. */

        return totalProtocolFee;
    }

    function buy(Order memory sell, Sig memory sellSig)
        internal
        nonReentrant
    {
        /* Ensure sell order validity and calculate hash if necessary. */
        bytes32 orderHash = requireValidOrder(sell, sellSig);
        
        /* Must be matchable. */
        require(block.timestamp < sell.expirationTime || sell.expirationTime == 0, "expiration time err.");
        require(sell.listingTime <= block.timestamp, "listing time err.");

        /* Target must exist (prevent malicious selfdestructs just prior to order settlement). */
        uint size;
        address target = sell.target;
        assembly {
            size := extcodesize(target)
        }
        require(size > 0, "target is not a contract");
        cancelledOrFinalized[orderHash] = true;

        /* INTERACTIONS */

        /* Execute funds transfer and pay fees. */
        
        uint fee = executeFundsTransfer(payable(msg.sender), sell);
        emit OrdersMatched(orderHash, sell.maker, msg.sender, sell.price, fee);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) 
        external 
        pure
        override
        returns (bytes4)
    {
        // fuck warnings of the solc
        if (false) {
            require(operator==operator);
            require(from==from);
            require(tokenId==tokenId);
            require(data.length>=0);
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}
