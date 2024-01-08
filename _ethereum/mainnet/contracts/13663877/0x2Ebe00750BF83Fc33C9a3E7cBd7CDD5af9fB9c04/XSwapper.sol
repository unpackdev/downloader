pragma solidity ^0.8.0;

import { Address } from "Address.sol";
import "ERC20.sol";
import "ECDSA.sol";  // openzeppelin v4.3.0
import "SafeERC20.sol";
import "Pausable.sol";
import "ReentrancyGuard.sol";
import "AccessControl.sol";

import "Supervisor.sol";
import "IAggregator.sol";
import "IYPoolVault.sol";

contract XSwapper is AccessControl, Pausable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    enum RequestStatus { Open, Closed }
    enum CloseSwapResult { NonSwapped, Success, Failed, Locked }
    enum CompleteSwapType { Claimed, FreeClaimed, Refunded }

    struct FeeStructure {
        bool isSet;
        uint256 gas;
        uint256 min;
        uint256 max;
        uint256 rate;
        uint256 decimals;
    }

    struct SwapRequest {
        uint32 toChainId;
        uint256 swapId;
        address receiver;
        address sender;
        uint256 YPoolTokenAmount;
        uint256 xyFee;
        uint256 gasFee;
        IERC20 YPoolToken;
        RequestStatus status;
    }

    struct ToChainDescription {
        uint32 toChainId;
        IERC20 toChainToken;
        uint256 expectedToChainTokenAmount;
        uint32 slippage;
    }

    // roles
    bytes32 public constant ROLE_OWNER = keccak256("ROLE_OWNER");
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER");
    bytes32 public constant ROLE_STAFF = keccak256("ROLE_STAFF");
    bytes32 public constant ROLE_YPOOL_WORKER = keccak256("ROLE_YPOOL_WORKER");

    // Mapping of YPool token to its max amount in a single swap
    mapping (address => uint256) public maxYPoolTokenSwapAmount;

    Supervisor public supervisor;
    address public constant ETHER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint32 public immutable chainId;
    uint256 public swapId = 0;
    mapping (bytes32 => bool) everClosed;

    mapping (address => bool) public YPoolSupoortedToken;
    mapping (address => address) public YPoolVaults;
    address public aggregator;
    address public swapValidatorXYChain;

    mapping (bytes32 => FeeStructure) public feeStructures;
    SwapRequest[] public swapRequests;

    // Owner events
    event FeeStructureSet(uint32 _toChainId, address _YPoolToken, uint256 _gas, uint256 _min, uint256 _max, uint256 _rate, uint256 _decimals);
    event YPoolVaultSet(address _supportedToken, address _vault, bool _isSet);
    event AggregatorSet(address _aggregator);
    event SwapValidatorXYChainSet(address _swapValidatorXYChain);
    // Swap events
    event SwapRequested(uint256 _swapId, ToChainDescription _toChainDesc, IERC20 _fromToken, IERC20 _YPoolToken, uint256 _YPoolTokenAmount, address _receiver, uint256 _xyFee, uint256 _gasFee);
    event SwapCompleted(CompleteSwapType _closeType, SwapRequest _swapRequest);
    event CloseSwapCompleted(CloseSwapResult _swapResult, uint32 _fromChainId, uint256 _fromSwapId);
    event SwappedForUser(IERC20 _fromToken, uint256 _fromTokenAmount, IERC20 _toToken, uint256 _toTokenAmountOut, address _receiver);

    constructor(address owner, address manager, address staff, address worker, address _supervisor, uint32 _chainId) public {
        require(Address.isContract(_supervisor), "ERR_SUPERVISOR_NOT_CONTRACT");
        supervisor = Supervisor(_supervisor);
        chainId = _chainId;

        // Validate chainId
        uint256 _realChainId;
        assembly {
            _realChainId := chainid()
        }
        require(_chainId == _realChainId, "ERR_WRONG_CHAIN_ID");

        _setRoleAdmin(ROLE_OWNER, ROLE_OWNER);
        _setRoleAdmin(ROLE_MANAGER, ROLE_OWNER);
        _setRoleAdmin(ROLE_STAFF, ROLE_OWNER);
        _setRoleAdmin(ROLE_YPOOL_WORKER, ROLE_OWNER);
        _setupRole(ROLE_OWNER, owner);
        _setupRole(ROLE_MANAGER, manager);
        _setupRole(ROLE_STAFF, staff);
        _setupRole(ROLE_YPOOL_WORKER, worker);
    }

    receive() external payable {}

    /* ====== MODIFIERS ====== */

    modifier approveAggregator(IERC20 token, uint256 amount) {
        if (address(token) != ETHER_ADDRESS) token.safeApprove(aggregator, amount);
        _;
        if (address(token) != ETHER_ADDRESS) token.safeApprove(aggregator, 0);
    }

    /* ====== PRIVATE FUNCTIONS ====== */

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function _getFeeStructure(uint32 _toChainId, address _token) private view returns (FeeStructure memory) {
        bytes32 universalTokenId = keccak256(abi.encodePacked(_toChainId, _token));
        return feeStructures[universalTokenId];
    }

    function _getTokenBalance(IERC20 token, address account) private view returns (uint256 balance) {
        balance = address(token) == ETHER_ADDRESS ? account.balance : token.balanceOf(account);
    }

    function _safeTransferAsset(address receiver, IERC20 token, uint256 amount) private {
        if (address(token) == ETHER_ADDRESS) {
            payable(receiver).transfer(amount);
        } else {
            token.safeTransfer(receiver, amount);
        }
    }

    function _safeTransferFromAsset(IERC20 fromToken, address from, uint256 amount) private {
        if (address(fromToken) == ETHER_ADDRESS)
            require(msg.value == amount, "ERR_INVALID_AMOUNT");
        else {
            uint256 _fromTokenBalance = _getTokenBalance(fromToken, address(this));
            fromToken.safeTransferFrom(from, address(this), amount);
            require(_getTokenBalance(fromToken, address(this)) - _fromTokenBalance == amount, "ERR_INVALID_AMOUNT");
        }
    }

    function _checkMinimumSwapAmount(uint32 _toChainId, IERC20 token, uint256 amount) private view returns (bool) {
        FeeStructure memory feeStructure = _getFeeStructure(_toChainId, address(token));
        require(feeStructure.isSet, "ERR_FEE_NOT_SET");
        uint256 minToChainFee = feeStructure.min;  // closeSwap

        feeStructure = _getFeeStructure(chainId, address(token));
        require(feeStructure.isSet, "ERR_FEE_NOT_SET");
        uint256 minFromChainFee = feeStructure.min;  // refund

        return amount >= max(minToChainFee, minFromChainFee);
    }

    function _calculateFee(uint32 _chainId, IERC20 token, uint256 amount) private view returns (uint256 xyFee, uint256 gasFee) {
        FeeStructure memory feeStructure = _getFeeStructure(_chainId, address(token));
        require(feeStructure.isSet, "ERR_FEE_NOT_SET");

        xyFee = amount * feeStructure.rate / (10 ** feeStructure.decimals);
        xyFee = min(max(xyFee, feeStructure.min), feeStructure.max);
        gasFee = feeStructure.gas;
    }

    /* ====== EXTERNAL FUNCTIONS ====== */
    /* ======== READ FUNCTIONS ======== */

    function getSwapRequest(uint256 _swapId) external view returns (SwapRequest memory) {
        if (_swapId >= swapId) revert();
        return swapRequests[_swapId];
    }

    function getFeeStructure(uint32 _chainId, address _token) external view returns (FeeStructure memory) {
        FeeStructure memory feeStructure = _getFeeStructure(_chainId, _token);
        require(feeStructure.isSet, "ERR_FEE_NOT_SET");
        return feeStructure;
    }

    function getEverClosed(uint32 _chainId, uint256 _swapId) external view returns (bool) {
        bytes32 universalSwapId = keccak256(abi.encodePacked(_chainId, _swapId));
        return everClosed[universalSwapId];
    }

    /* ======== WRITE FUNCTIONS ======= */

    function setFeeStructure(uint32 _toChainId, address _supportedToken, uint256 _gas, uint256 _min, uint256 _max, uint256 rate, uint256 decimals) external onlyRole(ROLE_STAFF) {
        if (_supportedToken != ETHER_ADDRESS) {
            require(Address.isContract(_supportedToken), "ERR_YPOOL_TOKEN_NOT_CONTRACT");
        }
        require(_max > _min, "ERR_INVALID_MAX_MIN");
        require(_min >= _gas, "ERR_INVALID_MIN_GAS");
        bytes32 universalTokenId = keccak256(abi.encodePacked(_toChainId, _supportedToken));
        FeeStructure memory feeStructure = FeeStructure(true, _gas, _min, _max, rate, decimals);
        feeStructures[universalTokenId] = feeStructure;
        emit FeeStructureSet(_toChainId, _supportedToken, _gas, _min, _max, rate, decimals);
    }

    function setYPoolVault(address _supportedToken, address _vault, bool _isSet) external onlyRole(ROLE_OWNER) {
        if (_supportedToken != ETHER_ADDRESS) {
            require(Address.isContract(_supportedToken), "ERR_YPOOL_TOKEN_NOT_CONTRACT");
        }
        require(Address.isContract(_vault), "ERR_YPOOL_VAULT_NOT_CONTRACT");
        YPoolSupoortedToken[_supportedToken] = _isSet;
        YPoolVaults[_supportedToken] = _vault;
        emit YPoolVaultSet(_supportedToken, _vault, _isSet);
    }

    function setMaxYPoolTokenSwapAmount(address _supportedToken, uint256 amount) external onlyRole(ROLE_MANAGER) {
        require(YPoolSupoortedToken[_supportedToken], "ERR_INVALID_YPOOL_TOKEN");
        maxYPoolTokenSwapAmount[_supportedToken] = amount;
    }

    function setAggregator(address _aggregator) external onlyRole(ROLE_MANAGER) {
        require(Address.isContract(_aggregator), "ERR_AGGREGATOR_NOT_CONTRACT");
        aggregator = _aggregator;
        emit AggregatorSet(_aggregator);
    }

    function setSwapValidatorXYChain(address _swapValidatorXYChain) external onlyRole(ROLE_STAFF) {
        swapValidatorXYChain = _swapValidatorXYChain;
        emit SwapValidatorXYChainSet(_swapValidatorXYChain);
    }

    function swap(
        IAggregator.SwapDescription memory swapDesc,
        bytes memory aggregatorData,
        ToChainDescription calldata toChainDesc
    ) external payable approveAggregator(swapDesc.fromToken, swapDesc.amount) whenNotPaused nonReentrant {
        address receiver = swapDesc.receiver;
        IERC20 fromToken = swapDesc.fromToken;
        IERC20 YPoolToken = swapDesc.toToken;
        require(YPoolSupoortedToken[address(YPoolToken)], "ERR_INVALID_YPOOL_TOKEN");

        uint256 fromTokenAmount = swapDesc.amount;
        uint256 yBalance;
        _safeTransferFromAsset(fromToken, msg.sender, fromTokenAmount);
        if (fromToken == YPoolToken) {
            yBalance = fromTokenAmount;
        } else {
            yBalance = _getTokenBalance(YPoolToken, address(this));
            swapDesc.receiver = address(this);
            IAggregator(aggregator).swap{value: msg.value}(swapDesc, aggregatorData);
            yBalance = _getTokenBalance(YPoolToken, address(this)) - yBalance;
        }
        require(_checkMinimumSwapAmount(toChainDesc.toChainId, YPoolToken, yBalance), "ERR_NOT_ENOUGH_SWAP_AMOUNT");
        require(yBalance <= maxYPoolTokenSwapAmount[address(YPoolToken)], "ERR_EXCEED_MAX_SWAP_AMOUNT");

        // Calculate XY fee and gas fee for closeSwap on toChain
        // NOTE: XY fee already includes gas fee and gas fee is computed here only for bookkeeping purpose
        (uint256 xyFee, uint256 closeSwapGasFee) = _calculateFee(toChainDesc.toChainId, YPoolToken, yBalance);
        SwapRequest memory request = SwapRequest(toChainDesc.toChainId, swapId, receiver, msg.sender, yBalance, xyFee, closeSwapGasFee, YPoolToken, RequestStatus.Open);
        swapRequests.push(request);
        emit SwapRequested(swapId++, toChainDesc, fromToken, YPoolToken, yBalance, receiver, xyFee, closeSwapGasFee);
    }

    function lockCloseSwap(uint32 fromChainId, uint256 fromSwapId, bytes[] memory signatures) external whenNotPaused {
        bytes32 universalSwapId = keccak256(abi.encodePacked(fromChainId, fromSwapId));
        require(!everClosed[universalSwapId], "ERR_ALREADY_CLOSED");
        bytes32 sigId = keccak256(abi.encodePacked(supervisor.LOCK_CLOSE_SWAP_AND_REFUND_IDENTIFIER(), address(this), fromChainId, fromSwapId));
        bytes32 sigIdHash = sigId.toEthSignedMessageHash();
        supervisor.checkSignatures(sigIdHash, signatures);

        everClosed[universalSwapId] = true;
        emit CloseSwapCompleted(CloseSwapResult.Locked, fromChainId, fromSwapId);
    }

    function closeSwap(
        IAggregator.SwapDescription calldata swapDesc,
        bytes memory aggregatorData,
        uint32 fromChainId,
        uint256 fromSwapId
    ) external payable whenNotPaused onlyRole(ROLE_YPOOL_WORKER) approveAggregator(swapDesc.fromToken, swapDesc.amount) {
        require(YPoolSupoortedToken[address(swapDesc.fromToken)], "ERR_INVALID_YPOOL_TOKEN");

        bytes32 universalSwapId = keccak256(abi.encodePacked(fromChainId, fromSwapId));
        require(!everClosed[universalSwapId], "ERR_ALREADY_CLOSED");
        everClosed[universalSwapId] = true;

        uint256 fromTokenAmount = swapDesc.amount;
        require(fromTokenAmount <= maxYPoolTokenSwapAmount[address(swapDesc.fromToken)], "ERR_EXCEED_MAX_SWAP_AMOUNT");
        IYPoolVault(YPoolVaults[address(swapDesc.fromToken)]).transferToSwapper(swapDesc.fromToken, fromTokenAmount);

        uint256 toTokenAmountOut;
        CloseSwapResult swapResult;
        if (swapDesc.toToken == swapDesc.fromToken) {
            toTokenAmountOut = fromTokenAmount;
            swapResult = CloseSwapResult.NonSwapped;
        } else {
            uint256 value = (address(swapDesc.fromToken) == ETHER_ADDRESS) ? fromTokenAmount : 0;
            toTokenAmountOut = _getTokenBalance(swapDesc.toToken, swapDesc.receiver);
            try IAggregator(aggregator).swap{value: value}(swapDesc, aggregatorData) {
                toTokenAmountOut = _getTokenBalance(swapDesc.toToken, swapDesc.receiver) - toTokenAmountOut;
                swapResult = CloseSwapResult.Success;
            } catch {
                swapResult = CloseSwapResult.Failed;
            }
        }
        if (swapResult != CloseSwapResult.Success) {
            _safeTransferAsset(swapDesc.receiver, swapDesc.fromToken, fromTokenAmount);
        }
        emit CloseSwapCompleted(swapResult, fromChainId, fromSwapId);
        emit SwappedForUser(swapDesc.fromToken, fromTokenAmount, swapDesc.toToken, toTokenAmountOut, swapDesc.receiver);
    }

    function claim(uint256 _swapId, bytes[] memory signatures) external whenNotPaused {
        require(_swapId < swapId, "ERR_INVALID_SWAPID");
        require(swapRequests[_swapId].status != RequestStatus.Closed, "ERR_ALREADY_CLOSED");
        swapRequests[_swapId].status = RequestStatus.Closed;

        bytes32 sigId = keccak256(abi.encodePacked(supervisor.VALIDATE_SWAP_IDENTIFIER(), address(swapValidatorXYChain), chainId, _swapId));
        bytes32 sigIdHash = sigId.toEthSignedMessageHash();
        supervisor.checkSignatures(sigIdHash, signatures);

        SwapRequest memory request = swapRequests[_swapId];
        IYPoolVault yPoolVault = IYPoolVault(YPoolVaults[address(request.YPoolToken)]);
        uint256 value = (address(request.YPoolToken) == ETHER_ADDRESS) ? request.YPoolTokenAmount : 0;
        if (address(request.YPoolToken) != ETHER_ADDRESS) {
            request.YPoolToken.safeApprove(address(yPoolVault), request.YPoolTokenAmount);
        }
        yPoolVault.receiveAssetFromSwapper{value: value}(request.YPoolToken, request.YPoolTokenAmount, request.xyFee, request.gasFee);

        emit SwapCompleted(CompleteSwapType.Claimed, request);
    }

    function refund(uint256 _swapId, address gasFeeReceiver, bytes[] memory signatures) external whenNotPaused {
        require(_swapId < swapId, "ERR_INVALID_SWAPID");
        require(swapRequests[_swapId].status != RequestStatus.Closed, "ERR_ALREADY_CLOSED");
        swapRequests[_swapId].status = RequestStatus.Closed;

        bytes32 sigId = keccak256(abi.encodePacked(supervisor.LOCK_CLOSE_SWAP_AND_REFUND_IDENTIFIER(), address(this), chainId, _swapId, gasFeeReceiver));
        bytes32 sigIdHash = sigId.toEthSignedMessageHash();
        supervisor.checkSignatures(sigIdHash, signatures);

        SwapRequest memory request = swapRequests[_swapId];
        (, uint256 refundGasFee) = _calculateFee(chainId, request.YPoolToken, request.YPoolTokenAmount);
        _safeTransferAsset(request.sender, request.YPoolToken, request.YPoolTokenAmount - refundGasFee);
        _safeTransferAsset(gasFeeReceiver, request.YPoolToken, refundGasFee);

        emit SwapCompleted(CompleteSwapType.Refunded, request);
    }

    function batchClaim(uint256[] calldata _swapIds, address _YPoolToken, bytes[] memory signatures) external whenNotPaused {
        require(YPoolSupoortedToken[_YPoolToken], "ERR_INVALID_YPOOL_TOKEN");
        bytes32 sigId = keccak256(abi.encodePacked(supervisor.BATCH_CLAIM_IDENTIFIER(), address(swapValidatorXYChain), chainId, _swapIds));
        bytes32 sigIdHash = sigId.toEthSignedMessageHash();
        supervisor.checkSignatures(sigIdHash, signatures);

        IERC20 YPoolToken = IERC20(_YPoolToken);
        uint256 totalClaimedAmount;
        uint256 totalXYFee;
        uint256 totalGasFee;
        for (uint256 i; i < _swapIds.length; i++) {
            uint256 _swapId = _swapIds[i];
            require(_swapId < swapId, "ERR_INVALID_SWAPID");
            SwapRequest memory request = swapRequests[_swapId];
            require(request.status != RequestStatus.Closed, "ERR_ALREADY_CLOSED");
            require(request.YPoolToken == YPoolToken, "ERR_WRONG_YPOOL_TOKEN");
            totalClaimedAmount += request.YPoolTokenAmount;
            totalXYFee += request.xyFee;
            totalGasFee += request.gasFee;
            swapRequests[_swapId].status = RequestStatus.Closed;
            emit SwapCompleted(CompleteSwapType.FreeClaimed, request);
        }

        IYPoolVault yPoolVault = IYPoolVault(YPoolVaults[_YPoolToken]);
        uint256 value = (_YPoolToken == ETHER_ADDRESS) ? totalClaimedAmount : 0;
        if (_YPoolToken != ETHER_ADDRESS) {
            YPoolToken.safeApprove(address(yPoolVault), totalClaimedAmount);
        }
        yPoolVault.receiveAssetFromSwapper{value: value}(YPoolToken, totalClaimedAmount, totalXYFee, totalGasFee);
    }

    function pause() external onlyRole(ROLE_MANAGER) {
        _pause();
    }

    function unpause() external onlyRole(ROLE_MANAGER) {
        _unpause();
    }
}
