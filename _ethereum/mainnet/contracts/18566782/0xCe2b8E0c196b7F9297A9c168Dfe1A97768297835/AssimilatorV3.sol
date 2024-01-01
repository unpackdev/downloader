// SPDX-License-Identifier: MIT

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.13;

import "./SafeERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeMath.sol";
import "./Math.sol";

import "./ABDKMath64x64.sol";
import "./IAssimilator.sol";
import "./IOracle.sol";
import "./IWeth.sol";

contract AssimilatorV3 is IAssimilator {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    using SafeMath for uint256;
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public immutable pairToken;

    IOracle public immutable oracle;
    IERC20Metadata public immutable token;
    uint256 public immutable oracleDecimals;
    uint256 public immutable tokenDecimals;
    uint256 public immutable pairTokenDecimals;

    address public immutable wETH;

    // solhint-disable-next-line
    constructor(
        address _wETH,
        address _pairToken,
        IOracle _oracle,
        address _token,
        uint256 _tokenDecimals,
        uint256 _oracleDecimals
    ) {
        wETH = _wETH;
        oracle = _oracle;
        token = IERC20Metadata(_token);
        oracleDecimals = _oracleDecimals;
        tokenDecimals = _tokenDecimals;
        pairToken = IERC20Metadata(_pairToken);
        pairTokenDecimals = pairToken.decimals();
    }

    function underlyingToken() external view override returns (address) {
        return address(token);
    }

    function getWeth() external view override returns (address) {
        return wETH;
    }

    function getRate() public view override returns (uint256) {
        (, int256 price,,,) = oracle.latestRoundData();
        require(price >= 0, "invalid price oracle");
        return uint256(price);
    }

    // takes raw eurs amount, transfers it in, calculates corresponding numeraire amount and returns it
    function intakeRawAndGetBalance(uint256 _amount)
        external
        payable
        override
        returns (int128 amount_, int128 balance_)
    {
        require(_amount > 0, "zero amount!");
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 balanceAfter = token.balanceOf(address(this));
        uint256 diff = _amount - (balanceAfter - balanceBefore);
        if (diff > 0) {
            intakeMoreFromFoT(_amount, diff);
        }

        uint256 _balance = token.balanceOf(address(this));

        uint256 _rate = getRate();

        balance_ = ((_balance * _rate) / 10 ** oracleDecimals).divu(10 ** tokenDecimals);

        amount_ = ((_amount * _rate) / 10 ** oracleDecimals).divu(10 ** tokenDecimals);
    }

    // takes raw eurs amount, transfers it in, calculates corresponding numeraire amount and returns it
    function intakeRaw(uint256 _amount) external payable override returns (int128 amount_) {
        require(_amount > 0, "zero amount!");
        uint256 balanceBefore = token.balanceOf(address(this));

        token.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 balanceAfter = token.balanceOf(address(this));

        uint256 diff = _amount - (balanceAfter - balanceBefore);
        if (diff > 0) {
            intakeMoreFromFoT(_amount, diff);
        }

        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 10 ** oracleDecimals).divu(10 ** tokenDecimals);
    }

    // takes a numeraire amount, calculates the raw amount of eurs, tr                                                                                                                                                                                                                                                                                        ansfers it in and returns the corresponding raw amount
    function intakeNumeraire(int128 _amount) external payable override returns (uint256 amount_) {
        uint256 _rate = getRate();
        // improve precision
        amount_ = Math.ceilDiv(_amount.mulu(10 ** (tokenDecimals + oracleDecimals + 18)), _rate * 1e18);
        require(amount_ > 0, "zero amount!");
        uint256 balanceBefore = token.balanceOf(address(this));

        token.safeTransferFrom(msg.sender, address(this), amount_);
        uint256 balanceAfter = token.balanceOf(address(this));
        uint256 diff = amount_ - (balanceAfter - balanceBefore);
        if (diff > 0) intakeMoreFromFoT(amount_, diff);
    }

    // takes a numeraire amount, calculates the raw amount of eurs, transfers it in and returns the corresponding raw amount
    function intakeNumeraireLPRatio(
        uint256 _minBaseAmount,
        uint256 _maxBaseAmount,
        uint256 _baseAmount,
        uint256 _minpairTokenAmount,
        uint256 _maxpairTokenAmount,
        uint256 _quoteAmount,
        address token0
    ) external payable override returns (uint256 amount_) {
        if (token0 == address(token)) {
            amount_ = _baseAmount;
        } else {
            amount_ = _quoteAmount;
        }

        require(amount_ > 0, "zero amount!");
        if (token0 == address(token)) {
            require(amount_ > _minBaseAmount && amount_ <= _maxBaseAmount, "Assimilator/LP Ratio imbalanced!");
        } else {
            require(amount_ > _minpairTokenAmount && amount_ <= _maxpairTokenAmount, "Assimilator/LP Ratio imbalanced!");
        }
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount_);
        uint256 balanceAfter = token.balanceOf(address(this));
        uint256 diff = amount_ - (balanceAfter - balanceBefore);
        if (diff > 0) intakeMoreFromFoT(amount_, diff);
    }

    function intakeMoreFromFoT(uint256 amount_, uint256 diff) internal {
        require(amount_ > 0, "zero amount!");
        // handle FoT token
        uint256 feePercentage = diff.mul(1e5).div(amount_).add(1);
        uint256 additionalIntakeAmt = (diff * 1e5) / (1e5 - feePercentage);
        token.safeTransferFrom(msg.sender, address(this), additionalIntakeAmt);
    }

    // takes a raw amount of eurs and transfers it out, returns numeraire value of the raw amount
    function outputRawAndGetBalance(address _dst, uint256 _amount)
        external
        override
        returns (int128 amount_, int128 balance_)
    {
        require(_amount > 0, "zero amount!");
        uint256 _rate = getRate();

        token.safeTransfer(_dst, _amount);

        uint256 _balance = token.balanceOf(address(this));

        amount_ = ((_amount * _rate)).divu(10 ** (tokenDecimals + oracleDecimals));
        balance_ = ((_balance * _rate)).divu(10 ** (tokenDecimals + oracleDecimals));
    }

    // takes a raw amount of eurs and transfers it out, returns numeraire value of the raw amount
    function outputRaw(address _dst, uint256 _amount) external override returns (int128 amount_) {
        require(_amount > 0, "zero amount!");
        uint256 _rate = getRate();

        token.safeTransfer(_dst, _amount);

        amount_ = ((_amount * _rate)).divu(10 ** (tokenDecimals + oracleDecimals));
    }

    // takes a numeraire value of eurs, figures out the raw amount, transfers raw amount out, and returns raw amount
    function outputNumeraire(address _dst, int128 _amount, bool _toETH)
        external
        payable
        override
        returns (uint256 amount_)
    {
        uint256 _rate = getRate();

        amount_ = Math.ceilDiv(_amount.mulu(10 ** (tokenDecimals + oracleDecimals + 18)), _rate * 1e18);
        require(amount_ > 0, "zero amount!");
        if (_toETH) {
            IWETH(wETH).withdraw(amount_);
            (bool success,) = payable(_dst).call{value: amount_}("");
            require(success, "Assimilator/Transfer ETH Failed");
        } else {
            token.safeTransfer(_dst, amount_);
        }
    }

    // takes a numeraire amount and returns the raw amount
    function viewRawAmount(int128 _amount) external view override returns (uint256 amount_) {
        uint256 _rate = getRate();
        // improve precision
        amount_ = Math.ceilDiv(_amount.mulu(10 ** (tokenDecimals + oracleDecimals + 18)), _rate * 1e18);
    }

    function viewRawAmountLPRatio(uint256 _baseWeight, uint256 _pairTokenWeight, address _addr, int128 _amount)
        external
        view
        override
        returns (uint256 amount_)
    {
        uint256 _tokenBal = token.balanceOf(_addr);

        if (_tokenBal <= 0) return 0;

        _tokenBal = _tokenBal.mul(10 ** (18 + pairTokenDecimals)).div(_baseWeight);

        uint256 _pairTokenBal = pairToken.balanceOf(_addr).mul(10 ** (18 + tokenDecimals)).div(_pairTokenWeight);

        // Rate is in pair token decimals
        uint256 _rate = _pairTokenBal.mul(1e6).div(_tokenBal);

        amount_ = Math.ceilDiv(_amount.mulu(10 ** tokenDecimals * 1e6 * 1e18), _rate * 1e18);
    }

    // takes a raw amount and returns the numeraire amount
    function viewNumeraireAmount(uint256 _amount) external view override returns (int128 amount_) {
        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 10 ** oracleDecimals).divu(10 ** tokenDecimals);
    }

    // views the numeraire value of the current balance of the reserve, in this case eurs
    function viewNumeraireBalance(address _addr) external view override returns (int128 balance_) {
        uint256 _rate = getRate();

        uint256 _balance = token.balanceOf(_addr);

        if (_balance <= 0) return ABDKMath64x64.fromUInt(0);

        balance_ = ((_balance * _rate) / 10 ** oracleDecimals).divu(10 ** tokenDecimals);
    }

    // views the numeraire value of the current balance of the reserve, in this case eurs
    function viewNumeraireAmountAndBalance(address _addr, uint256 _amount)
        external
        view
        override
        returns (int128 amount_, int128 balance_)
    {
        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 10 ** oracleDecimals).divu(10 ** tokenDecimals);

        uint256 _balance = token.balanceOf(_addr);

        balance_ = ((_balance * _rate) / 10 ** oracleDecimals).divu(10 ** tokenDecimals);
    }

    // views the numeraire value of the current balance of the reserve, in this case eurs
    // instead of calculating with chainlink's "rate" it'll be determined by the existing
    // token ratio. This is in here to prevent LPs from losing out on future oracle price updates
    function viewNumeraireBalanceLPRatio(uint256 _baseWeight, uint256 _pairTokenWeight, address _addr)
        external
        view
        override
        returns (int128 balance_)
    {
        uint256 _tokenBal = token.balanceOf(_addr);

        if (_tokenBal <= 0) return ABDKMath64x64.fromUInt(0);

        uint256 _pairTokenBal = pairToken.balanceOf(_addr).mul(1e18).div(_pairTokenWeight);

        // Rate is in 1e6
        uint256 _rate = _pairTokenBal.mul(1e18).div(_tokenBal.mul(1e18).div(_baseWeight));

        balance_ = ((_tokenBal * _rate) / 10 ** pairTokenDecimals).divu(1e18);
    }

    function transferFee(int128 _amount, address _treasury) external payable override {
        uint256 _rate = getRate();
        if (_amount < 0) _amount = -(_amount);
        uint256 amount = _amount.mulu(10 ** (tokenDecimals + oracleDecimals + 18)) / (_rate * 1e18);
        token.safeTransfer(_treasury, amount);
    }
}
