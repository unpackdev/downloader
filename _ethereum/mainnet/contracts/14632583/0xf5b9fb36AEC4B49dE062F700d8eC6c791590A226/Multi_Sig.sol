//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/*
██╗░░░░░░█████╗░░█████╗░███╗░░░███╗██╗  ██╗░░██╗███████╗░█████╗░██████╗░░██████╗
██║░░░░░██╔══██╗██╔══██╗████╗░████║██║  ██║░░██║██╔════╝██╔══██╗██╔══██╗██╔════╝
██║░░░░░██║░░██║██║░░██║██╔████╔██║██║  ███████║█████╗░░███████║██║░░██║╚█████╗░
██║░░░░░██║░░██║██║░░██║██║╚██╔╝██║██║  ██╔══██║██╔══╝░░██╔══██║██║░░██║░╚═══██╗
███████╗╚█████╔╝╚█████╔╝██║░╚═╝░██║██║  ██║░░██║███████╗██║░░██║██████╔╝██████╔╝
╚══════╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚═╝  ╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═════╝░╚═════╝░
*/
import "./ERC721A.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";



contract Multi_Sig is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    /*  Keeps track of which vote we're currently on.
        Used in hashing an eth message and verifying signer
        Prevents signature duplicates
    */
    uint256 public ballotNumber;

   
    //Store Admin Positions
    mapping(address => bytes32) public adminMapping;
    //Store information helping for voting
    mapping(uint256 => ballotRound) public voteHelper;
    //Store information for changing the address at payroll index 
    // mapping(uint256 => payeeHelper) internal payeeVoteMapping;

   

   address[] public payroll = [
       0x9376b1b8931f3F02B4119665079fb37C91d05464,
       0x4D4658b37b1eaB41a7Dca14c7EF90A8835186853,
       0x79FB7f4F1eD90DCC3a9a2200eFf843038C5DFcB5,
       0x0c2f8b7D7A7C8979F8297c14d27e76E7909ac1c0];
    //LoomiHeads main collection smart contract address
    address public loomiHeads;
    //Helper Bool
    bool hasRan;

    struct ballotRound{
        mapping(address=>bool) hasVoted;
        bool isApproved;
        address newOwner;
      }


    constructor()
    {
            //init all admins
     adminMapping[0x9376b1b8931f3F02B4119665079fb37C91d05464] = keccak256("admin"); //coso
      adminMapping[0x4D4658b37b1eaB41a7Dca14c7EF90A8835186853] = keccak256("admin"); //manic
       adminMapping[0x79FB7f4F1eD90DCC3a9a2200eFf843038C5DFcB5] = keccak256("admin"); //syed
        adminMapping[0x0c2f8b7D7A7C8979F8297c14d27e76E7909ac1c0] = keccak256("admin"); //meri

    }



   

  

  //MODIFIER check if sender == admin
    modifier onlyAdmin() {
       require(adminMapping[_msgSender()] == keccak256("admin"),"Not Admin");
       _;
    }
      //MODIFIER We can only set Loomiheads address one time
    modifier onlyLetExecuteOnce(){
        require(!hasRan,"Already Ran");
        _;

    }
    //Check if Caller is Loomiheads Contract
    modifier onlyLoomiContract(){
        require(_msgSender()!=address(0));
        require(_msgSender() == loomiHeads,"Not Loomi Contract Calling");
        _;
    }

    //sets Loomi Address, can only be used once
    function setLoomiAddress(address deployment_address) public onlyLetExecuteOnce onlyOwner nonReentrant{
        hasRan = true;
        loomiHeads = deployment_address;
    }

    /*
        increments ballotNumber
        only usable by LoomisContract
        used when TransferOwnership is called in LoomiHeads collection
    */
    function incrementBallotNumber() external onlyLoomiContract{
        ballotNumber++;        
    }
    
    //used by LoomiHeads main collection contract
    function isAdmin(address sender) external view returns(bool){
        return adminMapping[sender] == keccak256("admin");
    }

    


    /*REPLACE ADMIN FUNCTION
            @dev
        ----must have at least 3/4 admins agree upon this new change
        ---- loop through all the signatures and if >2 (at least 3) signatures match an admin
        ---- we ban the oldAdmin and add the newAdmin
        ----We also make sure that an admin can't manipulate the system and vote more than once using voteHelper
    */
      function replaceAdmin(address adminToBan, address newAdmin, bytes[] memory _signatures) external onlyAdmin returns(bool){
          require(adminMapping[adminToBan] == keccak256("admin"),"must ban a current admin");
            require(adminMapping[newAdmin] != keccak256("admin"),"New Admin Can't Be Old Admin");
          //init an address to be used later
        address curr_signer;
        uint256 count;
        bytes32 hash = keccak256(abi.encodePacked(ballotNumber,adminToBan,newAdmin));
        for(uint256 i;i<_signatures.length;i++){
           curr_signer  = hash.toEthSignedMessageHash().recover(_signatures[i]);
            if(adminMapping[curr_signer] == keccak256("admin")){
                //Prevent Voter Manipulation
                if(voteHelper[ballotNumber].hasVoted[curr_signer] == false){
                voteHelper[ballotNumber].hasVoted[curr_signer] = true;
                count++;
                }
            }
        }
        //at least 3 votes?
            if(count>2){
                  uint256 indexOfOldAdmin = getIndexOfAdmin(adminToBan);
                  payroll[indexOfOldAdmin] = newAdmin;
                delete adminMapping[adminToBan];
                adminMapping[newAdmin] = keccak256("admin"); 
              
                ballotNumber++;
                return true;
            }

            //If Not Enough Votes, Reset Storage
            revert("Not Enough Votes");
          
    }

    //replaceAdmin Helper Function
    function getIndexOfAdmin(address adminAddress) internal view returns(uint256){
        for(uint256 i; i<payroll.length;i++){
            if(adminAddress == payroll[i]){
                return i;
            }
        }
        revert("Didn't Find Old Admin");
    }




    /*
        Check Multi Sig For Transfer Ownership
            ----must have at least 3/4 admins agree upon this new change
        ---- loop through all the signatures and if >2 (at least 3) signatures match an admin
        ---- we ban the oldAdmin and add the newAdmin
        ----We also have to make sure that an admin can't manipulate the system and vote more than once
    */
    function approveTransferOwnership(address newOwner,bytes[] memory signatures) public  returns(bool){
        address curr_signer;
        uint256 count;
        bytes32 hash = keccak256(abi.encodePacked(ballotNumber,newOwner));
        for(uint256 i;i<signatures.length;i++){
          curr_signer = hash.toEthSignedMessageHash().recover(signatures[i]);
          if(adminMapping[curr_signer] == keccak256("admin")){

              //Prevent Voter Manipulation
             
              if(voteHelper[ballotNumber].hasVoted[curr_signer] == false){
              voteHelper[ballotNumber].hasVoted[curr_signer] = true;
              //add to count
                count++;
            }
          }
        }
            if(count>2){
                voteHelper[ballotNumber].isApproved = true;
                voteHelper[ballotNumber].newOwner = newOwner;
                return true;
            }
            revert("Not Enough Votes");
    }

       function isTransferOwnershipApproved() public view returns(bool){
        return voteHelper[ballotNumber].isApproved;
    }



      function deposit() external payable returns(bool) {
        require(msg.value>0,"Can't Send Zero");
        return true;
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function getNewOwner() public view returns(address){
        return voteHelper[ballotNumber].newOwner;
    }
   

    function withdraw() external payable returns(bool){

        //Dummy Values for Now
        uint256 balance = address(this).balance;
        sendValue(payable(payroll[0]),balance * 3125/10000 ); //coso
        sendValue(payable(payroll[1]),balance * 1625/10000); //manic
        sendValue(payable(payroll[2]),balance * 1400/10000); //syed
        sendValue(payable(payroll[3]),balance * 1500/10000); //melan
        sendValue(payable(0x5bBEC70750169fd75c6b428eca849273a25922aD),balance* 1500/10000); //community
        sendValue(payable(0xd9d426f049937F4664d6D450D66c6FD46D3E868D),balance * 500/10000); //ash
        sendValue(payable(0x6884efd53b2650679996D3Ea206D116356dA08a9),balance * 350/10000); //simon

        return true;
        
    }

    
     receive() external payable {
    }

    fallback() external payable {

    }
   

}