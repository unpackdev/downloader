// SPDX-License-Identifier: MIT
// @author: https://github.com/SHA-2048

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./ISwapRouter.sol";

contract Controller is Ownable, Pausable {

    struct RewardReceiver {
        address receiver;
        uint share;
    }

    IERC20 public rewardToken;
    address public feeConverter;

    RewardReceiver[] public rewardReceivers;
    ISwapRouter public swapRouter;

    uint public feeConversionIncentive;

    constructor(
        RewardReceiver[] memory _rewardReceivers,
        ISwapRouter _swapRouter,
        uint _feeConversionIncentive,
        IERC20 _rewardToken
    ) {
        rewardToken = _rewardToken;
        feeConversionIncentive = _feeConversionIncentive;
        swapRouter = _swapRouter;

        for(uint i = 0; i < _rewardReceivers.length; i++) {
            rewardReceivers.push(_rewardReceivers[i]);
        }
    }

    function setFeeConverter(address _feeConverter) external onlyOwner {
        feeConverter = _feeConverter;
    }

    function getRewardReceivers() external view returns(RewardReceiver[] memory){
        return rewardReceivers;
    }

    function setRewardReceivers(RewardReceiver[] memory _rewardReceivers) onlyOwner external {
        delete rewardReceivers;

        for(uint i = 0; i < _rewardReceivers.length; i++) {
            rewardReceivers.push(_rewardReceivers[i]);
        }
    }

    function setFeeConversionIncentive(uint _value) onlyOwner external {
        feeConversionIncentive = _value;
    }

    function setRewardToken(IERC20 _token) onlyOwner external {
        rewardToken = _token;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

}
