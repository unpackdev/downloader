// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Ownable.sol";

import "./SafeMath.sol";
import "./SafeMathUint.sol";
import "./SafeMathInt.sol";

import "./DividendPayingTokenInterface.sol";
import "./DividendPayingTokenOptionalInterface.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";

contract DividendPayingToken is
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface,
    Ownable
{
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
    // For more discussion about choosing the value of `magnitude`,
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 internal constant magnitude = 2 ** 128;

    mapping(address => uint256) internal magnifiedDividendPerShare;
    address[] public rewardTokens;
    address public nextRewardToken;
    uint256 public rewardTokenCounter;

    IUniswapV2Router02 public immutable uniswapV2Router;

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
    mapping(address => mapping(address => int256))
        internal magnifiedDividendCorrections;
    mapping(address => mapping(address => uint256)) internal withdrawnDividends;

    mapping(address => uint256) public holderBalance;
    uint256 public totalBalance;

    mapping(address => uint256) public totalDividendsDistributed;

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;

        // Mainnet
        rewardTokens.push(address(0xba386A4Ca26B85FD057ab1Ef86e3DC7BdeB5ce70)); // JESUS - Mainnet
        nextRewardToken = rewardTokens[0];
    }

    /// @dev Distributes dividends whenever ether is paid to this contract.
    receive() external payable {
        distributeDividends();
    }

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
        require(totalBalance > 0);
        uint256 initialBalance = IERC20(nextRewardToken).balanceOf(
            address(this)
        );
        buyTokens(msg.value, nextRewardToken);
        uint256 newBalance = IERC20(nextRewardToken)
            .balanceOf(address(this))
            .sub(initialBalance);
        if (newBalance > 0) {
            magnifiedDividendPerShare[
                nextRewardToken
            ] = magnifiedDividendPerShare[nextRewardToken].add(
                (newBalance).mul(magnitude) / totalBalance
            );
            emit DividendsDistributed(msg.sender, newBalance);

            totalDividendsDistributed[
                nextRewardToken
            ] = totalDividendsDistributed[nextRewardToken].add(newBalance);
        }
        rewardTokenCounter = rewardTokenCounter == rewardTokens.length - 1
            ? 0
            : rewardTokenCounter + 1;
        nextRewardToken = rewardTokens[rewardTokenCounter];
    }

    // useful for buybacks or to reclaim any BNB on the contract in a way that helps holders.
    function buyTokens(uint256 bnbAmountInWei, address rewardToken) internal {
        // generate the uniswap pair path of weth -> eth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = rewardToken;

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: bnbAmountInWei
        }(
            0, // accept any amount of Ethereum
            path,
            address(this),
            block.timestamp
        );
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function withdrawDividend(address _rewardToken) external virtual override {
        _withdrawDividendOfUser(payable(msg.sender), _rewardToken);
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawDividendOfUser(
        address payable user,
        address _rewardToken
    ) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(
            user,
            _rewardToken
        );
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user][_rewardToken] = withdrawnDividends[user][
                _rewardToken
            ].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            IERC20(_rewardToken).transfer(user, _withdrawableDividend);
            return _withdrawableDividend;
        }

        return 0;
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(
        address _owner,
        address _rewardToken
    ) external view override returns (uint256) {
        return withdrawableDividendOf(_owner, _rewardToken);
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(
        address _owner,
        address _rewardToken
    ) public view override returns (uint256) {
        return
            accumulativeDividendOf(_owner, _rewardToken).sub(
                withdrawnDividends[_owner][_rewardToken]
            );
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(
        address _owner,
        address _rewardToken
    ) external view override returns (uint256) {
        return withdrawnDividends[_owner][_rewardToken];
    }

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(
        address _owner,
        address _rewardToken
    ) public view override returns (uint256) {
        return
            magnifiedDividendPerShare[_rewardToken]
                .mul(holderBalance[_owner])
                .toInt256Safe()
                .add(magnifiedDividendCorrections[_rewardToken][_owner])
                .toUint256Safe() / magnitude;
    }

    /// @dev Internal function that increases tokens to an account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _increase(address account, uint256 value) internal {
        for (uint256 i; i < rewardTokens.length; i++) {
            magnifiedDividendCorrections[rewardTokens[i]][
                account
            ] = magnifiedDividendCorrections[rewardTokens[i]][account].sub(
                (magnifiedDividendPerShare[rewardTokens[i]].mul(value))
                    .toInt256Safe()
            );
        }
    }

    /// @dev Internal function that reduces an amount of the token of a given account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    function _reduce(address account, uint256 value) internal {
        for (uint256 i; i < rewardTokens.length; i++) {
            magnifiedDividendCorrections[rewardTokens[i]][
                account
            ] = magnifiedDividendCorrections[rewardTokens[i]][account].add(
                (magnifiedDividendPerShare[rewardTokens[i]].mul(value))
                    .toInt256Safe()
            );
        }
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = holderBalance[account];
        holderBalance[account] = newBalance;
        if (newBalance > currentBalance) {
            uint256 increaseAmount = newBalance.sub(currentBalance);
            _increase(account, increaseAmount);
            totalBalance += increaseAmount;
        } else if (newBalance < currentBalance) {
            uint256 reduceAmount = currentBalance.sub(newBalance);
            _reduce(account, reduceAmount);
            totalBalance -= reduceAmount;
        }
    }
}
