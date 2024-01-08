// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";

abstract contract BasicBoneDistributor is Ownable {

    using SafeMath for uint256;
    IERC20 public bone;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('receiveApproval(address,uint256,address,uint256)')));
    uint public lockPercentage = 67;

    constructor (IERC20 _bone) public {
        require(address(_bone) != address(0), "_bone is a zero address");
        bone = _bone;
    }

    function boneBalance() external view returns(uint) {
        return bone.balanceOf(address(this));
    }

    function withdrawBone(address _destination, address _lockDestination, uint256 _lockingPeriod, uint256 _amount) external onlyOwner {
        uint256 _lockAmount = _amount.mul(lockPercentage).div(100);
        require(bone.transfer(_destination, _amount.sub(_lockAmount)), "transfer: withdraw failed");
        if(_lockAmount != 0){
            approveAndCall(_lockDestination, _lockAmount, _lockingPeriod);
        }
    }

    function approveAndCall(address _spender, uint256 _value, uint256 _lockingPeriod) internal returns (bool success) {
        bone.approve(_spender, _value);
        (bool thisSuccess,) = _spender.call(abi.encodeWithSelector(SELECTOR, bone, _value, address(this), _lockingPeriod));
        require(thisSuccess, "Spender- receiveApproval failed");
        return true;
    }

    function setLockPercentage(uint _lockPercentage) external onlyOwner {
        lockPercentage = _lockPercentage;
    }
}
