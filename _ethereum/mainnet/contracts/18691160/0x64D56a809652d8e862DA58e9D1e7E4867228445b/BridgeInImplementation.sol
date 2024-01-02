pragma solidity 0.8.9;

import "./SafeMath.sol";
import "./Strings.sol";
import "./EnumerableSet.sol";
import "./SafeERC20.sol";
import "./Proxy.sol";
import "./StringHex.sol";
import "./BridgeOutInterface.sol";
import "./NativeTokenInterface.sol";
import "./LimiterInterface.sol";
import "./BridgeInLibrary.sol";

contract BridgeInImplementation is ProxyStorage {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using SafeERC20 for IERC20;
    using Strings for uint256;
    using StringHex for bytes32;

    address public bridgeOut;
    address public multiSigWallet;
    address public tokenAddress;
    address public pauseController;
    bool public isPaused;
    uint256 public constant MaxQueryRange = 100;
    uint256 public constant MaxTokenCount = 200;
    uint256 public constant MaxTokenCountPerAddOrRemove = 10;
    EnumerableSet.Bytes32Set private tokenList;

    mapping(bytes32 => mapping(uint256 => Receipt)) private receiptIndexMap;
    mapping(bytes32 => uint256) private tokenReceiptIndex; //from 1
    mapping(bytes32 => uint256) private totalAmountInReceipts;
    mapping(address => mapping(bytes32 => mapping(uint256 => string)))
        private ownerToReceiptIdMap;
    mapping(address => mapping(bytes32 => uint256))
        private ownerToReceiptsIndexMap; //from 0
    mapping(bytes32 => uint256) public depositAmount;
    address public limiter;

    modifier whenNotPaused() {
        require(!isPaused, "BrigeIn:paused");
        _;
    }
    modifier onlyWallet() {
        require(msg.sender == multiSigWallet, "BridgeIn:only for Wallet call");
        _;
    }
    modifier onlyPauseController() {
        require(
            msg.sender == pauseController,
            "BrigeIn:only for pause controller"
        );
        _;
    }

    struct Receipt {
        address asset; // ERC20 Token Address
        address owner; // Sender
        uint256 amount; // Locking amount
        uint256 blockHeight;
        uint256 blockTime;
        string targetChainId;
        string targetAddress; // User address in aelf
        string receiptId;
    }
    struct Token {
        address tokenAddress;
        string chainId;
    }
    event TokenAdded(address token, string chainId);
    event TokenRemoved(address token, string chainId);
    event NewReceipt(
        string receiptId,
        address asset,
        address owner,
        uint256 amount
    );

    function initialize(
        address _multiSigWallet,
        address _tokenAddress,
        address _pauseController
    ) external onlyOwner {
        require(multiSigWallet == address(0), "BrigeIn:already initialized");
        multiSigWallet = _multiSigWallet;
        tokenAddress = _tokenAddress;
        pauseController = _pauseController;
    }

    function changeMultiSignWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "invalid input");
        multiSigWallet = _wallet;
    }

    function setBridgeOut(address _bridgeOut) external onlyWallet {
        require(
            bridgeOut == address(0) && _bridgeOut != address(0),
            "invalid bridge out address"
        );
        bridgeOut = _bridgeOut;
    }

    function setLimiter(address _limiter) external onlyWallet {
        require(
            limiter == address(0) && _limiter != address(0),
            "invalid limiter address"
        );
        limiter = _limiter;
    }

    function changePauseController(
        address _pauseController
    ) external onlyWallet {
        require(_pauseController != address(0), "invalid input");
        pauseController = _pauseController;
    }

    function addToken(Token[] calldata tokens) public onlyWallet {
        require(
            tokenList.length() <= MaxTokenCount && tokens.length <= MaxTokenCountPerAddOrRemove,
            "token count exceed"
        );
        for (uint256 i = 0; i < tokens.length; i++) {
            bytes32 tokenKey = BridgeInLibrary._generateTokenKey(
                tokens[i].tokenAddress,
                tokens[i].chainId
            );
            require(!tokenList.contains(tokenKey), "tokenKey already added");
            tokenList.add(tokenKey);
            emit TokenAdded(tokens[i].tokenAddress, tokens[i].chainId);
        }
    }

    function removeToken(Token[] calldata tokens) public onlyWallet {
        require(tokens.length <= MaxTokenCountPerAddOrRemove, "input token count exceed");
        for (uint256 i = 0; i < tokens.length; i++) {
            bytes32 tokenKey = BridgeInLibrary._generateTokenKey(
                tokens[i].tokenAddress,
                tokens[i].chainId
            );
            require(tokenList.contains(tokenKey), "tokenKey not exist");
            tokenList.remove(tokenKey);
            emit TokenRemoved(tokens[i].tokenAddress, tokens[i].chainId);
        }
    }

    function pause() external onlyPauseController {
        require(!isPaused, "already paused");
        isPaused = true;
        IBridgeOut(bridgeOut).pause();
    }

    function restart() public onlyWallet {
        require(isPaused == true, "not paused");
        isPaused = false;
        IBridgeOut(bridgeOut).restart();
    }

    function isSupported(
        address token,
        string calldata chainId
    ) public view returns (bool) {
        bytes32 tokenKey = BridgeInLibrary._generateTokenKey(token, chainId);
        return tokenList.contains(tokenKey);
    }

    function createNativeTokenReceipt(
        string calldata targetChainId,
        string calldata targetAddress
    ) external payable whenNotPaused {
        consumeReceiptLimit(tokenAddress,msg.value,targetChainId);
        INativeToken(tokenAddress).deposit{value: msg.value}();
        IERC20(tokenAddress).safeApprove(bridgeOut, msg.value);
        generateReceipt(tokenAddress, msg.value, targetChainId, targetAddress);
    }

    // Create new receipt and deposit erc20 token
    function createReceipt(
        address token,
        uint256 amount,
        string calldata targetChainId,
        string calldata targetAddress
    ) external whenNotPaused {
        consumeReceiptLimit(token,amount,targetChainId);
        // Deposit token to this contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).safeApprove(bridgeOut, amount);
        generateReceipt(token, amount, targetChainId, targetAddress);
    }

    function consumeReceiptLimit(
        address token,
        uint256 amount,
        string calldata targetChainId
    ) internal{
        bytes32 tokenKey = BridgeInLibrary._generateTokenKey(token, targetChainId);
        require(
            tokenList.contains(tokenKey),
            "Token is not support in that chain"
        );
        require(amount > 0, "invalid amount");
        ILimiter(limiter).consumeDailyLimit(tokenKey,tokenAddress,amount);
        ILimiter(limiter).consumeTokenBucket(tokenKey,tokenAddress,amount);
    }

    function generateReceipt(
        address token,
        uint256 amount,
        string calldata targetChainId,
        string calldata targetAddress
    ) internal {
        bytes32 tokenKey = BridgeInLibrary._generateTokenKey(token, targetChainId);
        IBridgeOut(bridgeOut).deposit(tokenKey, token, amount);
        tokenReceiptIndex[tokenKey] = tokenReceiptIndex[tokenKey].add(1);
        uint256 receiptIndex = tokenReceiptIndex[tokenKey];
        string memory receiptId = BridgeInLibrary._generateReceiptId(tokenKey, receiptIndex.toString());
        receiptIndexMap[tokenKey][receiptIndex] = Receipt(
            token,
            msg.sender,
            amount,
            block.number,
            block.timestamp,
            targetChainId,
            targetAddress,
            receiptId
        );
        totalAmountInReceipts[tokenKey] = totalAmountInReceipts[tokenKey].add(
            amount
        );
        uint256 index = ownerToReceiptsIndexMap[msg.sender][tokenKey];
        ownerToReceiptsIndexMap[msg.sender][tokenKey] = ownerToReceiptsIndexMap[msg.sender][tokenKey].add(1);
        ownerToReceiptIdMap[msg.sender][tokenKey][index] = receiptId;
        emit NewReceipt(receiptId, token, msg.sender, amount);
    }

    function getMyReceipts(
        address user,
        address token,
        string calldata targetChainId
    ) external view returns (string[] memory receipt_ids) {
        bytes32 tokenKey = BridgeInLibrary._generateTokenKey(token, targetChainId);
        uint256 index = ownerToReceiptsIndexMap[user][tokenKey];
        receipt_ids = new string[](index);
        for (uint256 i = 0; i < index; i++) {
            receipt_ids[i] = ownerToReceiptIdMap[user][tokenKey][i];
        }
        return receipt_ids;
    }

    function getSendReceiptIndex(
        address[] memory tokens,
        string[] calldata targetChainIds
    ) external view returns (uint256[] memory indexes) {
        require(
            tokens.length == targetChainIds.length,
            "Invalid tokens/targetChainIds input"
        );
        indexes = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            bytes32 tokenKey = BridgeInLibrary._generateTokenKey(tokens[i], targetChainIds[i]);
            uint256 index = tokenReceiptIndex[tokenKey];
            indexes[i] = index;
        }
        return indexes;
    }

    function getSendReceiptInfos(
        address token,
        string calldata targetChainId,
        uint256 fromIndex,
        uint256 endIndex
    ) public view returns (Receipt[] memory _receipts) {
        bytes32 tokenKey = BridgeInLibrary._generateTokenKey(token, targetChainId);
        if (tokenReceiptIndex[tokenKey] == 0) {
            return _receipts;
        }
        require(
            endIndex <= tokenReceiptIndex[tokenKey] &&
                fromIndex > 0 &&
                fromIndex <= endIndex,
            "Invalid input"
        );
        uint256 length = endIndex.sub(fromIndex).add(1);
        require(length <= MaxQueryRange, "Query range is exceeded");
        _receipts = new Receipt[](length);
        for (uint256 i = 0; i < length; i++) {
            _receipts[i] = receiptIndexMap[tokenKey][i.add(fromIndex)];
        }
        return _receipts;
    }

    function getTotalAmountInReceipts(
        address token,
        string memory chainId
    ) public view returns (uint256) {
        bytes32 tokenKey = BridgeInLibrary._generateTokenKey(token, chainId);
        return totalAmountInReceipts[tokenKey];
    }

    function deposit(bytes32 tokenKey, address token, uint256 amount) external {
        require(tokenList.contains(tokenKey), "not support");
        depositAmount[tokenKey] = depositAmount[tokenKey].add(amount);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).safeApprove(bridgeOut, amount);
        IBridgeOut(bridgeOut).deposit(tokenKey, token, amount);
    }

    function withdraw(
        bytes32 tokenKey,
        address token,
        uint256 amount,
        address receiverAddress
    ) external onlyOwner {
        require(tokenList.contains(tokenKey), "not support");
        require(depositAmount[tokenKey] >= amount, "deposit not enough");
        depositAmount[tokenKey] = depositAmount[tokenKey].sub(amount);
        IBridgeOut(bridgeOut).withdraw(tokenKey, token, amount);
        IERC20(token).safeTransfer(receiverAddress, amount);
    }
}
