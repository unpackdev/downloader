// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "./SafeMath.sol";

import "./PoolStore.sol";
import "./Operator.sol";
import "./Oracle.sol";
import "./Curve.sol";

contract WeightFeeder is Operator {
    using SafeMath for uint256;

    enum FeedStatus {Neutral, BelowPeg, AbovePeg}

    uint256 public constant ETH = 1e18;

    // gov
    address public token;
    address public target;
    address public curve;
    address public oracle;

    function setToken(address _newToken) public onlyOwner {
        token = _newToken;
    }

    function setTarget(address _newTarget) public onlyOwner {
        target = _newTarget;
    }

    function setCurve(address _newCurve) public onlyOwner {
        curve = _newCurve;
    }

    function setOracle(address _newOracle) public onlyOwner {
        oracle = _newOracle;
    }

    // pools
    uint256 public cashLP;
    uint256 public cashVault;
    uint256 public shareLP;
    uint256 public boardroom;
    uint256 public bondroom;
    uint256 public strategicPair;
    uint256 public communityFund;

    FeedStatus public lastUpdated = FeedStatus.Neutral;

    function configure(
        uint256 _cashLP,
        uint256 _cashVault,
        uint256 _shareLP,
        uint256 _boardroom,
        uint256 _bondroom,
        uint256 _strategicPair,
        uint256 _communityFund
    ) public onlyOwner {
        cashLP = _cashLP;
        cashVault = _cashVault;
        shareLP = _shareLP;
        boardroom = _boardroom;
        bondroom = _bondroom;
        strategicPair = _strategicPair;
        communityFund = _communityFund;
    }

    function feed() public onlyOperator {
        uint256 price = IOracle(oracle).consult(token, ETH);
        uint256 rate = ICurve(curve).calcCeiling(price);

        // 60 * 1e18
        IPoolStoreGov(target).setPool(cashLP, rate.mul(60));
        IPoolStoreGov(target).setPool(cashVault, ETH.sub(rate).mul(60));
        if (IPoolStore(target).weightOf(shareLP) != ETH.mul(10)) {
            IPoolStoreGov(target).setPool(shareLP, ETH.mul(10));
        }

        // below peg
        if (lastUpdated != FeedStatus.BelowPeg && price < ETH) {
            /*
                15% BAS boardroom stakers
                5% BAB staking pool
                5% Strategic pairs
                5% CDF/Vision fund
            */
            IPoolStoreGov(target).setPool(boardroom, ETH.mul(15));
            IPoolStoreGov(target).setPool(bondroom, ETH.mul(5));
            IPoolStoreGov(target).setPool(strategicPair, ETH.mul(5));
            IPoolStoreGov(target).setPool(communityFund, ETH.mul(5));

            lastUpdated = FeedStatus.BelowPeg;
        }

        // above peg
        if (lastUpdated != FeedStatus.AbovePeg && price >= ETH) {
            /*
                5% BAS boardroom stakers
                0% BAB staking pool
                10% Strategic pairs
                15% the CDF/Vision fund
            */
            IPoolStoreGov(target).setPool(boardroom, ETH.mul(5));
            IPoolStoreGov(target).setPool(bondroom, 0);
            IPoolStoreGov(target).setPool(strategicPair, ETH.mul(10));
            IPoolStoreGov(target).setPool(communityFund, ETH.mul(15));

            lastUpdated = FeedStatus.AbovePeg;
        }
    }
}
