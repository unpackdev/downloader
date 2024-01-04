pragma solidity ^0.5.16;

contract IERC20{
    function transfer(address _to, uint _value) public returns (bool success);
    function balanceOf(address user) public view returns (uint256 balance);
}

contract AirDrop {
    IERC20 token;
    address owner;
    uint public reward;
    uint public inviteReward;
    mapping(address => address)  relationship;
    mapping(address => address[]) public invitationStorage;
    mapping(address => uint) public numOfInvitations;
    address[] public participationList;    
    mapping(address => uint) public participationIndex;
    
    constructor(address erc20_, uint reward_, uint inviteReward_) public{
        owner = msg.sender;
        token = IERC20(erc20_);
        reward = reward_ * 10**18;
        inviteReward = inviteReward_ * 10**18;
        
        participationList.push(address(0)); //
    }
    
    modifier updateParticipationList(){
       require(participationIndex[msg.sender] < 1, 'Participated!');
       participationIndex[msg.sender] = participationListLength();
       participationList.push(msg.sender);
       
        _;
    }
   function getAirDrop() public updateParticipationList{ //  
       
       _transfer(msg.sender,reward);
       
   }
   function getAirDropByInvitation(address inviter) public updateParticipationList{
       
       _transfer(msg.sender,reward);
       
       _setInviter(msg.sender, inviter);
       _transfer(inviter, inviteReward);
   }
   function _setInviter(address invitee , address inviter) internal{
        // require(participationIndex[inviter] > 0, 'The inviter must have participated!');
        relationship[invitee] = inviter;
        invitationStorage[inviter].push(invitee);
        numOfInvitations[inviter] = numOfInvitations[inviter] + 1;
    }
   function getInviter(address invitee) public view returns (address inviter){
        return relationship[invitee];
    }
    
   function participationListLength() public view returns (uint256 count){
        return participationList.length;
    }
    
   function _transfer(address _to,uint256 _amount) internal{
     bool success = token.transfer(_to, _amount);  
     require(success,"failed!");
   }
   
   function getBalance() public view returns(uint256 balance){
       return token.balanceOf(address(this));
   }
   
   function takeOut() public{
       require(msg.sender == owner);
       _transfer(owner, token.balanceOf(address(this)));
   }
}