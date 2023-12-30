pragma solidity 0.5.16;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract EEEMoney{
    // SafeMath
    using SafeMath for uint;
    
    // User struct
    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint totalEarnedETH;
        uint previousShare;
        uint sharesHoldings;
        uint directShare;
        uint referralShare;
        uint poolHoldings;
        uint created;
        address[] referral;
    }
    
    EEEMoney public oldEEEMoney;
    
    // Public variables
    address public ownerWallet;
    address public signature;
    uint public poolMoney;
    uint public qualifiedPoolHolding = 0.5 ether;
    uint public invest = 0.25 ether;
    uint public feePercentage = 5 ether; 
    uint public currUserID = 0;
    uint public qualify = 86400;
    bool public lockStatus;
    
    // Mapping
    mapping(address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping(bytes32 => bool) public hashComfirmation;
    
    // Events
    event regEvent(address indexed _user, address indexed _referrer, uint _time);
    event poolMoneyEvent(address indexed _user, uint _money, uint _time);
    event splitOverEvent(address indexed _user, uint _shareAmount, uint _userShares, uint _time);
    event userInversement(address indexed _user, uint _noOfShares, uint _amount, uint _time, uint investType);
    event userWalletTransferEvent(address indexed _user, uint _amount, uint _percentage, uint _time);
    event ownerWalletTransferEvent(address indexed _user, uint _percentage, uint _time);
    
    // On Deploy
    constructor(address _signature)public{
        ownerWallet = msg.sender;
        signature = _signature;
        
        oldEEEMoney = EEEMoney(0xE90606828f08FA31e97fC594EC549e6749732a90);
        
        UserStruct memory userStruct;
        currUserID = oldEEEMoney.currUserID();
        poolMoney = oldEEEMoney.poolMoney();
        
        userStruct = UserStruct({
            isExist: true,
            id: 1,
            referrerID: 0,
            totalEarnedETH: 0,
            previousShare: 0,
            sharesHoldings: 0,
            directShare: 0,
            referralShare: 0,
            poolHoldings: 0,
            created:0,
            referral: new address[](0)
        });
        users[ownerWallet] = userStruct;
        userList[1] = ownerWallet;
    }
    

    function () external payable {
    }
    
    /**
     * @dev To register the User
     * @param _referrerID id of user/referrer 
     */
    function regUser(uint _referrerID) public payable returns(bool){
        require(
            lockStatus == false,
            "Contract is locked"
        );
        require(
            !users[msg.sender].isExist && !syncIsExist(msg.sender),
            "User exist"
        );
        require(
            _referrerID > 0 && _referrerID <= currUserID,
            "Incorrect referrer Id"
        );
        require(
            msg.value == invest,
            "Incorrect Value"
        );
        
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            totalEarnedETH: 0,
            previousShare: 0,
            sharesHoldings: 1,
            directShare: 0,
            referralShare: 0,
            poolHoldings: 0,
            created:now.add(qualify),
            referral: new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;
        
        address referer;
        
         if(_referrerID <= oldEEEMoney.currUserID())
            referer = oldEEEMoney.userList(_referrerID);
        else    
            referer = userList[_referrerID];
        
        users[referer].sharesHoldings = users[referer].sharesHoldings.add(1);
        users[referer].referralShare = users[referer].referralShare.add(1);
        users[referer].referral.push(msg.sender);
    
        uint _value = invest.div(2);
        
        require(
            address(uint160(referer)).send(_value),
            "Transaction failed"
        );
        
        users[referer].totalEarnedETH = users[referer].totalEarnedETH.add(_value);
        
        poolMoney = poolMoney.add(_value);
        
        emit poolMoneyEvent( msg.sender, _value, now);
        emit regEvent(msg.sender, referer, now);
        
        return true;
    }

    /**
     * @dev To invest on shares
     * @param _noOfShares No of shares 
     */
    function investOnShare(uint _noOfShares) public payable returns(bool){
        require(
            lockStatus == false,
            "Contract is locked"
        );
        
        require(
            msg.value == invest.mul(_noOfShares),
            "Incorrect Value"
        );
        
        require(users[msg.sender].isExist || syncIsExist(msg.sender),"User not exist");
        
        uint _value = (msg.value).div(2);
        address _referer;
        uint refID = users[msg.sender].referrerID;
        
        if(refID == 0)
            refID = syncReferrerID(msg.sender);
            
        
        if(refID == 0)
            refID = 1;
        
        _referer = userList[refID];
        
        if(_referer == address(0))
            _referer = oldEEEMoney.userList(refID);
                
        
        require(
            address(uint160(_referer)).send(_value),
            "Transaction failed"
        ); 
        
        users[_referer].totalEarnedETH = users[_referer].totalEarnedETH.add(_value);
        
        users[msg.sender].directShare = users[msg.sender].directShare.add(_noOfShares);
        users[msg.sender].sharesHoldings = users[msg.sender].sharesHoldings.add(_noOfShares);
        
        poolMoney = poolMoney.add(_value);
        
        emit poolMoneyEvent( msg.sender, _value, now);
        emit userInversement( msg.sender, _noOfShares, msg.value, now, 1);
        
        return true;
    }
    
    
    function shareWithdraw(uint _shareAmount, uint _shares, bytes32[3] memory _mrs, uint8 _v) public returns(bool){
        
        require(hashComfirmation[_mrs[0]] != true,"hash already exist");
        require(
            ecrecover(_mrs[0], _v, _mrs[1], _mrs[2]) == signature,
            "signature verification failed"
        );
        
        require(users[msg.sender].isExist || syncIsExist(msg.sender),"User not exist");
        
        uint _totalInvestingShare = _shareAmount.div(qualifiedPoolHolding);
        uint _referervalue = invest.div(2);
        uint _value = (_referervalue.mul(_totalInvestingShare));
        
        poolMoney = poolMoney.sub(_shareAmount);
        
        users[msg.sender].previousShare = users[msg.sender].previousShare.add(_shares);
        
        uint refID = users[msg.sender].referrerID;
        
        if(refID == 0)
            refID = syncReferrerID(msg.sender);
            
        address _referer = userList[refID];
        
        if(_referer == address(0))
            _referer = oldEEEMoney.userList(refID);    
        
        if(_referer == address(0))
            _referer = ownerWallet;
        
        require(
            address(uint160(_referer)).send(_value),
            "re-inverset referer 50 percentage failed"
        );
        
        users[_referer].totalEarnedETH = users[_referer].totalEarnedETH.add(_value);
        
        users[msg.sender].directShare = users[msg.sender].directShare.add(_totalInvestingShare);
        users[msg.sender].sharesHoldings = users[msg.sender].sharesHoldings.add(_totalInvestingShare);
        
        poolMoney = poolMoney.add(_value);
        
        // wallet
        uint _walletAmount = invest.mul(_totalInvestingShare);
        uint _adminCommission = (_walletAmount.mul(feePercentage)).div(100 ether);
        
        _walletAmount = _walletAmount.sub(_adminCommission);
        
        require(
            msg.sender.send(_walletAmount) &&
            address(uint160(ownerWallet)).send(_adminCommission),
            "user wallet transfer failed"
        );  
        
        hashComfirmation[_mrs[0]] = true;
        
        emit splitOverEvent( msg.sender, _shareAmount, _shares, now);
        emit userInversement( msg.sender, _totalInvestingShare, invest.mul(_totalInvestingShare), now, 2);
        emit poolMoneyEvent( msg.sender, _value, now);
        emit userWalletTransferEvent(msg.sender, _walletAmount, _adminCommission, now);
        emit ownerWalletTransferEvent(msg.sender, _adminCommission, now);
        
        return true;
    }
    
    
    /**
     * @dev Contract balance withdraw
     * @param _toUser  receiver addrress
     * @param _amount  withdraw amount
     */ 
    function failSafe(address payable _toUser, uint _amount) public returns (bool) {
        require(msg.sender == ownerWallet, "Only Owner Wallet");
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    }

    /**
     * @dev To lock/unlock the contract
     * @param _lockStatus  status in bool
     */
    function contractLock(bool _lockStatus) public returns (bool) {
        require(msg.sender == ownerWallet, "Invalid ownerWallet");

        lockStatus = _lockStatus;
        return true;
    }
    
    
    // sync functions
    
    function syncListUsers(uint _userID) public view returns(address){
        address _user = userList[_userID];
        if(_user == address(0))
            _user = oldEEEMoney.userList(_userID);
            
        return _user;
    }
    
    function syncIsExist(address _user) public view  returns(bool){
        uint oldData;
        bool isExist;
        (isExist, 
            oldData, 
            oldData, 
            oldData,
            oldData,
            oldData,
            oldData,
            oldData,
            oldData,
            oldData) = 
            oldEEEMoney.users(_user);
            
            return(isExist);
    }
    
    function syncUser(address _user) public view  returns(bool,uint,uint,uint,uint){
        uint oldData;
        uint ID;
        uint referrerID;
        uint totalEth;
        uint created;
        bool isExist;
        (isExist, 
            ID, 
            referrerID, 
            totalEth,
            oldData,
            oldData,
            oldData,
            oldData,
            oldData,
            created) = 
            oldEEEMoney.users(_user);
            
            return(isExist,ID,referrerID,totalEth,created);
    }
    
    function syncShares(address _user) public view  returns(uint,uint,uint,uint){
        address _users = _user;
        uint oldData;
        uint shareHolding;
        uint previousShare;
        uint directShare;
        uint referralShare;
        bool isExist;
        (isExist, 
            oldData, 
            oldData, 
            oldData,
            previousShare,
            shareHolding,
            directShare,
            referralShare,
            oldData,
            oldData) = 
            oldEEEMoney.users(_users);
            
            return(shareHolding.add(users[_users].sharesHoldings),directShare.add(users[_users].directShare),referralShare.add(users[_users].referralShare),previousShare.add(users[_users].previousShare));
    }
    
    function syncReferrerID(address _user) public view  returns(uint){
        uint oldData;
        uint RefID;
        bool isExist;
        (isExist, 
            oldData, 
            RefID, 
            oldData,
            oldData,
            oldData,
            oldData,
            oldData,
            oldData,
            oldData) = 
            oldEEEMoney.users(_user);
            
            return RefID;
    }

    
    
    function syncTotalEarned(address _user) public view  returns(uint){
        uint oldData;
        uint totalEth;
        bool isExist;
        (isExist, 
            oldData, 
            oldData, 
            totalEth,
            oldData,
            oldData,
            oldData,
            oldData,
            oldData,
            oldData) = 
            oldEEEMoney.users(_user);
            
            return totalEth.add(users[_user].totalEarnedETH);
    }
    
    
     function getTotalEarnedEther() public view returns(uint) {
        uint totalEth;
        
        for( uint _userIndex=1;_userIndex<= currUserID;_userIndex++) {
            address user = userList[_userIndex];
            if(user == address(0))
                user = oldEEEMoney.userList(_userIndex);
                
            totalEth = totalEth.add(syncTotalEarned(user));
        }
        
        return totalEth;
    }
    
    /**
     * @dev To view the referrals
     * @param _user  User address
     */ 
    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }
    
    
    function syncRefferrals(address _user)public view returns(address[] memory,address[] memory){
        return(users[_user].referral,oldEEEMoney.viewUserReferral(_user));
    }
    
    
    
}