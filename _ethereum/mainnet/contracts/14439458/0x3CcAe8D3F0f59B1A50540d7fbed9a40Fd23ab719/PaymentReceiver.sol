//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;
import "./IERC20.sol";
import "./draft-EIP712.sol";

interface IPaymentReceiver {
    struct NFTPayment {
        address hostContract;
        uint256 tokenId;
        uint256 price;
        address payingAddress;
        address receivingAddress;
        string tokenUri;
    }
    event PaymentReceived(
        address indexed payingAddress,
        address indexed receivingAddress,
        address indexed hostContract,
        uint256 tokenId,
        uint256 price,
        string tokenUri
    );

    function createPayment(
        NFTPayment calldata payment,
        bytes calldata operatorSignature
    ) external;
}

contract PaymentReceiver is IPaymentReceiver, EIP712 {
    bytes32 constant NFT_PAYMENT_TYPEHASH =
        keccak256(
            "NFTPayment(address hostContract,uint256 tokenId,uint256 price,string tokenUri)"
        );
    uint256 public counter;
    address public operator;
    address public receiver;
    IERC20 public currency;
    mapping(address => mapping(uint256 => bool)) public paid;
    mapping(uint256 => NFTPayment) public payments;

    constructor(
        string memory name,
        string memory version,
        address operator_,
        address receiver_,
        IERC20 currency_
    ) EIP712(name, version) {
        operator = operator_;
        receiver = receiver_;
        currency = currency_;
    }

    function createPayment(
        NFTPayment calldata payment,
        bytes calldata operatorSignature
    ) external override {
        require(
            payment.payingAddress != address(0) &&
                payment.receivingAddress != address(0)
        );
        address signer = _verifyPayment(payment, operatorSignature);
        require(signer == operator && msg.sender == payment.payingAddress);
        require(!paid[payment.hostContract][payment.tokenId]);
        require(currency.allowance(msg.sender, address(this)) >= payment.price);
        paid[payment.hostContract][payment.tokenId] = true;
        currency.transferFrom(msg.sender, receiver, payment.price);
        counter++;
        NFTPayment memory newPayment = NFTPayment({
            hostContract: payment.hostContract,
            tokenId: payment.tokenId,
            price: payment.price,
            payingAddress: msg.sender,
            receivingAddress: payment.receivingAddress,
            tokenUri: payment.tokenUri
        });
        payments[counter] = newPayment;
        emit PaymentReceived(
            newPayment.payingAddress,
            newPayment.receivingAddress,
            newPayment.hostContract,
            newPayment.tokenId,
            newPayment.price,
            newPayment.tokenUri
        );
    }

    function _hash(NFTPayment calldata payment)
        internal
        view
        returns (bytes32)
    {
        return
            EIP712._hashTypedDataV4(
                keccak256(
                    abi.encode(
                        NFT_PAYMENT_TYPEHASH,
                        payment.hostContract,
                        payment.tokenId,
                        payment.price,
                        keccak256(bytes(payment.tokenUri))
                    )
                )
            );
    }

    function _verifyPayment(
        NFTPayment calldata payment,
        bytes calldata signature
    ) internal view returns (address) {
        bytes32 digest = _hash(payment);
        return ECDSA.recover(digest, signature);
    }
}
