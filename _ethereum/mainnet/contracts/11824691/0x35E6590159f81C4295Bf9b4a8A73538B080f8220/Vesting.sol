pragma solidity ^0.6.0;

import "./IMuse.sol";
import "./SafeMath.sol";

contract Vesting {
    using SafeMath for uint256;

    IMuse public token;

    uint256 public duration = 365 days;
    uint256 public timeStarted;

    address public dao = 0x0f4676178b5c53Ae0a655f1B19A96387E4b8B5f2;

    uint256 public paid;
    mapping(address => uint256) public shouldGet;

    address owner;

    constructor(IMuse _token) public {
        timeStarted = now;
        token = IMuse(_token);
        owner = msg.sender;
        shouldGet[owner] = 100000 * 10**18;
        shouldGet[dao] = 100000 * 10**18;
    }

    // only daves wallet can cashout this vested allocation as it's for dao and daves.

    function claimVestedTokens() external {
        require(owner == msg.sender);
        require(shouldGet[msg.sender] >= paid, "Finished vesting");
        uint256 _amount = getAllocation();
        paid += _amount;
        // send ves to daves wallet
        token.mint(owner, _amount);
        // send vest to contract wallet for future dao
        token.mint(dao, _amount);
    }

    //@TODO check my math
    function getAllocation() public view returns (uint256) {
        uint256 perDay = shouldGet[msg.sender].div(duration);
        uint256 daysPassed = (now.sub(timeStarted)).div(1 days);
        uint256 amount = (daysPassed.mul(perDay)).sub(paid);
        return amount;
    }
}
