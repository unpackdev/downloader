/**
*
*
         dP                   dP                         dP                   
         88                   88                         88                   
.d8888b. 88 .d8888b. .d8888b. 88d888b. dP   .dP .d8888b. 88 dP    dP .d8888b. 
Y8ooooo. 88 88'  `88 Y8ooooo. 88'  `88 88   d8' 88'  `88 88 88    88 88ooood8 
      88 88 88.  .88       88 88    88 88 .88'  88.  .88 88 88.  .88 88.  ... 
`88888P' dP `88888P8 `88888P' dP    dP 8888P'   `88888P8 dP `88888P' `88888P' 
                                                                              
*
* 
* SlashValue
* https://SlashValue.Com
* 
**/

pragma solidity 0.5.16; 

contract ERC20 {
    function authorizedMint(address reciever, uint256 value) public returns(bool);
    function transfer(address to, uint256 value) public returns(bool);
}

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
}


contract ownerShip  
{
    //Global storage declaration
    address public ownerWallet;
    address private newOwner;
    //Event defined for ownership transfered
    event OwnershipTransferredEv(address indexed previousOwner, address indexed newOwner);

    //Sets owner only on first run
    constructor() public 
    {
        //Set contract owner
        ownerWallet = msg.sender;
        emit OwnershipTransferredEv(address(0), msg.sender);
    }

    function transferOwnership(address _newOwner) public onlyOwner 
    {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public 
    {
        require(msg.sender == newOwner);
        emit OwnershipTransferredEv(ownerWallet, newOwner);
        ownerWallet = newOwner;
        newOwner = address(0);
    }

    //This will restrict function only for owner where attached
    modifier onlyOwner() 
    {
        require(msg.sender == ownerWallet);
        _;
    }

}


contract SlashValue is ownerShip {
    using SafeMath for uint256;
    uint maxDownLimit = 2;
    uint public lastIDCount = 0;
    ERC20 public SVToken;
    uint public svFee = 10 ether;
    uint public svTokenMultiplier = 10000;

    struct userInfo {
        bool joined;
        uint createdOn;
        uint id;
        uint sponsorID;
        uint referrerID;
        uint totalEarningEth;
        address[] referral;
        mapping(uint => uint) levelExpired;
    }

    mapping(uint => uint) public priceOfLevel;

    mapping (address => userInfo) public userInfos;
    mapping (uint => address) public userAddressByID;
    mapping (address => mapping (uint => uint)) public EarnedEth;

    event regLevelEv(uint indexed _userID, address indexed _userWallet, uint indexed _referrerID, address _refererWallet, uint _originalReferrer, uint _time);
    event levelBuyEv(address indexed _user, uint _level, uint _amount, uint _time);
    event paidForLevelEv(address indexed _user, address indexed _referral, uint _level, uint _amount, uint _time);
    event lostForLevelEv(address indexed _user, address indexed _referral, uint _level, uint _amount, uint _time);

    constructor(address _token) public {
        SVToken = ERC20(_token);

        priceOfLevel[1] = 0.05 ether;
        priceOfLevel[2] = 0.10 ether;
        priceOfLevel[3] = 0.20 ether;
        priceOfLevel[4] = 0.50 ether;
        priceOfLevel[5] = 1 ether;
        priceOfLevel[6] = 2 ether;
        priceOfLevel[7] = 3 ether;
        priceOfLevel[8] = 4 ether;
        priceOfLevel[9] = 5 ether;
        priceOfLevel[10] = 7 ether;

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            createdOn: now,
            id: lastIDCount,
            sponsorID: 0,
            referrerID: 0,
            totalEarningEth:0,
            referral: new address[](0)
        });
        userInfos[ownerWallet] = UserInfo;
        userAddressByID[lastIDCount] = ownerWallet;

        for(uint i = 1; i <= 10; i++) {
            userInfos[ownerWallet].levelExpired[i] = 99999999999;
            emit paidForLevelEv(ownerWallet, address(0), i, priceOfLevel[i], now);
            emit levelBuyEv(msg.sender, i, priceOfLevel[i], now);
        }
        
        emit regLevelEv(lastIDCount, msg.sender, 0, address(0), 0, now);

    }

    function () external payable {
        uint level;

        if(msg.value == priceOfLevel[1]) level = 1;
        else if(msg.value == priceOfLevel[2]) level = 2;
        else if(msg.value == priceOfLevel[3]) level = 3;
        else if(msg.value == priceOfLevel[4]) level = 4;
        else if(msg.value == priceOfLevel[5]) level = 5;
        else if(msg.value == priceOfLevel[6]) level = 6;
        else if(msg.value == priceOfLevel[7]) level = 7;
        else if(msg.value == priceOfLevel[8]) level = 8;
        else if(msg.value == priceOfLevel[9]) level = 9;
        else if(msg.value == priceOfLevel[10]) level = 10;
        else revert('Incorrect Value send');

        if(userInfos[msg.sender].joined) buyLevel(level);
        else if(level == 1) {
            uint refId = 1;
            address referrer = bytesToAddress(msg.data);

            if(userInfos[referrer].joined) refId = userInfos[referrer].id;

            regUser(refId);
        }
        else revert('Please buy first level for 0.1 ETH');
    }

    function regUser(uint _referrerID) public payable {
        uint originalReferrerID = _referrerID;
        require(!userInfos[msg.sender].joined, 'User exist');
        require(_referrerID > 0 && _referrerID <= lastIDCount, 'Incorrect referrer Id');
        require(msg.value == priceOfLevel[1], 'Incorrect Value');
        
        uint _sponsorID = _referrerID;

        if(userInfos[userAddressByID[_referrerID]].referral.length >= maxDownLimit) _referrerID = userInfos[findFreeReferrer(userAddressByID[_referrerID])].id;

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            createdOn: now,
            id: lastIDCount,
            sponsorID: _sponsorID,
            referrerID: _referrerID,
            totalEarningEth: 0,
            referral: new address[](0)
        });

        userInfos[msg.sender] = UserInfo;
        userAddressByID[lastIDCount] = msg.sender;

        userInfos[msg.sender].levelExpired[1] = 99999999999;

        userInfos[userAddressByID[_referrerID]].referral.push(msg.sender);
        
        uint256 mint = ((priceOfLevel[1]).mul(svTokenMultiplier));
        SVToken.authorizedMint(msg.sender, mint);
        
        // 10%
        mint = ((priceOfLevel[1]).mul((svTokenMultiplier.mul(uint(10).mul(10**18))).div(10**20)));
        SVToken.authorizedMint(userAddressByID[userInfos[msg.sender].sponsorID], mint);
        
        address(uint160(ownerWallet)).send((priceOfLevel[1].mul(uint(10).mul(10**18))).div(10**20));

        payForLevelUpline(1, msg.sender, false);
        payForLevelSponsor(1,msg.sender, false);

        emit regLevelEv(lastIDCount, msg.sender, _referrerID, userAddressByID[_referrerID], originalReferrerID, now);
        emit levelBuyEv(msg.sender, 1, msg.value, now);
    }

    function buyLevel(uint _level) public payable {
        require(userInfos[msg.sender].joined, 'User not exist'); 
        require(_level > 1 && _level <= 10, 'Incorrect level');
        require(userInfos[msg.sender].levelExpired[_level] == 0, 'Level Already Active');
        
        //owner can buy levels without paying anything
        if(msg.sender!=ownerWallet){
            require(msg.value == priceOfLevel[_level], 'Incorrect Value');
        }
        
        for(uint l =_level - 1; l > 0; l--) require(userInfos[msg.sender].levelExpired[l] > 0, 'Buy the previous level');

        userInfos[msg.sender].levelExpired[_level] = 2**_level;

        uint256 mint = ((priceOfLevel[_level]).mul(svTokenMultiplier));
        SVToken.authorizedMint(msg.sender, mint);
        
        // 10%
        mint = ((priceOfLevel[_level]).mul((svTokenMultiplier.mul(uint(10).mul(10**18))).div(10**20)));
        SVToken.authorizedMint(userAddressByID[userInfos[msg.sender].sponsorID], mint);
        
        address(uint160(ownerWallet)).send((priceOfLevel[_level].mul(uint(10).mul(10**18))).div(10**20));
        
        payForLevelUpline(_level, msg.sender, false);
        payForLevelSponsor(_level, msg.sender, false);

        emit levelBuyEv(msg.sender, _level, msg.value, now);
    }
    

    function payForLevelUpline(uint _level, address _user, bool _loop) internal {
        address referer;
        address nextReferrer;
       if(!_loop){
        if(_level == 1 || _level == 6) {
            referer = userAddressByID[userInfos[_user].referrerID];
        }
        else if(_level == 2 || _level == 7) {
            nextReferrer = userAddressByID[userInfos[_user].referrerID];
            referer = userAddressByID[userInfos[nextReferrer].referrerID];
        }
        else if(_level == 3 || _level == 8) {
            nextReferrer = userAddressByID[userInfos[_user].referrerID];
            nextReferrer = userAddressByID[userInfos[nextReferrer].referrerID];
            referer = userAddressByID[userInfos[nextReferrer].referrerID];
        }
        else if(_level == 4 || _level == 9) {
            nextReferrer = userAddressByID[userInfos[_user].referrerID];
            nextReferrer = userAddressByID[userInfos[nextReferrer].referrerID];
            nextReferrer = userAddressByID[userInfos[nextReferrer].referrerID];
            referer = userAddressByID[userInfos[nextReferrer].referrerID];
        }
        else if(_level == 5 || _level == 10) {
            nextReferrer = userAddressByID[userInfos[_user].referrerID];
            nextReferrer = userAddressByID[userInfos[nextReferrer].referrerID];
            nextReferrer = userAddressByID[userInfos[nextReferrer].referrerID];
            nextReferrer = userAddressByID[userInfos[nextReferrer].referrerID];
            referer = userAddressByID[userInfos[nextReferrer].referrerID];
        }
       }
        else 
         referer = userAddressByID[userInfos[_user].referrerID];

        if(!userInfos[referer].joined) referer = userAddressByID[1];

        if(userInfos[referer].levelExpired[_level] > 0) {
            address(uint160(referer)).send((priceOfLevel[_level].mul(uint(44).mul(10**18))).div(10**20));
            userInfos[referer].totalEarningEth = userInfos[referer].totalEarningEth.add(priceOfLevel[_level]);
            EarnedEth[referer][_level] = EarnedEth[referer][_level].add(priceOfLevel[_level]);
            userInfos[referer].levelExpired[_level]--;
            emit paidForLevelEv(referer, msg.sender, _level, msg.value, now);
        }

        else  {
            emit lostForLevelEv(referer, msg.sender, _level, msg.value, now);
            payForLevelUpline(_level,referer, true);
        }
       
    }
    
     function payForLevelSponsor(uint _level, address _user, bool _loop) internal {
        address sponsor;
        address nextSponsor;
        
        if(!_loop){
         if(_level == 1 || _level == 6) {
            sponsor = userAddressByID[userInfos[_user].sponsorID];
        }
        if(_level == 2 || _level == 7) {
            nextSponsor = userAddressByID[userInfos[_user].sponsorID];
            sponsor = userAddressByID[userInfos[nextSponsor].sponsorID];
        }
        else if(_level == 3 || _level == 8) {
            nextSponsor = userAddressByID[userInfos[_user].sponsorID];
            nextSponsor = userAddressByID[userInfos[nextSponsor].sponsorID];
            sponsor = userAddressByID[userInfos[nextSponsor].sponsorID];
            
        }
        else if(_level == 4 || _level == 9) {
            nextSponsor = userAddressByID[userInfos[_user].sponsorID];
            nextSponsor = userAddressByID[userInfos[nextSponsor].sponsorID];
            nextSponsor = userAddressByID[userInfos[nextSponsor].sponsorID];
            sponsor = userAddressByID[userInfos[nextSponsor].sponsorID];
        }
        else if(_level == 5 || _level == 10) {
            nextSponsor = userAddressByID[userInfos[_user].sponsorID];
            nextSponsor = userAddressByID[userInfos[nextSponsor].sponsorID];
            nextSponsor = userAddressByID[userInfos[nextSponsor].sponsorID];
            nextSponsor = userAddressByID[userInfos[nextSponsor].sponsorID];
            sponsor = userAddressByID[userInfos[nextSponsor].sponsorID];
        }
        }
        else 
         sponsor = userAddressByID[userInfos[_user].sponsorID];

        if(!userInfos[sponsor].joined) sponsor = userAddressByID[1];
        
        if(userInfos[sponsor].levelExpired[_level] > 0) {
            address(uint160(sponsor)).send((priceOfLevel[_level].mul(uint(46).mul(10**18))).div(10**20));
            userInfos[sponsor].totalEarningEth = userInfos[sponsor].totalEarningEth.add(priceOfLevel[_level]);
            EarnedEth[sponsor][_level] = EarnedEth[sponsor][_level].add(priceOfLevel[_level]);
            emit paidForLevelEv(sponsor, msg.sender, _level, msg.value, now);
        }

        else  {
            emit lostForLevelEv(sponsor, msg.sender, _level, msg.value, now);
            payForLevelSponsor(_level, sponsor, true);
        }
       
    }
    
    function getTotalEarnedEther(uint fromID, uint toID) public view returns (uint) {
        uint totalEth;
        for (uint i = fromID; i <=toID; i++) {
            totalEth = totalEth.add(userInfos[userAddressByID[i]].totalEarningEth);
        }
        return totalEth;
    }

    function findFreeReferrer(address _user) public view returns(address) {
        if(userInfos[_user].referral.length < maxDownLimit) return _user;

        address[] memory referrals = new address[](126);
        referrals[0] = userInfos[_user].referral[0];
        referrals[1] = userInfos[_user].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 126; i++) {
            if(userInfos[referrals[i]].referral.length == maxDownLimit) {
                if(i < 62) {
                    referrals[(i+1)*2] = userInfos[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = userInfos[referrals[i]].referral[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return userInfos[_user].referral;
    }

    function viewUserLevelExpired(address _user, uint _level) public view returns(uint) {
        return userInfos[_user].levelExpired[_level];
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
    function updateUserInfo(uint _id, uint _sponsorID, uint _referrerID) onlyOwner public{
        userInfos[userAddressByID[_id]].id = _id;
        userInfos[userAddressByID[_id]].sponsorID = _sponsorID;
        userInfos[userAddressByID[_id]].referrerID = _referrerID;
    }
    
    function updateUserLevelExpired(uint _id, uint _level, uint _expiry) onlyOwner public {
        userInfos[userAddressByID[_id]].levelExpired[_level] = _expiry;
    }
    
  
    function updateInternals(uint _svFee, uint _tokenMultiplier, uint _level1Price, uint _level2Price, uint _level3Price, uint _level4Price, uint _level5Price, uint _level6Price, uint _level7Price, uint _level8Price, uint _level9Price, uint _level10Price) onlyOwner public {
        svFee = _svFee;
        svTokenMultiplier = _tokenMultiplier;
        priceOfLevel[1] = _level1Price;
        priceOfLevel[2] = _level2Price;
        priceOfLevel[3] = _level3Price;
        priceOfLevel[4] = _level4Price;
        priceOfLevel[5] = _level5Price;
        priceOfLevel[6] = _level6Price;
        priceOfLevel[7] = _level7Price;
        priceOfLevel[8] = _level8Price;
        priceOfLevel[9] = _level9Price;
        priceOfLevel[10] = _level10Price;
    }
    
}
