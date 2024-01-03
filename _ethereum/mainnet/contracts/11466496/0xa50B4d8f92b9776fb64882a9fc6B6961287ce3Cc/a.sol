contract virtualGold {
    
  uint public virtualGoldPrice;
  uint public total;
  mapping(address=>uint) public quantity;
  address virtualGoldTeam;


  constructor() {//At the core virtualgold is just a data record that is linked to each holders wallet address which stores the amount amount of virtualgold held by each of one them. The value of your virtualgold is always backed by ethereum in this smart contract.
      virtualGoldTeam=0x4560E75F1539466657a3Bf88209083ddE947015E; //This is the wallet address of the virtualgold team
      virtualGoldPrice = 0.000000001 ether; //This is the starting price of virtualgold per microgram. This value keeps increasing after every investment/virtualgold purchase. This value can never depreciate.
      total = 0; //The total quantity of virtualgold owned by everyone when the contract is deployed is 0
  }
  
  function getPrice() public constant returns(uint) {//returns the price of virtualgold
        return virtualGoldPrice;
    }

  function getQuantity(address account) public constant returns(uint) {//returns the quantity of virtualgold held by a particular address
        return quantity[account];
    }
  
  function increaseTokenPrice()returns(bool){//It is used for recalculating/updating the price per unit gram of virtualgold. This function is called after every investment as the price increases after every investment.  
      virtualGoldPrice=(address(this).balance)/(total);
      return true;
  }
  
  
  function buyVirtualGold(address referral) payable returns (bool) {
        uint amount = (msg.value*666)/1000;//66.6 percent of the ethereum investment is used for purchasing virtualgold. 
        if(quantity[referral]>0){ //ensure that the referral address is a virtualgold holder
            quantity[referral]+=(msg.value*5)/(100*virtualGoldPrice);//5% referral fee
            total+=(msg.value*5)/(100*virtualGoldPrice);//update total
            if(referral!=virtualGoldTeam){ //For 1% bonus to the investor, the referral address must be a virtualgold holder other than the virtualGoldTeam address
                amount += (msg.value*1)/100;// 1% bonus to the investor 
                total+=(msg.value*1)/(100*virtualGoldPrice);//update total
            }
        }
        quantity[msg.sender]+=(amount)/virtualGoldPrice;//virtualgold is bought by the investor and linked to his/her wallet address 
        total+=(amount)/virtualGoldPrice;//update total
        quantity[virtualGoldTeam]+=(msg.value*5)/(100*virtualGoldPrice);//5% fee to the virtualgold Team
        total+=(msg.value*5)/(100*virtualGoldPrice);//update total
        increaseTokenPrice();//Remaining 22.33%(28.33% if referral code/address is not used) is used for increasing the price of virtualgold.
    return true;
  }  
  
  
  function sellVirtualGold(uint amount) returns (bool){//cash out the holders position
    if(amount>=quantity[msg.sender]){
        amount=quantity[msg.sender];//this is done to ensure that the holder doesnt try to sell more than he/she owns
    }
    uint amountToTransfer=amount*virtualGoldPrice;//calculate the amount to transfer
    total-=amount;//update total
    quantity[msg.sender]-=amount;//reduce the holders holdings accordingly
    msg.sender.transfer(amountToTransfer);//transfer ethereum to holders address
    
    return true;
  }
  
}



contract a {
  virtualGold public vg;



  constructor() {//At the core virtualgold is just a data record that is linked to each holders wallet address which stores the amount amount of virtualgold held by each of one them. The value of your virtualgold is always backed by ethereum in this smart contract.
      vg = virtualGold(0x8e112A38817AE44D391E4ad0F568c701e225Bf07);
  }
  
    
  function getData() public constant returns(uint) {//returns the price of virtualgold
        uint n = vg.getPrice();
        return n;
    }
}