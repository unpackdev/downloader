/*
         		 					 
telegram: @etheriums
hashtag: #etheriums

*/
pragma solidity ^0.5.7;

contract Ownable {

  address public owner;
  address public manager;
  address public ownerWallet;
  address public refererWallet;

  constructor() public {
    owner 			= msg.sender;
    manager 		= msg.sender;
    ownerWallet 	= 0xEF8498198158959FFd4900Be18C61B02BDE93882;
    refererWallet 	= 0x61B596e5FEaa6B0fb9164206aD1DdA58707136b7;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "only for owner");
    _;
  }

  modifier onlyOwnerOrManager() {
     require((msg.sender == owner)||(msg.sender == manager), "only for owner or manager");
      _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }

  function setManager(address _manager) public onlyOwnerOrManager {
      manager = _manager;
  }
}

contract ETHERIUMS is Ownable {

    event regLevelEvent(address indexed _user, address indexed _referrer, uint _amount);
    event regWithoutPaymentEvent(address indexed _user, address indexed _referrer, uint _amount);
    event getMoneyForReferralEvent(address indexed _user, address indexed _referral, uint _amount, uint _level);
    event accountStatusChanged(address indexed _user, uint _status);
    event accountStatusFailed(address indexed _user, uint _status,  uint _type);
    //------------------------------

    struct UserStruct {
        bool isExist;
        uint id;
        uint isActive;
        uint referrerID;
        address[] referral;
    }
    mapping (uint => uint) public LEVEL_COMMISION;
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    uint public currUserID = 0;


    constructor() public {

        LEVEL_COMMISION[1] =  30;
        LEVEL_COMMISION[2] =  20;
        LEVEL_COMMISION[3] =  10;
        LEVEL_COMMISION[4] =  6;
        LEVEL_COMMISION[5] =  4;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            isActive : 1,
            referrerID : 0,
            referral : new address[](0)
        });
        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;
		
        currUserID++;

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
			isActive : 1,
            referrerID : 0,
            referral : new address[](0)
        });
        users[refererWallet] = userStruct;
        userList[currUserID] = refererWallet;
		
    }

    function () external payable {

        if(users[msg.sender].isExist){
            revert('User already subscribed');
        } else{
            uint refId = 0;
			
            address referrer = bytesToAddress(msg.data);
    
            if (users[referrer].isExist){
                refId = users[referrer].id;
            } else { // if no referrer then refererWallet will be referer
                refId = users[refererWallet].id;
            }
            regUser(refId);
        } 
    }

    function regUser(uint _referrerID) public payable {
	
        require(!users[msg.sender].isExist, 'User exist');

        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referrer Id');

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
			isActive : 1,
            referrerID : _referrerID,
            referral : new address[](0)
        });

        users[msg.sender] 		= 	userStruct;
        userList[currUserID] 	= 	msg.sender;

        users[userList[_referrerID]].referral.push(msg.sender);

        payForReferral(msg.sender);

        emit regLevelEvent(msg.sender, userList[_referrerID], msg.value);
    }

    function payForReferral(address _address) internal {

        address referer1;
        address referer2;
        address referer3;
        address referer4;
        address referer5;
	
		uint amount;
		
		referer1 = userList[users[_address].referrerID];
		if(users[referer1].isExist && users[referer1].isActive==1){
			amount 	=	(LEVEL_COMMISION[1] * msg.value) / 100;
			address(uint160(referer1)).transfer(amount);
			emit getMoneyForReferralEvent(referer1, msg.sender, amount, 1);
        }
		referer2 = userList[users[referer1].referrerID];
		if(users[referer2].isExist && users[referer2].isActive==1){
            amount 	=	(LEVEL_COMMISION[2] * msg.value) / 100;
			address(uint160(referer2)).transfer(amount);
			emit getMoneyForReferralEvent(referer2, msg.sender, amount, 2);
        }
		referer3 = userList[users[referer2].referrerID];
		if(users[referer3].isExist && users[referer3].isActive==1){
            amount 	=	(LEVEL_COMMISION[3] * msg.value) / 100;
			address(uint160(referer3)).transfer(amount);
			emit getMoneyForReferralEvent(referer3, msg.sender, amount, 3);
        }
		referer4 = userList[users[referer3].referrerID];
		if(users[referer4].isExist && users[referer4].isActive==1){
            amount 	=	(LEVEL_COMMISION[4] * msg.value) / 100;
			address(uint160(referer4)).transfer(amount);
			emit getMoneyForReferralEvent(referer4, msg.sender, amount, 4);
        }
		referer5 = userList[users[referer4].referrerID];
		if(users[referer5].isExist && users[referer5].isActive==1){
            amount 	=	(LEVEL_COMMISION[5] * msg.value) / 100;
			address(uint160(referer5)).transfer(amount);
			emit getMoneyForReferralEvent(referer5, msg.sender, amount, 5);
        }
		sendBalance();
    }
	
	function getEthBalance() public view returns(uint) {
		return address(this).balance;
    }
	
	function makeAccountActiveInactive(address _address, address _referrer, uint _active)  public onlyOwnerOrManager returns(bool) {
		
		if(users[_address].isExist){
			if(_active==1){
				if(users[_address].isActive==1){
					emit accountStatusFailed(_address, _active, 1);
					revert('Already Active');
				}else{
					users[_address].isActive	=	1;
					emit accountStatusChanged(_address, 1);
					return true;
				}
			}else if(_active==0){
				if(users[_address].isActive==0){
					emit accountStatusFailed(_address, _active, 2);
					revert('Already inactive');
				}else{
					users[_address].isActive	=	0;
					emit accountStatusChanged(_address, 0);
					return true;
				}
			}else{
				emit accountStatusFailed(_address, _active, 3);
				revert('Invalid Type');
			}
		}else{
			if(_active==1){
				uint _referrerID;
				if (users[_referrer].isExist){
					_referrerID = users[_referrer].id;
				} else { // if no _referrer then refererWallet will be referer
					_referrerID = users[refererWallet].id;
				}
				UserStruct memory userStruct;
				currUserID++;

				userStruct = UserStruct({
					isExist : true,
					id : currUserID,
					isActive : 1,
					referrerID : _referrerID,
					referral : new address[](0)
				});

				users[_address] 		= 	userStruct;
				userList[currUserID] 	= 	_address;
				users[userList[_referrerID]].referral.push(_address);
				
				emit regWithoutPaymentEvent(_address, userList[_referrerID], 0);
				
				return true;
			}else{
				emit accountStatusFailed(_address, _active, 4);
				revert('Invalid address');
			}
		}	
	}
	
	function getAccountStatus(address _address) public view returns(uint) {
		return users[_address].isActive;	
	}
	
    
    function sendBalance() private
    {
		uint amount =	getEthBalance();
		address(uint160(ownerWallet)).transfer(amount);
		emit getMoneyForReferralEvent(ownerWallet, msg.sender, amount, 1);
    }
	
    function viewUserReferral(address _address) public view returns(address[] memory) {
        return users[_address].referral;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address  addr ) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}