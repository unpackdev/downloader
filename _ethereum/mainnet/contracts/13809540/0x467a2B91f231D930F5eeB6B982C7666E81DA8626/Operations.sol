pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import "./Bytes.sol";


/// @title ZKSwap operations tools
library Operations {

    // Circuit ops and their pubdata (chunks * bytes)

    /// @notice ZKSwap circuit operation type
    enum OpType {
        Noop,
        Deposit,
        TransferToNew,
        PartialExit,
        _CloseAccount, // used for correct op id offset
        Transfer,
        FullExit,
        ChangePubKey,
        CreatePair,
        AddLiquidity,
        RemoveLiquidity,
        Swap,
        DepositNFT,
        MintNFT,
        TransferNFT,
        TransferToNewNFT,
        PartialExitNFT,
        FullExitNFT,
        ApproveNFT,
        ExchangeNFT
    }

    // Byte lengths

    uint8 constant TOKEN_BYTES = 2;

    uint8 constant PUBKEY_BYTES = 32;

    uint8 constant NONCE_BYTES = 4;

    uint8 constant PUBKEY_HASH_BYTES = 20;

    uint8 constant ADDRESS_BYTES = 20;

    /// @notice Packed fee bytes lengths
    uint8 constant FEE_BYTES = 2;

    /// @notice ZKSwap account id bytes lengths
    uint8 constant ACCOUNT_ID_BYTES = 4;

    uint8 constant AMOUNT_BYTES = 16;

    /// @notice Signature (for example full exit signature) bytes length
    uint8 constant SIGNATURE_BYTES = 64;

    /// @notice nft uri bytes lengths
    uint8 constant NFT_URI_BYTES = 32;

    /// @notice nft seq id bytes lengths
    uint8 constant NFT_SEQUENCE_ID_BYTES = 4;

    /// @notice nft creator bytes lengths
    uint8 constant NFT_CREATOR_ID_BYTES = 4;

    /// @notice nft priority op id bytes lengths
    uint8 constant NFT_PRIORITY_OP_ID_BYTES = 8;

    /// @notice nft global id bytes lengths
    uint8 constant NFT_GLOBAL_ID_BYTES = 8;

    /// @notic withdraw nft use fee token id bytes lengths
    uint8 constant NFT_FEE_TOKEN_ID = 1;

    /// @notic fullexit nft success bytes lengths
    uint8 constant NFT_SUCCESS = 1;


    // Deposit pubdata
    struct Deposit {
        uint32 accountId;
        uint16 tokenId;
        uint128 amount;
        address owner;
    }

    uint public constant PACKED_DEPOSIT_PUBDATA_BYTES = 
        ACCOUNT_ID_BYTES + TOKEN_BYTES + AMOUNT_BYTES + ADDRESS_BYTES;

    /// Deserialize deposit pubdata
    function readDepositPubdata(bytes memory _data) internal pure
        returns (Deposit memory parsed)
    {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint offset = 0;
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset); // accountId
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);   // tokenId
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);   // amount
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);    // owner

        require(offset == PACKED_DEPOSIT_PUBDATA_BYTES, "rdp10"); // reading invalid deposit pubdata size
    }

    /// Serialize deposit pubdata
    function writeDepositPubdata(Deposit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            bytes4(0),   // accountId (ignored) (update when ACCOUNT_ID_BYTES is changed)
            op.tokenId,  // tokenId
            op.amount,   // amount
            op.owner     // owner
        );
    }

    /// @notice Check that deposit pubdata from request and block matches
    function depositPubdataMatch(bytes memory _lhs, bytes memory _rhs) internal pure returns (bool) {
        // We must ignore `accountId` because it is present in block pubdata but not in priority queue
        bytes memory lhs_trimmed = Bytes.slice(_lhs, ACCOUNT_ID_BYTES, PACKED_DEPOSIT_PUBDATA_BYTES - ACCOUNT_ID_BYTES);
        bytes memory rhs_trimmed = Bytes.slice(_rhs, ACCOUNT_ID_BYTES, PACKED_DEPOSIT_PUBDATA_BYTES - ACCOUNT_ID_BYTES);
        return keccak256(lhs_trimmed) == keccak256(rhs_trimmed);
    }

    // FullExit pubdata

    struct FullExit {
        uint32 accountId;
        address owner;
        uint16 tokenId;
        uint128 amount;
    }

    uint public constant PACKED_FULL_EXIT_PUBDATA_BYTES = 
        ACCOUNT_ID_BYTES + ADDRESS_BYTES + TOKEN_BYTES + AMOUNT_BYTES;

    function readFullExitPubdata(bytes memory _data) internal pure
        returns (FullExit memory parsed)
    {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint offset = 0;
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);      // accountId
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);         // owner
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);        // tokenId
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);        // amount

        require(offset == PACKED_FULL_EXIT_PUBDATA_BYTES, "rfp10"); // reading invalid full exit pubdata size
    }

    function writeFullExitPubdata(FullExit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            op.accountId,  // accountId
            op.owner,      // owner
            op.tokenId,    // tokenId
            op.amount      // amount
        );
    }

    /// @notice Check that full exit pubdata from request and block matches
    function fullExitPubdataMatch(bytes memory _lhs, bytes memory _rhs) internal pure returns (bool) {
        // `amount` is ignored because it is present in block pubdata but not in priority queue
        uint lhs = Bytes.trim(_lhs, PACKED_FULL_EXIT_PUBDATA_BYTES - AMOUNT_BYTES);
        uint rhs = Bytes.trim(_rhs, PACKED_FULL_EXIT_PUBDATA_BYTES - AMOUNT_BYTES);
        return lhs == rhs;
    }

    // PartialExit pubdata
    
    struct PartialExit {
        //uint32 accountId; -- present in pubdata, ignored at serialization
        uint16 tokenId;
        uint128 amount;
        //uint16 fee; -- present in pubdata, ignored at serialization
        address owner;
    }

    function readPartialExitPubdata(bytes memory _data, uint _offset) internal pure
        returns (PartialExit memory parsed)
    {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint offset = _offset + ACCOUNT_ID_BYTES;                   // accountId (ignored)
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);  // owner
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset); // tokenId
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset); // amount
    }

    function writePartialExitPubdata(PartialExit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            bytes4(0),  // accountId (ignored) (update when ACCOUNT_ID_BYTES is changed)
            op.tokenId, // tokenId
            op.amount,  // amount
            bytes2(0),  // fee (ignored)  (update when FEE_BYTES is changed)
            op.owner    // owner
        );
    }

    // ChangePubKey

    struct ChangePubKey {
        uint32 accountId;
        bytes20 pubKeyHash;
        address owner;
        uint32 nonce;
    }

    function readChangePubKeyPubdata(bytes memory _data, uint _offset) internal pure
        returns (ChangePubKey memory parsed)
    {
        uint offset = _offset;
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);                // accountId
        (offset, parsed.pubKeyHash) = Bytes.readBytes20(_data, offset);              // pubKeyHash
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);                   // owner
        (offset, parsed.nonce) = Bytes.readUInt32(_data, offset);                    // nonce
    }

    // Withdrawal nft data process

    struct WithdrawNFTData {
        bool valid;  //confirm the necessity of this field
        bool pendingWithdraw;
        uint64 globalId;
        uint32 creatorId;
        uint32 seqId;
        address target;
        bytes32 uri;
    }

    function readWithdrawalData(bytes memory _data, uint _offset) internal pure
    returns (bool isNFTWithdraw, uint128 amount, uint16 _tokenId, WithdrawNFTData memory parsed)
    {
        uint offset = _offset;
        (offset, isNFTWithdraw) = Bytes.readBool(_data, offset);
        (offset, parsed.pendingWithdraw) = Bytes.readBool(_data, offset);
        (offset, parsed.target) = Bytes.readAddress(_data, offset);  // target
        if (isNFTWithdraw) {
            (offset, parsed.globalId) = Bytes.readUInt64(_data, offset);
            (offset, parsed.creatorId) = Bytes.readUInt32(_data, offset);   // creatorId
            (offset, parsed.seqId) = Bytes.readUInt32(_data, offset);   // seqId
            (offset, parsed.uri) = Bytes.readBytes32(_data, offset);   // uri
            (offset, parsed.valid) = Bytes.readBool(_data, offset); // is withdraw valid
        } else {
            (offset, _tokenId) = Bytes.readUInt16(_data, offset);
            (offset, amount) = Bytes.readUInt128(_data, offset); // withdraw erc20 or eth token amount
        }
    }

    // CreatePair pubdata
    
    struct CreatePair {
        uint32 accountId;
        uint16 tokenA;
        uint16 tokenB;
        uint16 tokenPair;
        address pair;
    }

    uint public constant PACKED_CREATE_PAIR_PUBDATA_BYTES =
        ACCOUNT_ID_BYTES + TOKEN_BYTES + TOKEN_BYTES + TOKEN_BYTES + ADDRESS_BYTES;

    function readCreatePairPubdata(bytes memory _data) internal pure
        returns (CreatePair memory parsed)
    {
        uint offset = 0;
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset); // accountId
        (offset, parsed.tokenA) = Bytes.readUInt16(_data, offset); // tokenAId
        (offset, parsed.tokenB) = Bytes.readUInt16(_data, offset); // tokenBId
        (offset, parsed.tokenPair) = Bytes.readUInt16(_data, offset); // pairId
        (offset, parsed.pair) = Bytes.readAddress(_data, offset); // pairId
        require(offset == PACKED_CREATE_PAIR_PUBDATA_BYTES, "rcp10"); // reading invalid create pair pubdata size
    }

    function writeCreatePairPubdata(CreatePair memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            bytes4(0),      // accountId (ignored) (update when ACCOUNT_ID_BYTES is changed)
            op.tokenA,      // tokenAId
            op.tokenB,      // tokenBId
            op.tokenPair,   // pairId
            op.pair         // pair account
        );
    }

    /// @notice Check that create pair pubdata from request and block matches
    function createPairPubdataMatch(bytes memory _lhs, bytes memory _rhs) internal pure returns (bool) {
        // We must ignore `accountId` because it is present in block pubdata but not in priority queue
        bytes memory lhs_trimmed = Bytes.slice(_lhs, ACCOUNT_ID_BYTES, PACKED_CREATE_PAIR_PUBDATA_BYTES - ACCOUNT_ID_BYTES);
        bytes memory rhs_trimmed = Bytes.slice(_rhs, ACCOUNT_ID_BYTES, PACKED_CREATE_PAIR_PUBDATA_BYTES - ACCOUNT_ID_BYTES);
        return keccak256(lhs_trimmed) == keccak256(rhs_trimmed);
    }

    // DepositNFT pubdata
    struct DepositNFT {
        uint64 globalId;
        uint32 creatorId;
        uint32 seqId;
        bytes32 uri;
        address owner;
        uint32 accountId;
    }

    uint public constant PACKED_DEPOSIT_NFT_PUBDATA_BYTES = ACCOUNT_ID_BYTES +
    NFT_GLOBAL_ID_BYTES + NFT_CREATOR_ID_BYTES + NFT_SEQUENCE_ID_BYTES +
    NFT_URI_BYTES + ADDRESS_BYTES ;

    /// Deserialize deposit nft pubdata
    function readDepositNFTPubdata(bytes memory _data) internal pure
    returns (DepositNFT memory parsed) {

        uint offset = 0;
        (offset, parsed.globalId) = Bytes.readUInt64(_data, offset);   // globalId
        (offset, parsed.creatorId) = Bytes.readUInt32(_data, offset);   // creatorId
        (offset, parsed.seqId) = Bytes.readUInt32(_data, offset);   // seqId
        (offset, parsed.uri) = Bytes.readBytes32(_data, offset);   // uri
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);    // owner
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset); // accountId
        require(offset == PACKED_DEPOSIT_NFT_PUBDATA_BYTES, "rdnp10"); // reading invalid deposit pubdata size
    }

    /// Serialize deposit pubdata
    function writeDepositNFTPubdata(DepositNFT memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            op.globalId,
            op.creatorId,
            op.seqId,
            op.uri,
            op.owner,     // owner
            bytes4(0)
        );
    }

    /// @notice Check that deposit nft pubdata from request and block matches
    function depositNFTPubdataMatch(bytes memory _lhs, bytes memory _rhs) internal pure returns (bool) {
        // We must ignore `accountId` because it is present in block pubdata but not in priority queue
        uint offset = 0;
        uint64 globalId;
        (offset, globalId) = Bytes.readUInt64(_lhs, offset);   // globalId
        if (globalId == 0){
            bytes memory lhs_trimmed = Bytes.slice(_lhs, NFT_GLOBAL_ID_BYTES, PACKED_DEPOSIT_NFT_PUBDATA_BYTES - ACCOUNT_ID_BYTES - NFT_GLOBAL_ID_BYTES);
            bytes memory rhs_trimmed = Bytes.slice(_rhs, NFT_GLOBAL_ID_BYTES, PACKED_DEPOSIT_NFT_PUBDATA_BYTES - ACCOUNT_ID_BYTES - NFT_GLOBAL_ID_BYTES);
            return keccak256(lhs_trimmed) == keccak256(rhs_trimmed);

        }else{
            bytes memory lhs_trimmed = Bytes.slice(_lhs, 0, PACKED_DEPOSIT_NFT_PUBDATA_BYTES - ACCOUNT_ID_BYTES);
            bytes memory rhs_trimmed = Bytes.slice(_rhs, 0, PACKED_DEPOSIT_NFT_PUBDATA_BYTES - ACCOUNT_ID_BYTES);
            return keccak256(lhs_trimmed) == keccak256(rhs_trimmed);
        }
    }

    // FullExitNFT pubdata
    struct FullExitNFT {
        uint32 accountId;
        uint64 globalId;
        uint32 creatorId;
        uint32 seqId;
        bytes32 uri;
        address owner;
        uint8 success;
    }

    uint public constant PACKED_FULL_EXIT_NFT_PUBDATA_BYTES = ACCOUNT_ID_BYTES +
        NFT_GLOBAL_ID_BYTES +  NFT_CREATOR_ID_BYTES +
        NFT_SEQUENCE_ID_BYTES + NFT_URI_BYTES + ADDRESS_BYTES + NFT_SUCCESS;

    function readFullExitNFTPubdata(bytes memory _data) internal pure returns (FullExitNFT memory parsed) {
        uint offset = 0;
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset); // accountId
        (offset, parsed.globalId) = Bytes.readUInt64(_data, offset);   // globalId
        (offset, parsed.creatorId) = Bytes.readUInt32(_data, offset); // creator
        (offset, parsed.seqId) = Bytes.readUInt32(_data, offset); // seqId
        (offset, parsed.uri) = Bytes.readBytes32(_data, offset); // uri
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);    // owner
        (offset, parsed.success) = Bytes.readUint8(_data, offset); // success

        require(offset == PACKED_FULL_EXIT_NFT_PUBDATA_BYTES, "rfnp10"); // reading invalid deposit pubdata size
    }

    function writeFullExitNFTPubdata(FullExitNFT memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            op.accountId,
            op.globalId,   // nft id in layer2
            op.creatorId,
            op.seqId,
            op.uri,
            op.owner,
            op.success
        );
    }

    /// @notice Check that full exit pubdata from request and block matches
    /// TODO check it
    function fullExitNFTPubdataMatch(bytes memory _lhs, bytes memory _rhs) internal pure returns (bool) {
        bytes memory lhs_trimmed_1 = Bytes.slice(_lhs, 0, ACCOUNT_ID_BYTES + NFT_GLOBAL_ID_BYTES);
        bytes memory rhs_trimmed_1 = Bytes.slice(_rhs, 0, ACCOUNT_ID_BYTES + NFT_GLOBAL_ID_BYTES);
        bytes memory lhs_trimmed_2 = Bytes.slice(_lhs, PACKED_FULL_EXIT_NFT_PUBDATA_BYTES - ADDRESS_BYTES - NFT_SUCCESS, ADDRESS_BYTES);
        bytes memory rhs_trimmed_2 = Bytes.slice(_rhs, PACKED_FULL_EXIT_NFT_PUBDATA_BYTES - ADDRESS_BYTES - NFT_SUCCESS, ADDRESS_BYTES);
        return keccak256(lhs_trimmed_1) == keccak256(rhs_trimmed_1) && keccak256(lhs_trimmed_2) == keccak256(rhs_trimmed_2);
    }

    // PartialExitNFT pubdata
    struct PartialExitNFT {
//        uint32 accountId;
        uint64 globalId;
        uint32 creatorId;
        uint32 seqId;
        bytes32 uri;
        address owner;
    }

    function readPartialExitNFTPubdata(bytes memory _data, uint _offset) internal pure
    returns (PartialExitNFT memory parsed) {
        uint offset = _offset + ACCOUNT_ID_BYTES;                   // accountId (ignored)
        (offset, parsed.globalId) = Bytes.readUInt64(_data, offset);   // globalId
        (offset, parsed.creatorId) = Bytes.readUInt32(_data, offset);   // creatorId
        (offset, parsed.seqId) = Bytes.readUInt32(_data, offset);   // seqId
        (offset, parsed.uri) = Bytes.readBytes32(_data, offset);   // uri
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);    // owner
    }

    function writePartialExitNFTPubdata(PartialExitNFT memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            bytes4(0),  // accountId (ignored) (update when ACCOUNT_ID_BYTES is changed)
            op.globalId, // tokenId in layer2
            bytes4(0),
            bytes4(0),
            bytes32(0),
            op.owner
        );
    }


}
