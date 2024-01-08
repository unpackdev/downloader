// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./SafeMath.sol";


interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}

interface PendleLiquidityRewardsProxy {
    function redeemLiquidityRewards(
        address liqMiningContract,
        uint256[] calldata expiries,
        address user
    )
        external
        returns (
            uint256 rewards,
            uint256[] memory pendingRewards,
            uint256 currentEpoch
        );
}

interface PendleMarket {
    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function expiry() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint256 xytBalance,
            uint256 xytWeight,
            uint256 tokenBalance,
            uint256 tokenWeight,
            uint256 currentBlock
        );

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function token() external view returns (address);

    function xyt() external view returns (address);
}

interface PendleLiquidityMining {
    function stake(uint256 expiry, uint256 amount)
        external
        returns (address newLpHoldingContractAddress);

    function withdraw(uint256 expiry, uint256 amount) external;

    function allocationSettings(uint256 epochId, uint256 expiry) external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function getBalances(uint256 expiry, address user) external view returns (uint256);

    function readExpiryData(uint256 expiry)
        external
        view
        returns (
            uint256 totalStakeLP,
            uint256 lastNYield,
            uint256 paramL,
            address lpHolder
        );

    function startTime() external view returns (uint256);

    function latestSetting() external view returns (uint256 id, uint256 firstEpochToApply);

    function totalRewardsForEpoch(uint256 epochId) external view returns (uint256 rewards);
}

contract PendlePoolsReadWrapper {
    using SafeMath for uint256;

    struct Reserves {
        uint256 xytBalance;
        uint256 xytWeight;
        uint256 tokenBalance;
        uint256 tokenWeight;
    }

    function marketApprove(PendleMarket _market, address _staking) public {
        _market.approve(_staking, type(uint256).max);
    }

    function claim(
        PendleLiquidityRewardsProxy _rewardsProxy,
        address _liqMiningContract,
        uint256[] calldata _expiries,
        address _user
    )
        public
        returns (
            uint256 rewards,
            uint256[] memory pendingRewards,
            uint256 currentEpoch
        )
    {
        (rewards, pendingRewards, currentEpoch) = _rewardsProxy.redeemLiquidityRewards(
            _liqMiningContract,
            _expiries,
            _user
        );
    }

    function stake(
        PendleLiquidityMining _staking,
        uint256 _expiry,
        uint256 _balance
    ) public {
        _staking.stake(_expiry, _balance);
    }

    function withdraw(
        PendleLiquidityMining _staking,
        uint256 _expiry,
        uint256 _balance
    ) public {
        _staking.withdraw(_expiry, _balance);
    }

    function getMainInfo(PendleMarket _market, PendleLiquidityMining _staking)
        public
        view
        returns (
            uint256 expiry,
            string memory marketSymbol,
            uint256 lpTotalSupply,
            uint256 totalStakeLP,
            uint256 latestSettingId,
            uint8 tokenDecimals,
            uint8 xytDecimals,
            Reserves memory reserves
        )
    {
        IERC20 token = IERC20(_market.token());
        IERC20 xyt = IERC20(_market.xyt());

        {
            (
                uint256 xytBalance,
                uint256 xytWeight,
                uint256 tokenBalance,
                uint256 tokenWeight,

            ) = _market.getReserves();
            reserves.xytBalance = xytBalance;
            reserves.xytWeight = xytWeight;
            reserves.tokenBalance = tokenBalance;
            reserves.tokenWeight = tokenWeight;
        }

        expiry = _market.expiry();
        marketSymbol = _market.symbol();
        lpTotalSupply = _market.totalSupply();
        (totalStakeLP, , , ) = _staking.readExpiryData(expiry);
        (latestSettingId, ) = _staking.latestSetting();

        tokenDecimals = token.decimals();
        xytDecimals = xyt.decimals();
    }

    function getRewardsPerEpoch(
        PendleMarket _market,
        PendleLiquidityMining _staking,
        address _user
    )
        public
        view
        returns (
            uint256 epochDuration,
            uint256 expiry,
            uint256 rewardsPerEpoch,
            uint256 userStaked,
            uint256 userAvailableToStake,
            uint256 userAllowance
        )
    {
        epochDuration = _staking.epochDuration();
        expiry = _market.expiry();

        uint256 startTime = _staking.startTime();
        uint256 currentEpoch = (block.timestamp < startTime)
            ? 0
            : (block.timestamp.sub(startTime)).div(epochDuration).add(1);

        rewardsPerEpoch = _staking.totalRewardsForEpoch(currentEpoch);

        userStaked = _staking.getBalances(expiry, _user);
        userAvailableToStake = _market.balanceOf(_user);
        userAllowance = _market.allowance(_user, address(_staking));
    }
}
