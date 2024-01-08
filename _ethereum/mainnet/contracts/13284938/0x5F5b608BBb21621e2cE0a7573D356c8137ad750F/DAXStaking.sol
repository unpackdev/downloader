pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./SafeMath.sol";
import "./DAX.sol";

contract DragonXStaking is AccessControl {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    DAX public DAX_TOKEN = DAX(0x77E9618179820961eE99a988983BC9AB41fF3112);
    
    struct Stake {
        address staker;
        uint256 amount;
        uint256 timestamp;
        uint256 bonded;
    }
    
    uint256 public APY = 1000;
    uint256 public bondingPeriod = 60;
    uint256 public totalStaked = 0;
    uint256 public totalRewards = 0;
    
    string public name;

    address[] public stakers;  // this can be done  by mapping may be used to get total number of stakers
    mapping(address => Stake) public stakes;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Rewarded(address indexed user, uint256 amount);

    constructor(string memory _name) {
        name = _name;
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    function setRate(uint256 _newAPY) external onlyRole(ADMIN_ROLE) {
        require(_newAPY < 10000, "Hard limit 10,000");
        APY = _newAPY;
    }
    
    function setBond(uint256 _bondingPeriod) external onlyRole(ADMIN_ROLE) {
        bondingPeriod = _bondingPeriod;
    }
    
    function addStaker() internal {
        for (uint16 i = 0; i < stakers.length; i += 1) { // exit if staker already exists in pool
            if (msg.sender == stakers[i]) {
                return;
            }
        }
        stakers.push(msg.sender); // add staker
    }
    
    function timeStaked() external view returns(uint256) {
        Stake memory s = myStake(); 
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime.sub(s.timestamp);
        return timeElapsed;
    }
    
    function myStake() public view returns(Stake memory) {
        return stakes[msg.sender];
    }
    
    function totalStakers() external view returns(uint256) {
        return stakers.length;
    }
    
    function stake(uint256 _amount) external {
        require(_amount > 0, "stakable amount less than 0"); // require > 0 DAX
        addStaker(); // add staker to array
        uint256 alreadyStaked = stakes[msg.sender].amount; // append existing stake if exists
        DAX_TOKEN.transferFrom(msg.sender, address(this), _amount); // transfer stake
        if (reward() > 0) { // reward if rewards 
            withdrawRewards();
        }
        stakes[msg.sender] = Stake(msg.sender, _amount.add(alreadyStaked), block.timestamp, block.timestamp); // add stake to stake array
        totalStaked = totalStaked.add(_amount); // increment total staked in pool (TVL)
        
        emit  Deposit(msg.sender, _amount);
    }
    
    function bondRemaining() external view returns(uint256) {
        Stake memory s = myStake();
        if (block.timestamp > s.bonded) { // prevent negative overflow
            if (bondingPeriod > (block.timestamp.sub(s.bonded))) {
                return bondingPeriod.sub(block.timestamp.sub(s.bonded));
            }
            else {
                return 0;
            }
        }
        else {
            return 0;
        }
    }
    
    function pullStake() external {
        Stake memory s = myStake(); 
        uint256 currentTime = block.timestamp; // get current time in seconds
        uint256 timeElapsed = currentTime.sub(s.bonded); // calculate time elapsed since stake created or rewards last withdrawn
        require(timeElapsed >= bondingPeriod, "Cannot pull stake until bonding period has expired.");
        withdrawRewards(); // redeem rewards
        stakes[msg.sender] = Stake(msg.sender, 0, 0, 0);
        DAX_TOKEN.transfer(msg.sender, s.amount); // withdraw stake

        emit Withdraw(msg.sender, s.amount);
    }
    
    function reward() public view returns(uint256)  {
        Stake memory s = myStake(); 
        if (s.amount > 0) { // staking
            uint256 currentTime = block.timestamp; // get current time in seconds
            uint256 timeElapsed = currentTime.sub(s.timestamp); // calculate time elapsed since stake created or rewards last withdrawn
            uint256 r = s.amount.mul(timeElapsed).div(31557600); // calculate rewards relative to number of seconds in a year (31557600)
            r = r.mul(APY).div(100); // calculate rewards according to APY
            return r;
        }
        else { // not staking
            return 0;
        }
    }
    
    function withdrawRewards() public {
        uint256 r = reward(); // get staking rewards
        stakes[msg.sender].timestamp = block.timestamp; // set timestamp to now to reset rewards algo
        DAX_TOKEN.mint(msg.sender, r); // mint rewards to staker wallet
        totalRewards = totalRewards.add(r);

        emit Rewarded(msg.sender, r);
    }
}
