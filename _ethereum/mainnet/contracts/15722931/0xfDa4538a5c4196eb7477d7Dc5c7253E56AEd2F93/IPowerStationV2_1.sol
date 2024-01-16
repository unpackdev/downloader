// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
import "./IERC20Upgradeable.sol";
pragma solidity ^0.8.0;

/**
 * @dev Interface of the PowerStation
 */
interface IDUOPowerStation {
    
    event EnterPool(address indexed staker, uint64 shares);
    
    event PayDataGas(address indexed staker, uint256 amount);

    event PayPledge(address indexed staker, uint256 amount);

    event PayPower(address indexed staker, uint256 amount);

    // event PayIDC(address indexed staker, uint8 months);
    event PayIDC(address indexed staker, uint256 amount);

    event TopUp(uint256 indexed _pid, uint256 _allocPoint);

    event Withdraw(address indexed staker, uint256 indexed _pid, uint256 amount);

    event PoolCreated(uint256 _pid); 

    event PoolIsFull(uint256 _pid);


    function stakerJoinPool(uint256 _pid,uint256 shares, string memory Fil) external;
    
    // function payUtils(uint256 _pid, uint8 months) external;

    function withdraw(uint256 _pid) external;

    function poolLength()  external view returns (uint256) ;
    
    function addPool(uint256 periods,  uint256 pricePerShare, uint256 pledgePerShare, address poolMiner, 
                    string memory poolInfo,uint256 maxShares, uint256 startTime, 
                    uint256 dataFee, uint256 gasFee, uint256 rgptoShare, uint256 idcFee, uint256 buyEndTime) external;

    function topUpPool(uint256 _pid, uint256 _allocPoint) external;

    // function utilsAvailable(address user, uint256 _pid)  external returns(bool);

    function poolAvailable(uint256 _pid) external view returns(bool);

    function poolRemainingTime(uint256 _pid) external view returns(uint256);

    // function utilsRemaining(address user, uint256 _pid)  external returns(uint256);

    function pendingRewards(address user, uint256 _pid)  external  view returns (uint256);

    function checkSoldShares(uint256 _pid) external view returns(uint256);

    function poolExists(uint256 _pid)  external view returns(bool);

    function stakerExistsInPool(uint256 _pid, address stakerAddr) view external returns(bool);

    function numberOfstakers(uint256 _pid)  external view returns (uint256);

    function stakerAddrInPool(uint256 _pid)  external returns (address [] memory);

    function minerWithdraw(uint256 _pid)external;

    function emergencyWithdraw() external;

    function getPoolVars(uint256 _pid) external view returns(uint256[7] memory);

    function getPoolDailyPricePerShare(uint256 _pid) external view returns(uint256[] memory);
    
    function getTiming(uint256 _pid)  external view returns(uint256[3] memory);

    function getStakerInfoNTime(uint256 _pid, address stakerAddr) external view returns(uint256[6] memory);

    function AdminJoinPool(uint256 _pid, address stakerAddr, uint256 shares, string memory payby) external;

}