/*
Donation Exchange dexGiver smart-contract
*/

pragma solidity ^0.5.17;

library SafeMath32 {  
    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        require(b <= a, errorMessage);
        uint32 c = a - b;
        return c;
    }
}

library SafeMath128 {
    function mul(uint128 a, uint128 b) internal pure returns (uint128) {
        if (a == 0) {
            return 0;
        }
        uint128 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b <= a, errorMessage);
        uint128 c = a - b;
        return c;
    }
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

library SafeMath256 {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}


contract dexTokenInterface {
    function mintRefTokens(address referrer, address founder, uint32 id) external payable returns (bool);
    function mintForUnreachableAddress(address userAddress, uint32 donationTurn) external payable returns (bool);
}


contract dexGiver {
    
    using SafeMath32 for uint32;
    using SafeMath128 for uint128;
    using SafeMath256 for uint256;


    event addDonationEvent(
        address indexed user,
        address indexed referrer,
        uint128 amount,
        uint32 indexed id,
        uint64 time);
        
    event trasferDonationRewardEvent(
        address indexed reciever,
        address indexed donator,
        uint128 amount,
        uint32 indexed id,
        uint64 time);
        
    event putedIntoUserList(
        address indexed user,
        address indexed referrer,
        uint32 indexed id,
        uint64 time);


    struct DonationStruct {
        address user;
        uint128 trust;
        uint128 reward;
    }
    
    mapping (address => address) public refLinks;
    mapping (uint32 => DonationStruct) public donationsList;
    
    address private owner;
    address private founder;
    address private dexTokenAddress;
    string private support;
    uint128 private min;
    uint128 private max;
    uint32 private donationsCounter;
    uint32 private turn;
    uint32 private currentUser;
    uint8 constant donationPercent = 15;
    uint8 constant rewardPercent = 15;


    constructor() public {
        owner = msg.sender;
        founder = msg.sender;
        refLinks[msg.sender] = msg.sender;
        min = 50000000000000000;
        max = 5000000000000000000;
        donationsCounter = 0;
        turn = 0;
        currentUser = 1;
    }
    
    dexTokenInterface dexToken;


    modifier onlyOwner() {
        require (msg.sender == owner, "Only for owner");
        _;
    }
    
    modifier dexTokenOnly() {
        require (msg.sender == dexTokenAddress, "Only for dexToken contract");
        _;
    }
    
    function changeDexTokenAddress(address _newDexTokenAddress) external onlyOwner {
        dexTokenAddress = _newDexTokenAddress;
        dexToken = dexTokenInterface(_newDexTokenAddress);
        assert(dexTokenAddress == _newDexTokenAddress);
    }
    
    function changeOwnerAddress(address _newOwner) external onlyOwner {
        owner = _newOwner;
        assert(owner == _newOwner);
    }
    
    function changeFounderAddress(address _newFounder) external onlyOwner {
        refLinks[founder] = _newFounder;
        refLinks[_newFounder] = _newFounder;
        founder = _newFounder;
        assert(founder == _newFounder);
    }

    function changeMinMax(uint128 _newMin, uint128 _newMax) external onlyOwner {
        min = _newMin;
        max = _newMax;
        assert(min == _newMin && max == _newMax);
    }
    
    function changeSupport(string calldata _newSupport) external onlyOwner {
        support = _newSupport;
    }
    
    
    
    
    function () external payable {
        require(msg.sender != dexTokenAddress, "No access for dexToken");
        require(msg.value >= min && msg.value <= max, 'Wrong donation amount!');
        
        (address referrer, uint32 id) = setReferrer();
        
        transferRewards(referrer, id);
        
        donationsTransfer(msg.sender);
    }
    
    
    function setReferrer() private returns (address, uint32) {
        
        address refLinksReferrer = refLinks[msg.sender];
        address hexDataAddress = bytesToAddress(msg.data);
            require(hexDataAddress != address(this));
        address resultReferrer;
        
        if (refLinksReferrer != address(0)) {

            resultReferrer = refLinksReferrer;

        } else if (refLinks[hexDataAddress] != address(0)) {

            refLinks[msg.sender] = hexDataAddress;
            putUserIntoUserList(msg.sender, hexDataAddress);
            resultReferrer = hexDataAddress;

        } else {
            
            refLinks[msg.sender] = dexTokenAddress;
            putUserIntoUserList(msg.sender, dexTokenAddress);
            resultReferrer = dexTokenAddress;
            
        }
        
        uint32 donationId = addDonation(resultReferrer);
        return (resultReferrer, donationId);
    }
    

    function addDonation(address _referrer) private returns (uint32) {
        
        uint32 donationId = donationsCounter;
        
        donationsList[donationId] = DonationStruct(msg.sender, uint128(msg.value.mul(uint(donationPercent).add(100)).div(100)), 0);
        
        donationsCounter++;
        
        emit addDonationEvent(
            msg.sender,
            _referrer,
            uint128(msg.value),
            donationId,
            uint64(now));
        
        return donationId;
    }
    
    
    function transferRewards(address _referrer, uint32 _id) private {
        
        uint256 rewardAmount = uint256(msg.value.mul(uint(rewardPercent)).div(100));
        
        (bool success) = dexToken.mintRefTokens.value(rewardAmount)(_referrer, founder, _id);
        require(success, "Tokens were not minted");
    }
    
    
    function _donationsTransfer(address _dexTokenBuyer) external payable dexTokenOnly returns (bool) {
        bool result = donationsTransfer(_dexTokenBuyer);
        return result;
    }
    

    function donationsTransfer(address _donator) private returns (bool) {
        
        uint128 balance = uint128(address(this).balance);
        uint32 tempTurn = turn;
        uint32 tempDonationCounter = donationsCounter;

        while (balance > 0 && tempDonationCounter > tempTurn) {
            uint128 trust = donationsList[tempTurn].trust;
            uint128 reward = donationsList[tempTurn].reward;
            uint128 debt = trust.sub(reward);

            if ( debt <= balance) {
                
                donationsList[tempTurn].reward = trust;
                
                address payable rewardReciever = address(uint160(donationsList[tempTurn].user));
                
                tempTurn++;
                balance = balance.sub(debt);
                
                (bool wasEtherRecieved,) = rewardReciever.call.value(debt)("");
                
                if(!wasEtherRecieved) {
                    (bool success) = dexToken.mintForUnreachableAddress.value(debt)(rewardReciever, tempTurn.sub(1));
                    require(success);
                } else {
                    emit trasferDonationRewardEvent(rewardReciever, _donator, debt, tempTurn.sub(1), uint64(now));
                }
                
            } else {
                
                donationsList[tempTurn].reward = donationsList[tempTurn].reward.add(balance);
                
                address payable rewardReciever = address(uint160(donationsList[tempTurn].user));
                uint128 tempBalance = balance;
                balance = 0;
                
                (bool wasEtherRecieved,) = rewardReciever.call.value(tempBalance)("");
                
                if(!wasEtherRecieved) {
                    (bool success) = dexToken.mintForUnreachableAddress.value(tempBalance)(rewardReciever, tempTurn);
                    require(success);
                } else {
                    emit trasferDonationRewardEvent(rewardReciever, _donator, tempBalance, tempTurn, uint64(now));
                }
            }
            assert(address(this).balance == balance);
        }
        turn = tempTurn;
        return true;
    }
    
    
    function checkDexTokenUserReferrer(address _user, address _dataAddress) external dexTokenOnly returns (bool, address) {
        
        require(_dataAddress != address(this));
        
        address refLinksReferrer = refLinks[_user];
        address hexDataAddress = _dataAddress;
        
        if (refLinksReferrer != address(0)) {
            
            return (true, refLinksReferrer);
            
        } else if (refLinks[hexDataAddress] != address(0)) {
            
            refLinks[_user] = hexDataAddress;
            putUserIntoUserList(_user, hexDataAddress);
            
            return (true, hexDataAddress);
            
        } else {
            
            refLinks[_user] = dexTokenAddress;
            putUserIntoUserList(_user, dexTokenAddress);
            
            return (true, dexTokenAddress);
        }
    }
    
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        if (bys.length == 20) {
            assembly {
                addr := mload(add(bys, 20))
            }
            return addr;
        } else {
            return address(0);
        }
    }
    
    
    function whoIsSupport() external view returns (string memory) {
        return support;
    }
    
    
    function putUserIntoUserList(address _user, address _referrer) private {
        emit putedIntoUserList(_user, _referrer, currentUser, uint64(now));
        currentUser++;
    }
    
    
    function dataReturn(address _user) external view returns (address, uint32, uint32, uint32, uint128, uint128) {
        return (refLinks[_user], donationsCounter, turn, currentUser, min, max);
    }
    
    
    function getAddressByDonationId(uint32 _donationId) external view returns (address) {
        return donationsList[_donationId].user;
    }
    
    
    function userDonationsRewardReturn(uint[] calldata _array) external view returns (uint[] memory) {
        require(_array.length <= 100, "Too many donations");
        uint[] memory donationRewards = new uint[](_array.length);
        for(uint i = 0; i < _array.length; ++i) {
            donationRewards[i] = donationsList[uint32(_array[i])].reward;
        }
        return donationRewards;
    }
}