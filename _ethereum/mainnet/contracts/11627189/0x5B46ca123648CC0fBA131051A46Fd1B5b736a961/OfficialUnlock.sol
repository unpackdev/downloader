pragma solidity ^0.5.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract OfficialUnlock {
    using SafeMath for uint256;
    uint256 public totalRewards = (6000000 - 2400) * 1e18;
    uint256 public startTime;
    address public pegs;
    uint256 private lockDuration = 180 days;
    uint256 public receivedTimes;
    address public owner;
    address public team1;
    address public team2;
   

    constructor(address _pegs,address _team1,address _team2) public {
        owner = msg.sender;
        pegs = _pegs;
        startTime = 1610323200;
        team1 = _team1;
        team2 = _team2;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    function unlockRewards() public onlyOwner {
        uint256 _now = block.timestamp;
        require(_now.sub(startTime) >= lockDuration, "The reward is still locked!");
        require(receivedTimes <= 12, "Reward has been collected!");
        uint256 times = _now.sub(startTime).sub(lockDuration).div(30 days);
        uint256 rewardAmount = times.sub(receivedTimes).mul(totalRewards.div(12));
        receivedTimes = times;
        IERC20(pegs).transfer(team1, rewardAmount.mul(60).div(100));
        IERC20(pegs).transfer(team2, rewardAmount.mul(40).div(100));
    }

    function setRewardAddressTeam1(address _team1) public onlyOwner {
       team1 = _team1;
    }

    function setRewardAddressTeam2(address _team2) public onlyOwner {
       team2 = _team2;
    }

    function getRemainingRewards() public view returns(uint256 remainingRewards){
      remainingRewards =  IERC20(pegs).balanceOf(address(this));
    }

}