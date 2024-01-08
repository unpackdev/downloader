// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";

/// @notice Transaction excutor of Path
contract ExecutorOfPath is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    string public name;

    string public symbol;

    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    mapping(address => bool) public isWhiteListed;

    address public dev;

    uint256 public fee; // wei

    /// @notice Swap's log.
    /// @param fromToken token's address.
    /// @param toToken token's address.
    /// @param sender Who swap
    /// @param fromAmount Input amount.
    /// @param returnAmount toToken's amount include fee amount. Not cut fee yet.
    event Swap(
        address fromToken,
        address toToken,
        address sender,
        uint256 fromAmount,
        uint256 returnAmount
    );

    event SwapCrossChain(address fromToken, address sender, uint256 fromAmount);

    event AddWhiteList(address contractAddress);

    event RemoveWhiteList(address contractAddr);

    event SetFee(uint256 fee);

    event WithdrawETH(uint256 balance);

    event Withdtraw(address token, uint256 balance);

    event SetDev(address _dev);

    modifier noExpired(uint256 deadLine) {
        require(deadLine >= block.timestamp, "EXPIRED");
        _;
    }

    fallback() external payable {}

    receive() external payable {}

    constructor(
        address _dev,
        uint256 _fee,
        address _owner
    ) {
        name = "Excutor of PATH";
        symbol = "EXCUTOR_v1";
        require(_dev != address(0), "DEV_CAN_T_BE_0");
        require(_owner != address(0), "OWNER_CAN_T_BE_0");
        dev = _dev;
        fee = _fee;
        transferOwnership(_owner);
    }

    function addWhiteList(address contractAddr) public onlyOwner {
        isWhiteListed[contractAddr] = true;
        emit AddWhiteList(contractAddr);
    }

    function removeWhiteList(address contractAddr) public onlyOwner {
        isWhiteListed[contractAddr] = false;
        emit RemoveWhiteList(contractAddr);
    }

    /// @notice Excute transactions. 从转入的币中扣除手续费。
    /// @param fromToken token's address. 源币的合约地址
    /// @param toToken token's address. 目标币的合约地址。如果是跨链情况，这个参数用0地址
    /// @param approveTarget contract's address which will excute calldata 执行交易的目标合约地址
    /// @param callDataConcat calldata 交易数据
    /// @param deadLine Deadline 时间戳，超过这个时间戳就表示交易执行失败，将revert
    /// @param isCrossChain 是否是跨链
    function swap(
        address fromToken,
        address toToken,
        address approveTarget,
        uint256 fromTokenAmount,
        bytes calldata callDataConcat,
        uint256 deadLine,
        bool isCrossChain
    ) external payable noExpired(deadLine) nonReentrant {
        require(isWhiteListed[approveTarget], "NOT_WHITELIST_CONTRACT"); // 要求执行交易的目标合约地址，必须在白名单中。
        require(fromToken != address(0), "FROMTOKEN_CANT_T_BE_0"); // 源币地址不能为0
        if (!isCrossChain) {
            // 单链情况的限制条件
            require(toToken != address(0), "TOTOKEN_CAN_T_BE_0");
        } else {
            // 跨链的限制条件
            require(toToken == address(0), "TOTOKEN_MUST_BE_0"); // 跨链情况下totoken必须是0地址
        }
        uint256 _inputAmount; // 实际收到的源币的数量
        /// @dev 下面计算实际收到的源币的数量
        if (fromToken != ETH_ADDRESS) {
            uint256 _fromTokenBalanceOrigin = IERC20(fromToken).balanceOf(
                address(this)
            );
            TransferHelper.safeTransferFrom(
                fromToken,
                msg.sender,
                address(this),
                fromTokenAmount
            );
            uint256 _fromTokenBalanceNew = IERC20(fromToken).balanceOf(
                address(this)
            );
            _inputAmount = _fromTokenBalanceNew.sub(_fromTokenBalanceOrigin);
            require(
                _inputAmount > 0,
                "NO_FROM_TOKEN_TRANSFER_TO_THIS_CONTRACT"
            );
        } else {
            _inputAmount = msg.value;
        }
        uint256 feeAmount = 0; // 手续费的数量
        /// @dev 计算手续费的数量
        if (fee > 0 && dev != address(0)) {
            feeAmount = _inputAmount.mul(fee).div(10**18);
        }
        uint256 fromAmount = _inputAmount.sub(feeAmount); // 除去去手续费，将授权目标合约转走的数量。
        TransferHelper.safeApprove(fromToken, approveTarget, fromAmount); // 授权目标合约转走源币
        /// @dev 将手续费转到dev地址
        if (fee > 0 && dev != address(0) && fromToken != ETH_ADDRESS) {
            TransferHelper.safeTransfer(fromToken, dev, feeAmount);
        } else if (fee > 0 && dev != address(0) && fromToken == ETH_ADDRESS) {
            TransferHelper.safeTransferETH(dev, feeAmount);
        }
        uint256 _toTokenBalanceOrigin = 0; // 兑换成目标币的数量。
        if (!isCrossChain) {
            // 如果是单链情况，先记录一下目标合约执行交易前的totoken的余额。后面计算余额差给到用户地址。
            _toTokenBalanceOrigin = toToken == ETH_ADDRESS
                ? address(this).balance
                : IERC20(toToken).balanceOf(address(this));
        }
        (bool success, ) = approveTarget.call{
            value: fromToken == ETH_ADDRESS ? fromAmount : 0
        }(callDataConcat);
        uint256 returnAmt = 0;
        require(success, "EXTERNAL_SWAP_EXECUTION_FAILED");
        /// @dev 如果是跨链情况，目标合约执行交易后就结束了。
        if (!isCrossChain) {
            // 如果是单链的情况，把换出来的币转给用户地址。
            returnAmt = toToken == ETH_ADDRESS
                ? address(this).balance.sub(_toTokenBalanceOrigin)
                : IERC20(toToken).balanceOf(address(this)).sub(
                    _toTokenBalanceOrigin
                );
            require(returnAmt >= 0, "RETURN_AMOUNT_IS_0");
            if (toToken == ETH_ADDRESS) {
                TransferHelper.safeTransferETH(msg.sender, returnAmt);
            } else {
                TransferHelper.safeTransfer(toToken, msg.sender, returnAmt);
            }
            emit Swap(
                fromToken,
                toToken,
                msg.sender,
                fromTokenAmount,
                returnAmt
            );
        } else {
            emit SwapCrossChain(fromToken, msg.sender, fromTokenAmount);
        }
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit SetFee(_fee);
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        TransferHelper.safeTransferETH(owner(), balance);
        emit WithdrawETH(balance);
    }

    function withdtraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        TransferHelper.safeTransfer(token, owner(), balance);
        emit Withdtraw(token, balance);
    }

    function setDev(address _dev) external onlyOwner {
        require(_dev != address(0), "0_ADDRESS_CAN_T_BE_A_DEV");
        dev = _dev;
        emit SetDev(_dev);
    }
}
