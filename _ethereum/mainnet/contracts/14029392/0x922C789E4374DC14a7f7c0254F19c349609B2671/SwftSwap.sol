// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";

/// @notice swftswap
contract SwftSwap is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    string public name;

    string public symbol;
    
    address public dev;
    
    uint256 public fee; 

    /// @notice Swap's log.
    /// @param fromToken token's address.
    /// @param toToken 兑换的目标币的名称.
    /// @param sender Who swap
    /// @param destination 目标币的地址
    /// @param fromAmount Input amount.
    /// @param returnAmount 目标币的接收数量
    /// @param memo 存放兑换信息用，比如 'swft 1000 usdt(erc20) of address1 to 997.324 usdt(matic) of address2'
    event Swap(
        address fromToken,
        string toToken,
        address sender,
        string destination,
        uint256 fromAmount,
        uint256 returnAmount,
        string memo
    );

    event SetFee(uint256 fee);

    event SetDev(address _dev);

    event WithdrawETH(uint256 balance);

    event Withdtraw(address token, uint256 balance);

    modifier noExpired(uint256 deadLine) {
        require(deadLine >= block.timestamp, "EXPIRED");  //block.timestamp is a Unix time stamp, seconds unit
        _;
    }

    constructor(
        address _dev,
        uint256 _fee
    ) {
        name = "SWFT Swap";
        symbol = "SSwap";
        dev = _dev;
        fee = _fee;
    }

    /// @notice Excute transactions. 从转入的币中扣除手续费。
    /// @param fromToken token's address. 源币的合约地址
    /// @param toToken token's address. 目标币的类型，比如'usdt(matic)'
    /// @param destination 目标币的收币地址
    /// @param fromAmount 原币的数量
    /// @param returnAmount 目标币的接收数量
    /// @param memo 存放兑换信息用，比如 'swap 1000 usdt(erc20) to 997.324 usdt(matic) of destination address'
    /// @param deadLine Deadline 时间戳，超过这个时间戳就表示交易执行失败，将revert
    function swap(
        address fromToken,
        string memory toToken,
        string memory destination,
        uint256 fromAmount,
        uint256 returnAmount,
        string memory memo,
        uint256 deadLine
    ) external noExpired(deadLine) nonReentrant {
        require(fromToken != address(0), "FROMTOKEN_CANT_T_BE_0"); // 源币地址不能为0
        require(fromAmount > 0, "FROM_TOKEN_AMOUNT_MUST_BE_MORE_THAN_0");
        uint256 _inputAmount; // 实际收到的源币的数量
        uint256 _fromTokenBalanceOrigin = IERC20(fromToken).balanceOf(address(this));
        TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
        uint256 _fromTokenBalanceNew = IERC20(fromToken).balanceOf(address(this));
        _inputAmount = _fromTokenBalanceNew.sub(_fromTokenBalanceOrigin);
        require(_inputAmount > 0, "NO_FROM_TOKEN_TRANSFER_TO_THIS_CONTRACT");
        uint256 feeAmount = 0; // 手续费的数量
        /// @dev 计算手续费的数量，将手续费转到dev地址
        if (fee > 0 && dev != address(0)) {
            feeAmount = _inputAmount.mul(fee).div(1000);
            TransferHelper.safeTransfer(fromToken, dev, feeAmount);
        }    
        emit Swap(fromToken, toToken, msg.sender, destination, fromAmount, returnAmount, memo);
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit SetFee(_fee);
    }

    function setDev(address _dev) external onlyOwner {
        require(_dev != address(0), "0_ADDRESS_CAN_T_BE_A_DEV");
        dev = _dev;
        emit SetDev(_dev);
    }

    function withdrawETH(address destination, uint256 amount) external onlyOwner {
        require(destination != address(0), "DESTINATION_CANNT_BE_0_ADDRESS");
        uint256 balance = address(this).balance;
        require(balance >= amount, "AMOUNT_CANNT_MORE_THAN_BALANCE");
        TransferHelper.safeTransferETH(destination, amount);
        emit WithdrawETH(amount);
    }

    function withdraw(address token, address destination, uint256 amount) external onlyOwner {
        require(destination != address(0), "DESTINATION_CANNT_BE_0_ADDRESS");
        require(token != address(0), "TOKEN_MUST_NOT_BE_0");
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance >= amount, "AMOUNT_CANNT_MORE_THAN_BALANCE");
        TransferHelper.safeTransfer(token, destination, amount);
        emit Withdtraw(token, amount);
    }
}
