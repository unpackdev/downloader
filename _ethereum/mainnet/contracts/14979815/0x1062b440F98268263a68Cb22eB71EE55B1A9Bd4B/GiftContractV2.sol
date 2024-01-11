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
    mapping(uint8 => uint256) internal _giftSubmitSupply;
    mapping(address => mapping(uint8 => uint256)) public giftSubmitList;

    mapping(uint256 => bool) internal _isTokenSubmitted;
    uint256[] internal _giftedTokenList;

    bool private _initialized;

    address public nftToken;
    address public tokenPool;

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    //Defining Transaction
    struct Txn {
        address to;
        uint256 tokenId;
        bytes data;
        bool executed;
        bool reverted;
        uint256 confirms;
    }

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
    modifier notReverted(uint256 _txIndex) {
        require(!txns[_txIndex].reverted, "tx already reverted");
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
        giftReserves[ID_MOG] = 74;
        giftReserves[ID_INV] = 425;
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

    function getTransactionCount() public view override returns (uint256) {
        return txns.length;
    }

    function getTransaction(uint256 _txIndex)
        public
        view
        override
        returns (
            address to,
            uint256 tokenId,
            bytes memory data,
            bool executed,
            bool reverted,
            uint256 numConfirmations
        )
    {
        Txn storage transaction = txns[_txIndex];

        return (
            transaction.to,
            transaction.tokenId,
            transaction.data,
            transaction.executed,
            transaction.reverted,
            transaction.confirms
        );
    }

    function getActiveTxnCount() public view override returns (uint256) {
        Txn[] memory _txns = txns;
        uint256 txActiveCount = 0;
        for (uint256 i = 0; i < _txns.length; i++) {
            if (!_txns[i].reverted) txActiveCount++;
        }
        return txActiveCount;
    }

    function getActiveTokenIds()
        public
        view
        override
        returns (uint256[] memory)
    {
        Txn[] memory _txns = txns;
        uint256 txActiveCount = getActiveTxnCount();
        uint256 j = 0;
        uint256[] memory _activeTxnIds = new uint256[](txActiveCount);
        for (uint256 i = 0; i < _txns.length; i++) {
            if (!_txns[i].reverted) {
                _activeTxnIds[j] = _txns[i].tokenId;
                j++;
            }
        }
        return _activeTxnIds;
    }

    /**
    Muti Signature Txn Functions
 */
    function _submit(
        address _to,
        uint8 _tierIndex,
        uint256 _tokenId,
        bytes memory _data
    ) internal returns (uint256) {
        require(_tierIndex == getTierIndex(_tokenId), "GIFT_INVALID_TIER");

        IERC721 nftContract = IERC721(nftToken);
        require(nftContract.ownerOf(_tokenId) == tokenPool, "GIFT_NOT_EXIST");

        require(!_isTokenSubmitted[_tokenId], "GIFT_SUBMITTED_ALREADY");
        _isTokenSubmitted[_tokenId] = true;

        uint256 txIndex = txns.length;
        uint256 giftTierSupply = _giftSubmitSupply[_tierIndex];
        uint256 giftReserve = giftReserves[_tierIndex];

        require(giftTierSupply < giftReserve, "GIFT_RESERVE_LIMITED");
        require(
            giftSubmitList[_to][_tierIndex] < giftLimit[_tierIndex],
            "GIFT_EXCEED_ALLOC"
        );
        txns.push(
            Txn({
                to: _to,
                tokenId: _tokenId,
                data: _data,
                executed: false,
                reverted: false,
                confirms: 0
            })
        );
        _giftSubmitSupply[_tierIndex]++;
        giftSubmitList[_to][_tierIndex]++;
        return txIndex;
    }

    function _confirm(uint256 _txIndex) internal {
        Txn storage transaction = txns[_txIndex];
        transaction.confirms += 1;
        isConfirmed[_txIndex][msg.sender] = true;
    }

    function _execute(uint256 _txIndex) internal {
        Txn storage transaction = txns[_txIndex];
        uint8 tierIndex = getTierIndex(transaction.tokenId);

        require(transaction.confirms >= confirmsRequired, "GIFT_NOT_CONFIRMED");

        transaction.executed = true;

        (bool success, ) = address(nftToken).call(
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256)",
                tokenPool,
                transaction.to,
                transaction.tokenId
            )
        );
        require(success, "GIFT_FAILED_TRANSFER");
        _giftedTokenList.push(transaction.tokenId);
        _giftSupply[tierIndex]++;
        giftList[transaction.to][tierIndex]++;
    }

    function _revoke(uint256 _txIndex) internal {
        Txn storage transaction = txns[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");
        unchecked {
            transaction.confirms -= 1;
            isConfirmed[_txIndex][msg.sender] = false;
            if (transaction.confirms == 0) {
                transaction.reverted = true;
                _isTokenSubmitted[transaction.tokenId] = false;
                uint8 tierIndex = getTierIndex(transaction.tokenId);
                _giftSubmitSupply[tierIndex]--;
                giftSubmitList[transaction.to][tierIndex]--;
            }
        }
    }

    function submit(
        address _to,
        uint8 _tierIndex,
        uint256 _tokenId,
        bytes memory _data
    ) public onlyOwner {
        uint256 txIndex = txns.length;
        _submit(_to, _tierIndex, _tokenId, _data);
        emit Submit(msg.sender, txIndex, _to, _tierIndex, _tokenId, _data);
    }

    function confirm(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
        notReverted(_txIndex)
    {
        _confirm(_txIndex);
        emit Confirm(msg.sender, _txIndex);
    }

    function execute(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notReverted(_txIndex)
    {
        _execute(_txIndex);
        emit Execute(msg.sender, _txIndex);
    }

    function revoke(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notReverted(_txIndex)
    {
        _revoke(_txIndex);
        emit Revoke(msg.sender, _txIndex);
    }

    function submitAndConfirm(
        address _to,
        uint8 _tierIndex,
        uint256 _tokenId,
        bytes memory _data
    ) public onlyOwner {
        uint256 txIndex = _submit(_to, _tierIndex, _tokenId, _data);
        _confirm(txIndex);
        emit SubmitAndConfirm(
            msg.sender,
            txIndex,
            _to,
            _tierIndex,
            _tokenId,
            _data
        );
    }

    function confirmAndExecute(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notConfirmed(_txIndex)
        notExecuted(_txIndex)
        notReverted(_txIndex)
    {
        _confirm(_txIndex);
        Txn storage transaction = txns[_txIndex];
        if (transaction.confirms >= confirmsRequired) {
            _execute(_txIndex);
            emit ConfirmAndExecute(msg.sender, _txIndex);
        } else {
            emit Confirm(msg.sender, _txIndex);
        }
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

    function getGiftedList() public view override returns (uint256[] memory) {
        return _giftedTokenList;
    }

    function isTokenSubmitted(uint256 tokenId)
        public
        view
        override
        returns (bool)
    {
        return _isTokenSubmitted[tokenId];
    }

    function getTierStartId(uint8 tier) public view returns (uint256) {
        IMembershipNFT nftContract = IMembershipNFT(nftToken);
        return nftContract.tierStartId(tier);
    }

    function getTierEndId(uint8 tier) public view returns (uint256) {
        IMembershipNFT nftContract = IMembershipNFT(nftToken);
        return nftContract.tierEndId(tier);
    }

    function getTierIndex(uint256 tokenId) public view returns (uint8) {
        IMembershipNFT nftContract = IMembershipNFT(nftToken);
        return nftContract.getTierIndex(tokenId);
    }
    function getTierTokenId(uint256 _tokenId) public view returns(uint) {
        IMembershipNFT nftContract = IMembershipNFT(nftToken);
        return nftContract.getTierTokenId(_tokenId);
    }
    // convert external Token to internal one
    function getTokenId(uint8 _tier, uint _tierTokenId) public view returns(uint) {
        IMembershipNFT nftContract = IMembershipNFT(nftToken);
        return nftContract.getTokenId(_tier, _tierTokenId);
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
