// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

pragma experimental ABIEncoderV2;

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

//import "./ECDSAUpgradeable.sol";

import "./IERC721.sol";
import "./IERC1155.sol";

import "./ITransferProxy.sol";
import "./IERCWithRoyalties.sol";

contract SimpleSale is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    event Buy(
        uint256 indexed orderNonce,
        address indexed token,
        uint256 indexed tokenId,
        uint256 amount,
        address owner,
        address buyer,
        uint256 value,
        uint256 serviceFee
    );

    event CloseOrder(
        uint256 orderNonce,
        address indexed token,
        uint256 indexed tokenId,
        address owner
    );

    enum TokenType {ERC1155, ERC721}

    // for ERCRoyalties
    bytes4 private constant _INTERFACE_ID_ROYALTIES = 0xbebd9614;

    uint256 public buyerFee;
    address payable public beneficiary;
    ITransferProxy public transferProxy;

    // keccak256(token, tokenId, owner, orderNonce) => completed amount
    mapping(bytes32 => uint256) public completed;

    /* An ECDSA signature. */
    struct Signature {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    struct OrderData {
        /* token type, erc721 or erc1155 */
        TokenType tokenType;
        /* Exchange address - should be current contract */
        address exchange;
        /* owner of the token */
        address owner;
        /* taker of the order */
        address taker;
        /* Token contract  */
        address token;
        /* TokenId */
        uint256 tokenId;
        /* Quantity for this order */
        uint256 quantity;
        /* Max items by each buy. Allow to create one big order, but to limit how many can be bought at once */
        uint256 maxByBuy;
        /* OrderNonce so we can have different order for the same tokenId */
        uint256 orderNonce;
        /* Buy token */
        address buyToken; /* address(0) for current chain native token */
        /* Unit price */
        uint256 unitPrice;
        /* total order value; only used in contract */
        uint256 total;
        /* total value for seller; only used in contract */
        uint256 endValue;
    }

    function initialize(
        address payable _beneficiary,
        address _transferProxy,
        uint256 _buyerFee
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        setBeneficiary(_beneficiary);
        setTransferProxy(_transferProxy);
        setBuyerFee(_buyerFee);
    }

    function setBuyerFee(uint256 _buyerFee) public onlyOwner {
        require(_buyerFee <= 1000, 'Buyer fees too high');
        buyerFee = _buyerFee;
    }

    function setTransferProxy(address _transferProxy) public onlyOwner {
        require(_transferProxy != address(0));
        transferProxy = ITransferProxy(_transferProxy);
    }

    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        require(_beneficiary != address(0));
        beneficiary = _beneficiary;
    }

    function prepareOrderMessage(OrderData memory order)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(order));
    }

    function recoverMessageSignature(
        bytes32 message,
        Signature calldata signature
    ) public pure returns (address) {
        uint8 v = signature.v;
        if (v < 27) {
            v += 27;
        }

        return
            ecrecover(
                keccak256(
                    abi.encodePacked(
                        '\x19Ethereum Signed Message:\n32',
                        message
                    )
                ),
                v,
                signature.r,
                signature.s
            );
    }

    function buy(
        OrderData memory order,
        Signature calldata sig,
        uint256 amount // quantity to buy
    ) external payable nonReentrant {
        // verify that order is for this contract
        require(
            order.exchange == address(this),
            'Sale: Order not for this contract'
        );

        // verify if this order is for a specific address
        if (order.taker != address(0)) {
            require(msg.sender == order.taker, 'Sale: Order not for this user');
        }

        require(amount > 0, 'Sale: amount must be > 0');

        require(
            order.maxByBuy == 0 || amount <= order.maxByBuy,
            'Sale: Amount too big'
        );

        // verify order signature
        _validateOrderSig(order, sig);

        // update order state
        bool closed = _verifyOpenAndModifyState(order, amount);

        // calculate all values (service fees, amount for recipient, amount for seller, ...)
        order.total = order.unitPrice.mul(amount);
        uint256 fees = order.total.mul(buyerFee).div(10000);

        require(
            msg.value == order.total.add(fees), // total = (unitPrice * amount) + fees
            'Sale: Sent value is incorrect'
        );

        // set endValue to total
        order.endValue = order.total;

        // send token to buyer
        if (order.tokenType == TokenType.ERC1155) {
            transferProxy.erc1155SafeTransferFrom(
                order.token,
                order.owner,
                msg.sender,
                order.tokenId,
                amount,
                bytes('')
            );
        } else {
            transferProxy.erc721SafeTransferFrom(
                order.token,
                order.owner,
                msg.sender,
                order.tokenId,
                bytes('')
            );
        }

        // send service fees to beneficiary
        if (fees > 0) {
            beneficiary.transfer(fees);
        }

        if (order.total > 0) {
            // send royalties if there are
            _processRoyalties(order);

            // send what is left for value to owner
            if (order.endValue > 0) {
                payable(order.owner).transfer(order.endValue);
            }
        }

        // emit buy
        emit Buy(
            order.orderNonce,
            order.token,
            order.tokenId,
            amount,
            order.owner,
            msg.sender,
            order.total,
            fees
        );

        // if order is closed, emit close.
        if (closed) {
            emit CloseOrder(
                order.orderNonce,
                order.token,
                order.tokenId,
                order.owner
            );
        }
    }

    function cancelOrder(
        address token,
        uint256 tokenId,
        uint256 orderNonce,
        uint256 quantity
    ) public {
        bytes32 orderId =
            _getOrderId(token, tokenId, quantity, msg.sender, orderNonce);
        completed[orderId] = quantity;
        emit CloseOrder(orderNonce, token, tokenId, msg.sender);
    }

    function _validateOrderSig(OrderData memory order, Signature calldata sig)
        public
        pure
    {
        require(
            recoverMessageSignature(prepareOrderMessage(order), sig) ==
                order.owner,
            'Sale: Incorrect order signature'
        );
    }

    // returns orderId for completion
    function _getOrderId(
        address token,
        uint256 tokenId,
        uint256 quantity,
        address owner,
        uint256 orderNonce
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(token, tokenId, quantity, owner, orderNonce));
    }

    function _verifyOpenAndModifyState(
        OrderData memory order,
        uint256 buyingAmount
    ) internal returns (bool) {
        bytes32 orderId =
            _getOrderId(
                order.token,
                order.tokenId,
                order.quantity,
                order.owner,
                order.orderNonce
            );
        uint256 comp = completed[orderId].add(buyingAmount);

        // makes sure order is not already closed
        require(
            comp <= order.quantity,
            'Sale: Order already closed or quantity too high'
        );

        // update order completion amount
        completed[orderId] = comp;

        // returns if order is closed or not
        return comp == order.quantity;
    }

    function _processRoyalties(OrderData memory order) private {
        IERCWithRoyalties withRoyalties = IERCWithRoyalties(order.token);
        if (withRoyalties.supportsInterface(_INTERFACE_ID_ROYALTIES)) {
            uint256 royalties = withRoyalties.getRoyalties(order.tokenId);
            // do not process if royalties are 0 or more than 100%
            if (royalties == 0 || royalties > 10000) {
                return;
            }

            uint256 royaltiesValue =
                order.total.mul(uint256(royalties)).div(10000);

            (bool success, ) =
                order.token.call{value: royaltiesValue}(
                    abi.encodeWithSignature(
                        'onRoyaltiesReceived(uint256)',
                        order.tokenId
                    )
                );
            require(success, 'Sale: Problem when sending royalties');
            order.endValue = order.total.sub(royaltiesValue);
        }
    }
}
