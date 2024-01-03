pragma solidity 0.5.17;


contract Ownable {


  address newOwner;
  mapping (address=>bool) owners;
  address owner;

// all events will be saved as log files
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AddOwner(address newOwner,string name);
  event RemoveOwner(address owner);

   constructor() public {
    owner = msg.sender;
    owners[msg.sender] = true;
  }

  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }

  modifier onlyOwners(){
    require(owners[msg.sender] == true || msg.sender == owner);
    _;
  }

  function addOwner(address _newOwner,string memory newOwnerName) public onlyOwners{
    require(owners[_newOwner] == false);
    require(newOwner != msg.sender);
    owners[_newOwner] = true;
    emit AddOwner(_newOwner,newOwnerName);
  }


  function removeOwner(address _owner) public onlyOwners{
    require(_owner != msg.sender);  // can't remove your self
    owners[_owner] = false;
    emit RemoveOwner(_owner);
  }

  function isOwner(address _owner) public view returns(bool){
    return owners[_owner];
  }

}


contract SZOCalcReward is Ownable{
    uint256 public version = 1;
    uint256  public  maxPerDay = 10000 ether;
    uint256  public  amountPerToken;
    uint256  public  specialBonus; // percent
    
    uint256  public  rewardPerSec;
    
    
    constructor() public{
        amountPerToken = 50 ether;
        specialBonus = 60 days;
        rewardPerSec = 1 ether;// / 2592000; // 30 day
        rewardPerSec /= 2592000;
        
    }
    
    function getReward(uint256 _time,uint256 _amount) public view returns(uint256){
         uint256 _reward = (_amount * (_time * rewardPerSec)) / amountPerToken;  
         return _reward;
    }
    
    function setRewardRatio(uint256 _amount) public onlyOwners{
        amountPerToken = _amount;
    }
    
    function setSpecialBonus(uint256 _time) public onlyOwners{
        specialBonus = _time;
    }
}