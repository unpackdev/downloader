pragma solidity ^0.8.2;


import "AccessControlUpgradeable.sol";
import "UUPSUpgradeable.sol";
import "PausableUpgradeable.sol";
import "SafeERC20.sol";
import "ERC20.sol";
import { Address } from "Address.sol";
import "XYToken.sol";
import "IGasPriceConsumer.sol";


contract YPoolVault is AccessControlUpgradeable, UUPSUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;

    // roles
    bytes32 public constant ROLE_OWNER = keccak256("ROLE_OWNER");
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER");
    bytes32 public constant ROLE_STAFF = keccak256("ROLE_STAFF");
    bytes32 public constant ROLE_LIQUIDITY_WORKER = keccak256("ROLE_LIQUIDITY_WORKER");

    uint256 public constant XY_TOKEN_DECIMALS = 18;
    uint256 public constant YIELD_RATE_DECIMALS = 8;
    // Max yield rate bound of deposit/withdraw
    uint256 public maxYieldRateBound;
    uint256 public minYieldRateBound;

    address public swapper;
    address public gasFeeReceiver;
    address public constant ETHER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IERC20 public depositToken;
    uint8 public depositTokenDecimal;
    XYToken public xyWrappedToken;

    address public gasPriceConsumer;
    uint256 public completeDepositGasLimit;
    uint256 public completeWithdrawGasLimit;
    uint256 public depositAndWithdrawFees;
    uint256 public closeSwapGasFees;

    struct DepositRequest {
        uint256 amountDepositToken;
        address sender;
        bool isComplete;
    }

    struct WithdrawalRequest {
        uint256 amountXYWrappedToken;
        address sender;
        bool isComplete;
    }

    uint256 public numDeposits;
    uint256 public numWithdrawals;
    mapping (uint256 => DepositRequest) public depositRequests;
    mapping (uint256 => WithdrawalRequest) public withdrawalRequests;

    event TransferToSwapper(address swapper, IERC20 token, uint256 amount);
    event DepositRequested(address indexed sender, uint256 indexed depositID, uint256 amountDepositToken, uint256 gasFee);
    event DepositFulfilled(address indexed recipient, uint256 indexed depositID, uint256 amountXYWrappedToken);
    event WithdrawalRequested(address indexed sender, uint256 indexed withdrawID, uint256 amountXYWrappedToken, uint256 gasFee);
    event WithdrawalFulfilled(address indexed recipient, uint256 indexed withdrawID, uint256 amountDepositToken, uint256 withdrawFee);
    event AssetReceived(IERC20 token, uint256 assetAmount, uint256 xyFeeAmount, uint256 gasFeeAmount);
    event DepositAndWithdrawGasFeesCollected(address recipient, uint256 gasFees);
    event CloseSwapGasFeesCollected(IERC20 token, address recipient, uint256 gasFees);

    function initialize(address owner, address manager, address staff, address liquidityWorker, address _depositToken, address _xyWrappedToken, uint8 _depositTokenDecimal) initializer public {
        if (_depositToken != ETHER_ADDRESS) {
            require(Address.isContract(_depositToken), "ERR_DEPOSIT_TOKEN_NOT_CONTRACT");
        }
        require(Address.isContract(_xyWrappedToken), "ERR_XY_WRPAPPED_TOKEN_NOT_CONTRACT");
        depositToken = IERC20(_depositToken);
        xyWrappedToken = XYToken(_xyWrappedToken);

        depositTokenDecimal = _depositTokenDecimal;

        _setRoleAdmin(ROLE_OWNER, ROLE_OWNER);
        _setRoleAdmin(ROLE_MANAGER, ROLE_OWNER);
        _setRoleAdmin(ROLE_STAFF, ROLE_OWNER);
        _setRoleAdmin(ROLE_LIQUIDITY_WORKER, ROLE_OWNER);
        _setupRole(ROLE_OWNER, owner);
        _setupRole(ROLE_MANAGER, manager);
        _setupRole(ROLE_STAFF, staff);
        _setupRole(ROLE_LIQUIDITY_WORKER, liquidityWorker);
    }

    modifier onlySwapper() {
        require(msg.sender == swapper, "ERR_NOT_SWAPPER");
        _;
    }

    function _authorizeUpgrade(address) internal override onlyRole(ROLE_OWNER) {}

    receive() external payable {}

    function _getGasPrice() private view returns (uint256) {
        require(gasPriceConsumer != address(0), "ERR_GAS_PRICE_CONSUMER_NOT_SET");
        return uint256(IGasPriceConsumer(gasPriceConsumer).getLatestGasPrice());
    }

    function _safeTransferAsset(address receiver, IERC20 token, uint256 amount) private {
        if (address(token) == ETHER_ADDRESS) {
            payable(receiver).transfer(amount);
        } else {
            token.safeTransfer(receiver, amount);
        }
    }

    function _safeTransferAssetFrom(IERC20 token, address sender, address receiver, uint256 amount) private {
        require(address(token) != ETHER_ADDRESS, "ERR_TOKEN_ADDRESS");
        uint256 bal = token.balanceOf(receiver);
        token.safeTransferFrom(sender, receiver, amount);
        bal = token.balanceOf(receiver) - bal;
        require(bal == amount, "ERR_AMOUNT_NOT_ENOUGH");
    }

    function _collectDepositAndWithdrawGasFees(address receiver) private {
        uint256 _depositAndWithdrawFees = depositAndWithdrawFees;
        depositAndWithdrawFees = 0;
        payable(receiver).transfer(_depositAndWithdrawFees);
        emit DepositAndWithdrawGasFeesCollected(receiver, _depositAndWithdrawFees);
    }

    function _collectCloseSwapGasFees(address receiver) private {
        uint256 _closeSwapGasFees = closeSwapGasFees;
        closeSwapGasFees = 0;
        if (address(depositToken) == ETHER_ADDRESS) {
            payable(receiver).transfer(_closeSwapGasFees);
        } else {
            depositToken.safeTransfer(receiver, _closeSwapGasFees);
        }
        emit CloseSwapGasFeesCollected(depositToken, receiver, _closeSwapGasFees);
    }

    function setSwapper(address _swapper) external onlyRole(ROLE_OWNER) {
        require(Address.isContract(_swapper), "ERR_SWAPPER_NOT_CONTRACT");
        swapper = _swapper;
    }

    function setGasFeeReceiver(address _gasFeeReceiver) external onlyRole(ROLE_MANAGER) {
        gasFeeReceiver = _gasFeeReceiver;
    }

    function setGasPriceConsumer(address _gasPriceConsumer) external onlyRole(ROLE_MANAGER) {
        require(Address.isContract(_gasPriceConsumer), "ERR_GAS_PRICE_CONSUMER_NOT_CONTRACT");
        gasPriceConsumer = _gasPriceConsumer;
    }

    function setCompleteDepositGasLimit(uint256 gasLimit) external onlyRole(ROLE_STAFF) {
        completeDepositGasLimit = gasLimit;
    }

    function setYieldRateBound(uint256 _maxYieldRateBound, uint256 _minYieldRateBound) external onlyRole(ROLE_MANAGER) {
        require(_maxYieldRateBound >= 10 ** YIELD_RATE_DECIMALS);
        maxYieldRateBound = _maxYieldRateBound;
        minYieldRateBound = _minYieldRateBound;
    }

    function setCompleteWithdrawGasLimit(uint256 gasLimit) external onlyRole(ROLE_STAFF) {
        completeWithdrawGasLimit = gasLimit;
    }

    function transferToSwapper(IERC20 token, uint256 amount) external whenNotPaused onlySwapper {
        require(token == depositToken, "ERR_TRANSFER_WRONG_TOKEN_TO_SWAPPER");
        emit TransferToSwapper(swapper, token, amount);
        _safeTransferAsset(swapper, token, amount);
    }

    function deposit(uint256 amount) external whenNotPaused payable {
        require(amount > 0, "ERR_INVALID_DEPOSIT_AMOUNT");
        uint256 gasFee = completeDepositGasLimit * _getGasPrice();
        uint256 requiredValue = (address(depositToken) == ETHER_ADDRESS) ? gasFee + amount : gasFee;
        require(msg.value >= requiredValue, "ERR_NOT_ENOUGH_FEE");

        depositAndWithdrawFees += gasFee;
        uint256 id = numDeposits++;
        depositRequests[id] = DepositRequest(amount, msg.sender, false);
        payable(msg.sender).transfer(msg.value - requiredValue);
        if (address(depositToken) != ETHER_ADDRESS) {
            _safeTransferAssetFrom(depositToken, msg.sender, address(this), amount);
        }

        emit DepositRequested(msg.sender, id, amount, gasFee);
    }

    function completeDeposit(uint256 _depositID, uint256 amountXYWrappedToken) external whenNotPaused onlyRole(ROLE_LIQUIDITY_WORKER) {
        require(_depositID < numDeposits, "ERR_INVALID_DEPOSIT_ID");
        DepositRequest storage request = depositRequests[_depositID];
        require(!request.isComplete, "ERR_DEPOSIT_ALREADY_COMPLETE");
        // yield rate = (amount ypool token) / (amount wrapped token)
        require(request.amountDepositToken * 10 ** (YIELD_RATE_DECIMALS + XY_TOKEN_DECIMALS - depositTokenDecimal) / amountXYWrappedToken <= maxYieldRateBound, "ERR_YIELD_RATE_OUT_OF_MAX_BOUND");
        require(request.amountDepositToken * 10 ** (YIELD_RATE_DECIMALS + XY_TOKEN_DECIMALS - depositTokenDecimal) / amountXYWrappedToken >= minYieldRateBound, "ERR_YIELD_RATE_OUT_OF_MIN_BOUND");
        emit DepositFulfilled(request.sender, _depositID, amountXYWrappedToken);
        request.isComplete = true;
        xyWrappedToken.mint(request.sender, amountXYWrappedToken);
    }

    function withdraw(uint256 amountXYWrappedToken) external payable whenNotPaused {
        require(amountXYWrappedToken > 0, "ERR_INVALID_WITHDRAW_AMOUNT");
        uint256 gasFee = completeWithdrawGasLimit * _getGasPrice();
        require(msg.value >= gasFee, "ERR_NOT_ENOUGH_FEE");

        depositAndWithdrawFees += gasFee;
        uint256 id = numWithdrawals++;
        withdrawalRequests[id] = WithdrawalRequest(amountXYWrappedToken, msg.sender, false);
        payable(msg.sender).transfer(msg.value - gasFee);
        _safeTransferAssetFrom(xyWrappedToken, msg.sender, address(this), amountXYWrappedToken);
        emit WithdrawalRequested(msg.sender, id, amountXYWrappedToken, gasFee);
    }

    function completeWithdraw(uint256 _withdrawID, uint256 amount, uint256 withdrawFee) external whenNotPaused onlyRole(ROLE_LIQUIDITY_WORKER) {
        require(_withdrawID < numWithdrawals, "ERR_INVALID_WITHDRAW_ID");
        require(amount > 0, "ERR_WITHDRAW_FEE_NOT_LESS_THAN_AMOUNT");
        WithdrawalRequest storage request = withdrawalRequests[_withdrawID];
        require(!request.isComplete, "ERR_ALREADY_COMPLETED");
        // yield rate = (amount ypool token) / (amount wrapped token)
        require((amount + withdrawFee) * 10 ** (YIELD_RATE_DECIMALS + XY_TOKEN_DECIMALS - depositTokenDecimal) / request.amountXYWrappedToken <= maxYieldRateBound, "ERR_YIELD_RATE_OUT_OF_MAX_BOUND");
        require((amount + withdrawFee) * 10 ** (YIELD_RATE_DECIMALS + XY_TOKEN_DECIMALS - depositTokenDecimal) / request.amountXYWrappedToken >= minYieldRateBound, "ERR_YIELD_RATE_OUT_OF_MIN_BOUND");
        emit WithdrawalFulfilled(request.sender, _withdrawID, amount, withdrawFee);
        request.isComplete = true;
        xyWrappedToken.burn(request.amountXYWrappedToken);
        _safeTransferAsset(request.sender, depositToken, amount);
    }

    function collectDepositAndWithdrawGasFees() external whenNotPaused onlyRole(ROLE_STAFF) {
        _collectDepositAndWithdrawGasFees(gasFeeReceiver);
    }

    function collectCloseSwapGasFees() external whenNotPaused onlyRole(ROLE_STAFF) {
        _collectCloseSwapGasFees(gasFeeReceiver);
    }

    function collectFees() external whenNotPaused onlyRole(ROLE_STAFF) {
        _collectDepositAndWithdrawGasFees(gasFeeReceiver);
        _collectCloseSwapGasFees(gasFeeReceiver);
    }

    function receiveAssetFromSwapper(IERC20 token, uint256 amount, uint256 xyFeeAmount, uint256 gasFeeAmount) external payable whenNotPaused onlySwapper {
        require(token == depositToken, "ERR_TRANSFER_WRONG_TOKEN_FROM_SWAPPER");
        if (address(token) == ETHER_ADDRESS) {
            require(msg.value == amount, "ERR_INVALID_AMOUNT");
        } else {
            _safeTransferAssetFrom(token, swapper, address(this), amount);
        }

        closeSwapGasFees += gasFeeAmount;
        emit AssetReceived(token, amount, xyFeeAmount, gasFeeAmount);
    }

    function pause() external onlyRole(ROLE_MANAGER) {
        _pause();
    }

    function unpause() external onlyRole(ROLE_MANAGER) {
        _unpause();
    }

    // TODO: swap some deposit tokens to compensate swap fee
    // TODO: NFT fee discount
}
