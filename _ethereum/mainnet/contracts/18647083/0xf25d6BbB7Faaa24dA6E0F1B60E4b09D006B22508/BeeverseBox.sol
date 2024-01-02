// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./SignatureVerify.sol";
import "./IERC20.sol";
import "./IERC721Receiver.sol";
import "./MerkleProof.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract BeeverseBox is OwnableUpgradeable, SignatureVerify {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC721 public nft;
    bool public paused;
    uint256 private seed;
    uint256 public expireAt;
    address public recipient;
    address public publicKey;

    enum Level {
        SUPER_RARE,
        RARE,
        ORDINARY,
        COMMON
    }

    struct Box {
        uint8 index;
        Level level;
        string name;
        string description;
        uint256 price;
        IERC20 paymentToken;
        uint64 startAt;
        uint64 endAt;
        uint64 openAt;
        uint64 delayedOn;
        bytes32 merkleRoot;
        uint256[] available;
        uint256[] sold;
        uint256 maxPurchase;
        uint256 maxSerial;
        uint256 currentSerial;
    }
    Box[] public boxs;

    struct UserAllowed {
        uint256 bought;
        uint256 max;
        uint256[] serial;
        uint256[] purchaseAt;
    }
    // {address: {boxId: purchased}}
    mapping(address => mapping(uint8 => UserAllowed)) purchased;

    struct SerialInfo {
        bool open;
        uint256 tokenId;
    }
    // {address: {boxId: {serial: SerialInfo}}}
    mapping(address => mapping(uint8 => mapping(uint256 => SerialInfo))) opened;

    struct BoxIdRange {
        uint256 startId;
        uint256 endId;
    }
    // boxId -> {startId, endId}
    mapping(uint256 => BoxIdRange) boxIds;

    // boxId -> serial -> open?
    mapping(uint256 => mapping(uint256 => bool)) boxOpened;

    event BoxCreated(uint256 indexed index, Box box);
    event BoxTokens(uint256 indexed index, uint256 start, uint256 end);
    event BuyBox(address indexed buyer, uint256 boxId, uint256 serial);
    event OpenBox(address indexed buyer, uint256 boxId, uint256 serial, uint256 indexed tokenId);
    event SetPrice(address indexed sender, uint256 indexed boxId, uint256 price);
    event SetPaymentToken(address indexed sender, uint256 indexed boxId, IERC20 paymentToken);
    event SetTime(address indexed sender, uint256 indexed boxId, uint256 startAt, uint256 endAt, uint256 openAt, uint256 delayedOn);
    event SetMerkleRoot(address indexed sender, uint256 indexed boxId, bytes32 merkleRoot);
    event SetAvaliableToken(address indexed sender, uint256 indexed boxId, uint256 maxSerial, uint256[] available);
    event SetMaxMint(address indexed sender, uint256 indexed boxId, uint256 maxMint);
    event SetPaused(address indexed sender, bool paused);
    event SetNFT(address indexed sender, IERC721 nft);
    event SetRecipient(address indexed sender, address recipient);

    function initialize(address _token, address _recipient) public initializer {
        __Ownable_init();
        paused = false;
        seed = block.timestamp;
        nft = IERC721(_token);
        recipient = _recipient;
    }

    struct BoxTimeParams {
        uint64 startAt;
        uint64 endAt;
        uint64 openAt;
        uint64 delayedOn;
    }

    function createBox(bytes calldata data) external onlyOwner {
        (string memory _name, string memory _description, Level _level, uint256 _price, IERC20 _paymentToken, BoxTimeParams memory params, bytes32 _merkleRoot, uint256 startId, uint256 endId, uint256 _maxPurchase, uint256 _maxSerial) = abi.decode(
            data,
            (string, string, Level, uint256, IERC20, BoxTimeParams, bytes32, uint256, uint256, uint256, uint256)
        );
        require(params.endAt > params.startAt && params.endAt > block.timestamp, 'Box: Invalid time.');
        require(endId >= startId, 'Box: Error length.');

        Box memory box;
        uint8 index = uint8(boxs.length);

        box.index = index;
        box.name = _name;
        box.description = _description;
        box.level = _level;
        box.price = _price;
        box.paymentToken = _paymentToken;
        box.startAt = params.startAt;
        box.endAt = params.endAt;
        box.openAt = params.openAt;
        box.delayedOn = params.delayedOn;
        box.merkleRoot = _merkleRoot;
        box.maxPurchase = _maxPurchase;
        box.maxSerial = _maxSerial;
        box.currentSerial = 0;

        boxs.push(box);

        boxIds[index].startId = startId;
        boxIds[index].endId = endId;

        emit BoxCreated(index, box);
        emit BoxTokens(index, startId, endId);
    }

    function buyBox(uint8 _id, bytes32[] calldata _merkleProof, uint256 _maxBuy) external payable whenNotPaused isBoxExist(_id) {
        uint256 price = _buyBox(_id, _merkleProof, _maxBuy);
        pay(address(boxs[_id].paymentToken), price);
    }

    function _buyBox(uint8 _id, bytes32[] memory _merkleProof, uint256 _maxBuy) internal returns (uint256 price) {
        Box memory box = boxs[_id];
        require(box.startAt <= block.timestamp && box.endAt >= block.timestamp, 'Box: Current time is invalid.');
        require(box.currentSerial < box.maxSerial, 'Box: Sold out.');

        if (box.merkleRoot != bytes32(0)) {
            require(MerkleProof.verify(_merkleProof, box.merkleRoot, keccak256(abi.encodePacked(msg.sender, _maxBuy))), 'Box: Not allowed to buy this box.');
            purchased[msg.sender][_id].max = _maxBuy;
        } else {
            purchased[msg.sender][_id].max = box.maxPurchase;
        }
        _quotaCheck(_id, msg.sender, box.currentSerial);
        uint256 currentSerial = box.currentSerial;
        boxs[_id].currentSerial++;

        emit BuyBox(msg.sender, _id, currentSerial);
        return (box.price);
    }

    function bulkBuyBox(uint8 _id, bytes32[] memory _merkleProof, uint256 _maxBuy, uint256 total) external payable whenNotPaused {
        require(total > 0, 'Box: Null data cannot be provided.');

        uint256 totalPrice;
        address paymentToken = address(boxs[_id].paymentToken);

        for (uint256 i = 0; i < total; i++) {
            uint256 price = _buyBox(_id, _merkleProof, _maxBuy);
            totalPrice += price;
        }

        pay(paymentToken, totalPrice);
    }

    function _quotaCheck(uint8 _boxId, address _buyer, uint256 _currentSerial) internal {
        UserAllowed storage allowed = purchased[_buyer][_boxId];

        require(allowed.max == 0 || allowed.bought < allowed.max, 'Box: Insufficient quota.');
        allowed.bought += 1;
        allowed.serial.push(_currentSerial);
        allowed.purchaseAt.push(block.timestamp);
    }

    function pay(address _paymentToken, uint256 _value) internal {
        if (address(_paymentToken) == address(0)) {
            require(_value == msg.value, 'Box: Invalid ETH amount.');
            if (recipient != address(0)) {
                (bool success, ) = recipient.call{ value: _value }('');
                require(success, 'Revert treasury call');
            }
        } else {
            address recipient_ = recipient;
            if (recipient_ == address(0)) {
                recipient_ = address(this);
            }
            IERC20Upgradeable(_paymentToken).safeTransferFrom(msg.sender, recipient_, _value);
        }
    }

    function openBoxFromBytes(bytes calldata data) external {
        (address sender, uint256 expiration, uint256 boxId, uint256 _serial, uint256 tokenId, bytes memory signature) = abi.decode(data, (address, uint256, uint8, uint256, uint256, bytes));
        bytes32 _hash = keccak256(abi.encodePacked(sender, expiration, boxId, _serial, tokenId));
        require(verify(_hash, signature), 'Box: Signature verification failed.');

        require(boxId < uint8(boxs.length), 'Box: box not found.');
        require(block.timestamp + expireAt < expiration, 'Box: Signature has expired.');

        Box storage box = boxs[boxId];
        _quotaCheckOpen(box, uint8(boxId), _serial, msg.sender);

        _preSale(boxId, _serial, tokenId);
        nft.mint(msg.sender, tokenId);

        opened[msg.sender][uint8(boxId)][_serial].tokenId = tokenId;
        emit OpenBox(msg.sender, boxId, _serial, tokenId);
    }

    function _preSale(uint256 boxId, uint256 serial, uint256 tokenId) internal {
        require(!boxOpened[boxId][serial], 'Box: Already open.');
        require(boxIds[boxId].startId <= tokenId && boxIds[boxId].endId >= tokenId, "Box: Out of range.");

        boxOpened[boxId][serial] = true;
    }

    // function openBox(uint8 _id, uint256 _serial) external isBoxExist(_id) {
    //     Box storage box = boxs[_id];
    //     _quotaCheckOpen(box, _id, _serial, msg.sender);

    //     uint256 tokenId = _preSale(box);
    //     nft.mint(msg.sender, tokenId);

    //     opened[msg.sender][_id][_serial].tokenId = tokenId;

    //     emit OpenBox(msg.sender, _id, _serial, tokenId);
    // }

    function _quotaCheckOpen(Box memory _box, uint8 _boxId, uint256 _serial, address _buyer) internal {
        require(_box.openAt == 0 || block.timestamp > _box.openAt, 'Box: Current time is invalid.');
        require(isAllowedOpen(purchased[_buyer][_boxId], _box, _serial), 'Box: Not allowed to open.');
        require(!opened[_buyer][_boxId][_serial].open, 'Box: Already open.');
        opened[_buyer][_boxId][_serial].open = true;
    }

    function isAllowedOpen(UserAllowed memory _info, Box memory _box, uint256 _element) internal view returns (bool) {
        for (uint256 i = 0; i < _info.serial.length; i++) {
            if ((_info.serial[i] == _element) && (_box.delayedOn + _info.purchaseAt[i] <= block.timestamp)) {
                return true;
            }
        }
        return false;
    }

    function findElementIndex(uint256[] memory arr, uint256 e) internal pure returns (uint) {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == e) {
                return i;
            }
        }
        return arr.length;
    }

    function random(uint256 begin, uint256 end) internal returns (uint256) {
        if (begin == end) {
            return 0;
        }
        uint256 span = end - begin;
        return (_random() % span) + begin;
    }

    function _random() internal returns (uint256) {
        uint256 number = uint256(keccak256(abi.encodePacked(seed, block.prevrandao, block.gaslimit, block.number, block.timestamp)));
        seed = number;
        return number;
    }

    function setPrice(uint8 _id, uint256 _price) external onlyOwner isBoxExist(_id) {
        boxs[_id].price = _price;
        emit SetPrice(msg.sender, _id, _price);
    }

    function setPaymentToken(uint8 _id, IERC20 _paymentToken) external onlyOwner isBoxExist(_id) {
        boxs[_id].paymentToken = _paymentToken;
        emit SetPaymentToken(msg.sender, _id, _paymentToken);
    }

    function setTime(uint8 _id, uint64 _startAt, uint64 _endAt, uint64 _openAt, uint64 _delayedOn) external onlyOwner isBoxExist(_id) {
        require(_endAt >= _startAt, 'Box: Invalid time.');
        if (_startAt > 0) {
            boxs[_id].startAt = _startAt;
        }
        if (_endAt > 0) {
            boxs[_id].endAt = _endAt;
        }
        if (_openAt > 0) {
            boxs[_id].openAt = _openAt;
        }
        if (_delayedOn > 0) {
            boxs[_id].delayedOn = _delayedOn;
        }

        emit SetTime(msg.sender, _id, _startAt, _endAt, _openAt, _delayedOn);
    }

    function setMerkleRoot(uint8 _id, bytes32 _merkleRoot) external onlyOwner isBoxExist(_id) {
        boxs[_id].merkleRoot = _merkleRoot;
        emit SetMerkleRoot(msg.sender, _id, _merkleRoot);
    }

    function setAvaliableToken(uint8 _id, uint256[] calldata _available) external onlyOwner isBoxExist(_id) {
        require(boxs[_id].maxSerial <= _available.length, 'Box: Invalid available');
        boxs[_id].available = _available;
        boxs[_id].maxSerial = _available.length;
        emit SetAvaliableToken(msg.sender, _id, _available.length, _available);
    }

    function setMaxMint(uint8 _id, uint256 _maxPurchase) external onlyOwner isBoxExist(_id) {
        boxs[_id].maxPurchase = _maxPurchase;
        emit SetMaxMint(msg.sender, _id, _maxPurchase);
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit SetPaused(msg.sender, _paused);
    }

    function setNFT(IERC721 _nft) external onlyOwner {
        nft = _nft;
        emit SetNFT(msg.sender, _nft);
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
        emit SetRecipient(msg.sender, _recipient);
    }

    function withdraw(IERC20 _paymentToken, address _recipient) external onlyOwner {
        if (address(_paymentToken) == address(0)) {
            uint256 amount = address(this).balance;
            require(amount > 0, 'Box: balance zero.');
            payable(_recipient).transfer(amount);
        } else {
            uint256 amount = _paymentToken.balanceOf(address(this));
            require(amount > 0, 'Box: balance zero.');
            IERC20Upgradeable(address(_paymentToken)).safeTransferFrom(msg.sender, _recipient, amount);
        }
    }

    function verify(bytes32 hashMessage, bytes memory _data) internal view returns (bool) {
        address addr = ecrecoverToAddress(hashMessage, _data);
        return addr == publicKey ? true : false;
    }

    function setPublicKey(address _publicKey) external onlyOwner {
        publicKey = _publicKey;
    }

    function setExpireAt(uint256 _expireAt) external onlyOwner {
        expireAt = _expireAt;
    }

    modifier isBoxExist(uint8 _index) {
        require(_index < uint8(boxs.length), 'Box: box not found.');
        _;
    }

    modifier whenNotPaused() {
        require(!paused, 'Box: Paused.');
        _;
    }
}
