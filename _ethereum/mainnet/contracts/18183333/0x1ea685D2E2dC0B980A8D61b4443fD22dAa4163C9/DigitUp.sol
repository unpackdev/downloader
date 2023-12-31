pragma solidity ^0.8.0;

contract DigitUp {
    uint256 public totalSupply = 10000000 * 10 ** 18;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public stakingBalance;
    mapping(address => uint8) public adBoostLevel; // 0: No boost, 1: Level 1, 2: Level 2, 3: Level 3
    address public owner;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event AdBoosted(address indexed user, uint8 level);

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function stakeTokens(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        stakingBalance[msg.sender] += _amount;
        emit Staked(msg.sender, _amount);
    }

    function unstakeTokens(uint256 _amount) public {
        require(stakingBalance[msg.sender] >= _amount, "Insufficient staked balance");
        stakingBalance[msg.sender] -= _amount;
        balances[msg.sender] += _amount;
        emit Unstaked(msg.sender, _amount);
    }

    function setAdBoostLevel(uint8 _level) public onlyOwner {
        require(_level <= 3, "Invalid level. Must be between 0 and 3.");
        adBoostLevel[msg.sender] = _level;
        emit AdBoosted(msg.sender, _level);
    }

    function calculateRewards(address _user) public view returns(uint256) {
        uint256 baseReward = stakingBalance[_user]; // Replace with your reward calculation logic
        uint256 boostMultiplier = 1 + adBoostLevel[_user]; // 1x for Level 0, 2x for Level 1, 3x for Level 2, 4x for Level 3
        uint256 boostedReward = baseReward * boostMultiplier;
        return boostedReward;
    }
}