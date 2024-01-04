pragma solidity ^0.6.0;

import "./IMuse.sol";
import "./SafeMath.sol";

contract Vesting {
    using SafeMath for uint256;

    IMuse public token;

    uint256 public duration = 365;
    uint256 public timeStarted;

    address public dao = 0x0f4676178b5c53Ae0a655f1B19A96387E4b8B5f2;
    address public a = 0x230A9678009e797a8ea77D449a18C28A25b363dd;
    address public b = 0x889551682afc348e298Cf1BbB2D981592409C9D0;
    uint256 public paid;
    mapping(address => uint256) public shouldGet;

    address owner;

    constructor(address _token) public {
        timeStarted = now;
        token = IMuse(_token);
        owner = msg.sender;
        shouldGet[dao] = 100000 * 10**18;
    }

    // only daves wallet can cashout this vested allocation as it's for dao and daves.
    function claimVestedTokens() external {
        require(owner == msg.sender, "!forbidden");
        require(shouldGet[dao] >= paid, "Finished vesting");
        uint256 _amount = getAllocation();

        if (paid + _amount >= 100000 * 10**18) {
            // Case where we didnd withdraw all but passed the 1 year
            _amount = 100000 * 10**18 - paid;
        }
        paid += _amount;

        uint256 eachShares = _amount.div(2);

        token.mint(a, eachShares);
        token.mint(b, eachShares);
        // send vest to contract wallet for future dao
        token.mint(dao, _amount);
    }

    //@TODO check my math
    function getAllocation() public view returns (uint256) {
        uint256 perDay = shouldGet[dao].div(duration);
        uint256 daysPassed = (now.sub(timeStarted)).div(1 days);
        uint256 amount = (daysPassed.mul(perDay)).sub(paid);
        return amount;
    }
}
