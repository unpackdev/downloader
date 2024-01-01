// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMathUint.sol";
import "./SafeMathInt.sol";
import "./IDividendPayingToken.sol";
import "./IDividendPayingTokenOptional.sol";

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
abstract contract DividendToken is ERC20, IDividendPayingToken, IDividendPayingTokenOptional, Ownable {
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
    // For more discussion about choosing the value of `magnitude`,
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 internal constant magnitude = 10 ** 38;
    uint256 internal magnifiedDividendPerShare;
    uint256 internal lastAmount;
    uint256 public totalDividendsDistributed;
    uint256 public totalDividendsShares;
    // About dividendCorrection:
    // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
    // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
    //   `dividendOf(_user)` should not be changed,
    //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
    // To keep the `dividendOf(_user)` unchanged, we add a correction term:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
    //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
    //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
    // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    // public functions

    /// @notice Distributes ether to token holders as dividends.
    /// @dev It reverts if the total supply of tokens is 0.
    /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
    /// About undistributed ether:
    ///   In each distribution, there is a small amount of ether not distributed,
    ///     the magnified amount of which is
    ///     `(msg.value * magnitude) % totalSupply()`.
    ///   With a well-chosen `magnitude`, the amount of undistributed ether
    ///     (de-magnified) in a distribution can be less than 1 wei.
    ///   We can actually keep track of the undistributed ether in a distribution
    ///     and try to distribute it in the next distribution,
    ///     but keeping track of such data on-chain costs much more than
    ///     the saved ether, so we don't do that.
    function distributeDividends() public payable override {
        _distributeDividends(msg.value);
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) public view override returns (uint256) {
        uint256 _dividend = withdrawableDividendOf(_owner);
        return _dividend;
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(address _owner) public view override returns (uint256) {
        uint256 _withdrawable = accumulativeDividendOf(_owner) - (withdrawnDividends[_owner]);
        return _withdrawable;
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(address _owner) public view override returns (uint256) {
        uint256 _withdrawn = withdrawnDividends[_owner];
        return _withdrawn;
    }

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(address _owner) public view override returns (uint256) {
        uint256 _accumulative = (
            (magnifiedDividendPerShare * _dividendShare(_owner)).toInt256Safe() + magnifiedDividendCorrections[_owner]
        ).toUint256Safe() / magnitude;
        return _accumulative;
    }

    // internal functions

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user] + _withdrawableDividend;
            (bool success,) = user.call{value: _withdrawableDividend, gas: 3000}("");
            if (!success) {
                return 0;
            }
            return _withdrawableDividend;
        }
        return 0;
    }

    function _dividendShare(address _account) internal view virtual returns (uint256 _share);

    function _distributeDividends(uint256 amount) internal {
        require(totalDividendsShares > 0, "0 dividend totalsupply");
        if (amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare + (amount * magnitude / totalDividendsShares);
            emit DividendsDistributed(msg.sender, amount);
            totalDividendsDistributed = totalDividendsDistributed + amount;
        }
    }

    /// @dev Internal function that mints tokens to an account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _processMint(address account, uint256 value) internal {
        int256 _correction =
            magnifiedDividendCorrections[account] - ((magnifiedDividendPerShare * value).toInt256Safe());
        magnifiedDividendCorrections[account] = _correction;
    }

    /// @dev Internal function that burns an amount of the token of a given account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    function _processBurn(address account, uint256 value) internal {
        int256 _correction =
            magnifiedDividendCorrections[account] + ((magnifiedDividendPerShare * value).toInt256Safe());
        magnifiedDividendCorrections[account] = _correction;
    }

    /// @dev Internal function that adjusts an address dividends shares according to the new token balance.
    /// @param account The account whose tokens will be proccessed .
    /// @param newBalance The new address balance.
    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = _dividendShare(account);
        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance - currentBalance;
            totalDividendsShares += mintAmount;
            _processMint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance - newBalance;
            totalDividendsShares -= burnAmount;
            _processBurn(account, burnAmount);
        }
    }
}
