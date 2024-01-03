// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

contract virtualGold {
    
  uint private virtualGoldPrice;
  bool private preSale;
  bool private startSales;
  uint private total;
  mapping(address=>uint) private quantity;
  address private virtualGoldTeam;
  address private marketingFundAddress;


  constructor() {//At the core virtualgold is just a data record that is linked to each holders wallet address which stores the amount amount of virtualgold held by each of one them. The value of your virtualgold is always backed by ethereum in this smart contract.
      virtualGoldTeam=0xe2e78F4E954aAf5cCEB823FA163b73BCd884CFa8; //This is the wallet address of the virtualgold team
      marketingFundAddress=0x5C428bcd5cE1953288163e125f1B6AdeCBCD27c1; 
      virtualGoldPrice = 0.000000001 ether; //This is the starting price of virtualgold per microgram. This value keeps increasing after every investment/virtualgold purchase. This value can never depreciate.
      total = 0; //The total quantity of virtualgold owned by everyone when the contract is deployed is 0
      preSale=true;
      startSales=false;
  }
  
  function getPrice() external view returns(uint) {//returns the price of virtualgold
        return virtualGoldPrice;
    }
    
  function startSale() external returns(bool) {//gets called on January 19th January 2021
        require(msg.sender==virtualGoldTeam);
        startSales=true;
        return true;
    }
    
  
  function endPresale() external returns(bool) {//gets called 21 days after when the contract balnce crosses $1,000,000
        require(msg.sender==virtualGoldTeam);
        preSale=false;
        return true;
    }

  function getQuantity(address account) external view returns(uint) {//returns the quantity of virtualgold held by a particular address
        return quantity[account];
    }
  
  function increaseTokenPrice() internal returns(bool){//It is used for recalculating/updating the price per unit gram of virtualgold. This function is called after every investment as the price increases after every investment.  
      virtualGoldPrice=(address(this).balance)/(total);
      return true;
  }
  
    function buyVirtualGold(address referral) external payable returns (bool) {
        require(startSales==true,"Sales have not started yet"); // to ensure that sales have started
        uint amount;
        if (preSale==false){ //check if the presale period is over
            amount = (msg.value*93)/100;//93 percent of the ethereum investment is used for purchasing virtualgold.
            quantity[msg.sender]+=(amount)/virtualGoldPrice;//virtualgold is bought by the investor and linked to his/her wallet address 
            total+=(amount)/virtualGoldPrice;//update total
            increaseTokenPrice();//Remaining 7% is used for increasing the price of virtualgold.
            
            
        }else{
            amount = (msg.value*71)/100;//71 percent of the ethereum investment is used for purchasing virtualgold.
            if(msg.value>1.2 ether && msg.value< 2.4 ether){
                amount += (msg.value*3)/100;// 3% bonus to the investor 
            }
            if(msg.value>2.4 ether){
                amount += (msg.value*5)/100;// 5% bonus to the investor 
            }
            if(quantity[referral]>0){
                quantity[referral]+=(msg.value*5)/(100*virtualGoldPrice);//5% referral fee
                total+=(msg.value*5)/(100*virtualGoldPrice);//update total
                amount += (msg.value*1)/100;// 1% bonus to the investor
            }
            
             quantity[msg.sender]+=(amount)/virtualGoldPrice;//virtualgold is bought by the investor and linked to his/her wallet address 
             total+=(amount)/virtualGoldPrice;//update total
             quantity[virtualGoldTeam]+=(msg.value*5)/(100*virtualGoldPrice);//5% fee to the virtualgold Team
             total+=(msg.value*5)/(100*virtualGoldPrice);//update total
             quantity[marketingFundAddress]+=(msg.value*5)/(100*virtualGoldPrice);//5% fee to social media influencers
             total+=(msg.value*5)/(100*virtualGoldPrice);//update total
             increaseTokenPrice();//Remaining amount (9%-14%) is used for increasing the price of virtualgold.
                
        }
            
    return true;
  }
  
  
  function sellVirtualGold(uint amount) external returns (bool){ 
    if(amount>=quantity[msg.sender]){
        amount=quantity[msg.sender];//this is done to ensure that the holder doesnt try to sell more than he/she owns
    }
    uint amountToTransfer=amount*virtualGoldPrice;//calculate the amount to transfer
    total-=amount;//update total
    quantity[msg.sender]-=amount;//reduce the holders holdings accordingly
    payable(msg.sender).transfer(amountToTransfer);//transfer ethereum to holders address
    
    return true;
  }
  
  function transferVirtualGold(uint amount,address receiver) public returns (bool){
    if(amount>=quantity[msg.sender]){
        amount=quantity[msg.sender];//this is done to ensure that the holder doesnt try to transfer more than he/she owns
    }
    quantity[msg.sender]-=amount;
    quantity[receiver]+=amount;

    return true;
  }
  
}