// SPDX-License-Identifier: UNLICENSED
/*
* Author: luc.vutien
* @dev: Lock timer for the upgradable proxy standard
* Add new modifier that check the lock
* Require admin to pause
* Note: Please follow the standard of upgradable proxy,
*       If you have to define any variable then do it as below, dont create new variables
*       That not follow unstructured EIP1967
*/
pragma solidity ^0.8.0;
import "./Ownable.sol";

contract LockTimer is Ownable{

    // Create random position by keccak256 hashing
    bytes32 private constant pausedAtPosition = bytes32(uint256(keccak256('pausedAt')));
    bytes32 private constant delayTimePosition = bytes32(uint256(keccak256('delayTime')));

    event SetDelayTime(uint256 delayTime);

    modifier isAbleToWithdraw(){
        uint256 delayTime = _getDelayTime();
        uint256 pausedAt = _getPausedAt();
        // if delayTime has not been set yet then set to 1800 secs
        if (delayTime == 0) {
            delayTime = 1800;
        }
        require(block.timestamp - pausedAt >= delayTime, "Must wait for certain amount of time");
        _;
    }
    
    function _getPausedAt() internal view returns(uint256 time) {
        bytes32 position = pausedAtPosition;

        assembly{
            time:=sload(position)
        }
    }    

    function _setPausedAt() internal{
         bytes32 current = bytes32(block.timestamp);
         bytes32 position = pausedAtPosition;
         assembly {
            sstore(position, current)
        } 
    }

    function _getDelayTime() internal view returns(uint256 time) {
        bytes32 position = delayTimePosition;

        assembly{
            time:=sload(position)
        }
    }
    
    function _setDelayTime(uint256 delayInSecs) internal{
        require(delayInSecs >= 600, "Please set it more than 10 mins");
        require(delayInSecs <= 3600 * 24 * 7 , "Please set it less than 1 week");
        bytes32 position = delayTimePosition;
        assembly {
            sstore(position, delayInSecs)
        }
        emit SetDelayTime(delayInSecs);
    }

}