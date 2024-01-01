// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract LollipopRouter is AccessControl, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // VARIABLES
    address private constant NATIVE_ASSET_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    uint256 private constant MAX_SPEND_AMOUNT = type(uint256).max;
    uint256 private constant SCALE_FACTOR = 10 ** 18;
    uint256 private constant PERCENTAGE_SCALE = 10000;

    address public feeReceiver;

    // EVENTS
    event Swapped( address indexed receiver, uint256 fromAmount, uint256 toAmount, address fromToken, address toToken);
    event FeeCollected(address indexed token, uint256 fee);
    event EmergencyShutdown(address indexed receiver, uint256 timestamp);

    // STRUCT
    struct SwapData {
        address payable receiver;
        uint256 inputAmount;
        uint256 expectedOutputAmount;
        address fromToken;
        address toToken;
        uint32 feePercentage; // 50 = 0.5%. Required
        address router;
        bytes callData;
        bool isCrossChain;
    }

    // ROLES
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Lollipop: Caller is not an admin");
        _;
    }

    receive() external payable whenNotPaused {}

    constructor() {
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    //---------------------------------------------------------------------------
    // EXTERNAL FUNCTIONS

    function swap(SwapData memory _swapData) external payable nonReentrant whenNotPaused {
        validateSwap(_swapData);

        safeDeposit(_swapData);
        
        uint256 outputAmount = executeSwap(_swapData);

        if(outputAmount > 0) {
            uint256 feeAmount = getFeeAmount(_swapData, outputAmount);
            
            if(!isEmptyAddress(feeReceiver) && feeAmount > 0) {
                safeWithdraw(_swapData.toToken, feeReceiver, feeAmount);
                emit FeeCollected(_swapData.toToken, feeAmount);
            }

            uint256 recieverAmount = outputAmount.sub(feeAmount);
            safeWithdraw(_swapData.toToken, _swapData.receiver, recieverAmount);
        } else {
            outputAmount = _swapData.expectedOutputAmount;
        }

        emit Swapped(_swapData.receiver, _swapData.inputAmount, outputAmount, _swapData.fromToken, _swapData.toToken);
    }

    function rescueFunds(address _token, address _recipient) external onlyAdmin {
        require(!isEmptyAddress(_token), "Lollipop: Token to withdraw cannot be empty.");
        uint256 balance = getBalance(address(this), _token);
        safeWithdraw(_token, _recipient, balance);
    }

    function stopContract() external onlyAdmin whenNotPaused {
        require(!paused(), "Lollipop: Contract is already stopped");
        _pause();

        emit EmergencyShutdown(msg.sender, block.timestamp);
    }

    function resumeContract() external onlyAdmin whenPaused {
        require(paused(), "Lollipop: Contract is already is already running");
        _unpause();
    }

    function setFeeReceiver(address _receiver) external onlyAdmin {
        feeReceiver = _receiver;
    }

    //---------------------------------------------------------------------------
    // INTERNAL FUNCTIONS

    function validateSwap(SwapData memory _swapData) internal view {
        require(!isEmptyAddress(_swapData.receiver), "Lollipop: Swap receiver should not be empty");
        require(!isEmptyAddress(_swapData.router), "Lollipop: Swap router can not be empty");
        require(_swapData.callData.length > 0, "Lollipop: Swap callData can not be empty");
        
        require(!isEmptyAddress(_swapData.fromToken), "Lollipop: Swap from token can not be empty");
        require(!isEmptyAddress(_swapData.toToken), "Lollipop: Swap to token can not be empty");
        require(_swapData.fromToken != address(this), "Lollipop: Swap from token can't be contract's address");
        require(_swapData.toToken != address(this), "Lollipop: Swap to token can't be contract's address");

        require(_swapData.inputAmount > 0, "Swap from amount should be greater than 0");

        // Ensure that the sender has sufficient balance for the transaction
        require(msg.value >= (isNative(_swapData.fromToken) ? _swapData.inputAmount : 0), "Invalid msg.value");

        if(!isNative(_swapData.fromToken)) {
            uint256 balance = getBalance(msg.sender, _swapData.fromToken);
            require(balance >= _swapData.inputAmount, "Lollipop: Insufficient balance for swap.");
        }

        // Check if the fee percentage is valid E.g; 100 = 1%. 1% maximum
        require(_swapData.feePercentage >= 0 && _swapData.feePercentage <= 100, "Lollipop: Invalid fee percentage");
    }

    function getFeeAmount(SwapData memory _swapData, uint256 outputAmount) internal pure returns (uint256 fee) {
        if (_swapData.feePercentage > 0 && outputAmount > 0) {
            return outputAmount.mul(_swapData.feePercentage).div(PERCENTAGE_SCALE);
        } else {
            return 0;
        }
    }

    function isEmptyAddress(address _address) internal pure returns (bool) {
        return _address == address(0);
    }

    function isNative(address _token) internal pure returns (bool) {
        return _token == NATIVE_ASSET_ADDRESS || _token == address(0);
    }

    function getBalance(address _address, address _token) internal view returns (uint256) {
        if (isNative(_token)) {
            return _address.balance;
        } else {
            return IERC20(_token).balanceOf(_address);
        }
    }

    function grantSpendAllowance( address _token, address _spender, uint256 _amount ) internal {
        uint256 currentAllowance = IERC20(_token).allowance(address(this), _spender);

        if (currentAllowance < _amount) {
            SafeERC20.safeIncreaseAllowance(IERC20(_token), _spender, MAX_SPEND_AMOUNT - currentAllowance);
        }
    }

    function safeDeposit(SwapData memory _swapData) internal {
        // Get the initial balance before any deposit
        uint256 balanceBeforeDeposit = getBalance(address(this), _swapData.fromToken);

        // Check if the token is a native token
        if (isNative(_swapData.fromToken)) {
            // Ensure enough native token sis sent
            require(msg.value >= _swapData.inputAmount, "Lollipop: Not enough native token value was sent for swap");

            // Calculate refund amount if any extra value is sent
            if (msg.value > _swapData.inputAmount) {
                uint256 refundAmount = msg.value - _swapData.inputAmount;
                safeWithdraw(_swapData.fromToken, msg.sender, refundAmount);
            }
        } else {
            // Ensure there's enough allowance to transfer tokens
            uint256 currentAllowance = IERC20(_swapData.fromToken).allowance(msg.sender, address(this));
            require(currentAllowance >= _swapData.inputAmount, "Lollipop: Not enough allowance from user to spend this token.");

            // Transfer tokens to this contract
            SafeERC20.safeTransferFrom(IERC20(_swapData.fromToken), msg.sender, address(this), _swapData.inputAmount);
        }

        // If the token is not native, verify the deposit was successful
        if (!isNative(_swapData.fromToken)) {
            uint256 balanceAfterDeposit = getBalance(address(this), _swapData.fromToken);
            require(balanceAfterDeposit > balanceBeforeDeposit, "Lollipop: Asset deposit failed.");
        }
    }

    function safeWithdraw(address _token, address _to, uint256 _amount ) internal {
        require(!isEmptyAddress(_to), "Lollipop: Invalid recipient address.");
        
        uint256 balanceBeforeWithdraw;
        if(!isNative(_token)) {
            balanceBeforeWithdraw = getBalance(address(this), _token);
        }

        if (isNative(_token)) {
            (bool success, ) = payable(_to).call{ value: _amount }("");
            if (!success) revert("Lollipop: Native Asset withdrawal failed.");
        } else {
            SafeERC20.safeTransfer(IERC20(_token), _to, _amount);
        }
        
        if(!isNative(_token)) {
            uint256 balanceAfterWithdraw = getBalance(address(this), _token);
            require(balanceBeforeWithdraw - _amount == balanceAfterWithdraw, "Lollipop: Asset withdrawal failed.");
        }
    }

    function executeSwap(SwapData memory _swapData) internal returns (uint256 outputAmount) {
        uint256 initialBalance = getBalance(address(this), _swapData.toToken);

        if (isNative(_swapData.toToken)) {
            initialBalance -= msg.value;
        }

        swapWithRouter(_swapData);

        if(!_swapData.isCrossChain) {
            uint256 newBalance = getBalance(address(this), _swapData.toToken);
            require(newBalance > 0, "Lollipop: Swap output amount is invalid");

            uint256 swapOutputAmount = newBalance.sub(initialBalance);
            require(swapOutputAmount >= _swapData.expectedOutputAmount, "Lollipop: Received amount is below expected amount due to slippage.");

            return swapOutputAmount;
        }

        return 0;
    }

    function swapWithRouter(SwapData memory _swapData) internal {
        require(isContract(_swapData.router), "Lollipop: router address is not a contract");

        if (!isNative(_swapData.fromToken)) {
            grantSpendAllowance(_swapData.fromToken, _swapData.router, _swapData.inputAmount);
        }

        uint256 value = isNative(_swapData.fromToken) ? msg.value : 0;
        (bool success, ) = _swapData.router.call{value: value}(_swapData.callData);

        if (!success) revert("Lollipop: external router function call failed.");
    }

    function isContract(address _contractAddr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_contractAddr) }
        return size > 0;
    }
}