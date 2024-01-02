// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./MulticallUpgradeable.sol";

import "./IFlooring.sol";
import "./FlooringGetter.sol";

contract FlooringFragmentStaker is UUPSUpgradeable, OwnableUpgradeable, MulticallUpgradeable {
    error InsufficientBalance();

    event TokenForwarded(address indexed token, uint256 preTotalPooled, uint256 newTotalPooled, uint256 totalShares);
    event Staked(
        address indexed sender,
        address indexed token,
        address indexed receipt,
        uint256 amount,
        uint256 shares,
        uint256 pooledAmount
    );
    event Unstaked(
        address indexed sender, address indexed token, address indexed receipt, uint256 amount, uint256 shares
    );

    address public immutable flooring;
    address public immutable flooringReader;

    /// totalPooled[token]
    mapping(address => uint256) public totalPooled;
    /// totalShares[token]
    /// user staked tokens leading to shares increasing.
    mapping(address => uint256) public totalShares;
    /// shares[user][token]
    mapping(address => mapping(address => uint256)) public shares;

    constructor(address _flooring, address _flooringReader) payable {
        flooring = _flooring;
        flooringReader = _flooringReader;

        _disableInitializers();
    }

    /// required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public payable initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __Multicall_init();
    }

    /// @dev emergency withdraw
    function withdraw(address token) public payable onlyOwner {
        uint256 balance = FlooringGetter(flooringReader).tokenBalance(address(this), token);
        if (balance > 0) {
            IFlooring(flooring).removeTokens(token, balance, msg.sender);
        }
    }

    function stake(address token, uint256 amount, address onBehalf) public returns (uint256) {
        return _stake(token, amount, onBehalf);
    }

    function unstake(address token, uint256 amount, address receipt) public returns (uint256) {
        return _unstake(token, amount, receipt);
    }

    function balanceOf(address token, address user) public view returns (uint256) {
        return getPooledByShares(token, shares[user][token]);
    }

    function getSharesByPooled(address token, uint256 pooledAmount) public view returns (uint256) {
        uint256 _totalPooled = totalPooled[token];
        if (_totalPooled == 0) {
            return 0;
        }
        return pooledAmount * totalShares[token] / _totalPooled;
    }

    function getPooledByShares(address token, uint256 sharesAmount) public view returns (uint256) {
        uint256 _totalShares = totalShares[token];
        if (_totalShares == 0) {
            return 0;
        }
        return sharesAmount * totalPooled[token] / _totalShares;
    }

    function _refreshState(address token) internal {
        uint256 balance = FlooringGetter(flooringReader).tokenBalance(address(this), token);
        if (balance > 0) {
            uint256 preTotalPooled = totalPooled[token];

            totalPooled[token] += balance;
            IFlooring(flooring).removeTokens(token, balance, address(this));

            emit TokenForwarded(token, preTotalPooled, preTotalPooled + balance, totalShares[token]);
        }
    }

    function _stake(address token, uint256 amount, address receipt) internal returns (uint256) {
        _refreshState(token);

        uint256 newShares = getSharesByPooled(token, amount);
        if (newShares == 0) {
            /// First stake, the exchange ratio is 1:1
            newShares = amount;
        }

        totalShares[token] += newShares;
        totalPooled[token] += amount;

        shares[receipt][token] += newShares;

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, token, receipt, amount, newShares, getPooledByShares(token, newShares));

        return newShares;
    }

    function _unstake(address token, uint256 amount, address receipt) internal returns (uint256) {
        _refreshState(token);

        uint256 pooledAmount = balanceOf(token, msg.sender);
        if (amount > pooledAmount || pooledAmount == 0) revert InsufficientBalance();
        /// unstake all
        if (amount == 0) amount = pooledAmount;

        uint256 withdrawShares = getSharesByPooled(token, amount);
        shares[msg.sender][token] -= withdrawShares;

        totalShares[token] -= withdrawShares;
        totalPooled[token] -= amount;

        IERC20(token).transfer(receipt, amount);

        emit Unstaked(msg.sender, token, receipt, amount, withdrawShares);

        return amount;
    }
}
