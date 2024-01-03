pragma solidity >=0.5.11;

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

contract QuantumIO{
    using SafeMath for uint256;
    uint256 internal constant ENTRY_AMOUNT = 0.05 ether;
    uint256[] internal basketPrice;
    uint256 internal totalUsers;
    uint256 internal extraWallet;
    address owner;
    
    struct User {
        uint256 id;
        uint256[] referralArray;
        address upline;
        uint256 basketsPurchased;
        uint256 totalEarning;
        bool isExist;
        
    }
    struct UserCycles{
        uint256 cycle1;
        uint256 cycle2;
        uint256 cycle3;
        uint256 cycle4;
        uint256 cycle5;
        uint256 cycle6;
        uint256 cycle7;
        uint256 cycle8;
        uint256 cycle9;
        uint256 cycle10;
        uint256 cycle11;
        uint256 cycle12;
        uint256 cycle13;
    }
    
    mapping(address => User) public users;
    mapping(uint256 => address) internal usersId;
    mapping(address => UserCycles) public cycles;
    event RegisterEvent(address _add);
    event DistributeAmountEvent(address _upline, uint256 _percent, uint256 _amount);
    event BuyBasketEvent(address _user,uint256 _basketNumber);
    event ExtraWalletTransferEvent(uint256 _percent,uint256 _amount);
 
    constructor(address _owner) public payable {
        owner = _owner;
        require(msg.value >= ENTRY_AMOUNT, "insufficient amount");
        extraWallet = extraWallet.add(0.05 ether);
        address(uint256(owner)).transfer(0.05 ether);
        totalUsers = 1;
        users[msg.sender].id = totalUsers;
        users[msg.sender].isExist = true;
        users[msg.sender].upline = address(0);
        users[msg.sender].basketsPurchased = 1;
        
        usersId[totalUsers] = msg.sender;
        
        basketPrice.push(0.05 ether);
        basketPrice.push(0.1 ether);
        basketPrice.push(0.2 ether);
        basketPrice.push(0.4 ether);
        basketPrice.push(0.8 ether);
        basketPrice.push(1.6 ether);
        basketPrice.push(3.2 ether);
        basketPrice.push(6.4 ether);
        basketPrice.push(12.8 ether);
        basketPrice.push(25.6 ether);
        basketPrice.push(51.2 ether);
        basketPrice.push(102.4 ether);
        basketPrice.push(204.8 ether);
    }

    //function to register user
    function Register(address _upline) public payable {
        require(msg.value >= ENTRY_AMOUNT, "less amount");
        require(users[msg.sender].isExist == false, "user already exist");
        require(users[_upline].isExist == true, "upline not exist");

        totalUsers++;
        users[msg.sender].id = totalUsers;
        users[msg.sender].upline = _upline;
        users[msg.sender].isExist = true;

        users[msg.sender].basketsPurchased=1;
        usersId[totalUsers] = msg.sender;
        users[_upline].referralArray.push(totalUsers);
        cycles[_upline].cycle1++;
        if(cycles[_upline].cycle1%4==0)
        amountDistribute(1,true);
        else
        amountDistribute(1,false);
      
        emit RegisterEvent(msg.sender);
    }
    
    
    //function to distribute basket amount ie 50% 25% 15% 10% if its not 4th user of that cycle
    function amountDistribute(uint256 _level,bool _is4thUser) internal{
       bool flag;
        if(_is4thUser){
            address ref=users[users[msg.sender].upline].upline;
            while(ref!=address(0)){
                if(checkEligibility(ref,_level) ){
                 users[ref].totalEarning=users[ref].totalEarning.add(basketPrice[_level-1]);
                 address(uint256(ref)).transfer(basketPrice[_level-1]);
                 flag = true;
                 break;
                }
                ref=users[ref].upline;
            }
            if(flag==false){
                address(uint256(owner)).transfer(basketPrice[_level-1]);
            }
          
        }
        else
        {
            uint256 total = 100;
            uint256 currAmount = 50;
            address ref = users[msg.sender].upline;
            while(currAmount!=0 && ref!=address(0)){
              if(users[ref].basketsPurchased>=_level && currAmount==50){
                  users[ref].totalEarning= users[ref].totalEarning.add(basketPrice[_level-1].mul(currAmount).div(100));
                   address(uint256(ref)).transfer(basketPrice[_level-1].mul(currAmount).div(100));
                   emit DistributeAmountEvent(ref,currAmount,basketPrice[_level-1].mul(currAmount).div(100));
                  currAmount = 25;
                  total = total.sub(50);
              }  
              else if(users[ref].basketsPurchased>=_level && currAmount==25){
                  users[ref].totalEarning= users[ref].totalEarning.add(basketPrice[_level-1].mul(currAmount).div(100));
                   address(uint256(ref)).transfer(basketPrice[_level-1].mul(currAmount).div(100));
                   emit DistributeAmountEvent(ref,currAmount,basketPrice[_level-1].mul(currAmount).div(100));
                  currAmount = 15;
                  total = total.sub(25);
            }
             else if(users[ref].basketsPurchased>=_level && currAmount==15){
                  users[ref].totalEarning= users[ref].totalEarning.add(basketPrice[_level-1].mul(currAmount).div(100));
                   address(uint256(ref)).transfer(basketPrice[_level-1].mul(currAmount).div(100));
                   emit DistributeAmountEvent(ref,currAmount,basketPrice[_level-1].mul(currAmount).div(100));
                  currAmount = 10;
                  total = total.sub(15);
            }
             else if(users[ref].basketsPurchased>=_level && currAmount==10){
                  users[ref].totalEarning= users[ref].totalEarning.add(basketPrice[_level-1].mul(currAmount).div(100));
                  address(uint256(ref)).transfer(basketPrice[_level-1].mul(currAmount).div(100));
                  emit DistributeAmountEvent(ref,currAmount,basketPrice[_level-1].mul(currAmount).div(100));
                  currAmount = 0;
                  total = total.sub(10);
            }
           
            ref = users[ref].upline;
            }
            
            extraWallet = extraWallet.add(basketPrice[_level-1].mul(total).div(100));
            address(uint256(owner)).transfer(basketPrice[_level-1].mul(total).div(100));
            emit ExtraWalletTransferEvent(total,basketPrice[_level-1].mul(total).div(100));
        }
    }
    
    // function to buy a basket
    function buyBasket(uint256 _basketNumber) public payable {
        require(
            _basketNumber > users[msg.sender].basketsPurchased &&
                _basketNumber <= 13,
            "basket already purchased"
        );
        require(_basketNumber == users[msg.sender].basketsPurchased+1,"you need to purchase previous basket first");
        require(
            msg.value >= basketPrice[_basketNumber - 1],
            "you should have enough balance"
        );
        
        users[msg.sender].basketsPurchased = users[msg.sender]
            .basketsPurchased
            .add(1);
            emit BuyBasketEvent(msg.sender,_basketNumber);
            
            if(_basketNumber == 2){
                cycles[users[msg.sender].upline].cycle2 ++;
                if(cycles[users[msg.sender].upline].cycle2%4==0){
                    amountDistribute(_basketNumber,true);
                }
                else
                amountDistribute(_basketNumber,false);
            }
            else  if(_basketNumber == 3){
                cycles[users[msg.sender].upline].cycle3 ++;
                if(cycles[users[msg.sender].upline].cycle3%4==0){
                    amountDistribute(_basketNumber,true);
                }
                else
                amountDistribute(_basketNumber,false);
            }
            else  if(_basketNumber == 4){
                cycles[users[msg.sender].upline].cycle4 ++;
                if(cycles[users[msg.sender].upline].cycle4%4==0){
                    amountDistribute(_basketNumber,true);
                }
                else
                amountDistribute(_basketNumber,false);
            }
            else  if(_basketNumber == 5){
                cycles[users[msg.sender].upline].cycle5 ++;
                if(cycles[users[msg.sender].upline].cycle5%4==0){
                    amountDistribute(_basketNumber,true);
                }
                else
                amountDistribute(_basketNumber,false);
            }
            else  if(_basketNumber == 6){
                cycles[users[msg.sender].upline].cycle6 ++;
                if(cycles[users[msg.sender].upline].cycle6%4==0){
                    amountDistribute(_basketNumber,true);
                }
                else
                amountDistribute(_basketNumber,false);
            }
            else  if(_basketNumber == 7){
                cycles[users[msg.sender].upline].cycle7 ++;
                if(cycles[users[msg.sender].upline].cycle7%4==0){
                    amountDistribute(_basketNumber,true);
                }
                else
                amountDistribute(_basketNumber,false);
            }
            else  if(_basketNumber == 8){
                cycles[users[msg.sender].upline].cycle8 ++;
                if(cycles[users[msg.sender].upline].cycle8%4==0){
                    amountDistribute(_basketNumber,true);
                }
                else
                amountDistribute(_basketNumber,false);
            }
            else  if(_basketNumber == 9){
                cycles[users[msg.sender].upline].cycle9 ++;
                if(cycles[users[msg.sender].upline].cycle9%4==0){
                    amountDistribute(_basketNumber,true);
                }
                else
                amountDistribute(_basketNumber,false);
            }
            else  if(_basketNumber == 10){
                cycles[users[msg.sender].upline].cycle10 ++;
                if(cycles[users[msg.sender].upline].cycle10%4==0){
                    amountDistribute(_basketNumber,true);
                }
                else
                amountDistribute(_basketNumber,false);
            }
            else  if(_basketNumber == 11){
                cycles[users[msg.sender].upline].cycle11 ++;
                if(cycles[users[msg.sender].upline].cycle11%4==0){
                    amountDistribute(_basketNumber,true);
                }
                else
                amountDistribute(_basketNumber,false);
            }
            else  if(_basketNumber == 12){
                cycles[users[msg.sender].upline].cycle12 ++;
                if(cycles[users[msg.sender].upline].cycle12%4==0){
                    amountDistribute(_basketNumber,true);
                }
                else
                amountDistribute(_basketNumber,false);
            }
            else  if(_basketNumber == 13){
                cycles[users[msg.sender].upline].cycle13 ++;
                if(cycles[users[msg.sender].upline].cycle13%4==0){
                    amountDistribute(_basketNumber,true);
                }
                else
                amountDistribute(_basketNumber,false);
            }
            
    }
  
 
  function checkEligibility(address _user,uint256 _basketNumber) internal view returns(bool){
      if(cycles[_user].cycle1%4 >= 1){
          if(users[_user].basketsPurchased>1 && users[_user].basketsPurchased>= _basketNumber){
              return true;
          }
          else
          return false;
      }
      else{
          if(users[_user].basketsPurchased>= _basketNumber){
              return true;
          }
          else
          return false;
      }
  }
//   external getter functions

    function getUserInfo(address _addr) external view returns(
        uint256 id,
        address upline,
        uint256 basketsPurchased,
        uint256 totalEarning,
        bool isExist
        ){
            User memory user=users[_addr];
            return (user.id,user.upline,user.basketsPurchased,user.totalEarning,user.isExist);
    }
    
    function getTotalUsers() public view returns(uint256){
        return totalUsers;
    }
    
    function getUserAddressUsingId(uint256 _id) public view returns(address){
        return usersId[_id];
    }
    
 

}