// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.20;

library SafeMath {
  
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20{
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns(uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
    */
    function balanceOf(address acount) external view returns(uint256);

    /**
     *  @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded. 
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient,uint256 amount) external returns (bool);
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner,address spender) external view returns(uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender,uint256 amount)external returns(bool);
   /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */

    function transferFrom(address sender,address recipient,uint256 amount) external returns(bool);


}

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


    abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Utilities is Ownable, Pausable {

    mapping(address => bool) private admins;
    bool private reentrancyLock_ = false;
    // event OpraterAdmin(address indexed from);

    function addAdmin(address _address) public virtual onlyOwner {
        // require(_address.code.length>0," must be a contract's address");
        require(_address!=address(0));
        admins[_address] = true;
    }

    function addAdmins(address[] calldata _addresses) public virtual onlyOwner {
        uint256 len = _addresses.length;
        for (uint256 i = 0; i < len; i++) {
              require(_addresses[i]!=address(0));
            // require(_addresses[i].code.length>0," must be a contract's address");
            admins[_addresses[i]] = true;
        }
    }



    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function removeAdmin(address[] calldata _addresses) external onlyOwner {
        uint256 len = _addresses.length;
        for (uint256 i = 0; i < len; i++) {
            admins[_addresses[i]] = false;
        }
    }

    
    function setPause(bool _shouldPause) external onlyAdminOrOwner {
        if (_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function isAdmin(address _address) public view returns (bool) {
        return admins[_address];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }


    modifier reentrancyLock {
        require(!reentrancyLock_, "Reentrancy detected");
        reentrancyLock_ = true;
        _;
        reentrancyLock_ = false;
    }


    modifier onlyAdminOrOwner() {
        
        require(admins[msg.sender] || isOwner(), "Not admin or owner");      
        _;
        // emit OpraterAdmin(msg.sender);
    }
    // modifier nonZeroAddress(address _address)    {
    //     require(address(0) != _address, "0 address");
    //     _;
    // }
    // modifier nonZeroLength(uint[] memory _array) {
    //     require(_array.length > 0, "Empty array");
    //     _;
    // }
    // modifier lengthsAreEqual(uint[] memory _array1, uint[] memory _array2) {
    //     require(_array1.length == _array2.length, "Unequal lengths");
    //     _;
    // }
    // modifier onlyEOA() {
    //     /* solhint-disable avoid-tx-origin */
    //     require(msg.sender == tx.origin, "No contracts");
    //     _;
    // }

    modifier sharesCaller() {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin||isAdmin(msg.sender), " caller address error ");
        _;
    }

    function isOwner() internal view returns (bool) {
        return owner() == msg.sender;
    }


}



contract T2LockCoin is Utilities{
    using SafeMath for uint256;
    struct LockCoin {
        // 1:propfunds;2:teamReward;3:vc;4:adveiser
         uint8 lockType;
         uint256 totalAmount;              
         //0 or times
         uint releaseInterval;
         uint intervalReleaseAmount;
         uint nextReleaseTime; 
         uint endTime;          
         address[] withdrawAddrs;
	   
    }

    uint256 public firstPropfundsHalfTime;
    uint256 public secPropfundsHalfTime;

    uint256 public constant firstPropfundsIntervalReleaseAmout = 10000000* 1 ether; 
    uint256 public constant secPropfundsIntervalReleaseAmount=5000000*1 ether;
    uint256 public constant thirdPropfundsintervalReleaseAmount=2500000*1 ether;



    LockCoin private propfunds;
    LockCoin private teamReward;   
    LockCoin private vc;   
    LockCoin private adveiser;
    //1=>num,2=>num,3=>num
    mapping(uint256=>uint256) claimedProfundsAmount;

    uint256 public claimedTeamRewardAmount;
    uint256 public claimedVcAmount;
    uint256 public claimedAdveiserAmount;
    address public t2T2ddr=0x390e61F798267fe7aa9BBE61Be8BB1776250D44C;
    event ClaimCoin(address sender,uint8 claimType,address to, uint256 amount);

    constructor(){

        // uint startTime = block.timestamp+10 minutes;  // delay 10 ninutes start

        uint intervalTimes = 30 days;// 2 minutes; 

        uint start20231206 = 1701792000 ; 
        uint start20240506 =1714924800;//startTime+intervalTimes*5;// delay 5 months start
        uint end20260506 =1777996800;// start20240506+intervalTimes*12*2;//two years releas all
        uint end20261206 =1796486400;// startTime +intervalTimes*12*3; // three years release all
        uint end20240906 = end20261206+intervalTimes*8; //startTime+intervalTimes*9;// // 9 months release all 

        firstPropfundsHalfTime = start20231206+intervalTimes*12;
        secPropfundsHalfTime = start20231206+intervalTimes*24;
        uint256 sendAmount = 200000*1 ether;
        // 2023.12.6=1701792000,2024.5.6=1714924800,2026.12.6 =1796486400,2024.8.6 = 1722873600,2026.5.6=1777996800
        propfunds = LockCoin(1,((210000000*1 ether) -sendAmount)  ,intervalTimes,10000000*1 ether,start20231206,end20261206,new address[](1)); 
        propfunds.withdrawAddrs[0]=0x3fF5236025F715B3FAA58922DC93c2AadeEA4571;       
        teamReward = LockCoin(2,1500000000*1 ether,intervalTimes,62500000*1 ether,start20240506,end20260506,new address[](1));    
        teamReward.withdrawAddrs[0]=0x6B7d9138e342E823eFF1f9df8531b57a64e62a26;
               
        vc = LockCoin(3,500000000*1 ether,intervalTimes,2083333333*1e16,start20240506,end20260506,new address[](1));   
        vc.withdrawAddrs[0]=0x4175A1b468692801966dA949DDa90C32d4D54f01;
        sendAmount = 1111110*1 ether; 
        adveiser = LockCoin(4,((11111111*1 ether)-sendAmount),intervalTimes,111111122*1e16,start20231206,end20240906,new address[](1));
        adveiser.withdrawAddrs[0]=0xE5E62257ABb765c14E6104C9b5b215d2Ba527Cfc;
        


    }

    function setErc20(address addr_) public onlyAdminOrOwner {
          require(addr_!=address(0)," addr_ error");
          t2T2ddr = addr_;
    }
    
    /*
    uint256 public firstPropfundsHalfTime;
    uint256 public secPropfundsHalfTime;
    */

    function setHalTimes(uint firstPropfundsHalfTime_,uint secPropfundsHalfTime_) public onlyAdminOrOwner {
        require(firstPropfundsHalfTime_!=0 && secPropfundsHalfTime_!=0," time error ");
        firstPropfundsHalfTime = firstPropfundsHalfTime_;
        secPropfundsHalfTime=secPropfundsHalfTime_;
    }

    function setPropFundsHalfTimes(uint256  firstPropfundsHalfTime_, uint256 secPropfundsHalfTime_) public onlyAdminOrOwner returns (bool){
       
        require(firstPropfundsHalfTime_>block.timestamp && secPropfundsHalfTime_>firstPropfundsHalfTime_," halfTime error ");

        firstPropfundsHalfTime = firstPropfundsHalfTime;
        secPropfundsHalfTime = secPropfundsHalfTime;
        return true;

    }

    function setLockCoin(LockCoin memory lockCoin) public onlyAdminOrOwner whenNotPaused returns (bool) {
       uint length = lockCoin.withdrawAddrs.length;
       require(length>0," withdrawAddrs length error");     
       if(lockCoin.lockType==1)
       {
          propfunds = lockCoin;
       }else if(lockCoin.lockType==2)
       {
         teamReward = lockCoin;         
       }else if(lockCoin.lockType==3)
       {
         vc = lockCoin;  
       }else if(lockCoin.lockType==4)
       {
         adveiser = lockCoin;  
       }
       return true;
    } 

    function isReceiver( uint8 claimType, address to) public view returns (bool retb){
        address[] memory addrArry ;
        retb= false;
        if(claimType==1)
        {
            addrArry = propfunds.withdrawAddrs;
        }else if(claimType==2)
        {
           addrArry = teamReward.withdrawAddrs;
        }else if(claimType==3)
        {
            addrArry = vc.withdrawAddrs;
        }else if(claimType==4)
        {
            addrArry = adveiser.withdrawAddrs;
        } 
        
        for(uint i=0;i<addrArry.length;i++)
        {
          if(addrArry[i]==to)
          {
            retb = true;
            break ;
          }
        }

        return retb;

    }
   
      // 1:propfunds;2:teamReward;3:vc;4:adveiser
    function claimReleaseCoin( uint8 claimType,address to) public whenNotPaused  returns(bool)
    {
        require(claimType>=1 && claimType<=4 && to!=address(0)," claimReleaseCoin params error");
        require(isReceiver(claimType,to)," reciever address ${to} error ");
        uint256 tokenAmount =0;
        if(claimType==1)
        {
            tokenAmount=claimPropfunds();
        }else if(claimType==2)
        {
           tokenAmount = claimTeam();
        }else if(claimType==3)
        {
            tokenAmount = claimVc();
        }else if(claimType==4)
        {
            tokenAmount = claimAdveiser();
        } 

        require(tokenAmount>0," token amount error ");   
        require(IERC20(t2T2ddr).balanceOf(address(this))>=tokenAmount," token balance error");    
        _safeTransfer(t2T2ddr,to,tokenAmount);
        emit ClaimCoin(msg.sender,claimType,to,tokenAmount);
        return true;
    }
    // /claimedAdveiserAmount
    function claimAdveiser() internal  returns (uint tokenToRelase){
        uint256 currentTime = block.timestamp;
        require(currentTime>=adveiser.nextReleaseTime," Coins are not released,limit time");  
        require(claimedAdveiserAmount<adveiser.totalAmount," Coins total amount released ");  
        uint256 elapsedTime =currentTime - adveiser.nextReleaseTime;
        uint256 rounds =  elapsedTime.div(adveiser.releaseInterval)+1;
        if(claimedAdveiserAmount<adveiser.totalAmount)
        {
            tokenToRelase=rounds*adveiser.intervalReleaseAmount;
        }

        if((claimedAdveiserAmount+tokenToRelase)>adveiser.totalAmount)
        {
            tokenToRelase = adveiser.totalAmount.sub(claimedAdveiserAmount);
            claimedAdveiserAmount = adveiser.totalAmount;
        }else 
        {
            claimedAdveiserAmount = claimedAdveiserAmount+tokenToRelase;
        }

        if(currentTime>=adveiser.endTime)
        {
             tokenToRelase = adveiser.totalAmount.sub(claimedAdveiserAmount);
             claimedAdveiserAmount = adveiser.totalAmount;
        }

        if(tokenToRelase>0)
            adveiser.nextReleaseTime = adveiser.nextReleaseTime + (rounds * adveiser.releaseInterval);

        return tokenToRelase;


     }
    //claimedVcAmount
    function claimVc() internal  returns (uint tokenToRelase){
        uint256 currentTime = block.timestamp;
        require(currentTime>=vc.nextReleaseTime," Coins are not released,limit time");  
        require(claimedVcAmount<vc.totalAmount," Coins total amount released ");  
        uint256 elapsedTime =currentTime - vc.nextReleaseTime;
        uint256 rounds =  elapsedTime.div(vc.releaseInterval)+1;
        if(claimedVcAmount<vc.totalAmount)
        {
            tokenToRelase=rounds*vc.intervalReleaseAmount;
        }

        if((claimedVcAmount+tokenToRelase)>vc.totalAmount)
        {
            tokenToRelase = vc.totalAmount.sub(claimedVcAmount);
            claimedVcAmount = vc.totalAmount;
        }else 
        {
            claimedVcAmount = claimedVcAmount+tokenToRelase;
        }

        if(currentTime>=vc.endTime)
        {
            tokenToRelase = vc.totalAmount.sub(claimedVcAmount);
            claimedVcAmount = vc.totalAmount;
        }

        if(tokenToRelase>0)
           vc.nextReleaseTime = vc.nextReleaseTime + (rounds * vc.releaseInterval);

        return tokenToRelase;

    } 
    function claimTeam() internal  returns (uint tokenToRelase)
    {
        uint256 currentTime = block.timestamp;
        require(currentTime>=teamReward.nextReleaseTime," Coins are not released,limit time");  
        require(claimedTeamRewardAmount<teamReward.totalAmount," Coins total amount released ");  
        uint256 elapsedTime =currentTime - teamReward.nextReleaseTime;
        uint256 rounds =  elapsedTime.div(teamReward.releaseInterval)+1;
        if(claimedTeamRewardAmount<teamReward.totalAmount)
        {
            tokenToRelase=rounds*teamReward.intervalReleaseAmount;
        }
      
        if((claimedTeamRewardAmount+tokenToRelase)>teamReward.totalAmount)
        {
            tokenToRelase = teamReward.totalAmount.sub(claimedTeamRewardAmount);
            claimedTeamRewardAmount = teamReward.totalAmount;
        }else {
           claimedTeamRewardAmount = claimedTeamRewardAmount+tokenToRelase;
        }
        if(tokenToRelase>0)
            teamReward.nextReleaseTime = teamReward.nextReleaseTime + (rounds * teamReward.releaseInterval);
        return tokenToRelase;
    }

    function claimPropfunds() internal  returns (uint tokensToRelease)
    {
        uint256 currentTime = block.timestamp;
        require(currentTime>=propfunds.nextReleaseTime," Coins are not released");       
        uint256 elapsedTime = currentTime - propfunds.nextReleaseTime;
        uint256 rounds =elapsedTime.div(propfunds.releaseInterval)+1;           
        if(rounds>=1)
        {
             uint256 firstTotalAmount=firstPropfundsIntervalReleaseAmout*12;
             uint256  secTotalAmount=secPropfundsIntervalReleaseAmount*12;
             uint256 sectionAmount =0;

            if(currentTime<=firstPropfundsHalfTime)
            {               
               tokensToRelease= getSectionPropFundsAmount(1,currentTime,propfunds.nextReleaseTime);
            }

            if(currentTime>firstPropfundsHalfTime && currentTime<=secPropfundsHalfTime)
            {
               if(propfunds.nextReleaseTime<firstPropfundsHalfTime)
               {
                  propfunds.nextReleaseTime=firstPropfundsHalfTime;
               } 
               if(claimedProfundsAmount[1]<firstTotalAmount)
               {
                 tokensToRelease = firstTotalAmount.sub(claimedProfundsAmount[1]);
                 claimedProfundsAmount[1]=firstTotalAmount;
               }
                    
               sectionAmount= getSectionPropFundsAmount(2,currentTime,propfunds.nextReleaseTime);
               tokensToRelease=tokensToRelease+sectionAmount;
            }

             if(currentTime>secPropfundsHalfTime && currentTime<=propfunds.endTime)
             {
               if(propfunds.nextReleaseTime<secPropfundsHalfTime)
               {
                  propfunds.nextReleaseTime=secPropfundsHalfTime;
               } 
               if(claimedProfundsAmount[1]<firstTotalAmount)
               {
                 tokensToRelease = firstTotalAmount.sub(claimedProfundsAmount[1]);
                 claimedProfundsAmount[1]=firstTotalAmount;
               }

               if(claimedProfundsAmount[2]<secTotalAmount)
               {
                  tokensToRelease = tokensToRelease +secTotalAmount.sub(claimedProfundsAmount[2]);
                  claimedProfundsAmount[2]=secTotalAmount;
               }                           
               sectionAmount= getSectionPropFundsAmount(3,currentTime,propfunds.nextReleaseTime);
               tokensToRelease=tokensToRelease+ sectionAmount;
             }

             if(currentTime>propfunds.endTime)
             {
                sectionAmount = claimedProfundsAmount[1]+claimedProfundsAmount[2]+claimedProfundsAmount[3];
                if(sectionAmount<propfunds.totalAmount)
                {
                    tokensToRelease = propfunds.totalAmount.sub(sectionAmount);
                }
             }

            
        }
       if(tokensToRelease>0)
          propfunds.nextReleaseTime = propfunds.nextReleaseTime + (rounds * propfunds.releaseInterval);
        return  tokensToRelease;
    }

    function getSectionPropFundsAmount(uint8 sectionType,uint currentTime,uint sectionTime) internal  returns (uint256 retAmount) {
        if(sectionType>=1 && sectionType<=3)
        {
            uint256 rounds =  (currentTime - sectionTime).div(propfunds.releaseInterval)+1;  
            uint256 releaseAmount =0;
            if(sectionType==1)
            {            
                releaseAmount=firstPropfundsIntervalReleaseAmout;
            }else if(sectionType==2)
            {
                releaseAmount=secPropfundsIntervalReleaseAmount;
            }else if(sectionType==3)
            {
                releaseAmount=thirdPropfundsintervalReleaseAmount;
            }
            retAmount = rounds * releaseAmount;
            claimedProfundsAmount[sectionType]= claimedProfundsAmount[sectionType].add(retAmount);
            // if(retAmount>0)
            //     propfunds.nextReleaseTime = propfunds.nextReleaseTime + (rounds * propfunds.releaseInterval);
        }     

        return retAmount;
    }


    function getPropfunds() public view  returns (LockCoin memory)
    {
        return propfunds;
    }

    function getTeamReward() public view  returns (LockCoin memory)
    {
        return teamReward;
    }

    function getVc() public view  returns (LockCoin memory)
    {
        return vc;
    }

    function getAdveiser() public view  returns (LockCoin memory)
    {
        return adveiser;
    }
    
    function _safeTransfer(address token,address to,uint256 amount) internal  {
        require(token.code.length > 0);
        //  erc20 erc = erc20(token);
        // require(erc.transfer(to, amount),'_safeTransfer TransferHelper: TRANSFER_FAILED');     
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transfer.selector,  to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))),'safeTransferFrom TransferHelper: TRANSFER_FAILED');       
    }

    function withdraw(address to, uint256 amount_) external onlyAdminOrOwner {
      
        require(IERC20(t2T2ddr).balanceOf(address(this))>=amount_," token balance error");    
        _safeTransfer(t2T2ddr,to,amount_);
      
    }

}