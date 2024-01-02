// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC20.sol";

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./SafeMath.sol";

contract NpGraveyard is UUPSUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;

    uint256 public constant upperboundPercentage = 51;
    uint256 public lastRebalance;

    IERC20 public token;

    event Rebalance(uint256 tokens);

    constructor() {
        _disableInitializers();
    }

    function initialize(address _token) external initializer {
        token = IERC20(_token);
        lastRebalance = block.timestamp;

        __Ownable_init(_msgSender());
    }

    function rebalance() external {
        //we should rebalance when we get more than target percentage of the supply in the graveyard
        uint256 upperbound = token.totalSupply().mul(upperboundPercentage).div(100);
        uint256 target = token.totalSupply().mul(50).div(100);
        uint256 balance = token.balanceOf(address(this));

        //airdrop the difference by sending back to the token contract which will
        //split rewards and locked liquidity
        if (balance > upperbound) {
            uint256 airdrop = balance.sub(target);

            //send airdrop to token where it will be added to liquidity
            token.transfer(address(token), airdrop);

            lastRebalance = block.timestamp;

            emit Rebalance(airdrop);
        }
    }

    function ready() external view returns (bool) {
        //we should rebalance when we get more than 51% of the supply in the graveyard
        uint256 upperbound = token.totalSupply().mul(upperboundPercentage).div(100);
        uint256 balance = token.balanceOf(address(this));

        //airdrop the difference by sending back to the token contract which will
        //split rewards and locked liquidity
        if (balance > upperbound) {
            return true;
        }

        return false;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
