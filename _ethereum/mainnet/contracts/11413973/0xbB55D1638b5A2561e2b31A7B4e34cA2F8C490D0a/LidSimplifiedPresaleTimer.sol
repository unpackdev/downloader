pragma solidity 0.5.16;

import "./SafeMath.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Initializable.sol";


contract LidSimplifiedPresaleTimer is Initializable, Ownable {
    using SafeMath for uint;

    uint public startTime;
    uint public endTime;
    uint public softCap;
    address public presale;

    uint public refundTime;
    uint public maxBalance;

    function initialize(
        uint _startTime,
        uint _refundTime,
        uint _endTime,
        uint _softCap,
        address _presale,
        address owner
    ) external initializer {
        Ownable.initialize(msg.sender);
        startTime = _startTime;
        refundTime = _refundTime;
        endTime = _endTime;
        softCap = _softCap;
        presale = _presale;
        //Due to issue in oz testing suite, the msg.sender might not be owner
        _transferOwnership(owner);
    }

    function setStartTime(uint time) external onlyOwner {
        startTime = time;
    }

    function setRefundTime(uint time) external onlyOwner {
        refundTime = time;
    }

    function setEndTime(uint time) external onlyOwner {
        endTime = time;
    }

    function updateSoftCap(uint valueWei) external onlyOwner {
        softCap = valueWei;
    }

    function updateRefunding() external returns (bool) {
        if (maxBalance < presale.balance) maxBalance = presale.balance;
        if (maxBalance < softCap && now > refundTime) return true;
        return false;
    }

    function isStarted() external view returns (bool) {
        return (startTime != 0 && now > startTime);
    }

}
