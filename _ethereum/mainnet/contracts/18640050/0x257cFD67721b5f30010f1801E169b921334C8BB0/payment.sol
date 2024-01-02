// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./AccessControl.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./Ownable2Step.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./console.sol";

contract PaymentContract is Ownable2Step, EIP712, AccessControl, ReentrancyGuard{

    string private constant SIGNING_DOMAIN = "Leaf-payment";
    string private constant SIGNATURE_VERSION = "1";

     bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

    uint256 public constant UNITS = 10 ** 8;
    uint256 public constant DECIMAL = 10 ** 18;

    address public paySigner;

    enum ActionPayment { Payment, CancelPayment, ConfirmPayment, BuyOption}
    struct Payment {
        address payable receiver;
        uint256 amount;
        bool isConfirmed;
    }

    struct PaymentVoucher {
        uint8 action;
        address payable receiver;   // 事業者のアドレス
        address caller;             // 支払いするエンドユーザーのアドレス
        uint256 tokenId;
        uint256 jpy;
        uint256 amount;
        uint256 paymentId;
        uint256 nonce;
        bytes signature;
    }

    uint256 public paymentId = 0;

    mapping(uint256 => Payment) public payments;
    mapping(address => mapping(uint256 => bool)) public userPayments;
    mapping(address => uint256) public refunds;
    mapping(bytes32 => bool) usedSignatures;

    event PayEvent (
        address indexed receiver,
        address indexed caller,
        uint256 paymentId,
        uint256 tokenId,
        uint256 jpy,
        uint256 amount
    );

    event CancelEvent (
        address indexed receiver,
        address indexed caller,
        uint256 paymentId,
        uint256 tokenId,
        uint256 jpy,
        uint256 amount
    );

    event ConfirmEvent (
        address indexed receiver,
        address indexed caller,
        uint256 paymentId,
        uint256 tokenId,
        uint256 jpy,
        uint256 amount
    );

    event BuyOptionEvent(
        address indexed receiver,
        address indexed caller,
        uint256 paymentId,
        uint256 tokenId,
        uint256 jpy,
        uint256 amount
    );

    event SignerEvent(
        address indexed signer
    );

    event WithdrawEvent(
        uint256 amount,
        address indexed owner
    );

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), 'Caller is not a admin');
        _;
    }

    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION){
        require(msg.sender != address(0));

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function payment(PaymentVoucher calldata voucher) external payable nonReentrant{
        require(voucher.action == uint8(ActionPayment.Payment), "Invalid action");
        require(msg.value > 0, "Payment should be more than 0");
        require(msg.value >= voucher.amount  * DECIMAL / UNITS, "Insufficient funds");
        bytes32 messageHash = validation(voucher);
        require(compareAddresses(voucher.caller, msg.sender),'Not your signature'); // only target enduer
        payments[paymentId] = Payment(voucher.receiver, msg.value, false);
        userPayments[msg.sender][paymentId] = true;
        usedSignatures[messageHash] = true;
        emit PayEvent(
            voucher.receiver,
            msg.sender,
            paymentId,
            voucher.tokenId,
            voucher.jpy,
            voucher.amount
        );
        paymentId++;
    }

    function buyOption(PaymentVoucher calldata voucher) external payable nonReentrant{
        require(voucher.action == uint8(ActionPayment.BuyOption), "Invalid action");
        require(msg.value > 0, "Payment should be more than 0");
        require(msg.value >= voucher.amount  * DECIMAL / UNITS, "Insufficient funds");
        bytes32 messageHash = validation(voucher);
        require(compareAddresses(voucher.caller, msg.sender),'Not your signature'); // only target enduer
        payments[paymentId] = Payment(voucher.receiver, msg.value, true);
        userPayments[msg.sender][paymentId] = true;
        usedSignatures[messageHash] = true;
        emit BuyOptionEvent(
            voucher.receiver,
            msg.sender,
            paymentId,
            voucher.tokenId,
            voucher.jpy,
            voucher.amount
        );
        paymentId++;
    }
 
    function cancelPayment(PaymentVoucher calldata voucher) external nonReentrant {
        bytes32 messageHash = validation(voucher);
        
        require(voucher.action == uint8(ActionPayment.CancelPayment), "Invalid action");
        require(compareAddresses(voucher.caller, msg.sender), 'Not your signature'); // only target end-user
        require(userPayments[msg.sender][voucher.paymentId], "No such payment exists");
        require(!payments[voucher.paymentId].isConfirmed, "Payment is already confirmed");

        uint256 refundAmount = payments[voucher.paymentId].amount;
        payments[voucher.paymentId].amount = 0;
        usedSignatures[messageHash] = true;

        // Directly transfer the refund amount to the sender
        payable(msg.sender).transfer(refundAmount);

        emit CancelEvent(
            voucher.receiver, 
            msg.sender, 
            voucher.paymentId,
            voucher.tokenId, 
            voucher.jpy,
            refundAmount
        );
    }

    function confirmPayment(PaymentVoucher calldata voucher) external nonReentrant{
        bytes32 messageHash = validation(voucher);
        require(voucher.action == uint8(ActionPayment.ConfirmPayment), "Invalid action");
        require(userPayments[voucher.caller][voucher.paymentId], "No such payment exists");
        // require(payments[voucher.paymentId].amount > 0, "Payment does not exist");   // impossible code
        require(!payments[voucher.paymentId].isConfirmed, "Payment is already confirmed");
        payments[voucher.paymentId].isConfirmed = true;
        payments[voucher.paymentId].receiver.transfer(payments[voucher.paymentId].amount);
        usedSignatures[messageHash] = true;
        emit ConfirmEvent( 
            payments[voucher.paymentId].receiver, 
            voucher.caller, 
            voucher.paymentId, 
            voucher.tokenId, 
            voucher.jpy,
            payments[voucher.paymentId].amount
        );
    }

    function withdraw() payable external nonReentrant onlyOwner{
        address payable to = payable(msg.sender);
        uint256 amount = address(this).balance;
        require(amount != 0, "Insufficient Error");
        to.transfer(amount);
        emit WithdrawEvent(
            amount,
            msg.sender
        );
    }

    // function claimRefund() external nonReentrant{
    //     require(refunds[msg.sender] > 0, "No refund available");
    //     uint256 refundAmount = refunds[msg.sender];
    //     refunds[msg.sender] = 0;
    //     payable(msg.sender).transfer(refundAmount);
    //     emit ClaimEvent(msg.sender, refundAmount);
    // }

    function validation(PaymentVoucher calldata voucher) internal view returns(bytes32){
        bytes32 messageHash = keccak256(abi.encodePacked(voucher.signature, msg.sender));

        require(msg.sender != address(0),'Invalid address');
        require(!usedSignatures[messageHash], "Signature already used");

        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);
        require(paySigner == signer, "Signature invalid or unauthorized");

        //check nftContractSigner Address
        //require(compareAddresses(voucher.caller, msg.sender),'Not your signature'); 
        //require(compareAddresses(voucher.caller, msg.sender),'Not your signature'); 
        return messageHash;
    }

    function _hash(PaymentVoucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
        keccak256("PaymentVoucher(uint8 action,address receiver,address caller,uint256 tokenId,uint256 jpy,uint256 amount,uint256 paymentId,uint256 nonce)"),
        voucher.action,
        voucher.receiver,
        voucher.caller,
        voucher.tokenId,
        voucher.jpy,
        voucher.amount,
        voucher.paymentId,
        voucher.nonce
        )));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControl) returns (bool) {
        return AccessControl.supportsInterface(interfaceId);
    }

    function setPaySigner(address _addr) external onlyAdmin{
        require(_addr != address(0));
        paySigner = _addr;
        emit SignerEvent(_addr);
    }


    function _verify(PaymentVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
         return ECDSA.recover(digest, voucher.signature);
    }

    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function compareAddresses(address addr1, address addr2) internal pure returns(bool) {
        bytes20 b1 = bytes20(addr1);
        bytes20 b2 = bytes20(addr2);
        bytes memory b1hash = abi.encodePacked(ripemd160(abi.encodePacked(b1)));
        bytes memory b2hash = abi.encodePacked(ripemd160(abi.encodePacked(b2)));
        return keccak256(b1hash) == keccak256(b2hash);
    }  
}