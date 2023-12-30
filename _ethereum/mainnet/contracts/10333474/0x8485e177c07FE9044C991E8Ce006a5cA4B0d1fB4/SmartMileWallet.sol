// ----------------------------------------------------------------------------
// Company Name : Mile Wallet 
// Website      : www.milewallet.co
//
// (c) by MILE WALLET.
// --


pragma solidity ^0.5.7;


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}


contract Ownable {

  address public owner;
  address public manager;
  address public ownerWallet;

  constructor() public {
    owner = msg.sender;
    manager = msg.sender;
    ownerWallet = 0x19bAf1B6C28F89248174397fBE1cD436c256B54e;
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

contract SmartMileWallet is Ownable {

    event regLevelEvent(address indexed _user, address indexed , uint _time);
    event buyLevelEvent(address indexed _user, uint _level, uint _time);
    event prolongateLevelEvent(address indexed _user, uint _level, uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed , uint _level, uint _time);
    event lostMoneyForLevelEvent(address indexed _user, address indexed , uint _level, uint _time);
    //------------------------------

    mapping (uint => uint) public LEVEL_PRICE;
    uint PERIOD_LENGTH = 365 days;


    struct UserStruct {
        bool isExist;
        uint id;
        mapping (uint => uint) levelExpired;
    }

    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;




    constructor() public {

        LEVEL_PRICE[1] = 0.10 ether;
        LEVEL_PRICE[2] = 0.10 ether;
        LEVEL_PRICE[3] = 0.20 ether;
        LEVEL_PRICE[4] = 0.40 ether;
        LEVEL_PRICE[5] = 1.00 ether;
        LEVEL_PRICE[6] = 5.00 ether;
        LEVEL_PRICE[7] = 8.00 ether;
        LEVEL_PRICE[8] = 20.00 ether;
        LEVEL_PRICE[9] = 100.00 ether;


        users[ownerWallet].levelExpired[1] = 77777777777;
        users[ownerWallet].levelExpired[2] = 77777777777;
        users[ownerWallet].levelExpired[3] = 77777777777;
        users[ownerWallet].levelExpired[4] = 77777777777;
        users[ownerWallet].levelExpired[5] = 77777777777;
        users[ownerWallet].levelExpired[6] = 77777777777;
        users[ownerWallet].levelExpired[7] = 77777777777;
        users[ownerWallet].levelExpired[8] = 77777777777;
        users[ownerWallet].levelExpired[9] = 77777777777;

    }

    function () external payable {

        uint level;

        if(msg.value == LEVEL_PRICE[1]){
            level = 1;
        }else if(msg.value == LEVEL_PRICE[2]){
            level = 2;
        }else if(msg.value == LEVEL_PRICE[3]){
            level = 3;
        }else if(msg.value == LEVEL_PRICE[4]){
            level = 4;
        }else if(msg.value == LEVEL_PRICE[5]){
            level = 5;
        }else if(msg.value == LEVEL_PRICE[6]){
            level = 6;
        }else if(msg.value == LEVEL_PRICE[7]){
            level = 7;
        }else if(msg.value == LEVEL_PRICE[8]){
            level = 8;
        }else if(msg.value == LEVEL_PRICE[9]){
            level = 9;
        }else {
            revert('Incorrect Value send');
        }


        UserStruct memory userStruct;

        users[msg.sender] = userStruct;

        users[msg.sender].levelExpired[1] = now + PERIOD_LENGTH;
        users[msg.sender].levelExpired[2] = 0;
        users[msg.sender].levelExpired[3] = 0;
        users[msg.sender].levelExpired[4] = 0;
        users[msg.sender].levelExpired[5] = 0;
        users[msg.sender].levelExpired[6] = 0;
        users[msg.sender].levelExpired[7] = 0;
        users[msg.sender].levelExpired[8] = 0;
        users[msg.sender].levelExpired[9] = 0;


        payForLevel(1, msg.sender);

    }

    function buyLevel(uint _level) public payable {
        require(users[msg.sender].isExist, 'User not exist');

        require( _level>0 && _level<=9, 'Incorrect level');

        if(_level == 1){
            require(msg.value==LEVEL_PRICE[1], 'Incorrect Value');
            users[msg.sender].levelExpired[1] += PERIOD_LENGTH;
        } else {
            require(msg.value==LEVEL_PRICE[_level], 'Incorrect Value');

            for(uint l =_level-1; l>0; l-- ){
                require(users[msg.sender].levelExpired[l] >= now, 'Buy the previous level');
            }

            if(users[msg.sender].levelExpired[_level] == 0){
                users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
            } else {
                users[msg.sender].levelExpired[_level] += PERIOD_LENGTH;
            }
        }
        payForLevel(_level, msg.sender);
        emit buyLevelEvent(msg.sender, _level, now);
    }

    function payForLevel(uint _level, address _user) internal {


    }
}