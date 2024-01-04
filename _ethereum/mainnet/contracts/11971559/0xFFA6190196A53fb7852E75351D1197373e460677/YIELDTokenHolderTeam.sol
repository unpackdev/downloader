// SPDX-License-Identifier: MIT
pragma solidity =0.7.4;

import "./ReentrancyGuard.sol";
import "./SafeMath.sol";


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}


contract YIELDTokenHolderTeam is ReentrancyGuard {
    using SafeMath for uint256;

    struct TeamOptions {
        uint256 perMonth;
        uint256 maxCap;
        uint256 sent;
    }

    mapping(address => TeamOptions) public team;

    uint256 public constant releasesMonths = 10;
    uint256 public constant fullLockMonths = 6;
    uint256 public createdAt;//counter start
    string public constant name = "Yield Protocol - Team";

    uint256 public perMonth;
    uint256[] public perMonthCustom;

    
    address public yieldTokenAddress;

    constructor (address _yieldTokenAddress) {
        yieldTokenAddress = _yieldTokenAddress;
        createdAt = block.timestamp;

        team[0x8eb62f29886c3d69Da21e7DdfB13EFCC9EB3E0FD] = TeamOptions(1809865 ether, 18098650 ether, 0);
        team[0xD80B0ECD49e1442f71dc6A5bD63E2DE3604a3c9D] = TeamOptions(468651 ether, 4686510 ether, 0);
        team[0xba9F77bB2eFDF3F4Ee377f46D20926C6A82bA4c3] = TeamOptions(235084 ether, 2350840 ether, 0);
    }

    /**
    @notice This function is used to return amout of available tokens
    @return amount of tokens that can be sent instantly by "send" function 
    */
   function getAvailableTokens(address _address) public view  returns (uint256) {

        //2592000 = 1 month;
        //months variable starts from 0; 
        uint256 months = block.timestamp.sub(createdAt).div(2592000);

        if(months >= fullLockMonths+releasesMonths){//lock is over, we can unlock everything we have
            return team[_address].maxCap.sub(team[_address].sent);
        }else if(months < fullLockMonths){
            //too early, tokens are still under full lock;
            return 0;
        }

        //+1 due to beginning of a month
        uint256 potentialAmount;
        potentialAmount = (months-fullLockMonths+1).mul(team[_address].perMonth);
        return potentialAmount.sub(team[_address].sent);
    }

    /**
    @notice This function is used to claim unlocked tokens
    @param to is a distination address
    @param amount how many tokens to sent
    */
    function claim(address to, uint256 amount) nonReentrant external {
        require(getAvailableTokens(msg.sender) >= amount, "available amount is less than requested amount");
        team[msg.sender].sent = team[msg.sender].sent.add(amount);
        IERC20(yieldTokenAddress).transfer(to, amount);
    }

}