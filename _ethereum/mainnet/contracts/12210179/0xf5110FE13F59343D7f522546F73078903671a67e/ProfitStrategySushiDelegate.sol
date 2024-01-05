pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./TransferHelper.sol";
import "./MasterCaller.sol";
import "./IProfitStrategy.sol";

import "./StrategySushiStorage.sol";



interface IMasterChef {

    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);
    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory _userInfo);
}
/**
 * mine SUSHI via SUSHIswap.MasterChef
 * will transferOnwership to stakeGatling
 */
contract ProfitStrategySushiDelegate is StrategySushiStorage, Ownable, IProfitStrategy {

     /**
     * Stake LP
     */
    function stake(uint256 _amount) external override onlyOwner() {

        if(stakeRewards != address(0)) {
            IMasterChef(stakeRewards).deposit( pid, _amount);
        }
    }

    /**
     * withdraw LP
     */
    function withdraw(uint256 _amount) public override onlyOwner() {

        if(stakeRewards != address(0) && _amount > 0) {

            IMasterChef(stakeRewards).withdraw(pid, _amount);
            TransferHelper.safeTransfer(stakeLpPair, address(stakeGatling),_amount);
        }
    }

    function burn(address _to, uint256 _amount) external override onlyOwner() returns (uint256 amount0, uint256 amount1) {

        if(stakeRewards != address(0) && _amount > 0) {
            IMasterChef(stakeRewards).withdraw(pid, _amount);
            TransferHelper.safeTransfer(stakeLpPair, stakeLpPair, _amount);
            (amount0, amount1) =  IUniswapV2Pair(stakeLpPair).burn(_to);
        }
    }

    function stakeToken() external view override returns (address) {
        return stakeRewards;
    }

    function earnToken() external view override returns (address) {
        return earnTokenAddr;
    }

    function earnPending(address _account) external view override returns (uint256) {
        return IMasterChef(stakeRewards).pendingSushi(pid, _account);
    }
    function earn() external override onlyOwner() {
        IMasterChef(stakeRewards).deposit(pid, 0);
        transferEarn2Gatling();
    }
    function earnTokenBalance(address _account) external view override returns (uint256) {
        return IERC20(earnTokenAddr).balanceOf(_account);
    }

    function balanceOfLP(address _account) external view override  returns (uint256) {
        //
        return IMasterChef(stakeRewards).userInfo(pid, _account).amount;
    }
    
    /**
     * withdraw LP && earnToken
     */
    function exit() external override  onlyOwner() {

        withdraw(IMasterChef(stakeRewards).userInfo(pid, address(this)).amount);
        transferLP2Gatling();
        transferEarn2Gatling();
    }
    function transferLP2Gatling() private {

        uint256 _lpAmount = IERC20(stakeLpPair).balanceOf(address(this));
        if(_lpAmount > 0) {
            TransferHelper.safeTransfer(stakeLpPair, stakeGatling, IERC20(stakeLpPair).balanceOf(address(this)));
        }
    }
    function transferEarn2Gatling() private {

        uint256 _tokenAmount = IERC20(earnTokenAddr).balanceOf(address(this));
        if(_tokenAmount > 0) {
            TransferHelper.safeTransfer(earnTokenAddr, address(stakeGatling), _tokenAmount);
        }
    }
}