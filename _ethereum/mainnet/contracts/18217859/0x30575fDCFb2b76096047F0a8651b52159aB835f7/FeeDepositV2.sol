// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IFeeReceiver.sol";
import "./IVoterProxy.sol";
import "./IBooster.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";



contract FeeDepositV2 {
    using SafeERC20 for IERC20;

    //tokens
    address public constant fxn = address(0x365AccFCa291e7D3914637ABf1F7635dB165Bb09);
    address public immutable vefxnProxy;
    address public immutable cvxfxn;
    
    uint256 public constant denominator = 10000;
    uint256 public platformIncentive = 2000;
    uint256 public vlcvxIncentive = 0;
    address public platformReceiver;
    address public cvxfxnReceiver;
    address public vlcvxReceiver;

    address public rewardToken;

    mapping(address => bool) public requireProcessing;

    event SetPlatformIncentive(uint256 _amount);
    event SetvlCvxIncentive(uint256 _amount);
    event SetPlatformReceiver(address _account);
    event SetCvxFxnReceiver(address _account);
    event SetvlCvxReceiver(address _account);
    event AddDistributor(address indexed _distro, bool _valid);
    event PlatformFeesDistributed(address indexed token, uint256 amount);
    event VlcvxFeesDistributed(address indexed token, uint256 amount);
    event RewardsDistributed(address indexed token, uint256 amount);
    event RewardTokenSet(address indexed token);

    constructor(address _proxy, address _cvxfxn, address _initialReceiver) {
        vefxnProxy = _proxy;
        cvxfxn = _cvxfxn;
        platformReceiver = address(0x1389388d01708118b497f59521f6943Be2541bb7);
        cvxfxnReceiver = _initialReceiver;
        requireProcessing[_initialReceiver] = true;
    }

    modifier onlyOwner() {
        require(IBooster(IVoterProxy(vefxnProxy).operator()).owner() == msg.sender, "!owner");
        _;
    }

    function setRewardToken(address _rToken) external onlyOwner{
        rewardToken = _rToken;
        emit RewardTokenSet(_rToken);
    }

    function setPlatformIncentive(uint256 _incentive) external onlyOwner{
        require(_incentive <= 5000, "too high");
        platformIncentive = _incentive;
        emit SetPlatformIncentive(_incentive);
    }

    function setvlCvxIncentive(uint256 _incentive) external onlyOwner{
        require(_incentive <= 5000, "too high");
        vlcvxIncentive = _incentive;
        emit SetvlCvxIncentive(_incentive);
    }

    function cvxfxnIncentive() external view returns(uint256){
        return denominator - platformIncentive;
    }

    function setPlatformReceiver(address _receiver, bool _requireProcess) external onlyOwner{
        platformReceiver = _receiver;
        requireProcessing[_receiver] = _requireProcess;
        emit SetPlatformReceiver(_receiver);
    }

    function setvlCvxReceiver(address _receiver, bool _requireProcess) external onlyOwner{
        vlcvxReceiver = _receiver;
        requireProcessing[_receiver] = _requireProcess;
        emit SetvlCvxReceiver(_receiver);
    }

    function setCvxFxnReceiver(address _receiver, bool _requireProcess) external onlyOwner{
        cvxfxnReceiver = _receiver;
        requireProcessing[_receiver] = _requireProcess;
        emit SetCvxFxnReceiver(_receiver);
    }

    function rescueToken(address _token, address _to) external onlyOwner{
        require(_token != fxn, "not allowed");

        uint256 bal = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_to, bal);
    }

    function processFees() external {
        require(msg.sender == IVoterProxy(vefxnProxy).operator(), "!auth");

        //get reward amounts
        uint256 platformAmount = IERC20(fxn).balanceOf(address(this)) * platformIncentive / denominator;
        uint256 vlcvxAmount = IERC20(fxn).balanceOf(address(this)) * vlcvxIncentive / denominator;

        uint256 rewardplatformAmount;
        uint256 rewardvlcvxAmount;
        if(rewardToken != address(0)){
            rewardplatformAmount = IERC20(rewardToken).balanceOf(address(this)) * platformIncentive / denominator;
            rewardvlcvxAmount = IERC20(rewardToken).balanceOf(address(this)) * vlcvxIncentive / denominator;
        }

        //process platform incentives
        if(platformAmount > 0 || rewardplatformAmount > 0){
            if(platformAmount > 0){
                IERC20(fxn).safeTransfer(platformReceiver, platformAmount);
                emit PlatformFeesDistributed(fxn,platformAmount);
            }
            if(rewardplatformAmount > 0){
                IERC20(rewardToken).safeTransfer(platformReceiver, rewardplatformAmount);
                emit PlatformFeesDistributed(rewardToken,rewardplatformAmount);
            }
            if(requireProcessing[platformReceiver]){
                IFeeReceiver(platformReceiver).processFees();
            }
        }

        //process vlcvx incentives
        if(vlcvxAmount > 0 || rewardvlcvxAmount > 0){
            if(vlcvxAmount > 0){
                IERC20(fxn).safeTransfer(vlcvxReceiver, vlcvxAmount);
                emit PlatformFeesDistributed(fxn,vlcvxAmount);
            }
            if(rewardvlcvxAmount > 0){
                IERC20(rewardToken).safeTransfer(vlcvxReceiver, rewardvlcvxAmount);
                emit PlatformFeesDistributed(rewardToken,rewardvlcvxAmount);
            }
            if(requireProcessing[vlcvxReceiver]){
                IFeeReceiver(vlcvxReceiver).processFees();
            }
        }

        //send rest to cvxfxn incentives
        uint256 fxnbalance = IERC20(fxn).balanceOf(address(this));
        uint256 rewardbalance;
        if(rewardToken != address(0)){
            rewardbalance = IERC20(rewardToken).balanceOf(address(this));
        }
        if(fxnbalance > 0 || rewardbalance > 0){
            if(fxnbalance > 0){
                IERC20(fxn).safeTransfer(cvxfxnReceiver, fxnbalance);
                emit RewardsDistributed(fxn, fxnbalance);
            }
            if(rewardbalance > 0){
                IERC20(rewardToken).safeTransfer(cvxfxnReceiver, rewardbalance);
                emit RewardsDistributed(rewardToken, rewardbalance);
            }
            if(requireProcessing[cvxfxnReceiver]){
                IFeeReceiver(cvxfxnReceiver).processFees();
            }
        }
    }

}