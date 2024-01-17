// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.0;
import "./ECDSA.sol";
import "./AccessControl.sol";

abstract contract DruzhbaStateMachine is AccessControl {
    enum DealState {
        ZERO,
        START,
        PAYMENT_COMPLETE,
        DISPUTE,
        CANCELED_ARBITER,
        CANCELED_TIMEOUT_ARBITER,
        CANCELED_BUYER,
        CANCELED_SELLER,
        CLEARED_SELLER,
        CLEARED_ARBITER
    }

    bytes32 public constant ARBITER_ROLE = keccak256("ARBITER_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));
    bytes32 private constant ACCEPT_DEAL_TYPEHASH = keccak256(abi.encodePacked("AcceptDeal(address token,address seller,address buyer,uint256 amount,uint256 fee,uint256 nonce,uint256 deadline)"));
    bytes32 private DOMAIN_SEPARATOR;

    mapping(bytes32 => DealState) public deals;
    mapping(address => uint256) public fees;

    struct DealData {
        address token;
        address seller;
        address buyer;
        uint256 amount;
        uint256 fee;
        uint256 nonce;
    }

    /***********************
    +       Events        +
    ***********************/

    event StateChanged(bytes32 indexed dealHash, DealData deal, DealState state, address creator);

    constructor(uint256 chainId, address _admin, address _signer) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(ARBITER_ROLE, _admin);
        _setupRole(SIGNER_ROLE, _signer);

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes("Druzhba")),
            keccak256(bytes("1")),
            chainId,
            address(this)
        ));
    }

    modifier isProperlySigned(
        DealData calldata deal,
        uint256 deadline,
        bytes memory signature
    ) {
        bytes32 _hash = acceptDealHash(deal, deadline);
        address dealSigner = ECDSA.recover(_hash, signature);
        require(hasRole(SIGNER_ROLE, dealSigner), "Invalid signer or signature");
        require(block.timestamp < deadline, "Signature expired");
        require(deal.seller != deal.buyer, "seller == buyer");
        _;
    }

    modifier isValidStateTransfer(
        DealData calldata deal,
        DealState fromState,
        DealState toState
    ) {
        bytes32 _hash = dealHash(deal);
        require(deals[_hash] == fromState, "Wrong deal state or deal is missing");
        deals[_hash] = toState;
        _;
        emit StateChanged(_hash, deal, toState, msg.sender);
    }

    modifier onlyBuyer(DealData calldata deal) {
        require(deal.buyer == msg.sender, 'buyer != msg.sender');
        _;
    }

    modifier onlySeller(DealData calldata deal) {
        require(deal.seller == msg.sender, 'seller != msg.sender');
        _;
    }

    function startDealBuyer(DealData calldata deal, uint256 deadline, bytes memory signature) external 
        onlyBuyer(deal) isProperlySigned(deal, deadline, signature) returns (bytes32) {
        return _startDeal(deal);
    }

    function startDealSeller(DealData calldata deal, uint256 deadline, bytes memory signature) external 
        onlySeller(deal) isProperlySigned(deal, deadline, signature) returns (bytes32) {
        return _startDeal(deal);
    }

    function _startDeal(DealData calldata deal) internal returns (bytes32) {
        bytes32 _hash = dealHash(deal);
        require(deals[_hash] == DealState.ZERO, "storage slot collision");
        deals[_hash] = DealState.START;
        
        _transferFrom(deal.token, deal.seller, address(this), deal.amount+deal.fee);

        emit StateChanged(_hash, deal, DealState.START, msg.sender);
        return _hash;
    }

    function cancelTimeoutArbiter(DealData calldata deal) external 
        onlyRole(ARBITER_ROLE) isValidStateTransfer(deal, DealState.START, DealState.CANCELED_TIMEOUT_ARBITER) {
        _transfer(deal.token, deal.seller, deal.amount+deal.fee); 
    }

    function cancelDealBuyer(DealData calldata deal) external 
        onlyBuyer(deal) isValidStateTransfer(deal, DealState.START, DealState.CANCELED_BUYER) {
        _transfer(deal.token, deal.seller, deal.amount+deal.fee);
    }

    function completePaymentBuyer(DealData calldata deal) external 
        onlyBuyer(deal) isValidStateTransfer(deal, DealState.START, DealState.PAYMENT_COMPLETE) {}

    function clearDealSeller(DealData calldata deal) external 
        onlySeller(deal) isValidStateTransfer(deal, DealState.PAYMENT_COMPLETE, DealState.CLEARED_SELLER) {
        fees[deal.token] += deal.fee;
        _transfer(deal.token, deal.buyer, deal.amount);
    }

    function clearDisputeDealSeller(DealData calldata deal) external 
        onlySeller(deal) isValidStateTransfer(deal, DealState.DISPUTE, DealState.CLEARED_SELLER) {
        fees[deal.token] += deal.fee;
        _transfer(deal.token, deal.buyer, deal.amount);
    }

    function callHelpSeller(DealData calldata deal) external 
        onlySeller(deal) isValidStateTransfer(deal, DealState.PAYMENT_COMPLETE, DealState.DISPUTE) {}

    function callHelpBuyer(DealData calldata deal) external 
        onlyBuyer(deal) isValidStateTransfer(deal, DealState.PAYMENT_COMPLETE, DealState.DISPUTE) {}

    function cancelDealArbiter(DealData calldata deal) external 
        onlyRole(ARBITER_ROLE) isValidStateTransfer(deal, DealState.DISPUTE, DealState.CANCELED_ARBITER) {
        _transfer(deal.token, deal.seller, deal.amount+deal.fee);
    }

    function clearDealArbiter(DealData calldata deal) external 
        onlyRole(ARBITER_ROLE) isValidStateTransfer(deal, DealState.DISPUTE, DealState.CLEARED_ARBITER) {
        fees[deal.token] += deal.fee;
        _transfer(deal.token, deal.buyer, deal.amount);
    }

    function claim(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = fees[token];
        fees[token] = 0;
        _transfer(token, msg.sender, amount);
    }

    function dealHash(DealData calldata deal) internal pure returns (bytes32) {
        return keccak256(abi.encode(deal));
    }

    function acceptDealHash(DealData calldata deal, uint256 deadline) internal view returns (bytes32) {
        bytes32 _hash = keccak256(abi.encode(ACCEPT_DEAL_TYPEHASH, deal.token, deal.seller, deal.buyer, deal.amount, deal.fee, deal.nonce, deadline));
        return keccak256(abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, _hash));
    }
    
    function _transfer(address token, address _to, uint256 _value) internal virtual;

    function _transferFrom(address token, address _from, address _to, uint256 _value) internal virtual;
}
