// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⢦⡀⠉⠙⢦⡀⠀⠀⣀⣠⣤⣄⣀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣀⡤⠤⠴⠶⠤⠤⢽⣦⡀⠀⢹⡴⠚⠁⠀⢀⣀⣈⣳⣄⠀⠀
⠀⠀⠀⠀⠀⢠⠞⣁⡤⠴⠶⠶⣦⡄⠀⠀⠀⠀⠀⠀⠀⠶⠿⠭⠤⣄⣈⠙⠳⠀
⠀⠀⠀⠀⢠⡿⠋⠀⠀⢀⡴⠋⠁⠀⣀⡖⠛⢳⠴⠶⡄⠀⠀⠀⠀⠀⠈⠙⢦⠀
⠀⠀⠀⠀⠀⠀⠀⠀⡴⠋⣠⠴⠚⠉⠉⣧⣄⣷⡀⢀⣿⡀⠈⠙⠻⡍⠙⠲⢮⣧
⠀⠀⠀⠀⠀⠀⠀⡞⣠⠞⠁⠀⠀⠀⣰⠃⠀⣸⠉⠉⠀⠙⢦⡀⠀⠸⡄⠀⠈⠟
⠀⠀⠀⠀⠀⠀⢸⠟⠁⠀⠀⠀⠀⢠⠏⠉⢉⡇⠀⠀⠀⠀⠀⠉⠳⣄⢷⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡾⠤⠤⢼⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡇⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠉⠉⠉⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣀⣀⣀⣻⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣀⣀⡤⠤⠤⣿⠉⠉⠉⠘⣧⠤⢤⣄⣀⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢀⡤⠖⠋⠉⠀⠀⠀⠀⠀⠙⠲⠤⠤⠴⠚⠁⠀⠀⠀⠉⠉⠓⠦⣄⠀⠀⠀
⢀⡞⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⣄⠀
⠘⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠚⠀
  ____    _    _     ___ 
 | __ )  / \  | |   |_ _|
 |  _ \ / _ \ | |    | | 
 | |_) / ___ \| |___ | | 
 |____/_/   \_\_____|___|

  Twitter: https://twitter.com/fraudeth_gg
  Telegram: http://t.me/fraudportal
  Website: https://fraudeth.gg
  Docs: https://docs.fraudeth.gg
*/       
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IFraudToken.sol";

contract Bali is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    IFraudToken public fraud;
    address public lpToken;
    bool public emergencyMode = false;
    
    struct UserInfo {
        uint256 deposit;
        uint256 lockEndedTimestamp;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => uint256) public lastClaim;
    mapping(address => uint256) public lastDeposit;

    uint256 public totalDeposits;
    uint256 public totalFraudReward;
    // Lock-up period (in seconds)
    uint256 public lockupPeriod;
    // Timestamp when the contract was deployed
    uint256 public contractStartTime;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount, uint256 rewards);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(
        IFraudToken _fraud,
        address _lpToken
    ) {
        fraud = _fraud;
        lpToken = _lpToken;
        contractStartTime = block.timestamp;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        require(IERC20(lpToken).balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(emergencyMode == false, "Contract is in emergency mode, deposits not allowed");
        UserInfo storage user = userInfo[msg.sender];
        IERC20(lpToken).transferFrom(msg.sender, address(this), amount);

        user.deposit = user.deposit.add(amount);
        lastDeposit[msg.sender] = block.timestamp;

        user.lockEndedTimestamp = block.timestamp.add(60 hours);
        totalDeposits = totalDeposits.add(amount);

        emit Deposit(msg.sender, amount);
    }

    // Withdraw LP tokens and earned APR tokens
    function withdraw(uint256 amount) external {
        require(amount > 0, "Invalid amount");

        UserInfo storage user = userInfo[msg.sender];
        require(user.deposit > 0, "No balance to withdraw");
        require(user.deposit >= amount, "Not enough balance");
        require(user.lockEndedTimestamp <= block.timestamp || emergencyMode == true, "Still locked");

        uint256 rewards = 0;
        if(emergencyMode == false && pendingReward(msg.sender) > 0){
        //Claim APR rewards
            rewards = claimReward();
        }
        
        // Transfer LP tokens back to the user
        IERC20(lpToken).transfer(msg.sender, amount);
        
        // Reset user balance
        user.deposit = user.deposit.sub(amount);
        totalDeposits = totalDeposits.sub(amount);
        emit Withdraw(msg.sender, amount, rewards);
    }

    function claimReward() public nonReentrant returns(uint256){
        require(emergencyMode == false, "Contract is in emergency mode, reward claims not allowed");
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No reward available");
        require(block.timestamp.sub(lastClaim[msg.sender]) > 1 days, "Can only claim once per day");
        // require last deposit > 6h ago
        require(block.timestamp.sub(lastDeposit[msg.sender]) > 6 hours, "Can only claim if last deposit was more than 6 hours ago");

        // decrease the fraud token balance of the contract
        // and increase the fraud token balance of the user
        fraud.transfer(msg.sender, reward);
        lastClaim[msg.sender] = block.timestamp;
        totalFraudReward = totalFraudReward.sub(reward);
        return reward;
    }

    function pendingReward(address _user) public view returns (uint256) {
        if(block.timestamp.sub(lastClaim[_user]) < 1 days){ return 0; }
        if(block.timestamp.sub(lastDeposit[_user]) < 6 hours){ return 0; }
        if(fraud.balanceOf(address(this)) == 0){ return 0; }
        return calculateReward(_user);
    }

    function calculateReward(address _user) public view returns (uint256) {
        // for example, the user's reward is proportional to their share of the total deposits
        uint256 share = userInfo[_user].deposit.mul(1e18).div(totalDeposits); // multiply by 1e18 to avoid division truncation
        uint256 reward = totalFraudReward.mul(share).div(1e18); // divide by 1e18 to correct for the multiplication above
        return reward;
    }

    function setTotalReward(uint256 _amount) external onlyOwner {
        require(_amount <= fraud.balanceOf(address(this)), "Not enough fraud tokens");
        totalFraudReward = _amount;
    }

    function toggleEmergency() external onlyOwner {
        emergencyMode = !emergencyMode;
    }

    receive() external payable {}
}
