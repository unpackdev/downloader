//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./INineInchPool.sol";
import "./INineInchFlexiblePool.sol";
import "./INineInchFactory.sol";
import "./IMasterChef.sol";
import "./INineInchPair.sol";

contract VotePower is Ownable {
    IERC20 public immutable token;
    INineInchFactory public immutable factory;
    IMasterChef public immutable masterChef;
    INineInchPool public immutable vault;
    INineInchFlexiblePool public immutable flexibleVault;
    uint256 public multiplier = 10;
    uint256 public constant MAX_MULTIPLIER = 100;

    event AddressUpdated(address _address);
    event NewDurationThreshold(uint256 DURATION_THRESHOLD);
    event NewDurationBoostFactor(uint256 DURATION_BOOST_FACTOR);

    constructor(address _token, address _factory, address _masterChef, address _vault, address _flexibleVault) {
        token = IERC20(_token);
        factory = INineInchFactory(_factory);
        masterChef = IMasterChef(_masterChef);
        vault = INineInchPool(_vault);
        flexibleVault = INineInchFlexiblePool(_flexibleVault);
    }

    function setLpMutiplier(uint256 _multiplier) external onlyOwner {
        require(_multiplier != 0, "Cannot be zero value");
        require(_multiplier < MAX_MULTIPLIER, "Must be less than MAX_MULTIPLIER");
        multiplier = _multiplier;
    }

    function getTokenBalance(address _user) public view returns (uint256) {
        return token.balanceOf(_user);
    }

    function getTokenBalanceFlexible(address _user) public view returns (uint256) {
        uint256 balance;
        (uint256 share, , , , , , uint256 userBoostedShare, bool locked, ) = vault.userInfo(_user);
        uint256 nineinchPoolPricePerFullShare = vault.getPricePerFullShare();
        if (!locked && share > 0) {
            balance += (share * nineinchPoolPricePerFullShare) / 1e18 - userBoostedShare;
        } else if(locked && share > 0) {
            (uint256 shareForFlexiblePool, , , ) = flexibleVault.userInfo(_user);
            uint256 nineinchFlexiblePoolPricePerFullShare = flexibleVault.getPricePerFullShare();
            if (shareForFlexiblePool > 0) {
                balance += (shareForFlexiblePool * nineinchFlexiblePoolPricePerFullShare) / 1e18;
            }
        }
        return balance;
    }

    function getTokenBalanceLocked(address _user) public view returns (uint256) {
        ( , , uint256 lastUserActionAmount, , , , , bool locked, ) = vault.userInfo(_user);
        return locked ? lastUserActionAmount : 0;
    }

    function getTokenBalanceInLiquidity(address _user) public view returns (uint256) {
        uint256 _length = factory.allPairsLength();
        uint256 _total = 0;
        for(uint256 _pid = 0; _pid < _length; _pid++) {
            address _lp = factory.allPairs(_pid);
            INineInchPair _pair = INineInchPair(_lp);
            address _token0 = _pair.token0();
            address _token1 = _pair.token1();
            if(address(token) == _token0 || address(token) == _token1) {
                uint256 _balance = INineInchPair(_lp).balanceOf(_user);
                if(_balance==0)
                    continue;
                uint256 _totalSupply = _pair.totalSupply();
                (uint256 _reserve0, uint256 _reserve1, ) = _pair.getReserves();
                _total += _balance * (address(token) == _token0 ? _reserve0 : _reserve1) / _totalSupply;
            }
        }
        return _total;
    }

    function getTokenBalanceInFarms(address _user) public view returns (uint256) {
        uint256 _length = masterChef.poolLength();
        uint256 _total = 0;
        for(uint256 _pid = 1; _pid < _length; _pid++) {
            address _lp = masterChef.lpToken(_pid);
            INineInchPair _pair = INineInchPair(_lp);
            address _token0 = _pair.token0();
            address _token1 = _pair.token1();
            if(address(token) == _token0 || address(token) == _token1) {
                (uint256 _staked, ) = masterChef.userInfo(_pid, _user);
                if(_staked==0)
                    continue;
                uint256 _totalSupply = _pair.totalSupply();
                (uint256 _reserve0, uint256 _reserve1, ) = _pair.getReserves();
                _total += _staked * (address(token) == _token0 ? _reserve0 : _reserve1) / _totalSupply;
            }
        }
        return _total;
    }

    function getVotingPower(address _user) public view returns (uint256) {
        return getVotingPowerWithoutLps(_user) + (getTokenBalanceInLiquidity(_user) + getTokenBalanceInFarms(_user)) * multiplier / MAX_MULTIPLIER;
    }

    function getVotingPowerWithoutLps(address _user) public view returns (uint256) {
        return
            getTokenBalance(_user) +
            getTokenBalanceLocked(_user) +
            getTokenBalanceFlexible(_user);
    }
}