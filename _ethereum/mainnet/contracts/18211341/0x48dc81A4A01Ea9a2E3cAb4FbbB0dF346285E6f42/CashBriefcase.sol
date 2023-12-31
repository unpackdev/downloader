// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
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
   ____    _    ____  _   _   ____  ____  ___ _____ _____ ____    _    ____  _____ 
  / ___|  / \  / ___|| | | | | __ )|  _ \|_ _| ____|  ___/ ___|  / \  / ___|| ____|
 | |     / _ \ \___ \| |_| | |  _ \| |_) || ||  _| | |_ | |     / _ \ \___ \|  _|  
 | |___ / ___ \ ___) |  _  | | |_) |  _ < | || |___|  _|| |___ / ___ \ ___) | |___ 
  \____/_/   \_\____/|_| |_| |____/|_| \_\___|_____|_|   \____/_/   \_\____/|_____|

    Twitter: https://twitter.com/fraudeth_gg
    Telegram: http://t.me/fraudportal
    Website: https://fraudeth.gg
    Docs: https://docs.fraudeth.gg
  
  */
                                                                                   
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./IBribeToken.sol";
import "./IFraudToken.sol";

contract CashBriefcase is Ownable, ReentrancyGuard {
    IBribeToken public bribe;
    IFraudToken public fraud;
    using SafeMath for uint256;

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastClaim;
    mapping(address => uint256) public lastDeposit;
    mapping(address => uint256) public depositEpoch;

    uint256 public totalDeposits;

    bool public emergencyMode = false;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(address _bribe, address _fraud) {
        bribe = IBribeToken(_bribe);
        fraud = IFraudToken(_fraud);
    }

    function deposit(uint256 _amount) external {
        require(_amount > 0, "Invalid amount");
        require(bribe.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        require(emergencyMode == false, "Contract is in emergency mode, deposits not allowed");
        // transfer the tokens to this contract
        bribe.burn(msg.sender, _amount);

        // update the user's deposit amount and the total deposit amount
        deposits[msg.sender] = deposits[msg.sender].add(_amount);
        lastDeposit[msg.sender] = block.timestamp;

        totalDeposits = totalDeposits.add(_amount);

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        require(deposits[msg.sender] >= _amount, "Withdrawal amount exceeds deposit");
        require(block.timestamp.sub(lastDeposit[msg.sender]) > 6 hours || emergencyMode == true, "Can only withdraw if last deposit was more than 6 hours / 1 epoch");

        // update the user's deposit amount and the total deposit amount
        if(emergencyMode == false && pendingReward(msg.sender) > 0){
            claimReward(msg.sender);
        }

        deposits[msg.sender] = deposits[msg.sender].sub(_amount);
        totalDeposits = totalDeposits.sub(_amount);

        // transfer the tokens back to the user
        bribe.mint(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }

    function claimReward(address user) public nonReentrant {
        require (msg.sender == user, "Only the user can claim their reward");
        require(emergencyMode == false, "Contract is in emergency mode, reward claims not allowed");
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No rewards available");
        require(block.timestamp.sub(lastClaim[msg.sender]) > 1 days, "Can only claim once per day");
        // require last deposit > 6h ago
        require(block.timestamp.sub(lastDeposit[msg.sender]) > 6 hours, "Can only claim if last deposit was more than 6 hours ago");

        // decrease the fraud token balance of the contract
        // and increase the fraud token balance of the user
        fraud.transfer(msg.sender, reward);
        lastClaim[msg.sender] = block.timestamp;
        emit RewardClaimed(msg.sender, reward);
    }

    function pendingReward(address _user) public view returns (uint256) {
        if(block.timestamp.sub(lastClaim[_user]) < 1 days){ return 0; }
        if(block.timestamp.sub(lastDeposit[_user]) < 6 hours){ return 0; }
        if(fraud.balanceOf(address(this)) == 0){ return 0; }
        return calculateReward(_user);
    }

    function calculateReward(address _user) public view returns (uint256) {
        // for example, the user's reward is proportional to their share of the total deposits
        uint256 share = deposits[_user].mul(1e18).div(totalDeposits); // multiply by 1e18 to avoid division truncation
        uint256 reward = fraud.balanceOf(address(this)).mul(share).div(1e18); // divide by 1e18 to correct for the multiplication above
        return reward;
    }

    function getSharePercentage(address _user) public view returns (uint256) {
        if(totalDeposits == 0) return 0;
        uint256 sharePercentage = deposits[_user].mul(1e18).div(totalDeposits);
        return sharePercentage;
    }
    function toggleEmergency() external onlyOwner {
        emergencyMode = !emergencyMode;
    }
}
