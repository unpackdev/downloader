//SPDX-License-Identifier: MIT

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
  _____  _    __  __  _   _    ___     _______ _   _ ____            
 |_   _|/ \   \ \/ / | | | |  / \ \   / / ____| \ | / ___| 
   | | / _ \   \  /  | |_| | / _ \ \ / /|  _| |  \| \___ \ 
   | |/ ___ \  /  \  |  _  |/ ___ \ V / | |___| |\  |___) |
   |_/_/   \_\/_/\_\ |_| |_/_/   \_\_/  |_____|_| \_|____/ 


    Twitter: https://twitter.com/fraudeth_gg
    Telegram: http://t.me/fraudportal
    Website: https://fraudeth.gg
    Docs: https://docs.fraudeth.gg                                                         
*/
pragma solidity ^0.8.19;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./ABDKMath64x64.sol";

import "./IFraudToken.sol";
import "./IBribeToken.sol";
import "./IFraudVRF.sol";

contract TaxHavens is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // FRAUD
    IFraudToken public fraud;
    // Bribe
    IBribeToken public bribe;
    // VRF
    IFraudVRF public vrf;
    // Eth
    IERC20 public eth; 

    struct VenezuelaStakerInfo {
        uint256 amount;
        uint256 dailyReward;
        uint256 delayedReward;
        uint256 rewardWithdrawn;
        uint256 rewardTaxed;
        uint256 lockEndedTimestamp;
        uint256 startTimestamp;
        uint256 rebaseEpoch; 
        uint256 totalDeposit;
    }

    struct PanamaStakerInfo {
        uint256 amount;
        uint256 lockEndedTimestamp;
        uint256 startTimestamp;
        uint256 rebaseEpoch;  
    }

    struct PricePoint {
        uint256 timestamp;
        uint256 price;
    }

    address public fraudpair;
    address public bribepair;
    address public marketingAddr;
    address public cashBriefCaseAddr;
    address public pureBribingAddr;

    uint256 constant public MAX_INT_TYPE = type(uint256).max;
    uint256 public randomNumber;
    uint256 public totalStackedVenezuela;
    uint256 public totalStackedPanama;
    uint256 public totalTaxedVenezuela;
    uint256 public totalTaxedPanama;
    uint256 public vrfFee;

    uint256 public currentFraudIndex = 0;
    uint256 public currentBribeIndex = 0;

    uint256 public lastUpdateTimeBribe = 0;
    uint256 public lastUpdateTimeFraud = 0;

    uint256 constant INTERVAL = 30 minutes;

    uint256 public totalFraudDataPoints = 0;
    uint256 public totalBribeDataPoints = 0;

    bool public emergencyMode = false;

    PricePoint[48] public fraudPrices;
    PricePoint[48] public bribePrices;

    mapping(address => VenezuelaStakerInfo) public venezuelaStakerInfo;
    mapping(address => PanamaStakerInfo) public panamaStakerInfo;

    // Events
    event DepositPanama(address indexed user, uint256 amount);
    event DepositVenezuela(address indexed user, uint256 amount);
    event WithdrawPanama(address indexed user, uint256 amount, bool isTaxed);
    event WithdrawVenezuela(address indexed user, uint256 amount, bool isTaxed);
    event RewardPaid(address indexed user, uint256 amount);
    event RewardTaxed(address indexed user, uint256 amount);
    event FeeWithdrawn(address indexed user, uint256 amount);
    event RandomNumberRequested(address indexed user);

    constructor(
        IFraudToken _fraud,
        IBribeToken _bribe, 
        IERC20 _eth,
        address _marketingAddr,
        address _cashBriefCaseAddr,
        address _pureBribingAddr
    ) Ownable() ReentrancyGuard() {
        fraud = _fraud;
        bribe = _bribe;
        eth = _eth;
        marketingAddr = _marketingAddr;
        cashBriefCaseAddr = _cashBriefCaseAddr;
        pureBribingAddr = _pureBribingAddr;
        vrfFee = 0.0065 ether;
    }

    function depositPanama(uint256 _amount) external nonReentrant onlyNonEmergencyMode {
        require(_amount > 0, "Invalid amount");
        require(_amount <= fraud.balanceOf(msg.sender), "Not enough FRAUD tokens");

        PanamaStakerInfo storage user = panamaStakerInfo[msg.sender];

        if(user.amount > 0) {
            uint256 currentEpoch = fraud.getCurrentEpoch();
            uint256 epochsElapsed = currentEpoch.sub(user.rebaseEpoch);
            uint256 rebaseFactor = 1 ether;  // Start with 1 for multiplication
            for (uint256 i = 0; i < epochsElapsed; i++) {
                rebaseFactor = rebaseFactor.mul(975).div(1000);  // Decrease by 2.5% each epoch
            }

            // Rebase user's amount
            uint256 debasedAmount = _amount.mul(rebaseFactor).div(1 ether);
            user.amount = debasedAmount; 
        }

        user.amount = user.amount.add(_amount);
        user.lockEndedTimestamp = block.timestamp.add(1 days);
        user.startTimestamp = block.timestamp;
        user.rebaseEpoch = fraud.getCurrentEpoch();  
        totalStackedPanama = totalStackedPanama.add(_amount);
        fraud.burn(msg.sender, _amount);

        emit DepositPanama(msg.sender, _amount);
    }

    function withdrawPanama() external payable nonReentrant {
        PanamaStakerInfo storage user = panamaStakerInfo[msg.sender];
        require(user.lockEndedTimestamp <= block.timestamp, "Still locked");
        require(user.amount > 0, "No deposit made");
        require(address(vrf) != address(0), "VRF not set");
        require(msg.value >= vrfFee, "Not enough ETH for VRF fee");
        // vault = 0 for Panama, 0 = 0 reward
        vrf.requestRandomWords(0, 0, msg.sender);
        emit RandomNumberRequested(msg.sender);
    }

    function withdrawPanamaEmergency() external nonReentrant {
        require(emergencyMode == true, "Not in emergency mode");
        PanamaStakerInfo storage user = panamaStakerInfo[msg.sender];
        require(user.amount > 0, "No deposit made");
        withdrawPanamaVrf(msg.sender, 25);
    }

    function withdrawPanamaVrf(address _user, uint256 _randNum) public onlyVRF {
        PanamaStakerInfo storage user = panamaStakerInfo[_user];

        bool isTaxed = false;
        // Calculate the rebase factor
        uint256 currentEpoch = fraud.getCurrentEpoch();
        uint256 epochsElapsed = currentEpoch.sub(user.rebaseEpoch);
        uint256 rebaseFactor = 1 ether;  // Start with 1 for multiplication
        if(epochsElapsed < 4){
            for (uint256 i = 0; i < epochsElapsed; i++) {
                rebaseFactor = rebaseFactor.mul(975).div(1000);  // Decrease by 2.5% each epoch
            }
        } else {
            for (uint256 i = 0; i < 4; i++) {
                rebaseFactor = rebaseFactor.mul(975).div(1000);  // Decrease by 2.5% each epoch
            }
        }

        // Rebase user's amount
        uint256 debasedAmount = user.amount.mul(rebaseFactor).div(1 ether);

        if(epochsElapsed > 4){
            uint256 epochRebased = epochsElapsed.sub(4);
            uint256 rebaseFactorPost = 1 ether;  // Start with 1 for multiplication

            for (uint256 i = 0; i < epochRebased; i++) {
                rebaseFactorPost = rebaseFactorPost.mul(900).div(1000);  // Decrease by 10% each epoch
            }

            debasedAmount = debasedAmount.mul(rebaseFactorPost).div(1 ether);
        }

        // Check if user will be taxable he has a 20% chance of getting taxed 50% of his debased amount

        if(_randNum < 20) {  
            uint256 taxAmount = debasedAmount.div(2);
            taxAmountToTaxOffice(taxAmount, 0);
            debasedAmount = debasedAmount.sub(taxAmount);
            isTaxed = true;
        }

        fraud.mint(_user, debasedAmount);  // Mint rebased amount to the user

        totalStackedPanama = totalStackedPanama.sub(user.amount);
        user.amount = 0;

        emit WithdrawPanama(_user, debasedAmount, isTaxed);
    }

    function depositVenezuela(uint256 _amount) external nonReentrant onlyNonEmergencyMode {
        require(_amount > 0, "Invalid amount");
        require(_amount <= fraud.balanceOf(msg.sender), "Not enough FRAUD tokens");
        
        VenezuelaStakerInfo storage user = venezuelaStakerInfo[msg.sender];

        if(user.amount > 0){
            uint256 currentEpoch = fraud.getCurrentEpoch();
            uint256 epochsElapsed = currentEpoch.sub(user.rebaseEpoch);
            uint256 rebaseFactor = 1 ether; // Start with 1 for multiplication
            
            for (uint256 i = 0; i < epochsElapsed; i++) {
                rebaseFactor = rebaseFactor.mul(900).div(1000);  // Decrease by 10% each epoch
            }

            // Rebase user's amount
            uint256 debasedAmount = user.amount.mul(rebaseFactor).div(1 ether);
            uint256 reward = calculateReward(msg.sender, debasedAmount);
            user.amount = debasedAmount;  
            user.delayedReward = reward;    
        }

        user.amount = user.amount.add(_amount);
        user.lockEndedTimestamp = block.timestamp.add(6 hours);
        user.startTimestamp = block.timestamp;
        user.rebaseEpoch = fraud.getCurrentEpoch(); 
        //Calculate daily rewards
        uint256 dailyReward = calculateDailyReward(_amount);
        user.dailyReward = dailyReward;

        totalStackedVenezuela = totalStackedVenezuela.add(_amount);
        //Burn tokens
        fraud.burn(msg.sender, _amount);
        emit DepositVenezuela(msg.sender, _amount);
    }

    function withdrawVenezuela() external payable nonReentrant{
        VenezuelaStakerInfo storage user = venezuelaStakerInfo[msg.sender];
        require(user.lockEndedTimestamp <= block.timestamp, "Still locked");
        require(user.amount > 0, "No deposit made");
        require(address(vrf) != address(0), "VRF not set");
        require(msg.value >= vrfFee, "Not enough ETH for VRF fee");
        // vault 1 for Venezuela, 0 = 0 reward
        vrf.requestRandomWords(1, 0, msg.sender);
        emit RandomNumberRequested(msg.sender);
    }

    function withdrawVenezuelaEmergency() external nonReentrant {
        require(emergencyMode == true, "Not in emergency mode");
        VenezuelaStakerInfo storage user = venezuelaStakerInfo[msg.sender];
        require(user.amount > 0, "No deposit made");
        withdrawVenezuelaVrf(msg.sender, 69, 69);
    }

    function withdrawVenezuelaVrf(address _user, uint256 randNum, uint256 randNum2) public onlyVRF {
        // We get the user's staking info
        VenezuelaStakerInfo storage user = venezuelaStakerInfo[_user];
        // Declare a bool to check if the user will be taxed
        bool isTaxed = false;
        // Get the current epoch
        uint256 currentEpoch = fraud.getCurrentEpoch();
        // Calculate the epoch elapsed
        uint256 epochsElapsed = currentEpoch.sub(user.rebaseEpoch);
        // Declare a rebase factor
        uint256 rebaseFactor = 1 ether; // Start with 1 for multiplication
        
        for (uint256 i = 0; i < epochsElapsed; i++) {
            rebaseFactor = rebaseFactor.mul(900).div(1000);  // Decrease by 10% each epoch
        }

        // Rebase user's amount
        uint256 debasedAmount = user.amount.mul(rebaseFactor).div(1 ether);
        // Calculate the reward
        uint256 reward = calculateReward(_user, debasedAmount);
        if(emergencyMode == false){
            if(reward >= 1 ether){
                // Wa add delayed reward to the reward
                reward = reward.add(user.delayedReward);
                claimBribeReward(_user, reward, randNum2);
            }
    
            if (randNum < 33) {  
                isTaxed = true;
            }
        }

        if(isTaxed == false){
            fraud.mint(_user, debasedAmount);
        } else 
        {
            taxAmountToTaxOffice(debasedAmount, 1);
        }
            
        totalStackedVenezuela = totalStackedVenezuela.sub(user.amount);

        user.amount = 0;

        emit WithdrawVenezuela(_user, debasedAmount, isTaxed);
    }

    function taxAmountToTaxOffice(uint256 _debasedAmount, uint256 vault) internal {
        // 75% Bribing system 
        uint256 bribingSystemAmount = _debasedAmount.mul(75).div(100);
        // 70% of the 75% Bribing System
        uint256 cashBriefcaseAmount = bribingSystemAmount.mul(70).div(100);
        fraud.mint(cashBriefCaseAddr, cashBriefcaseAmount);
        // 30% of the 75% Bribing System
        uint256 pureBribingAmount = bribingSystemAmount.mul(30).div(100);
        fraud.mint(pureBribingAddr, pureBribingAmount);
        // 1% Marketing wallet
        uint256 marketingAmount = _debasedAmount.mul(1).div(100);
        fraud.mint(marketingAddr, marketingAmount);
        // add  to totalTaxedVenezuela

        if(vault == 0){
            totalTaxedPanama = totalTaxedPanama.add(bribingSystemAmount);
            totalTaxedPanama = totalTaxedPanama.add(marketingAmount);
        } else 
        {
            totalTaxedVenezuela = totalTaxedVenezuela.add(bribingSystemAmount);
            totalTaxedVenezuela = totalTaxedVenezuela.add(marketingAmount);
        }
    }

    function claimBribeReward(address _account, uint256 reward, uint256 randNum) internal {
        require(
            msg.sender == _account || msg.sender == address(vrf),
            "not allowed"
        );

        // Loading user staking infos
        VenezuelaStakerInfo storage user = venezuelaStakerInfo[_account];
        // Reset the startTimestamp to the current blockTimestamp to reset the reward calculation
        user.startTimestamp = block.timestamp;
        // User has 33% chance of getting taxed 100% of his reward
        if(randNum < 33){
            user.rewardTaxed = user.rewardTaxed.add(reward);
            emit RewardTaxed(_account, reward);
        } else 
        {
            user.rewardWithdrawn = user.rewardWithdrawn.add(reward);
            bribe.mint(_account, reward);
            emit RewardPaid(_account, reward);
        }
        user.delayedReward = 0;
    }

    function claimBribe() external payable nonReentrant  onlyNonEmergencyMode {
        VenezuelaStakerInfo storage user = venezuelaStakerInfo[msg.sender];
        require(user.amount > 0, "No deposit made");

        uint256 currentEpoch = fraud.getCurrentEpoch();
        uint256 epochsElapsed = currentEpoch.sub(user.rebaseEpoch);
        uint256 rebaseFactor = 1 ether;  // Start with 1 for multiplication
        for (uint256 i = 0; i < epochsElapsed; i++) {
            rebaseFactor = rebaseFactor.mul(900).div(1000);  // Decrease by 10% each epoch
        }
        // Rebase user's amount
        uint256 debasedAmount = user.amount.mul(rebaseFactor).div(1 ether);
        uint256 reward = calculateReward(msg.sender, debasedAmount);
        reward = reward.add(user.delayedReward);
        require(reward >= 1 ether, "No reward to claim");
        require(address(vrf) != address(0), "VRF not set");
        require(msg.value >= vrfFee, "Not enough ETH for VRF fee");
        // 2 => ClaimBribe, reward = reward
        vrf.requestRandomWords(2, reward, msg.sender);
        emit RandomNumberRequested(msg.sender);
    }

    function claimBribeVrf(address _user, uint256 _reward, uint256 _randNum) external nonReentrant onlyNonEmergencyMode onlyVRF {
        claimBribeReward(_user, _reward, _randNum);
    }

    function calculateReward(address userAddr, uint256 debasedAmount ) public view returns (uint256) {
        VenezuelaStakerInfo storage user = venezuelaStakerInfo[userAddr];
        uint256 userAmount = debasedAmount;
        if (userAmount == 0) {
            return 0;
        }   

        uint256 blockTimestamp = uint256(block.timestamp);
        uint256 timePassed = blockTimestamp.sub(user.startTimestamp);
        uint256 dailyReward = calculateDailyReward(debasedAmount);
        uint256 reward = dailyReward.mul(timePassed).div(86400); // scale down by the number of seconds in a day
        return reward;
    }

    function calculateDailyReward(uint256 _debasedAmount) public view returns (uint256) {
        uint256 fraudprice = getFraudTwap();
        uint256 bribeprice = getBribeTwap();
        // Here we're assuming that fraudprice and bribeprice are scaled by 1e18 to provide enough precision
        require(bribeprice > 0, "Bribe price is zero, can't divide by zero");
        uint256 priceratio = fraudprice.mul(1e18).div(bribeprice); 
        uint256 userTokenStaked = _debasedAmount;
        uint256 reward = priceratio.mul(userTokenStaked).div(1e18); // Scale down the reward back to normal
        return reward;
    }

    function getPanamaCurrentStake(address _user) external view  returns(uint256){
        PanamaStakerInfo storage user = panamaStakerInfo[_user];
        uint256 currentEpoch = fraud.getCurrentEpoch();
        uint256 epochsElapsed = currentEpoch.sub(user.rebaseEpoch);
        uint256 rebaseFactor = 1 ether;  // Start with 1 for multiplication
        if(epochsElapsed < 4){
            for (uint256 i = 0; i < epochsElapsed; i++) {
                rebaseFactor = rebaseFactor.mul(975).div(1000);  // Decrease by 2.5% each epoch
            }
        } else {
            for (uint256 i = 0; i < 4; i++) {
                rebaseFactor = rebaseFactor.mul(975).div(1000);  // Decrease by 2.5% each epoch
            }
        }
        // Rebase user's amount
        uint256 debasedAmount = user.amount.mul(rebaseFactor).div(1 ether);

        if(epochsElapsed > 4){
            uint256 epochRebased = epochsElapsed.sub(4);
            uint256 rebaseFactorPost = 1 ether;  // Start with 1 for multiplication

            for (uint256 i = 0; i < epochRebased; i++) {
                rebaseFactorPost = rebaseFactorPost.mul(900).div(1000);  // Decrease by 10% each epoch
            }

            debasedAmount = debasedAmount.mul(rebaseFactorPost).div(1 ether);
        }
        return debasedAmount;
    }

    function getVenezuelaCurrentStake(address _user) external view returns(uint256){
        VenezuelaStakerInfo storage user = venezuelaStakerInfo[_user];

        uint256 currentEpoch = fraud.getCurrentEpoch();
        uint256 epochsElapsed = currentEpoch.sub(user.rebaseEpoch);
        uint256 rebaseFactor = 1 ether; // Start with 1 for multiplication

        for (uint256 i = 0; i < epochsElapsed; i++) {
            rebaseFactor = rebaseFactor.mul(900).div(1000);  // Decrease by 10% each epoch
        }
        uint256 debasedAmount = user.amount.mul(rebaseFactor).div(1 ether);
        return debasedAmount;
    }

    function logFraudPrice() public {
        uint256 currentPrice = getFraudPrice();
        require(block.timestamp.sub(lastUpdateTimeFraud) >= INTERVAL, "Too soon to update.");

        fraudPrices[currentFraudIndex] = PricePoint(block.timestamp, currentPrice);
        currentFraudIndex = (currentFraudIndex.add(1)) % 48;

        if (totalFraudDataPoints < 48) {
            totalFraudDataPoints++;
        }

        lastUpdateTimeFraud = block.timestamp;
    }

    function logBribePrice() public {
        uint256 currentPrice = getBribePrice();
        require(block.timestamp.sub(lastUpdateTimeBribe) >= INTERVAL, "Too soon to update.");

        bribePrices[currentBribeIndex] = PricePoint(block.timestamp, currentPrice);
        currentBribeIndex = (currentBribeIndex.add(1)) % 48;

        if (totalBribeDataPoints < 48) {
            totalBribeDataPoints++;
        }

        lastUpdateTimeBribe = block.timestamp;
    }

    

    function getFraudPrice() public view returns (uint256){
        uint256 fraudBalance = fraud.balanceOf(fraudpair); // 18 decimals
        uint256 ethBalance = eth.balanceOf(fraudpair); // 18 decimals
        require(fraudBalance > 0, "divison by zero error");
        uint256 fraudprice = ethBalance.mul(1e18).div(fraudBalance);
        return fraudprice;
    }
    
    function getBribePrice() public view returns (uint256){
        uint256 bribeBalance = bribe.balanceOf(bribepair); // 18 decimals
        uint256 ethBalance = eth.balanceOf(bribepair); // 18 decimals
        require(bribeBalance > 0, "divison by zero error");
        uint256 bribeprice = ethBalance.mul(1e18).div(bribeBalance);
        return bribeprice;
    }

    function getFraudTwap() public view returns (uint256) {
        if(totalFraudDataPoints == 0){
            return getFraudPrice();
        }
        uint256 total = 0;

        for (uint256 i = 0; i < totalFraudDataPoints; i++) {
            total = total.add(fraudPrices[i].price);
        }

        return total / totalFraudDataPoints;
    }

    function getBribeTwap() public view returns (uint256) {
        if(totalBribeDataPoints == 0){
            return getBribePrice();
        }
        uint256 total = 0;

        for (uint256 i = 0; i < totalBribeDataPoints; i++) {
            total = total.add(bribePrices[i].price);
        }

        return total.div(totalBribeDataPoints);
    }

    function getStructInfo(address userAddr) public view  returns (VenezuelaStakerInfo memory)  {
        return venezuelaStakerInfo[userAddr];
    }

    function setVRF(IFraudVRF _vrf) external onlyOwner {
        vrf = _vrf;
    }

    function setFraudPair(address _fraudpair) public onlyOwner {
        fraudpair = _fraudpair;
    } 

    function setBribePair(address _bribepair) public onlyOwner {
        bribepair = _bribepair;
    }

    function setMarketingAddr(address _marketingAddr) public onlyOwner {
        marketingAddr = _marketingAddr;
    }

    function setCashBriefCase(address _cashBriefCaseAddr) public onlyOwner {
        cashBriefCaseAddr = _cashBriefCaseAddr;
    }

    function setPureBribing(address _pureBribingAddr) public onlyOwner {
        pureBribingAddr = _pureBribingAddr;
    }

    function setVrfFee(uint256 _vrfFee) public onlyOwner {
        // fee in ether
        vrfFee = _vrfFee;
    }

    // withdraw vrfFee
    function withdrawFee() public onlyOwner {
        uint256 ethBalance = address(this).balance;
        payable(msg.sender).transfer(ethBalance);
        emit FeeWithdrawn(msg.sender, ethBalance);
    }

    modifier onlyVRF() {
        require(msg.sender == address(vrf) || emergencyMode == true, "Only VRF can call this function");
        _;
    }

    modifier onlyNonEmergencyMode() {
        require(emergencyMode == false, "Emergency mode");
        _;
    }
    function toggleEmergencyMode() public onlyOwner {
        emergencyMode = !emergencyMode;
    }
        // Rescue tokens
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        require(to != address(0), "Rescue to the zero address");
        require(token != address(0), "Rescue of the zero address");
        
        // transfer to
        SafeERC20.safeTransfer(IERC20(token),to, amount);
    }
    
    receive() external payable {}

}