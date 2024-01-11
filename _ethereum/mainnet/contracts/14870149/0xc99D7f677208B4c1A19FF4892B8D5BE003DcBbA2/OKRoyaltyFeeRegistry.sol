// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IRoyaltyFeeRegistry.sol";
import "./ArrayUtils.sol";

/**
 * @title RoyaltyFeeRegistry
 * @notice It is a royalty fee registry for the LooksRare exchange.
 */
contract OKRoyaltyFeeRegistry is IRoyaltyFeeRegistry, Ownable {
    struct FeeInfo {
        address setter;
        address receiver;
        uint256 fee;
    }

    bytes32 DOMAIN_SEPARATOR;

    // Limit (if enforced for fee royalty in percentage (10,000 = 100%)
    uint256 public royaltyFeeLimit;

    mapping(address => FeeInfo) private _royaltyFeeInfoCollection;

    // whitelist to set sale
    mapping(address => bool) public whitelist;

    event SetWhitelist(address _member, bool _isAdded);

    function setWhitelist(address _member, bool _status) external onlyOwner {
        whitelist[_member] = _status;
        emit SetWhitelist(_member, _status);
    }

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "the caller isn't in the whitelist");
        _;
    }

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    //这里需要把要签名的数据结构化
    /* An order on the exchange. */
    struct RoyaltyFee {
        address collection;
        address setter;
        address receiver;
        uint256 fee;
        string nonce;
        string lengthStr;
        bytes32 hash;
    }

    function sizeOf(RoyaltyFee memory royaltyFee)
        internal
        pure
        returns (uint256)
    {
        return ((0x14 * 4) + (0x20 * 2));
    }

    function strConcat(string _a, string _b) public pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) bret[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
    }

    function _toBytes(address a) public pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(
                add(m, 20),
                xor(0x140000000000000000000000000000000000000000, a)
            )
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    function bytesConcat(bytes _a, bytes _b) public pure returns (bytes) {
        bytes memory _ba = _a;
        bytes memory _bb = _b;
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) bret[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        //return string(ret);
        return bret;
    }

    function toBytes(bytes32 _data) public pure returns (bytes) {
        return abi.encodePacked(_data);
    }

    function toString(address account) public pure returns (string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(uint256 value) public pure returns (string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes32 value) public pure returns (string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes memory data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function toStringNoPre(address account)
        public
        pure
        returns (string memory)
    {
        return toStringNOPre(abi.encodePacked(account));
    }

    function toStringNOPre(bytes memory data)
        public
        pure
        returns (string memory)
    {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(data.length * 2);

        for (uint256 i = 0; i < data.length; i++) {
            str[i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[1 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    bytes32 aHash;

    event ResultHash(bytes32 rHash);

    address serverAddress;

    function setServerAddress(address _serverAddress) public onlyWhitelist {
        serverAddress = _serverAddress;
    }

    //这里的v用 不带0x的地址 长度用40可以做到hash一致
    function updateRoyaltyFeeByThirdParty(RoyaltyFee royaltyFee, Sig sig)
        public
        returns (bytes32)
    {
        // Note: we need to use `encodePacked` here instead of `encode`.

        //string memory collectionStr = string(abi.encodePacked(collection));
        bytes memory a = abi.encodePacked(royaltyFee.collection);
        string memory aStr = toStringNOPre(a);

        bytes memory b = abi.encodePacked(royaltyFee.setter);
        string memory bStr = toStringNOPre(b);

        string memory abStr = strConcat(aStr, bStr);

        bytes memory c = abi.encodePacked(royaltyFee.receiver);
        string memory cStr = toStringNOPre(c);

        string memory abcStr = strConcat(abStr, cStr);
        string memory abcStrNonce = strConcat(abcStr, royaltyFee.nonce);

        aHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                royaltyFee.lengthStr,
                abcStrNonce
            )
        );

        require(aHash == royaltyFee.hash, "hash error");
        require(
            ecrecover(aHash, sig.v, sig.r, sig.s) == serverAddress,
            "sign error"
        );
        //require(cHash == hash,"hash error");
        emit ResultHash(aHash);

        require(
            royaltyFee.fee <= royaltyFeeLimit,
            "Registry: Royalty fee too high"
        );
        _royaltyFeeInfoCollection[royaltyFee.collection] = FeeInfo({
            setter: royaltyFee.setter,
            receiver: royaltyFee.receiver,
            fee: royaltyFee.fee
        });

        emit RoyaltyFeeUpdate(
            royaltyFee.collection,
            royaltyFee.setter,
            royaltyFee.receiver,
            royaltyFee.fee
        );

        return (aHash);
    }

    function stringToBytes32(string memory source)
        public
        constant
        returns (bytes32 result)
    {
        assembly {
            result := mload(add(source, 32))
        }
    }

    event NewRoyaltyFeeLimit(uint256 royaltyFeeLimit);
    event RoyaltyFeeUpdate(
        address indexed collection,
        address indexed setter,
        address indexed receiver,
        uint256 fee
    );

    /**
     * @notice Constructor
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    constructor(uint256 _royaltyFeeLimit) {
        require(_royaltyFeeLimit <= 9500, "Owner: Royalty fee limit too high");
        royaltyFeeLimit = _royaltyFeeLimit;
    }

    /**
     * @notice Update royalty info for collection
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit)
        external
        onlyWhitelist
    {
        require(_royaltyFeeLimit <= 9500, "Owner: Royalty fee limit too high");
        royaltyFeeLimit = _royaltyFeeLimit;

        emit NewRoyaltyFeeLimit(_royaltyFeeLimit);
    }

    /**
     * @notice Update royalty info for collection
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external onlyWhitelist {
        require(fee <= royaltyFeeLimit, "Registry: Royalty fee too high");
        _royaltyFeeInfoCollection[collection] = FeeInfo({
            setter: setter,
            receiver: receiver,
            fee: fee
        });

        emit RoyaltyFeeUpdate(collection, setter, receiver, fee);
    }

    /**
     * @notice Calculate royalty info for a collection address and a sale gross amount
     * @param collection collection address
     * @param amount amount
     * @return receiver address and amount received by royalty recipient
     */
    function royaltyInfo(address collection, uint256 amount)
        external
        view
        returns (address, uint256)
    {
        return (
            _royaltyFeeInfoCollection[collection].receiver,
            (amount * _royaltyFeeInfoCollection[collection].fee) / 10000
        );
    }

    /**
     * @notice View royalty info for a collection address
     * @param collection collection address
     */
    function royaltyFeeInfoCollection(address collection)
        external
        view
        returns (
            address,
            address,
            uint256
        )
    {
        return (
            _royaltyFeeInfoCollection[collection].setter,
            _royaltyFeeInfoCollection[collection].receiver,
            _royaltyFeeInfoCollection[collection].fee
        );
    }
}
