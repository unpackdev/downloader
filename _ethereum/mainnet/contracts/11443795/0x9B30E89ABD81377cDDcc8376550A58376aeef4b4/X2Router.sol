// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./IWETH.sol";
import "./IX2Factory.sol";
import "./IX2Router.sol";
import "./IX2Market.sol";
import "./IX2Token.sol";

contract X2Router is IX2Router {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public factory;
    address public override weth;

    modifier ensureDeadline(uint _deadline) {
        require(_deadline >= block.timestamp, "X2Router: expired");
        _;
    }

    constructor(address _factory, address _weth) public {
        factory = _factory;
        weth = _weth;
    }

    receive() external payable {
        require(msg.sender == weth, "X2Token: unsupported sender");
    }

    function deposit(
        address _token,
        uint256 _amount,
        uint256 _subsidy,
        address _receiver,
        uint256 _deadline
    ) external ensureDeadline(_deadline) {
        address market = _getMarket(_token);
        if (_subsidy > 0) {
            _transferFeeTokenToMarket(market, _subsidy);
        }
        _transferCollateralToMarket(market, _amount);
        IX2Market(market).deposit(_token, _receiver, _subsidy > 0);
    }

    function depositETH(
        address _token,
        uint256 _subsidy,
        address _receiver,
        uint256 _deadline
    ) external payable ensureDeadline(_deadline) {
        address market = _getMarket(_token);
        if (_subsidy > 0) {
            _transferFeeTokenToMarket(market, _subsidy);
        }
        _transferETHToMarket(market, msg.value);
        IX2Market(market).deposit(_token, _receiver, _subsidy > 0);
    }

    function withdraw(
        address _token,
        uint256 _amount,
        uint256 _subsidy,
        address _receiver,
        uint256 _deadline
    ) external ensureDeadline(_deadline) {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        address market = _getMarket(_token);
        if (_subsidy > 0) {
            _transferFeeTokenToMarket(market, _subsidy);
        }
        IX2Market(market).withdraw(_token, _amount, _receiver, _subsidy > 0);
    }

    function withdrawETH(
        address _token,
        uint256 _amount,
        uint256 _subsidy,
        address _receiver,
        uint256 _deadline
    ) external ensureDeadline(_deadline) {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        address market = _getMarket(_token);
        require(IX2Market(market).collateralToken() == weth, "X2Router: mismatched collateral");
        if (_subsidy > 0) {
            _transferFeeTokenToMarket(market, _subsidy);
        }

        uint256 withdrawAmount = IX2Market(market).withdraw(_token, _amount, address(this), _subsidy > 0);
        IWETH(weth).withdraw(withdrawAmount);

        (bool success,) = _receiver.call{value: withdrawAmount}("");
        require(success, "X2Token: eth transfer failed");
    }

    function withdrawAll(
        address _token,
        uint256 _subsidy,
        address _receiver,
        uint256 _deadline
    ) external ensureDeadline(_deadline) {
        address market = _getMarket(_token);
        if (_subsidy > 0) {
            _transferFeeTokenToMarket(market, _subsidy);
        }
        uint256 amount = IERC20(_token).balanceOf(msg.sender);
        IERC20(_token).transferFrom(msg.sender, address(this), amount);
        IX2Market(market).withdraw(_token, amount, _receiver, _subsidy > 0);
    }

    function withdrawAllETH(
        address _token,
        uint256 _subsidy,
        address _receiver,
        uint256 _deadline
    ) external ensureDeadline(_deadline) {
        address market = _getMarket(_token);
        if (_subsidy > 0) {
            _transferFeeTokenToMarket(market, _subsidy);
        }
        uint256 amount = IERC20(_token).balanceOf(msg.sender);
        require(IX2Market(market).collateralToken() == weth, "X2Router: mismatched collateral");

        IERC20(_token).transferFrom(msg.sender, address(this), amount);
        uint256 withdrawAmount = IX2Market(market).withdraw(_token, amount, address(this), _subsidy > 0);
        IWETH(weth).withdraw(withdrawAmount);

        (bool success,) = _receiver.call{value: withdrawAmount}("");
        require(success, "X2Token: eth transfer failed");
    }

    function _transferETHToMarket(address _market, uint256 _amount) private {
        require(IX2Market(_market).collateralToken() == weth, "X2Router: mismatched collateral");
        IWETH(weth).deposit{value: _amount}();
        require(IWETH(weth).transfer(_market, _amount), "X2Router: weth transfer failed");
    }

    function _transferCollateralToMarket(address _market, uint256 _amount) private {
        address collateralToken = IX2Market(_market).collateralToken();
        IERC20(collateralToken).safeTransferFrom(msg.sender, _market, _amount);
    }

    function _getMarket(address _token) private view returns (address) {
        address market = IX2Token(_token).market();
        return market;
    }

    function _transferFeeTokenToMarket(address _market, uint256 _subsidy) private {
        address feeToken = IX2Factory(factory).feeToken();
        IERC20(feeToken).safeTransferFrom(msg.sender, _market, _subsidy);
    }
}
