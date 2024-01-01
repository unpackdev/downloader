// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

contract HyprTokenL1 is ERC20Upgradeable, OwnableUpgradeable {
    address public rewardsWallet;

    address public marketWallet;

    address public liquidWallet;

    uint256 public sellRewardFee;
    uint256 public sellLiquidityFee;
    uint256 public sellMarketFee;

    uint256 public buyLimit;

    mapping(address => bool) public pairs;

    mapping(address => bool) public blacklist;

    // Events
    event AddPair(address);

    function initialize(address _reward, address _market, address _liquid) external initializer {
        __Ownable_init();
        __ERC20_init("HYPR", "HYPR");
        rewardsWallet = _reward;
        marketWallet = _market;
        liquidWallet = _liquid;
        sellRewardFee = 2;
        sellLiquidityFee = 1;
        sellMarketFee = 2;

        buyLimit = 100000 * 1e18;

        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

    function addAddresses(address[] calldata bls) public onlyOwner {
        for (uint256 i = 0; i != bls.length; i++) {
            blacklist[bls[i]] = true;
        }
    }

    function removeAddress(address[] calldata bls) public onlyOwner {
        for (uint256 i = 0; i != bls.length; i++) {
            blacklist[bls[i]] = false;
        }
    }

    function updateSellRewardFee(uint256 _sellRewardFee) public onlyOwner {
        sellRewardFee = _sellRewardFee;
    }

    function updateSellLiquidityFee(uint256 _sellLiquidityFee) public onlyOwner {
        sellLiquidityFee = _sellLiquidityFee;
    }

    function updateSellMarketFee(uint256 _sellMarketFee) public onlyOwner {
        sellMarketFee = _sellMarketFee;
    }

    function updateBuyLimit(uint256 _buyLimit) public onlyOwner {
        buyLimit = _buyLimit;
    }

    function addPair(address _pair) public onlyOwner {
        pairs[_pair] = true;
        emit AddPair(_pair);
    }

    function updateReward(address newReward) public onlyOwner {
        rewardsWallet = newReward;
    }

    function updateMarket(address newMarket) public onlyOwner {
        marketWallet = newMarket;
    }

    function updateLiquid(address newLiquid) public onlyOwner {
        liquidWallet = newLiquid;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(amount > 0, "amount must gt 0");
        require(!blacklist[from]);

        if (pairs[from]) {
            require(amount + balanceOf(to) <= buyLimit, "buy limit is 100,000");
            super._transfer(from, to, amount);
            return;
        }

        if (pairs[to]) {
            uint256 rewardFee = (amount * sellRewardFee) / 100;
            uint256 marketFee = (amount * sellMarketFee) / 100;
            uint256 liquidFee = (amount * sellLiquidityFee) / 100;

            super._transfer(from, rewardsWallet, rewardFee);
            super._transfer(from, marketWallet, marketFee);
            super._transfer(from, liquidWallet, liquidFee);
            super._transfer(from, to, amount - rewardFee - marketFee - liquidFee);
            return;
        }
        super._transfer(from, to, amount);
    }
}
