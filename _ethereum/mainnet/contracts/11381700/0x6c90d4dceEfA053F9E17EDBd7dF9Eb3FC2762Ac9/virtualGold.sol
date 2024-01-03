pragma solidity ^0.4.24;


contract virtualGold {

  uint public virtualGoldPrice;
  uint public total;
  mapping(address=>uint) quantity;
  address virtualGoldTeam;


  constructor() public
  {
      //At the core virtualgold is just a data record that is linked to each holders wallet address which stores the amount amount of virtualgold held by each of one them. The value of your virtualgold is always backed by ethereum in this smart contract.
      virtualGoldTeam=0xd98F9E1191Ac53B1Af3E7A09Af53E08755B3DE9a; //This is the wallet address of the virtualgold team
      virtualGoldPrice = 0.000000001 ether; //This is the starting price of virtualgold per microgram. This value keeps increasing after every investment/virtualgold purchase. This value can never depreciate.
      total = 0; //The total quantity of virtualgold owned by everyone when the contract is deployed is 0
  }


  function increaseTokenPrice()
      public returns(bool)
  {
      // It is used for recalculating/updating the price per unit gram of virtualgold. This function is called after every investment as the price increases after every investment.
      virtualGoldPrice=(address(this).balance)/(total);
      return true;
  }


  function buyVirtualGold(address referral)
        public payable returns (bool)
  {
        uint amount = (msg.value*666)/1000; //66.6 percent of the ethereum investment is used for purchasing virtualgold.
        if(quantity[referral]>0)
        {
            //ensure that the referral address is a virtualgold holder
            quantity[referral]+=(msg.value*3)/(100*virtualGoldPrice); //3% referral fee
            total+=(msg.value*3)/(100*virtualGoldPrice);//update total
            if(referral!=virtualGoldTeam)
            {
                //For 1% bonus to the investor, the referral address must be a virtualgold holder other than the virtualGoldTeam address
                amount += (msg.value*1)/100;// 1% bonus to the investor
                total+=(msg.value*1)/(100*virtualGoldPrice);//update total
            }
        }
        quantity[msg.sender]+=(amount)/virtualGoldPrice; //virtualgold is bought by the investor and linked to his/her wallet address
        total+=(amount)/virtualGoldPrice; //update total
        quantity[virtualGoldTeam]+=(msg.value*3)/(100*virtualGoldPrice); //3% fee to the virtualgold Team
        total+=(msg.value*7)/(100*virtualGoldPrice); //update total
        increaseTokenPrice(); //Remaining 26.33%(if referral address isn't a holder then 30.33%) is used for increasing the price of virtualgold.
        return true;
  }


  function sellVirtualGold()
        public returns (bool)
  {
        //cash out the holders position
        uint amountToTransfer=quantity[msg.sender]*virtualGoldPrice; //calculate the amount to transfer
        total-=quantity[msg.sender]; //update total
        quantity[msg.sender]=0; //reset quantity to zero as he/she is no longer a holder
        msg.sender.transfer(amountToTransfer); //transfer ethereum to holders address
        return true;
  }

}