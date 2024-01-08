pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./IZKSeaNFT.sol";
import "./ERC721.sol";
import "./Bytes.sol";
import "./Utils.sol";
import "./OwnableContract.sol";

contract ZKSeaNFT is IZKSeaNFT, ERC721, OwnableContract {

    struct L1Info {
        address tokenContract;
        uint256 tokenId;
    }

    struct L2Info {
        uint64 globalId;
        uint32 creatorId;
        uint32 seqId;
        bool isOnL2; //whether NFT token is on L2?
    }

    struct PendingWithdrawal {
        address to;
        uint64 globalId;
    }

    address public zksCore;
    mapping(uint256 => L1Info) public infoMapL1;
    mapping(address => mapping(uint256 => L2Info)) public infoMapL2;
    mapping(uint256 => L1Info) public externSeqIdMap; /// Records token info for first deposit of external NFT

    uint32 public firstPendingWithdrawal;
    uint32 public numOfPendingWithdrawals;
    mapping(uint256 => PendingWithdrawal) public pendingWithdrawals;

    mapping(bytes28 => bool) public toWithdraw;

    uint32 externAccountSeqId;

    bytes constant sha256MultiHash = hex"1220";
    bytes constant ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    // Optional mapping from token ID to token content hash
    mapping(uint256 => bytes32) private _contentHashes;

    string private _contractURI;

    constructor() public ERC721("ZKSeaNFT", "ZKSeaNFT") {
        zksCore = msg.sender;
    }

    function initialize(bytes calldata initializationParameters) external {
        require(externAccountSeqId == 0, "duplicate init");
        _name = "ZKSeaNFT";
        _symbol = "ZKSeaNFT";
        _setOwner(abi.decode(initializationParameters, (address)));
        externAccountSeqId = 1;
    }

    function setZkSyncAddress(address _zksyncAddress) external {
        require(zksCore == address(0), "ZKSeaNFT: already initialized");
        zksCore = _zksyncAddress;
    }

    modifier onlyZksCore() {
        require(msg.sender == zksCore, "ZKSeaNFT: caller is not zks core");
        _;
    }

    /// @notice Build DepositNFT data for each deposit. Internal (layer2) token will be burned, while external token need to be transferred by caller.
    function onDeposit(IERC721 c, uint256 tokenId, address addr) external onlyZksCore returns (Operations.DepositNFT memory) {
        L2Info storage info = infoMapL2[address(c)][tokenId];
        require(info.isOnL2 == false, "ZKSeaNFT: NFT is already on L2");
        info.isOnL2 = true;

        // external NFT  it's possible the mapping information is NOT build when deposit for the 1st time.
        address tokenContractAddress = address(c);
        bool isInternalNFT = tokenContractAddress == address(this);
        bytes32 uri = 0x0;
        if (isInternalNFT) {
            uri = _contentHashes[tokenId];
            _burn(tokenId);
            delete _contentHashes[tokenId];
        } else {
            // external NFT
            if (info.seqId == 0) {
                // first deposit of external NFT
                externSeqIdMap[externAccountSeqId] = L1Info({
                    tokenContract: address(c),
                    tokenId: tokenId
                });
                info.seqId = externAccountSeqId;
                externAccountSeqId += 1;
            }
        }
        return Operations.DepositNFT({
            accountId: 0,
            globalId: info.globalId,
            creatorId: info.creatorId,
            seqId: info.seqId,
            uri: uri,
            owner: addr
        });
    }

    function mint(address to, uint64 globalId, bytes32 uri) internal {
        _mint(to, globalId);
        _contentHashes[globalId] = uri;
    }

    /// @dev Converts hex string to base 58
    function toBase58(bytes memory source) internal pure returns (string memory) {
        uint8[] memory digits = new uint8[](46);
        digits[0] = 0;
        uint8 digitLength = 1;
        for (uint8 i = 0; i < source.length; ++i) {
            uint256 carry = uint8(source[i]);
            for (uint32 j = 0; j < digitLength; ++j) {
                carry += uint256(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }

            while (carry > 0) {
                digits[digitLength] = uint8(carry % 58);
                digitLength++;
                carry = carry / 58;
            }
        }
        return toAlphabet(reverse(digits));
    }

    function ipfsCID(bytes32 source) public pure returns (string memory) {
        return toBase58(abi.encodePacked(sha256MultiHash, source));
    }

    function toAlphabet(uint8[] memory indices) internal pure returns (string memory) {
        bytes memory output = new bytes(indices.length);
        for (uint32 i = 0; i < indices.length; i++) {
            output[i] = ALPHABET[indices[i]];
        }
        return string(output);
    }

    function reverse(uint8[] memory input) internal pure returns (uint8[] memory) {
        uint8[] memory output = new uint8[](input.length);
        for (uint8 i = 0; i < input.length; i++) {
            output[i] = input[input.length - 1 - i];
        }
        return output;
    }

    // Set Contract-level URI
    function setContractURI(string memory contractURI_) public onlyOwner {
        _contractURI = contractURI_;
    }

    // View Contract-level URI
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Packs address and global nft id into single word to use as a key in withdraw mapping
    function packWithdrawKey(address addr, uint64 globalId) internal pure returns (bytes28) {
        return bytes28((uint224(addr) | (uint224(globalId) << 160)));
    }

    /// @notice withdrawBalanceUpdate set the key to withdraw is true
    function withdrawBalanceUpdate(address addr, uint64 globalId) external onlyZksCore  {
        bytes28 withdrawKey =  bytes28((uint224(addr) | (uint224(globalId) << 160)));
        toWithdraw[withdrawKey] = true;
    }

    /// @notice Store withdrawal, which should be called when partial exit or full exit is verified
    function addWithdraw(Operations.WithdrawNFTData calldata wd) external onlyZksCore {
        if (!wd.valid) {
            return;
        }

	    L1Info memory info1 = infoMapL1[wd.globalId];
        // Save L1 L2 mapping data
        if (info1.tokenContract == address(0x0)) {
            // first time withdraw
            if (wd.creatorId != 0) {
                // internal NFT: create new token info
                info1 = L1Info({
                    tokenContract: address(this),
                    tokenId: wd.globalId
                });
            } else {
                // external NFT: copy token info from externSeqIdMap
                info1 = externSeqIdMap[wd.seqId];
                // validate external
                require(wd.seqId == infoMapL2[info1.tokenContract][info1.tokenId].seqId, "ZKSeaNFT: invalid seqId");
            }

            // save mapping data
            infoMapL1[wd.globalId] = info1;

            L2Info storage info2 = infoMapL2[info1.tokenContract][info1.tokenId];
            require(0 == info2.globalId && 0 == info2.creatorId, "ZKSeaNFT: invalid info2 state");
            info2.globalId = wd.globalId;
            info2.creatorId = wd.creatorId;
            info2.seqId = wd.seqId;
            info2.isOnL2 = false;
        } else {
            // not first time withdraw
            infoMapL2[info1.tokenContract][info1.tokenId].isOnL2 = false;
        }

        // do withdraw
        if (wd.creatorId != 0) {
            // internal NFT: mint now
            mint(wd.target, wd.globalId, wd.uri);
        } else {
            // external NFT: prepare to withdraw
            if (wd.pendingWithdraw) {
                pendingWithdrawals[firstPendingWithdrawal + numOfPendingWithdrawals] = PendingWithdrawal(wd.target, wd.globalId);
                numOfPendingWithdrawals = numOfPendingWithdrawals + 1;
            } else {
                bytes28 key = packWithdrawKey(wd.target, wd.globalId);
                toWithdraw[key] = true;
            }
        }
    }

    function genWithdrawItems(uint32 n) external onlyZksCore returns (WithdrawItem[] memory) {
        uint32 toProcess = Utils.minU32(n, numOfPendingWithdrawals);
        uint32 startIndex = firstPendingWithdrawal;
        firstPendingWithdrawal += toProcess;
        numOfPendingWithdrawals -= toProcess;
        WithdrawItem[] memory items = new WithdrawItem[](toProcess);
        PendingWithdrawal memory pw;
        L1Info memory info;
        for (uint32 i = startIndex; i < startIndex + toProcess; ++i) {
            pw = pendingWithdrawals[i];
            delete pendingWithdrawals[i];
            info = infoMapL1[pw.globalId];
            items[i - startIndex] = WithdrawItem({
                tokenContract: info.tokenContract,
                tokenId: info.tokenId,
                to: pw.to,
                globalId: pw.globalId
            });
        }
        return items;
    }

    /// @notice Update withdrawal info, while the caller need deal with the transfer
    function onWithdraw(address target, uint64 globalId) external onlyZksCore returns (address, uint256) {
        require(globalId > 0, "ZKSeaNFT: invalid withdraw id");
        bytes28 key = packWithdrawKey(target, globalId);
        require(toWithdraw[key], "ZKSeaNFT: invalid withdraw key");
        toWithdraw[key] = false;
        L1Info memory info = infoMapL1[globalId];
        return (info.tokenContract, info.tokenId);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ZKSeaNFT: token not exist");
        string memory base = "ipfs://";
        string memory tokenContentHash = ipfsCID(_contentHashes[tokenId]);
        return string(abi.encodePacked(base, tokenContentHash));
    }

    function getContentHash(uint256 _tokenId) external view returns (bytes32) {
        return _contentHashes[_tokenId];
    }

}
