import "./PaymentSplitter.sol";

pragma solidity >=0.6.0 <0.8.0;




contract SleazySlothSplitter is PaymentSplitter {

uint256[] private _shares = [17,17,17,17,32];
address[] private _payees = [0xDCC901529c4FF557156d56D7f7dc980ebfA9e754,0xe0B1532ecd193637662a8dFAE2495354d54556E1, 0x343FCEbEF2366f5E15a225F5b4564C2b7cc388E4, 0x032e70c32f7f9d463cd30a141a20f7EbF4360964,0xb212231EdC0A34787896D17C7A1c020eaDb2Ac63 ];


constructor() 
    PaymentSplitter(_payees, _shares)
   
  {
  

  }

}