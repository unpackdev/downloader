//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "./AccessControl.sol";
//import "./ReentrancyGuard.sol";
import "./IERC721A.sol";
import "./IMembershipNFT.sol";
import "./IGiftContract.sol";

contract GiftContractV2 is IGiftContract, AccessControl {
    uint256 public confirmsRequired;
    uint8 private constant ID_MOG = 0;
    uint8 private constant ID_INV = 1;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    mapping(uint8 => uint16) public giftLimit;
    mapping(uint8 => uint16) public giftReserves;
    mapping(uint8 => uint256) internal _giftSupply;
    mapping(address => mapping(uint8 => uint256)) public giftList;

    bool private _initialized;

    address public nftToken;
    address public tokenPool;

    struct Txn {
        address to;
        uint256[] amounts;
        bytes data;
        bool executed;
        uint256 confirms;
    }

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Txn[] public txns;
    modifier onlyOwner() {
        address account = msg.sender;
        require(
            hasRole(DEFAULT_ADMIN_ROLE, account) ||
                hasRole(MINTER_ROLE, account) ||
                hasRole(OWNER_ROLE, account),
            "Not admin"
        );
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < txns.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!txns[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }
    modifier initializer() {
        require(!_initialized, "GIFT_ALREADY_INITIALIZED");
        _initialized = true;
        _;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);
    }

    function initialize(address token, address pool)
        external
        initializer
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            token != address(0) && pool != address(0),
            "GIFT_INIT_ZERO_ADDRESS"
        );
        nftToken = token;
        tokenPool = pool;
        setGiftLimit(ID_MOG, 1);
        setGiftLimit(ID_INV, 1);
        giftReserves[ID_MOG] = 4;
        giftReserves[ID_INV] = 5;
        confirmsRequired = 2;
    }

    function setGiftLimit(uint8 tierIndex, uint8 limit) public onlyOwner {
        unchecked {
            giftLimit[tierIndex] = limit;
        }
        emit UpdateGiftLimit(msg.sender, tierIndex, limit);
    }

    function setGiftReserve(uint16[] memory reserves) public onlyOwner {
        unchecked {
            for (uint8 i = 0; i < reserves.length; i++) {
                giftReserves[i] = reserves[i];
            }
        }
        emit UpdateGiftReserves(msg.sender, reserves);
    }

    function setNumConfirms(uint256 number) public onlyOwner {
        unchecked {
            confirmsRequired = number;
        }
    }

    function getTransactionCount() public view returns (uint256) {
        return txns.length;
    }

    function getTransaction(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256[] memory amounts,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Txn storage transaction = txns[_txIndex];

        return (
            transaction.to,
            transaction.amounts,
            transaction.data,
            transaction.executed,
            transaction.confirms
        );
    }

    /**
    Muti Signature Txn Functions
 */
    function _submit(
        address _to,
        uint8 _tierIndex,
        uint256 _amount,
        bytes memory _data
    ) internal returns (uint256) {
        uint256 txIndex = txns.length;

        uint256 giftTierSupply = _giftSupply[_tierIndex];
        uint256 giftReserve = giftReserves[_tierIndex];

        require(_amount > 0, "GIFT_INVAID_AMOUNT");
        require(giftTierSupply + _amount <= giftReserve, "GIFT_OUT_OF_STOCK");
        require(
            giftList[_to][_tierIndex] + _amount <= giftLimit[_tierIndex],
            "GIFT_EXCEED_ALLOC"
        );
        uint256[] memory _amounts = new uint256[](2);
        _amounts[_tierIndex] = _amount;

        txns.push(
            Txn({
                to: _to,
                amounts: _amounts,
                data: _data,
                executed: false,
                confirms: 0
            })
        );
        return txIndex;
    }

    function _confirm(uint256 _txIndex) internal {
        Txn storage transaction = txns[_txIndex];
        transaction.confirms += 1;
        isConfirmed[_txIndex][msg.sender] = true;
    }

    function _execute(uint256 _txIndex) internal {
        Txn storage transaction = txns[_txIndex];
        uint256[] memory amounts = transaction.amounts;
        IMembershipNFT nftContract = IMembershipNFT(nftToken);

        require(transaction.confirms >= confirmsRequired, "cannot execute tx");

        transaction.executed = true;
        for (uint8 i = 0; i < amounts.length; i++) {
            uint256 giftTierSupply = _giftSupply[i];
            uint256 startId = nftContract.tierStartId(i);
            for (uint256 j = 0; j < amounts[i]; j++) {
                (bool success, ) = address(nftToken).call(
                    abi.encodeWithSignature(
                        "safeTransferFrom(address,address,uint256)",
                        tokenPool,
                        transaction.to,
                        startId + giftTierSupply + j
                    )
                );
                require(success, "tx failed");
            }
            _giftSupply[i] += amounts[i];
            giftList[transaction.to][i] += amounts[i];
        }
    }

    function _revoke(uint256 _txIndex) internal {
        Txn storage transaction = txns[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.confirms -= 1;
        isConfirmed[_txIndex][msg.sender] = false;
    }

    function submit(
        address _to,
        uint8 _tierIndex,
        uint256 _amount,
        bytes memory _data
    ) public onlyOwner {
        uint256 txIndex = txns.length;
        _submit(_to, _tierIndex, _amount, _data);
        emit Submit(msg.sender, txIndex, _to, _tierIndex, _amount, _data);
    }

    function confirm(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Txn storage transaction = txns[_txIndex];
        transaction.confirms += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit Confirm(msg.sender, _txIndex);
    }

    function execute(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        _execute(_txIndex);
        emit Execute(msg.sender, _txIndex);
    }

    function revoke(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        _revoke(_txIndex);
        emit Revoke(msg.sender, _txIndex);
    }

    function submitAndConfirm(
        address _to,
        uint8 _tierIndex,
        uint256 _amount,
        bytes memory _data
    ) public onlyOwner {
        uint txIndex = _submit(_to, _tierIndex, _amount, _data);
        _confirm(txIndex);
        emit SubmitAndConfirm(msg.sender, txIndex, _to, _tierIndex, _amount, _data);
    }
        function confirmAndExecute(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notConfirmed(_txIndex)
        notExecuted(_txIndex)
    {
        _confirm(_txIndex);
        _execute(_txIndex);
        emit ConfirmAndExecute(msg.sender, _txIndex);
    }
    //--------------------------------------------------------------
    function totalSupply(uint8 tierIndex)
        public
        view
        override
        returns (uint256)
    {
        return _giftSupply[tierIndex];
    }

    function getNftToken() public view override returns (address) {
        require(nftToken != address(0), "TOKEN_ZERO_ADDRESS");
        return nftToken;
    }

    function getTokenPool() public view override returns (address) {
        require(tokenPool != address(0), "ACCOUNT_ZERO_ADDRESS");
        return tokenPool;
    }

    function balanceOf(address owner, uint8 tierIndex)
        public
        view
        override
        returns (uint256)
    {
        require(owner != address(0), "OWNER_ZERO_ADDRESS");
        return giftList[owner][tierIndex];
    }
}
