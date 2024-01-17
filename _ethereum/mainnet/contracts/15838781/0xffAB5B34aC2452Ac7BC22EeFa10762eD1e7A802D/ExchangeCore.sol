/*

  Decentralized digital asset exchange. Supports any digital asset that can be represented on the Ethereum blockchain (i.e. - transferred in an Ethereum transaction or sequence of transactions).

  Let us suppose two agents interacting with a distributed ledger have utility functions preferencing certain states of that ledger over others.
  Aiming to maximize their utility, these agents may construct with their utility functions along with the present ledger state a mapping of state transitions (transactions) to marginal utilities.
  Any composite state transition with positive marginal utility for and enactable by the combined permissions of both agents thus is a mutually desirable trade, and the trustless 
  code execution provided by a distributed ledger renders the requisite atomicity trivial.

  Relative to this model, this instantiation makes two concessions to practicality:
  - State transition preferences are not matched directly but instead intermediated by a standard of tokenized value.
  - A small fee can be charged in WYV for order settlement in an amount configurable by the frontend hosting the orderbook.

  Solidity presently possesses neither a first-class functional typesystem nor runtime reflection (ABI encoding in Solidity), so we must be a bit clever in implementation and work at a lower level of abstraction than would be ideal.

  We elect to utilize the following structure for the initial version of the protocol:
  - Buy-side and sell-side orders each provide calldata (bytes) - for a sell-side order, the state transition for sale, for a buy-side order, the state transition to be bought.
    Along with the calldata, orders provide `replacementPattern`: a bytemask indicating which bytes of the calldata can be changed (e.g. NFT destination address).
    When a buy-side and sell-side order are matched, the desired calldatas are unified, masked with the bytemasks, and checked for agreement.
    This alone is enough to implement common simple state transitions, such as "transfer my CryptoKitty to any address" or "buy any of this kind of nonfungible token".
  - Orders (of either side) can optionally specify a static (no state modification) callback function, which receives configurable data along with the actual calldata as a parameter.
    Although it requires some encoding acrobatics, this allows for arbitrary transaction validation functions.
    For example, a buy-sider order could express the intent to buy any CryptoKitty with a particular set of characteristics (checked in the static call),
    or a sell-side order could express the intent to sell any of three ENS names, but not two others.
    Use of the EVM's STATICCALL opcode, added in Ethereum Metropolis, allows the static calldata to be safely specified separately and thus this kind of matching to happen correctly
    - that is to say, wherever the two (transaction => bool) functions intersect.

  Future protocol versions may improve upon this structure in capability or usability according to protocol user feedback demand, with upgrades enacted by the Wyvern DAO.
 
*/

// SPDX-License-Identifier: None
pragma solidity 0.8.12;

import "./IERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ProxyRegistry.sol";
import "./TokenTransferProxy.sol";
import "./AuthenticatedProxy.sol";
import "./ArrayUtils.sol";
import "./ContextMixin.sol";
import "./NativeMetaTransaction.sol";
import "./SaleKindLibrary.sol";
import "./Errors.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

/**
 * @title ExchangeCore
 * @author Project Wyvern Developers, JungleNFT Developers
 */
contract ExchangeCore is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ContextMixin,
    NativeMetaTransaction
{

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* User registry. */
    ProxyRegistry public registry;

    /* Token transfer proxy. */
    TokenTransferProxy public tokenTransferProxy;

    // Note: the domain separator is derived and verified in the constructor. */
    bytes32 public DOMAIN_SEPARATOR;

    string public constant NAME = "Wyvern Exchange Contract";
    string public constant VERSION = "2.3.1";

    // NOTE: these hashes are derived and verified in the constructor.
    bytes32 private constant _EIP_712_DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 private constant _NAME_HASH =
        0x9a2ed463836165738cfa54208ff6e7847fd08cbaac309aac057086cb0a144d13;
    bytes32 private constant _VERSION_HASH =
        0xa8b0a8837a56ea69398e77c1bedb65d43e1b4f9aecb58f24aaef3c7279227fd1;
    bytes32 private constant _ORDER_TYPEHASH =
        0x1f2ea8eb0d151b283bbdafa24fdb870619cadf006c2b53f22aa3a56c05756f8e;

    bytes4 private constant _EIP_1271_MAGIC_VALUE = 0x1626ba7e;

    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;

    /* Orders verified by on-chain approval (alternative to ECDSA signatures so that smart contracts can place orders directly). */
    /* Note that the maker's nonce at the time of approval **plus one** is stored in the mapping. */
    mapping(bytes32 => uint256) private _approvedOrdersByNonce;

    /* Track per-maker nonces that can be incremented by the maker to cancel orders in bulk. */
    // The current nonce for the maker represents the only valid nonce that can be signed by the maker
    // If a signature was signed with a nonce that's different from the one stored in nonces, it
    // will fail validation.
    mapping(address => uint256) public nonces;

    /* Inverse basis point. */
    uint256 public constant INVERSE_BASIS_POINT = 10000;

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
        /* Maker relayer fee of the order, unused for taker order. */
        uint256 makerRelayerFee;
        /* Taker relayer fee of the order, or maximum taker fee for a taker order. */
        uint256 takerRelayerFee;
        /* Taker Cashback of the order. */
        uint256 takerCashbackFee;
        /* Order fee recipient or zero address for taker order. */
        address feeRecipient;
        /* Side (buy/sell). */
        SaleKindLibrary.Side side;
        /* Kind of sale. */
        SaleKindLibrary.SaleKind saleKind;
        /* Target. */
        address target;
        /* HowToCall. */
        AuthenticatedProxy.HowToCall howToCall;
        /* Calldata. */
        bytes data;
        /* Calldata replacement pattern, or an empty byte array for no replacement. */
        bytes replacementPattern;
        /* Extra data for NFT royalty details. */
        bytes royaltyData;
        /* Static call target, zero-address for no static call. */
        address staticTarget;
        /* Static call extra data. */
        bytes staticExtradata;
        /* Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
        address paymentToken;
        /* Base price of the order (in paymentTokens). */
        uint256 basePrice;
        /* Auction extra parameter - minimum bid increment for English auctions, starting/ending price difference. */
        uint256 extra;
        /* Listing timestamp. */
        uint256 listingTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order salt, used to prevent duplicate hashes. */
        uint256 salt;
        /* NOTE: uint nonce is an additional component of the order but is read from storage */
    }

    event OrderApprovedPartOne(
        bytes32 indexed hash,
        address exchange,
        address indexed maker,
        address taker,
        uint256 makerRelayerFee,
        uint256 takerRelayerFee,
        address indexed feeRecipient,
        SaleKindLibrary.Side side,
        SaleKindLibrary.SaleKind saleKind,
        address target
    );
    event OrderApprovedPartTwo(
        bytes32 indexed hash,
        AuthenticatedProxy.HowToCall howToCall,
        bytes data,
        bytes replacementPattern,
        bytes royaltyData,
        address staticTarget,
        bytes staticExtradata,
        address paymentToken,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 salt,
        bool orderbookInclusionDesired
    );
    event OrderCancelled(bytes32 indexed hash);
    event OrdersMatched(
        bytes32 buyHash,
        bytes32 sellHash,
        address indexed maker,
        address indexed taker,
        uint256 price,
        bytes32 indexed metadata
    );
    event NonceIncremented(address indexed maker, uint256 newNonce);
    event TokenTransferProxyUpdated(address tokenTransferProxy);
    event ProxyRegistryUpdated(address proxyRegistry);

    function __ExchangeCore_init_() internal {
        __ReentrancyGuard_init();
        __Ownable_init();
        DOMAIN_SEPARATOR = _deriveDomainSeparator();
        require(
            keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            ) == _EIP_712_DOMAIN_TYPEHASH,
            Errors.DOMAIN_HASH_DID_NOT_MATCH
        );
        require(
            keccak256(bytes(NAME)) == _NAME_HASH,
            Errors.NAME_HASH_DID_NOT_MATCH
        );
        require(
            keccak256(bytes(VERSION)) == _VERSION_HASH,
            Errors.VERSION_HASH_DID_NOT_MATCH
        );
        require(
            keccak256(
                "Order(address exchange,address maker,address taker,uint256 makerRelayerFee,uint256 takerRelayerFee,uint256 takerCashbackFee,address feeRecipient,uint8 side,uint8 saleKind,address target,uint8 howToCall,bytes data,bytes replacementPattern,bytes royaltyData,address staticTarget,bytes staticExtradata,address paymentToken,uint256 basePrice,uint256 extra,uint256 listingTime,uint256 expirationTime,uint256 salt,uint256 nonce)"
            ) == _ORDER_TYPEHASH,
            Errors.ORDER_HASH_DID_NOT_MATCH
        );
        _initializeEIP712();
    }

    /**
     * Increment a particular maker's nonce, thereby invalidating all orders that were not signed
     * with the original nonce.
     */
    function incrementNonce() external {
        uint256 newNonce = ++nonces[_msgSender()];
        emit NonceIncremented(_msgSender(), newNonce);
    }
    /**
     * @dev Sets the tokenTrannsferProxy address.
     * @param _tokenTransferProxy the tokenTransferProxy address.
     */
    function setTokenTransferProxy(TokenTransferProxy _tokenTransferProxy) external onlyOwner {
        require(address(_tokenTransferProxy) != address(0), Errors.INVALID_IMPLEMENTATION);
        tokenTransferProxy = _tokenTransferProxy;
        emit TokenTransferProxyUpdated(address(_tokenTransferProxy));
    }

    /**
     * @dev Sets the proxyRegistry address.
     * @param _proxyRegistry the proxyRegistry address.
     */
    function setProxyRegistry(ProxyRegistry _proxyRegistry) external onlyOwner {
        require(address(_proxyRegistry) != address(0), Errors.INVALID_IMPLEMENTATION);
        registry = _proxyRegistry;
        emit ProxyRegistryUpdated(address(_proxyRegistry));
    }

    /**
     * @dev Return blockchain's chainID.
     * @return ChainID for current blockchain.
     */
    function getChainID() public view returns (uint256) {
        return block.chainid;
    }

    /**
     * @dev Execute a STATICCALL (introduced with Ethereum Metropolis, non-state-modifying external call)
     * @param target Contract to call
     * @param data Calldata (appended to extradata)
     * @param extradata Base data for STATICCALL (probably function selector and argument encoding)
     * @return result The result of the call (success or failure)
     */
    function staticCall(
        address target,
        bytes memory data,
        bytes memory extradata
    ) public view returns (bool result) {
        bytes memory combined = new bytes(data.length + extradata.length);
        uint256 index;
        assembly {
            index := add(combined, 0x20)
        }
        index = ArrayUtils.unsafeWriteBytes(index, extradata);
        ArrayUtils.unsafeWriteBytes(index, data);
        assembly {
            result := staticcall(
                gas(),
                target,
                add(combined, 0x20),
                mload(combined),
                mload(0x40),
                0
            )
        }
        return result;
    }

    /**
     * @dev Determine if an order has been approved. Note that the order may not still
     * be valid in cases where the maker's nonce has been incremented.
     * @param hash Hash of the order
     * @return approved whether or not the order was approved.
     */
    function approvedOrders(bytes32 hash) external view returns (bool approved) {
        return _approvedOrdersByNonce[hash] != 0;
    }

    /**
     * @dev Transfer tokens
     * @param token Token to transfer
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of tokens to transfer
     */
    function transferTokens(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (from == address(this)) {
                IERC20Upgradeable(token).safeTransfer(to, amount);
            } else {
                require(
                    tokenTransferProxy.transferFrom(token, from, to, amount),
                    Errors.TRANSFER_NOT_SUCCESSFUL
                );
            }
        }
    }

    /**
     * @dev Hash an order, returning the canonical EIP-712 order hash without the domain separator
     * @param order Order to hash
     * @param nonce maker nonce to hash
     * @return hash Hash of order
     */
    function hashOrder(Order memory order, uint256 nonce)
        internal
        pure
        returns (bytes32 hash)
    {
        /* Unfortunately abi.encodePacked doesn't work for entire object, stack size constraints. */
        bytes memory part1 = abi.encode(
            _ORDER_TYPEHASH,
            order.exchange,
            order.maker,
            order.taker,
            order.makerRelayerFee,
            order.takerRelayerFee
        );

        bytes memory part2 = abi.encode(
            order.takerCashbackFee,
            order.feeRecipient,
            order.side,
            order.saleKind,
            order.target
        );

        bytes memory part3 = abi.encode(
            order.howToCall,
            keccak256(order.data),
            keccak256(order.replacementPattern),
            keccak256(order.royaltyData),
            order.staticTarget,
            keccak256(order.staticExtradata),
            order.paymentToken,
            order.basePrice
        );

        bytes memory part4 = abi.encode(
            order.extra,
            order.listingTime,
            order.expirationTime,
            order.salt,
            nonce
        );

        hash = keccak256(abi.encodePacked(part1, part2, part3, part4));
        return hash;
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign via EIP-712 including the message prefix
     * @param order Order to hash
     * @param nonce Nonce to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function hashToSign(Order memory order, uint256 nonce)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    hashOrder(order, nonce)
                )
            );
    }

    /**
     * @dev Assert an order is valid and return its hash
     * @param order Order to validate
     * @param nonce Nonce to validate
     * @param sig ECDSA signature
     */
    function requireValidOrder(
        Order memory order,
        Sig memory sig,
        uint256 nonce
    ) internal view returns (bytes32) {
        bytes32 hash = hashToSign(order, nonce);
        require(validateOrder(hash, order, sig), Errors.INVALID_ORDER);
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

        /* Order must have a maker. */
        if (order.maker == address(0)) {
            return false;
        }

        /* Order must possess valid sale kind parameter combination. */
        if (
            !SaleKindLibrary.validateParameters(
                order.saleKind,
                order.expirationTime
            )
        ) {
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
    function validateOrder(
        bytes32 hash,
        Order memory order,
        Sig memory sig
    ) internal view returns (bool) {
        /* Not done in an if-conditional to prevent unnecessary ecrecover evaluation, which seems to happen even though it should short-circuit. */

        /* Order must have valid parameters. */
        if (!validateOrderParameters(order)) {
            return false;
        }

        /* Order must have not been canceled or already filled. */
        if (cancelledOrFinalized[hash]) {
            return false;
        }

        /* Return true if order has been previously approved with the current nonce */
        uint256 approvedOrderNoncePlusOne = _approvedOrdersByNonce[hash];
        if (approvedOrderNoncePlusOne != 0) {
            return approvedOrderNoncePlusOne == nonces[order.maker] + 1;
        }

        /* Prevent signature malleability and non-standard v values. */
        if (
            uint256(sig.s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return false;
        }
        if (sig.v != 27 && sig.v != 28) {
            return false;
        }

        /* recover via ECDSA, signed by maker (already verified as non-zero). */
        if (ecrecover(hash, sig.v, sig.r, sig.s) == order.maker) {
            return true;
        }

        /* fallback — attempt EIP-1271 isValidSignature check. */
        return _tryContractSignature(order.maker, hash, sig);
    }

    function _tryContractSignature(
        address orderMaker,
        bytes32 hash,
        Sig memory sig
    ) internal view returns (bool) {
        bytes memory isValidSignatureData = abi.encodeWithSelector(
            _EIP_1271_MAGIC_VALUE,
            hash,
            abi.encodePacked(sig.r, sig.s, sig.v)
        );

        bytes4 result;

        // NOTE: solidity 0.4.x does not support STATICCALL outside of assembly
        assembly {
            let success := staticcall(
                // perform a staticcall
                gas(), // forward all available gas
                orderMaker, // call the order maker
                add(isValidSignatureData, 0x20), // calldata offset comes after length
                mload(isValidSignatureData), // load calldata length
                0, // do not use memory for return data
                0 // do not use memory for return data
            )

            if iszero(success) {
                // if the call fails
                returndatacopy(0, 0, returndatasize()) // copy returndata buffer to memory
                revert(0, returndatasize()) // revert + pass through revert data
            }

            if eq(returndatasize(), 0x20) {
                // if returndata == 32 (one word)
                returndatacopy(0, 0, 0x20) // copy return data to memory in scratch space
                result := mload(0) // load return data from memory to the stack
            }
        }

        return result == _EIP_1271_MAGIC_VALUE;
    }

    /**
     * @dev Approve an order and optionally mark it for orderbook inclusion. Must be called by the maker of the order
     * @param order Order to approve
     * @param orderbookInclusionDesired Whether orderbook providers should include the order in their orderbooks
     */
    function approveOrder(Order memory order, bool orderbookInclusionDesired)
        internal
    {
        /* CHECKS */

        /* Assert sender is authorized to approve order. */
        require(_msgSender() == order.maker, Errors.CALLER_IS_NOT_MAKER);

        /* Calculate order hash. */
        bytes32 hash = hashToSign(order, nonces[order.maker]);

        /* Assert order has not already been approved. */
        require(
            _approvedOrdersByNonce[hash] == 0,
            Errors.ORDER_ALREADY_APPROVED
        );

        /* EFFECTS */

        /* Mark order as approved. */
        _approvedOrdersByNonce[hash] = nonces[order.maker] + 1;

        /* Log approval event. Must be split in two due to Solidity stack size limitations. */
        {
            emit OrderApprovedPartOne(
                hash,
                order.exchange,
                order.maker,
                order.taker,
                order.makerRelayerFee,
                order.takerRelayerFee,
                order.feeRecipient,
                order.side,
                order.saleKind,
                order.target
            );
        }
        {
            emit OrderApprovedPartTwo(
                hash,
                order.howToCall,
                order.data,
                order.replacementPattern,
                order.royaltyData,
                order.staticTarget,
                order.staticExtradata,
                order.paymentToken,
                order.basePrice,
                order.extra,
                order.listingTime,
                order.expirationTime,
                order.salt,
                orderbookInclusionDesired
            );
        }
    }

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     * @param nonce Nonce to cancel
     * @param sig ECDSA signature
     */
    function cancelOrder(
        Order memory order,
        Sig memory sig,
        uint256 nonce
    ) internal {
        /* CHECKS */

        /* Calculate order hash. */
        bytes32 hash = requireValidOrder(order, sig, nonce);

        /* Assert sender is authorized to cancel order. */
        require(_msgSender() == order.maker, Errors.CALLER_IS_NOT_MAKER);

        /* EFFECTS */

        /* Mark order as cancelled, preventing it from being matched. */
        cancelledOrFinalized[hash] = true;

        /* Log cancel event. */
        emit OrderCancelled(hash);
    }

    /**
     * @dev Calculate the current price of an order (convenience function)
     * @param order Order to calculate the price of
     * @return The current price of the order
     */
    function calculateCurrentPrice(Order memory order)
        internal
        view
        returns (uint256)
    {
        return
            SaleKindLibrary.calculateFinalPrice(
                order.side,
                order.saleKind,
                order.basePrice,
                order.extra,
                order.listingTime,
                order.expirationTime
            );
    }

    /**
     * @dev Calculate the price two orders would match at, if in fact they would match (otherwise fail)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Match price
     */
    function calculateMatchPrice(Order memory buy, Order memory sell)
        internal
        view
        returns (uint256)
    {
        /* Calculate sell price. */
        uint256 sellPrice = SaleKindLibrary.calculateFinalPrice(
            sell.side,
            sell.saleKind,
            sell.basePrice,
            sell.extra,
            sell.listingTime,
            sell.expirationTime
        );

        /* Calculate buy price. */
        uint256 buyPrice = SaleKindLibrary.calculateFinalPrice(
            buy.side,
            buy.saleKind,
            buy.basePrice,
            buy.extra,
            buy.listingTime,
            buy.expirationTime
        );

        /* Require price cross. */
        require(buyPrice >= sellPrice, Errors.INVALID_PRICE);

        /* Maker/taker priority. */
        return sell.feeRecipient != address(0) ? sellPrice : buyPrice;
    }

    /**
     * @dev Calculates and transfer the royality 
     * @param sell Sell-side order
     * @return Royality amount
     */
    function transferRoyalty(Order memory sell, uint256 price) internal returns (uint256) {
            /* Retrieving NFT details */
            /* Retreives the position for nftAddress and tokenID position from the royaltyData */
            (uint256[] memory nftPosition, uint256[] memory tokenPosition) = abi
                .decode(sell.royaltyData, (uint256[], uint256[]));
            require(
                nftPosition.length == tokenPosition.length,
                Errors.ROYALTY_DATA_LENGTH_NOT_EQUAL
            );
            // Arrays to store NFTAddress and TokenIDs
            address[] memory nftAddresses = new address[](nftPosition.length);
            uint256[] memory tokenIDs = new uint256[](tokenPosition.length);

            for (uint256 i = 0; i < nftPosition.length; i++) {
                uint256 n = nftPosition[i] / 2 - 1;
                uint256 t = tokenPosition[i] / 2 - 1;
                bytes memory nft = new bytes(32);
                bytes memory token = new bytes(32);
                for (uint256 j = 0; j < 32; j++) {
                    nft[j] = sell.data[n];
                    token[j] = sell.data[t];
                    n++;
                    t++;
                }
                // If salekind is English Auction then NFTAddress can be retrieved from the sell object, else we need to decode it from data.
                if (
                    sell.saleKind == SaleKindLibrary.SaleKind.EnglishAuction
                ) {
                    nftAddresses[i] = sell.target;
                } else {
                    address nftAddress = abi.decode(nft, (address));
                    nftAddresses[i] = nftAddress;
                }
                uint256 tokenID = abi.decode(token, (uint256));
                tokenIDs[i] = tokenID;
            }
            uint256 totalRoyalty = 0;
            uint256 sellPrice = price / nftAddresses.length;
            for (uint256 i = 0; i < nftAddresses.length; i++) {
                // checks if NFT supports EIP-2981 or not
                if (
                    IERC165Upgradeable(nftAddresses[i]).supportsInterface(
                        type(IERC2981Upgradeable).interfaceId
                    )
                ) {
                    (address reciever, uint256 royaltyAmount) = IERC2981Upgradeable(
                        nftAddresses[i]
                    ).royaltyInfo(tokenIDs[i], sellPrice);
                    totalRoyalty += royaltyAmount;
                    if(reciever != address(0) && royaltyAmount > 0){
                        if(sell.paymentToken == address(0)){
                            (bool success, ) = payable(reciever).call{value: royaltyAmount}("");
                            require(success, Errors.ROYALTY_TRANSFER_FAILED);
                        } else {
                            transferTokens(
                                sell.paymentToken,
                                sell.maker,
                                reciever,
                                royaltyAmount
                            );
                        }
                    }
                }
            }
            return totalRoyalty;
    }

    /**
     * @dev Execute all ERC20 token / Ether transfers associated with an order match (fees and buyer => seller transfer)
     * @param buy Buy-side order
     * @param sell Sell-side order
     */
    function executeFundsTransfer(Order memory buy, Order memory sell)
        internal
        returns (uint256)
    {
        /* Only payable in the special case of unwrapped Ether. */
        if (sell.paymentToken != address(0)) {
            require(msg.value == 0, Errors.VALUE_IS_NOT_ZERO);
        }

        /* Calculate match price. */
        uint256 price = calculateMatchPrice(buy, sell);

        /* If paying using a token (not Ether), transfer tokens. This is done prior to fee payments to that a seller will have tokens before being charged fees. */
        if (price > 0 && sell.paymentToken != address(0)) {
            transferTokens(sell.paymentToken, buy.maker, sell.maker, price);
        }

        /* Amount that will be received by seller (for Ether). */
        uint256 receiveAmount = price;

        /* Amount that must be sent by buyer (for Ether). */
        uint256 requiredAmount = price;

        uint256 totalFees = 0;

        uint256 cashback = (sell.takerCashbackFee * price) /
            INVERSE_BASIS_POINT;

        /* transfer royalty to the maker */
        receiveAmount -= transferRoyalty(sell, price);

        /* Determine maker/taker and charge fees accordingly. */
        if (sell.feeRecipient != address(0)) {
            /* Sell-side order is maker. */

            /* Assert taker fee is less than or equal to maximum fee specified by buyer. */
            require(
                sell.takerRelayerFee <= buy.takerRelayerFee,
                Errors.INVALID_BUY_TAKER_RELAYER_FEE
            );

            /* Maker fees are deducted from the token amount that the maker receives. Taker fees are extra tokens that must be paid by the taker. */

            if (sell.makerRelayerFee > 0) {
                uint256 makerRelayerFee = (sell.makerRelayerFee * price) /
                    INVERSE_BASIS_POINT;
                totalFees += makerRelayerFee;
                // if payment token is ether then the recieve amount is updated. If payment token is any other Token then we transfer the fees directly to this contract.
                if (sell.paymentToken == address(0)) {
                    receiveAmount = receiveAmount - makerRelayerFee;
                } else {
                    transferTokens(
                        sell.paymentToken,
                        sell.maker,
                        address(this),
                        makerRelayerFee
                    );
                }
            }

            if (sell.takerRelayerFee > 0) {
                uint256 takerRelayerFee = (sell.takerRelayerFee * price) /
                    INVERSE_BASIS_POINT;
                totalFees += takerRelayerFee;
                // if payment token is ether then the recieve amount is updated. If payment token is any other Token then we transfer the fees directly to this contract.
                if (sell.paymentToken == address(0)) {
                    requiredAmount = requiredAmount + takerRelayerFee;
                } else {
                    transferTokens(
                        sell.paymentToken,
                        buy.maker,
                        address(this),
                        takerRelayerFee
                    );
                }
            }
        } else {
            /* Buy-side order is maker. */

            /* Assert taker fee is less than or equal to maximum fee specified by seller. */
            require(
                buy.takerRelayerFee <= sell.takerRelayerFee,
                Errors.INVALID_SELL_TAKER_RELAYER_FEE
            );
            /* The Exchange does not escrow Ether, so direct Ether can only be used to with sell-side maker / buy-side taker orders. */
            require(
                sell.paymentToken != address(0),
                Errors.INVALID_SELL_PAYMENT_TOKEN
            );

            if (buy.makerRelayerFee > 0) {
                uint256 makerRelayerFee = (buy.makerRelayerFee * price) /
                    INVERSE_BASIS_POINT;
                totalFees += makerRelayerFee;
                transferTokens(
                    sell.paymentToken,
                    buy.maker,
                    address(this),
                    makerRelayerFee
                );
            }

            if (buy.takerRelayerFee > 0) {
                uint256 takerRelayerFee = (buy.takerRelayerFee * price) /
                    INVERSE_BASIS_POINT;
                totalFees += takerRelayerFee;
                transferTokens(
                    sell.paymentToken,
                    sell.maker,
                    address(this),
                    takerRelayerFee
                );
            }
        }
        // Checks if the order is eligible for cashback or not.
        if (cashback > 0) {
            require(cashback <= totalFees, Errors.INVALID_CASHBACK_AMOUNT);
            // cashback is given from the totalfees so we are deducting the cashback from the totalFees.
            totalFees -= cashback;
            if (sell.paymentToken != address(0)) {
                transferTokens(
                    sell.paymentToken,
                    address(this),
                    buy.maker,
                    cashback
                );
            } else {
                (bool success, ) = payable(buy.maker).call{value: cashback}("");
                require(success, Errors.CASHBACK_FAILED);
            }
        }

        // transfers the totalFees to the feeRecipient 
        if (sell.paymentToken != address(0)) {
            if (sell.feeRecipient != address(0)) {
                transferTokens(
                    sell.paymentToken,
                    address(this),
                    sell.feeRecipient,
                    totalFees
                );
            } else {
                transferTokens(
                    sell.paymentToken,
                    address(this),
                    buy.feeRecipient,
                    totalFees
                );
            }
        } else {
            if (sell.feeRecipient != address(0)) {
                (bool success, ) = payable(sell.feeRecipient).call{
                    value: totalFees
                }("");
                require(success, Errors.FEE_FAILED);
            } else {
                (bool success, ) = payable(buy.feeRecipient).call{
                    value: totalFees
                }("");
                require(success, Errors.FEE_FAILED);
            }
        }
        // transfer the ether to the seller.
            if (sell.paymentToken == address(0)) {
            /* Special-case Ether, order must be matched by buyer. */
            require(msg.value >= requiredAmount, Errors.NOT_ENOUGH_VALUE);
            (bool success, ) = payable(sell.maker).call{value: receiveAmount}("");
            require(success, Errors.ETHER_TRANSFER_NOT_SUCCESSFUL);
            /* Allow overshoot for variable-price auctions, refund difference. */
            uint256 diff = msg.value - requiredAmount;
            if (diff > 0) {
                (bool ret, ) = payable(buy.maker).call{value: diff}("");
                require(ret, Errors.ETHER_TRANSFER_NOT_SUCCESSFUL);
            }
        }

        /* This contract should never hold Ether, however, we cannot assert this, since it is impossible to prevent anyone from sending Ether e.g. with selfdestruct. */

        return price;
    }

    /**
     * @dev Return whether or not two orders can be matched with each other by basic parameters (does not check order signatures / calldata or perform static calls)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Whether or not the two orders can be matched
     */
    function ordersCanMatch(Order memory buy, Order memory sell)
        internal
        view
        returns (bool)
    {
        return (/* Must be opposite-side. */
        (buy.side == SaleKindLibrary.Side.Buy &&
            sell.side == SaleKindLibrary.Side.Sell) &&
            /* Must use same payment token. */
            (buy.paymentToken == sell.paymentToken) &&
            /* Must match maker/taker addresses. */
            (sell.taker == address(0) || sell.taker == buy.maker) &&
            (buy.taker == address(0) || buy.taker == sell.maker) &&
            /* One must be maker and the other must be taker (no bool XOR in Solidity). */
            ((sell.feeRecipient == address(0) &&
                buy.feeRecipient != address(0)) ||
                (sell.feeRecipient != address(0) &&
                    buy.feeRecipient == address(0))) &&
            /* Must match target. */
            (buy.target == sell.target) &&
            /* Must match howToCall. */
            (buy.howToCall == sell.howToCall) &&
            /* Buy-side order must be settleable. */
            SaleKindLibrary.canSettleOrder(
                buy.listingTime,
                buy.expirationTime
            ) &&
            /* Sell-side order must be settleable. */
            SaleKindLibrary.canSettleOrder(
                sell.listingTime,
                sell.expirationTime
            ));
    }

    /**
     * @dev Atomically match two orders, ensuring validity of the match, and execute all associated state transitions. Protected against reentrancy by a contract-global lock.
     * @param buy Buy-side order
     * @param buySig Buy-side order signature
     * @param sell Sell-side order
     * @param sellSig Sell-side order signature
     */
    function atomicMatch(
        Order memory buy,
        Sig memory buySig,
        Order memory sell,
        Sig memory sellSig,
        bytes32 metadata
    ) internal nonReentrant {
        /* CHECKS */

        /* Ensure buy order validity and calculate hash if necessary. */
        bytes32 buyHash;
        if (buy.maker == _msgSender()) {
            require(
                validateOrderParameters(buy),
                Errors.INVALID_ORDER_PARAMETERS_BUY_ORDER
            );
        } else {
            buyHash = _requireValidOrderWithNonce(buy, buySig);
        }

        /* Ensure sell order validity and calculate hash if necessary. */
        bytes32 sellHash;
        if (sell.maker == _msgSender()) {
            require(
                validateOrderParameters(sell),
                Errors.INVALID_ORDER_PARAMETERS_SELL_ORDER
            );
        } else {
            sellHash = _requireValidOrderWithNonce(sell, sellSig);
        }

        /* Must be matchable. */
        require(ordersCanMatch(buy, sell), Errors.ORDERS_NOT_MATCHABLE);

        /* Target must exist (prevent malicious selfdestructs just prior to order settlement). */
        require(sell.target.code.length > 0, Errors.TARGET_NOT_CONTRACT);

        /* Must match calldata after replacement, if specified. */
        if (buy.replacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(
                buy.data,
                sell.data,
                buy.replacementPattern
            );
        }
        if (sell.replacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(
                sell.data,
                buy.data,
                sell.replacementPattern
            );
        }
        require(
            ArrayUtils.arrayEq(buy.data, sell.data),
            Errors.DATA_NOT_MATCHED
        );

        /* Retrieve delegateProxy contract. */
        OwnableDelegateProxy delegateProxy = registry.proxies(sell.maker);

        /* Proxy must exist. */
        require(
            address(delegateProxy) != address(0),
            Errors.PROXY_NOT_REGISTERED
        );

        /* Assert implementation. */
        require(
            delegateProxy.implementation() ==
                registry.delegateProxyImplementation(),
            Errors.INVALID_IMPLEMENTATION
        );

        /* Access the passthrough AuthenticatedProxy. */
        AuthenticatedProxy proxy = AuthenticatedProxy(address(delegateProxy));

        /* EFFECTS */

        /* Mark previously signed or approved orders as finalized. */
        if (_msgSender() != buy.maker) {
            cancelledOrFinalized[buyHash] = true;
        }
        if (_msgSender() != sell.maker) {
            cancelledOrFinalized[sellHash] = true;
        }

        /* INTERACTIONS */

        /* Execute funds transfer and pay fees. */
        uint256 price = executeFundsTransfer(buy, sell);

        /* Execute specified call through proxy. */
        require(
            proxy.proxy(sell.target, sell.howToCall, sell.data),
            Errors.PROXY_CALL_FAILED
        );

        /* Static calls are intentionally done after the effectful call so they can check resulting state. */

        /* Handle buy-side static call if specified. */
        if (buy.staticTarget != address(0)) {
            require(
                staticCall(buy.staticTarget, sell.data, buy.staticExtradata),
                Errors.BUY_STATIC_CALL_FAILED
            );
        }

        /* Handle sell-side static call if specified. */
        if (sell.staticTarget != address(0)) {
            require(
                staticCall(sell.staticTarget, sell.data, sell.staticExtradata),
                Errors.SELL_STATIC_CALL_FAILED
            );
        }

        /* Log match event. */
        emit OrdersMatched(
            buyHash,
            sellHash,
            sell.feeRecipient != address(0) ? sell.maker : buy.maker,
            sell.feeRecipient != address(0) ? buy.maker : sell.maker,
            price,
            metadata
        );
    }

    function _requireValidOrderWithNonce(Order memory order, Sig memory sig)
        internal
        view
        returns (bytes32)
    {
        return requireValidOrder(order, sig, nonces[order.maker]);
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    /**
     * @dev Derive the domain separator for EIP-712 signatures.
     * @return The domain separator.
     */
    function _deriveDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _EIP_712_DOMAIN_TYPEHASH, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                    _NAME_HASH, // keccak256("Wyvern Exchange Contract")
                    _VERSION_HASH, // keccak256(bytes("2.3.1"))
                    getChainID(),
                    address(this)
                )
            );
    }
}
