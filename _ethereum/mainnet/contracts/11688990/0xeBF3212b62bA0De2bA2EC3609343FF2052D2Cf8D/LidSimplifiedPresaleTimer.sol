pragma solidity 0.5.16;

import "./SafeMath.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Initializable.sol";

contract LidSimplifiedPresaleTimer is Initializable, Ownable {
    using SafeMath for uint256;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public softCap;
    address public presale;

    uint256 public refundTime;
    uint256 public maxBalance;

    function initialize(
        uint256 _startTime,
        uint256 _refundTime,
        uint256 _endTime,
        uint256 _softCap,
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

    function setStartTime(uint256 time) external onlyOwner {
        startTime = time;
    }

    function setRefundTime(uint256 time) external onlyOwner {
        refundTime = time;
    }

    function setEndTime(uint256 time) external onlyOwner {
        endTime = time;
    }

    function updateSoftCap(uint256 valueWei) external onlyOwner {
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
