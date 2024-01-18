// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "./ERC20.sol";

interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
}

interface ILidostETHInterface {
    function sharesOf(address _user) external view returns (uint256);
    function getTotalShares() external view returns (uint256);
    function getTotalPooledEther() external view returns (uint256);
    function getFee() external view returns (uint256);
}

interface ILidoOracleInterface {
    function getLastCompletedReportDelta() external view returns (uint256, uint256, uint256);
}

interface IAaveInterface {
    function balanceOf(address _user) external view returns (uint256);
    function assets(address _token) external view returns (uint128, uint128, uint256);
    function getTotalRewardsBalance(address _user) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function DISTRIBUTION_END() external view returns (uint256);
}

interface IConvexEarnCRVInterface {
    function balanceOf(address _user) external view returns (uint256);
    function earned(address _user) external view returns (uint256);
}

interface IConvexEarncvxCRVInterface {
    function userLocks(address _user, uint256 _pId) external view returns (uint112, uint112, uint32);
    function rewards(address _user, address _rewardToken) external view returns (uint256);
}

interface IShibaswapInterface {
    function balanceOf(address _user) external view returns (uint256);
}

interface ISushiswapStakingInterface {
    function balanceOf(address _user) external view returns (uint256);
}

interface ISushiswapFarmingV1Interface {
    function pendingSushi(uint256 _pId, address _user) external view returns (uint256);
    function poolInfo(uint256 _pId) external view returns (address, uint256, uint256, uint256);
    function userInfo(uint256 _pId, address _user) external view returns (uint256, uint256);
}

interface ISushiswapFarmingV2Interface {
    function pendingSushi(uint256 _pId, address _user) external view returns (uint256);
    function poolInfo(uint256 _pId) external view returns (uint128, uint64, uint64);
    function userInfo(uint256 _pId, address _user) external view returns (uint256, uint256);
    function lpToken(uint256 _pId) external view returns (address);
}

contract LFWUtils_ETH {
    uint private numStakingParameters = 5;
    uint private numFarmingParameters = 2;
    uint private numFarmingData = 3;
    address private pancakeFarmingPool = 0xa5f8C5Dbd5F286960b9d90548680aE5ebFf07652;
    address private lidoOracle = 0x442af784A788A5bd6F42A01Ebe9F287a871243fb;
    address private earnCRV = 0xCF50b810E57Ac33B91dCF525C6ddd9881B139332;
    address private earncvxCRV = 0x72a19342e8F1838460eBFCCEf09F6585e32db86E;
    address private sushiFarmingV1 = 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;
    address private sushiFarmingV2 = 0xEF0881eC094552b2e128Cf945EF17a6752B4Ec5d;
    address private sushi = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    uint private dailyBlock = 7150;
    uint private yearDay = 365;
    uint private secondsPerYear = 31536000;

    function getLidoStakingInfo(
        address _scAddress, 
        address _userAddress
    ) public view returns(uint256[] memory stakingInfo) {
        // Define array to return
        stakingInfo = new uint256[](2);

        // Initialize interface
        ILidostETHInterface scInterface = ILidostETHInterface(_scAddress);
        ILidoOracleInterface scOracle = ILidoOracleInterface(lidoOracle);

        // [0] is the user's staking amount
        stakingInfo[0] = scInterface.sharesOf(_userAddress)*scInterface.getTotalPooledEther()/scInterface.getTotalShares();

        // [1] is the pool APR
        (uint256 postTotalPooledEther, uint256 preTotalPooledEther, uint256 timeElapsed) = scOracle.getLastCompletedReportDelta();
        stakingInfo[1] = (postTotalPooledEther - preTotalPooledEther) * secondsPerYear / (preTotalPooledEther * timeElapsed);
    }

    function getAaveStakingInfo(
        address _scAddress,
        address _userAddress
    ) public view returns(uint256[] memory stakingInfo) {
        // Define array to return
        stakingInfo = new uint256[](numStakingParameters);

        // Initialize interface        
        IAaveInterface scInterface = IAaveInterface(_scAddress);

        // [0] is the user's pending reward
        stakingInfo[0] = scInterface.getTotalRewardsBalance(_userAddress);

        // [1] is the user's staking amount
        stakingInfo[1] = scInterface.balanceOf(_userAddress);

        // [2] Calculate an optional term to calculate APR for backend
        (uint256 rewardPerSecond, , ) = scInterface.assets(_scAddress);
        uint256 rewardPerYear = rewardPerSecond*secondsPerYear;
        uint256 stakedTokenBalance = scInterface.totalSupply();
        stakingInfo[2] = rewardPerYear;
        stakingInfo[3] = stakedTokenBalance;

        // [3] is the pool countdown by block
        stakingInfo[4] = scInterface.DISTRIBUTION_END() - block.number;
    }

    function getConvexStakingInfo(
        address _scAddress,
        address _userAddress
    ) public view returns(uint256[] memory stakingInfo) {
        // Define array to return
        stakingInfo = new uint256[](2);

        // Initialize interface 
        if (_scAddress == earnCRV) {
            IConvexEarnCRVInterface scInterface = IConvexEarnCRVInterface(_scAddress);
            // [0] is the user pending reward
            stakingInfo[0] = scInterface.earned(_userAddress);
            // [1] is the user staking amount
            stakingInfo[1] = scInterface.balanceOf(_userAddress);
        } else {
            IConvexEarncvxCRVInterface scInterface = IConvexEarncvxCRVInterface(_scAddress);
            address crxCRV = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
            // [0] is the user pending reward
            stakingInfo[0] = scInterface.rewards(_userAddress, crxCRV);
            // [1] is the user staking amount
            (stakingInfo[1], , ) = scInterface.userLocks(_userAddress, 0);            
        }
    }

    function getShibaStakingInfo(
        address _scAddress,
        address _userAddress
    ) public view returns(uint256 stakingInfo) {
        // Initialize interface
        IShibaswapInterface scInterface = IShibaswapInterface(_scAddress);
        stakingInfo = scInterface.balanceOf(_userAddress);
    }

    function getSushiStakingInfo(
        address _scAddress,
        address _userAddress
    ) public view returns(uint256 stakingInfo) {
        // Initialize interface
        ISushiswapStakingInterface scInterface = ISushiswapStakingInterface(_scAddress);
        stakingInfo = scInterface.balanceOf(_userAddress);
    }

    function getSushiFarmingV1Info(
        uint256 _pId,
        address _userAddress
    ) public view returns(uint256[] memory farmingInfo, address[] memory farmingData) {
        // Define array to return info
        farmingInfo = new uint256[](numFarmingParameters);

        // Define array to return data
        farmingData = new address[](numFarmingData);

        // Initialize interface
        ISushiswapFarmingV1Interface scInterface = ISushiswapFarmingV1Interface(sushiFarmingV1);

        // [0] is the user pending reward
        farmingInfo[0] = scInterface.pendingSushi(_pId, _userAddress);

        // [1] is the user's staking amount
        (farmingInfo[1], ) = scInterface.userInfo(_pId, _userAddress);

        // [0] and [1] are token 0 and token 1
        (address _lp, , , ) = scInterface.poolInfo(_pId);
        
        // Initialize interfacee
        IPair scPair = IPair(_lp);

        farmingData[0] = scPair.token0();
        farmingData[1] = scPair.token1();

        // [3] is the reward token address
        farmingData[2] = sushi;
    }

    function getSushiFarmingV2Info(
        uint256 _pId,
        address _userAddress
    ) public view returns(uint256[] memory farmingInfo, address[] memory farmingData) {
        // Define array to return info
        farmingInfo = new uint256[](numFarmingParameters);

        // Define array to return data
        farmingData = new address[](numFarmingData);

        // Initialize interface
        ISushiswapFarmingV2Interface scInterface = ISushiswapFarmingV2Interface(sushiFarmingV2);

        // [0] is the user pending reward
        farmingInfo[0] = scInterface.pendingSushi(_pId, _userAddress);

        // [1] is the user's staking amount
        (farmingInfo[1], ) = scInterface.userInfo(_pId, _userAddress);

        // [0] and [1] are token 0 and token 1
        address _lp = scInterface.lpToken(_pId);
        
        // Initialize interfacee
        IPair scPair = IPair(_lp);

        farmingData[0] = scPair.token0();
        farmingData[1] = scPair.token1();

        // [3] is the reward token address
        farmingData[2] = sushi;
    }

}