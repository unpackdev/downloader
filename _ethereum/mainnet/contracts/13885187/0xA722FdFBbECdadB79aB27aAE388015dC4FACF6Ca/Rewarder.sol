// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IRewarder.sol";
import "./TransferHelper.sol";

contract Rewarder is IRewarder, ReentrancyGuard {
    address public immutable override currency;
    address public immutable pool;
    address public operator;

    event LogRewarderWithdraw(address indexed _rewarder, address _currency, address indexed _to, uint256 _amount);
    event LogTransferOwnerShip(address indexed _rewarder, address indexed _oldOperator, address indexed _newOperator);

    constructor(
        address _operator,
        address _currency,
        address _pool
    ) {
        currency = _currency;
        pool = _pool;
        operator = _operator;
    }

    receive() external payable {}

    function onReward(address _to, uint256 _amount) external payable override onlyPOOL returns (uint256) {
        require(_to != address(0), "UnoRe: zero address reward");
        if (currency == address(0)) {
            if (address(this).balance >= _amount) {
                TransferHelper.safeTransferETH(_to, _amount);
                return _amount;
            } else {
                if (address(this).balance > 0) {
                    TransferHelper.safeTransferETH(_to, address(this).balance);
                    return address(this).balance;
                } else {
                    return 0;
                }
            }
        } else {
            if (IERC20(currency).balanceOf(address(this)) >= _amount) {
                TransferHelper.safeTransfer(currency, _to, _amount);
                return _amount;
            } else {
                if (IERC20(currency).balanceOf(address(this)) > 0) {
                    TransferHelper.safeTransfer(currency, _to, IERC20(currency).balanceOf(address(this)));
                    return IERC20(currency).balanceOf(address(this));
                } else {
                    return 0;
                }
            }
        }
    }

    function withdraw(address _to, uint256 _amount) external onlyOperator nonReentrant {
        require(_to != address(0), "UnoRe: zero address reward");
        if (currency == address(0)) {
            if (address(this).balance >= _amount) {
                TransferHelper.safeTransferETH(_to, _amount);
                emit LogRewarderWithdraw(address(this), currency, _to, _amount);
            } else {
                if (address(this).balance > 0) {
                    TransferHelper.safeTransferETH(_to, address(this).balance);
                    emit LogRewarderWithdraw(address(this), currency, _to, address(this).balance);
                }
            }
        } else {
            if (IERC20(currency).balanceOf(address(this)) >= _amount) {
                TransferHelper.safeTransfer(currency, _to, _amount);
                emit LogRewarderWithdraw(address(this), currency, _to, _amount);
            } else {
                if (IERC20(currency).balanceOf(address(this)) > 0) {
                    TransferHelper.safeTransfer(currency, _to, IERC20(currency).balanceOf(address(this)));
                    emit LogRewarderWithdraw(address(this), currency, _to, IERC20(currency).balanceOf(address(this)));
                }
            }
        }
    }

    function transferOwnership(address _to) external onlyOperator nonReentrant {
        require(_to != address(0), "UnoRe: zero address reward");
        address oldOperator = operator;
        operator = _to;
        emit LogTransferOwnerShip(address(this), oldOperator, _to);
    }

    modifier onlyPOOL() {
        require(msg.sender == pool, "Only SSRP or SSIP contract can call this function.");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator call this function.");
        _;
    }
}
