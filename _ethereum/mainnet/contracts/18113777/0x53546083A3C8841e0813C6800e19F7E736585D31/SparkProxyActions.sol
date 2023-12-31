pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IWETH.sol";
import "./IPool.sol";

struct SparkData {
    address collateralTokenAddress;
    address debtTokenAddress;
    address payable fundsReceiver;
}

contract SparkProxyActions {
    address public immutable weth;
    IPool public immutable spark;

    constructor(address _weth, address _spark) {
        weth = _weth;
        spark = IPool(_spark);
    }

    function openPosition(address token, uint256 amount) external payable {
        _pull(token, amount);
        IERC20(token).approve(address(spark), amount);
        spark.deposit(token, amount, address(this), 0);
        emit Deposit(address(this), token, amount);
    }

    function drawDebt(address token, address recipient, uint256 amount) external payable {
        if (amount > 0) {
            spark.borrow(token, amount, 2, 0, address(this));
            _send(token, recipient, amount);
            emit Borrow(address(this), token, amount);
        }
    }

    function repayDebt(address token, uint256 amount, address user) public payable {
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "spark-proxy-action/insufficient-repay-balance"
        );

        IERC20(token).approve(address(spark), amount);
        spark.repay(token, amount, 2, user);
        emit Repay(address(this), token, amount);
    }

    function depositCollateral(address token, uint256 amount) external payable {
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "spark-proxy-action/insufficient-deposit-balance"
        );
        IERC20(token).approve(address(spark), amount);
        spark.deposit(token, amount, address(this), 0);
        emit Deposit(address(this), token, amount);
    }

    function withdrawCollateral(address token, address recipient, uint256 amount) external {
        spark.withdraw(token, amount, address(this));
        _send(token, recipient, amount);
        emit Withdraw(address(this), token, amount);
    }

    function _send(address token, address recipient, uint256 amount) internal {
        if (token == weth) {
            IWETH(weth).withdraw(amount);
            payable(recipient).transfer(amount);
        } else {
            IERC20(token).transfer(recipient, amount);
        }
    }

    function _pull(address token, uint256 amount) internal {
        if (token == weth) {
            require(msg.value == amount, "spark-proxy-action/insufficient-eth-amount");
            IWETH(weth).deposit{ value: amount }();
        } else {
            require(
                IERC20(token).allowance(msg.sender, address(this)) == amount,
                "spark-proxy-action/insufficient-allowance"
            );
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }
    }

    event Deposit(address indexed depositor, address indexed token, uint256 amount);

    event Withdraw(address indexed depositor, address indexed token, uint256 amount);

    event Borrow(address indexed depositor, address indexed token, uint256 amount);

    event Repay(address indexed depositor, address indexed token, uint256 amount);
}
