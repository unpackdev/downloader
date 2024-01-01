pragma solidity ^0.8.0;

/*
PAYSPEC: Atomic and deterministic invoicing system

Generate offchain invoices based on sell-order data and allow users to fulfill those order invoices onchain.

*/
 

import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

 
contract Payspec is Ownable, ReentrancyGuard {

  uint256 public immutable contractVersion  = 100;
  address immutable ETHER_ADDRESS = address(0x0000000000000000000000000000000000000010);
  
  mapping(bytes32 => Invoice) public invoices; 

  bool lockedByOwner = false; 

  event CreatedInvoice(bytes32 uuid, bytes32 metadataHash ); 
  event PaymentMade(bytes32 uuid,  address token, address from, address to, uint256 amt);
  event PaidInvoice(bytes32 uuid, address from, uint256 totalPaidAmt); 
      

  struct Invoice {
    bytes32 uuid;

   
    
    

    address token;
   
    uint256 chainId;
    
    address[] payTo;
    uint[] amountsDue;
    

    bytes32 metadataHash; 
    uint256 nonce; 

    address paidBy;


    uint256 paidAt; 
    uint256 expiresAt;

  }



  constructor(   ) {

  } 
 

  function lockContract() public onlyOwner {
    lockedByOwner = true;
  }


   


  function createAndPayInvoice( address token, address[] memory payTo, uint[] memory amountsDue,   uint256 nonce,   uint256 chainId, bytes32 metadataHash,uint256 expiresAt, bytes32 expecteduuid  ) 
    public 
    payable 
    nonReentrant
    returns (bool) {

     uint256 totalAmountDue = calculateTotalAmountDue(amountsDue);
     
     if(token == ETHER_ADDRESS){
       require(msg.value == totalAmountDue, "Transaction sent incorrect ETH amount.");
     }else{
       require(msg.value == 0, "Transaction sent ETH for an ERC20 invoice.");
     }
     
     bytes32 newuuid = _createInvoice(token,payTo,amountsDue, nonce, chainId, metadataHash, expiresAt,expecteduuid);
    
     return _payInvoice(newuuid);
  }

   function _createInvoice(  address token, address[] memory payTo, uint[] memory amountsDue, uint256 nonce, uint256 chainId, bytes32 metadataHash,  uint256 expiresAt, bytes32 expecteduuid ) 
    internal 
    returns (bytes32 uuid) { 


      bytes32 newuuid = getInvoiceUUID(token, payTo, amountsDue, nonce,  chainId, metadataHash, expiresAt ) ;

      require(!lockedByOwner);
      require( newuuid == expecteduuid , "Invalid invoice uuid");
      require( invoices[newuuid].uuid == 0 );  //make sure you do not overwrite invoices
      require(payTo.length == amountsDue.length, "Invalid number of amounts due");

      //require(ethBlockExpiresAt == 0 || block.number < expiresAt);

      invoices[newuuid] = Invoice({
       uuid:newuuid,
       metadataHash:metadataHash,
       nonce: nonce,
       token: token,

       chainId: chainId,

       payTo: payTo,
       amountsDue: amountsDue,
       
       paidBy: address(0),
        
       paidAt: 0,
       expiresAt: expiresAt 
      });


       emit CreatedInvoice(newuuid, metadataHash);

       return newuuid;
   }

   function _payInvoice( bytes32 invoiceUUID ) internal returns (bool) {

       address from = msg.sender;

       require( !lockedByOwner );
       require( invoices[invoiceUUID].uuid == invoiceUUID ); //make sure invoice exists
       require( invoiceWasPaid(invoiceUUID) == false ); 

       require( invoices[invoiceUUID].chainId == 0 || invoices[invoiceUUID].chainId == block.chainid, "Invalid chain id");

       
       require( invoices[invoiceUUID].expiresAt == 0 || block.timestamp < invoices[invoiceUUID].expiresAt);

 
       uint256 totalPaidAmt = 0;

       for(uint i=0;i<invoices[invoiceUUID].payTo.length;i++){
              uint amtDue = invoices[invoiceUUID].amountsDue[i]; 
              totalPaidAmt += amtDue;

              //transfer each fee to fee recipient
              require(  _payTokenAmount(invoices[invoiceUUID].token, from, invoices[invoiceUUID].payTo[i], amtDue ) , "Unable to pay amount due." );
              
              emit PaymentMade(invoiceUUID, invoices[invoiceUUID].token, from, invoices[invoiceUUID].payTo[i], amtDue );
       } 

        
       invoices[invoiceUUID].paidBy = from;

       invoices[invoiceUUID].paidAt = block.timestamp; 

       emit PaidInvoice(invoiceUUID, from, totalPaidAmt);

       return true;


   }


   function _payTokenAmount(address tokenAddress, address from, address to, uint256 tokenAmount) 
      internal 
      returns (bool) {
      
      if(tokenAddress == ETHER_ADDRESS){
        payable(to).transfer( tokenAmount ); 
      }else{ 
        IERC20( tokenAddress  ).transferFrom( from ,  to, tokenAmount  );
      }
      return true;
   }

  function calculateTotalAmountDue(uint256[] memory amountsDue) internal pure returns (uint256 _totalAmountDue) {
      for (uint256 i = 0; i < amountsDue.length; i++) {
          _totalAmountDue += amountsDue[i];
      } 
  }



   function getInvoiceUUID(    address token,   address[] memory payTo, uint[] memory amountsDue,   uint256 nonce,uint256 chainId, bytes32 metadataHash, uint expiresAt  ) public view returns (bytes32 uuid) {

         address payspecContractAddress = address(this); //prevent from paying through the wrong contract

         bytes32 newuuid = keccak256( abi.encode(payspecContractAddress, token, payTo, amountsDue,   nonce,  chainId, metadataHash,   expiresAt ) );

         return newuuid;
    }

 

   function invoiceWasCreated( bytes32 invoiceUUID ) public view returns (bool){

       return invoices[invoiceUUID].uuid != bytes32(0) ;
   }

   function invoiceWasPaid( bytes32 invoiceUUID ) public view returns (bool){

       return invoices[invoiceUUID].paidAt > 0 ;
   }


    function getInvoiceMetadataHash( bytes32 invoiceUUID ) public view returns (bytes32){

       return invoices[invoiceUUID].metadataHash;
   }

   function getInvoiceTokenCurrency( bytes32 invoiceUUID ) public view returns (address){

       return invoices[invoiceUUID].token;
   }


   function getInvoicePayer( bytes32 invoiceUUID ) public view returns (address){

       return invoices[invoiceUUID].paidBy;
   }

   function getInvoicePaidAt( bytes32 invoiceUUID ) public view returns (uint){

       return invoices[invoiceUUID].paidAt;
   }

 


}
