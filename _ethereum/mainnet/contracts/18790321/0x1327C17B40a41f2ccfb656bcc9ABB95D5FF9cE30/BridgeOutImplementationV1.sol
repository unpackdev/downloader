// SPDX-License-Identifier: MIT
import "./MerkleTreeInterface.sol";
import "./RegimentInterface.sol";
import "./NativeTokenInterface.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ECDSA.sol";
import "./Proxy.sol";
import "./BridgeOutLibrary.sol";
import "./LimiterInterface.sol";

pragma solidity 0.8.9;

contract BridgeOutImplementationV1 is ProxyStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    address private merkleTree;
    address public regiment;
    address public bridgeIn;
    uint256 public defaultMerkleTreeDepth = 3;
    uint256 public constant MaxQueryRange = 100;
    uint256 public constant MaxTokenKeyCount = 200;
    bool public isPaused;
    address public tokenAddress;
    address public approveController;
    address public multiSigWallet;
    EnumerableSet.Bytes32Set private targetTokenList;

    mapping(bytes32 => SwapInfo) internal swapInfos;
    mapping(bytes32 => bytes32) internal tokenKeyToSwapIdMap;
    mapping(bytes32 => SwapAmounts) internal ledger;
    mapping(bytes32 => mapping(uint256 => ReceivedReceipt))
        internal receivedReceiptsMap;
    mapping(bytes32 => uint256) internal receivedReceiptIndex;
    mapping(string => bool) internal receiptApproveMap;
    mapping(address => uint256) public tokenAmountLimit;
    mapping(bytes32 => uint256) internal tokenDepositAmount;
    address public limiter;
    uint8 public signatureThreshold;

    struct ReceivedReceipt {
        address asset; // ERC20 Token Address
        address targetAddress; // User address in eth
        uint256 amount; // Locking amount
        uint256 blockHeight;
        uint256 blockTime;
        string fromChainId;
        string receiptId;
    }
    struct SwapTargetToken {
        address token;
        string fromChainId;
        uint64 originShare;
        uint64 targetShare;
    }
    struct SwapInfo {
        bytes32 swapId;
        bytes32 regimentId;
        bytes32 spaceId;
        SwapTargetToken targetToken;
    }
    struct SwapAmounts {
        address receiver;
        uint256 leafNodeIndex;
        mapping(address => uint256) receivedAmounts;
    }

    event SwapPairAdded(bytes32 swapId, address token, string chainId);
    event TokenSwapEvent(address receiveAddress, address token, uint256 amount);
    event NewTransmission(
        bytes32 swapId,
        address transmiter,
        uint256 receiptIndex,
        bytes32 receiptHash
    );

    modifier onlyBridgeInContract() {
        require(msg.sender == bridgeIn, "no permission");
        _;
    }
    modifier onlyWallet() {
        require(msg.sender == multiSigWallet, "BridgeOut:only for Wallet call");
        _;
    }

    function initialize(
        address _merkleTree,
        address _regiment,
        address _bridgeIn,
        address _tokenAddress,
        address _approveController,
        address _multiSigWallet
    ) external onlyOwner {
        require(merkleTree == address(0), "already initialized");
        merkleTree = _merkleTree;
        regiment = _regiment;
        bridgeIn = _bridgeIn;
        tokenAddress = _tokenAddress;
        approveController = _approveController;
        multiSigWallet = _multiSigWallet;
    }

    function pause() external onlyBridgeInContract {
        isPaused = true;
    }

    function restart() public onlyBridgeInContract {
        isPaused = false;
    }

    function setDefaultMerkleTreeDepth(
        uint256 _defaultMerkleTreeDepth
    ) external onlyWallet {
        require(
            _defaultMerkleTreeDepth > 0 && _defaultMerkleTreeDepth <= 20,
            "invalid input"
        );
        defaultMerkleTreeDepth = _defaultMerkleTreeDepth;
    }

    function setLimiter(address _limiter) external onlyWallet {
        require(
            limiter == address(0) && _limiter != address(0),
            "invalid limiter address"
        );
        limiter = _limiter;
    }

    function setSignatureThreshold(uint8 _signatureThreshold) external onlyWallet {
        require(_signatureThreshold > 0,"Invalid input.");
        signatureThreshold = _signatureThreshold;
    }

    function changeMultiSignWallet(address _multiSigWallet) external onlyOwner {
        require(_multiSigWallet != address(0), "invalid input");
        multiSigWallet = _multiSigWallet;
    }

    //Swap
    function createSwap(
        SwapTargetToken calldata targetToken,
        bytes32 regimentId
    ) external {
        require(
            IRegiment(regiment).IsRegimentManager(regimentId, msg.sender),
            "no permission"
        );
        require(targetToken.token != address(0), "invalid input");
        require(
            targetTokenList.length() < MaxTokenKeyCount,
            "token list exceed"
        );
        bytes32 tokenKey = BridgeOutLibrary.generateTokenKey(
            targetToken.token,
            targetToken.fromChainId
        );
        require(
            !targetTokenList.contains(tokenKey),
            "target token already exist"
        );
        bytes32 spaceId = IMerkleTree(merkleTree).createSpace(
            regimentId,
            defaultMerkleTreeDepth
        );
        bytes32 swapId = keccak256(msg.data);
        require(
            targetToken.originShare > 0 && targetToken.targetShare > 0,
            "invalid swap ratio"
        );
        swapInfos[swapId] = SwapInfo(swapId, regimentId, spaceId, targetToken);
        targetTokenList.add(tokenKey);
        tokenKeyToSwapIdMap[tokenKey] = swapId;

        emit SwapPairAdded(swapId, targetToken.token, targetToken.fromChainId);
    }

    function deposit(bytes32 tokenKey, address token, uint256 amount) external {
        check(token, tokenKey);
        IERC20(token).safeTransferFrom(
            address(msg.sender),
            address(this),
            amount
        );
        bytes32 swapId = tokenKeyToSwapIdMap[tokenKey];
        tokenDepositAmount[swapId] = tokenDepositAmount[swapId].add(amount);
    }

    function withdraw(
        bytes32 tokenKey,
        address token,
        uint256 amount
    ) external onlyBridgeInContract {
        check(token, tokenKey);
        bytes32 swapId = tokenKeyToSwapIdMap[tokenKey];
        tokenDepositAmount[swapId] = tokenDepositAmount[swapId].sub(amount);
        IERC20(token).safeTransfer(address(msg.sender), amount);
    }

    function check(address token, bytes32 tokenKey) private view {
        require(targetTokenList.contains(tokenKey), "target token not exist");
        bytes32 swapId = tokenKeyToSwapIdMap[tokenKey];
        require(swapInfos[swapId].targetToken.token == token, "invalid token");
    }

    function swapToken(
        bytes32 swapId,
        string calldata receiptId,
        uint256 amount,
        address receiverAddress
    ) external {
        require(!isPaused, "BridgeOut:paused");
        require(msg.sender == receiverAddress, "no permission");
        bytes32 spaceId = swapInfos[swapId].spaceId;
        require(spaceId != bytes32(0), "swap pair not found");
        require(amount > 0, "invalid amount");
        
        SwapInfo storage swapInfo = swapInfos[swapId];
        uint256 targetTokenAmount = amount
            .mul(swapInfo.targetToken.targetShare)
            .div(swapInfo.targetToken.originShare);

        ILimiter(limiter).consumeDailyLimit(swapId, tokenAddress, targetTokenAmount);
        ILimiter(limiter).consumeTokenBucket(swapId, tokenAddress, targetTokenAmount);

        bytes32 leafHash = BridgeOutLibrary.computeLeafHash(
            receiptId,
            amount,
            receiverAddress
        );
        uint256 leafNodeIndex = ledger[leafHash].leafNodeIndex.sub(1);
        BridgeOutLibrary.verifyMerkleTree(
            spaceId,
            merkleTree,
            leafNodeIndex,
            leafHash
        );

        SwapAmounts storage swapAmouts = ledger[leafHash];
        require(swapAmouts.receiver == address(0), "already claimed");
        swapAmouts.receiver = receiverAddress;
        
        require(
            targetTokenAmount <= tokenDepositAmount[swapId],
            "deposit not enough"
        );
        tokenDepositAmount[swapId] = tokenDepositAmount[swapId].sub(
            targetTokenAmount
        );
        if (swapInfo.targetToken.token == tokenAddress) {
            INativeToken(tokenAddress).withdraw(targetTokenAmount);
            (bool success, ) = payable(receiverAddress).call{
                value: targetTokenAmount
            }("");
            require(success, "failed");
        } else {
            IERC20(swapInfo.targetToken.token).safeTransfer(
                receiverAddress,
                targetTokenAmount
            );
        }
        swapAmouts.receivedAmounts[
            swapInfo.targetToken.token
        ] = targetTokenAmount;
        emit TokenSwapEvent(
            receiverAddress,
            swapInfo.targetToken.token,
            targetTokenAmount
        );

        bytes32 tokenKey = BridgeOutLibrary.generateTokenKey(
            swapInfo.targetToken.token,
            swapInfo.targetToken.fromChainId
        );
        receivedReceiptIndex[tokenKey] = receivedReceiptIndex[tokenKey].add(1);
        uint256 receiptIndex = receivedReceiptIndex[tokenKey];
        receivedReceiptsMap[tokenKey][receiptIndex] = ReceivedReceipt(
            swapInfo.targetToken.token,
            receiverAddress,
            amount,
            block.number,
            block.timestamp,
            swapInfo.targetToken.fromChainId,
            receiptId
        );
    }

    function transmit(
        bytes32 swapHashId,
        bytes calldata _report,
        bytes32[] calldata _rs, // observer signatures->r
        bytes32[] calldata _ss, //observer signatures->s
        bytes32 _rawVs // signatures->v (Each 1 byte is combined into a 32-byte binder, which means that the maximum number of observer signatures is 32.)
    ) external {
        SwapInfo storage swapInfo = swapInfos[swapHashId];
        uint8 signersCount = BridgeOutLibrary.verifySignature(
                swapInfo.regimentId,
                _report,
                _rs,
                _ss,
                _rawVs,
                regiment
            );
        (uint256 receiptIndex, bytes32 receiptHash) = 
            BridgeOutLibrary.checkSignersThresholdAndDecodeReport(signersCount, signatureThreshold, _report);
        bytes32[] memory leafNodes = new bytes32[](1);
        leafNodes[0] = receiptHash;
        require(ledger[receiptHash].leafNodeIndex == 0, "already recorded");
        uint256 index = IMerkleTree(merkleTree).recordMerkleTree(
            swapInfo.spaceId,
            leafNodes
        );
        ledger[receiptHash].leafNodeIndex = index.add(1);
        emit NewTransmission(swapHashId, msg.sender, receiptIndex, receiptHash);
    }

    function isReceiptRecorded(bytes32 receiptHash) public view returns (bool) {
        return ledger[receiptHash].leafNodeIndex > 0;
    }

    function getReceiveReceiptIndex(
        address[] memory tokens,
        string[] calldata fromChainIds
    ) external view returns (uint256[] memory) {
        require(tokens.length == fromChainIds.length, "invalid input");
        uint256[] memory indexs = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            bytes32 tokenKey = BridgeOutLibrary.generateTokenKey(
                tokens[i],
                fromChainIds[i]
            );
            indexs[i] = receivedReceiptIndex[tokenKey];
        }
        return indexs;
    }

    function getSwapId(
        address token,
        string calldata fromChainId
    ) public view returns (bytes32) {
        bytes32 tokenKey = BridgeOutLibrary.generateTokenKey(
            token,
            fromChainId
        );
        return tokenKeyToSwapIdMap[tokenKey];
    }

    function getReceivedReceiptInfos(
        address token,
        string calldata fromChainId,
        uint256 fromIndex,
        uint256 endIndex
    ) public view returns (ReceivedReceipt[] memory _receipts) {
        bytes32 tokenKey = BridgeOutLibrary.generateTokenKey(
            token,
            fromChainId
        );
        require(
            endIndex <= receivedReceiptIndex[tokenKey] && fromIndex > 0,
            "Invalid input"
        );
        uint256 length = endIndex.sub(fromIndex).add(1);
        require(length <= MaxQueryRange, "Query range is exceeded");
        _receipts = new ReceivedReceipt[](length);
        for (uint256 i = 0; i < length; i++) {
            _receipts[i] = receivedReceiptsMap[tokenKey][i.add(fromIndex)];
        }

        return _receipts;
    }

    function getDepositAmount(bytes32 swapId) public view returns (uint256) {
        return tokenDepositAmount[swapId];
    }

    function getSwapInfo(
        bytes32 swapId
    )
        external
        view
        returns (
            string memory fromChainId,
            bytes32 regimentId,
            bytes32 spaceId,
            address token
        )
    {
        fromChainId = swapInfos[swapId].targetToken.fromChainId;
        regimentId = swapInfos[swapId].regimentId;
        spaceId = swapInfos[swapId].spaceId;
        token = swapInfos[swapId].targetToken.token;
    }

    function approve(string calldata receiptId) external {
        require(msg.sender == approveController, "no permission");
        receiptApproveMap[receiptId] = true;
    }

    function changeApproveController(
        address _approveController
    ) external onlyWallet {
        require(_approveController != address(0), "Invalid input");
        approveController = _approveController;
    }
}
