// SPDX-License-Identifier: MIT

/*                          
*                                          |`._         |\
*                                           `   `.  .    | `.    |`.
*                                            .    `.|`-. |   `-..'  \           _,.-'
*                                            '      `-. `.           \ /|   _,-'   /
*                                        .--..'        `._`           ` |.-'      /
*                                         \   |                                  /
*                                      ,..'   '                                 /
*                                      `.                                      /
*                                      _`.---                                 /
*                                  _,-'               `.                 ,-  /"-._
*                                ,"                   | `.             ,'|   `    `.           
*                              .'                     |   `.         .'  |    .     `.
*                            ,'                       '   ()`.     ,'()  '    |       `.
*'                          -.                    |`.  `.....-'    -----' _   |         .
*                           / ,   ________..'     '  `-._              _.'/   |         :
*                           ` '-"" _,.--"'         \   | `"+--......-+' //   j `"--.. , '
*                              `.'"    .'           `. |   |     |   / //    .       ` '
*                                `.   /               `'   |    j   /,.'     '
*                                  \ /                  `-.|_   |_.-'       /\
*                                   /                        `""          .'  \
*                                  j                                           .
*                                  |                                 _,        |
*                                  |             ,^._            _.-"          '
*                                  |          _.'    `'""`----`"'   `._       '
*                                  j__     _,'                         `-.'-."`
*                                     ',-.,' 
*                           ++======================================================++
*       `````^`                                                                                                                                        .'```'  
*       ``````^^                                                                                                                                      `````^` 
*       ^````^"^                                                                                                                                      `^^^""' 
*       ^````^"^                                                                                                                                       .''.   
*       ^````^"^                                                                                                                                              
*       ^````^"^                          `````^'                       `````^`      ..'```````````````````````^.  ``````^'                          .``````^`
*       ^````^"^         ..''.            ````^^`                       `````^^    .'`````^^"""""^^^``````````^^.  ``````^`                          ``'''``^^
*       ^`````^^      .'`````^^.          ^```^"`            .          ````^^"   .`````^",`'..     .`````````^^.  ``````^`                          ``'''``^^
*       ^`````^`...'``^^^^^^^"".          ^```^"`        `````^'        ````^^"   `````^,`        '``````''```^".  ``````^`                          ``'''``^^
*       ^`````^""""""""""",,"^.           ^```^"`        `````^`        `````^"  .````^"`       .```````.``'``^".  ``''``^`                         .``'''``^^
*       ^````^""                          ````^"`        ````^^`        `````^"  '````^"'     .```````` ``''``^^.  ``''``^`                         .``'''``^^
*       `````^""                 ......   ````^"`        ````^"`        `````^"  '````^"'    .```````^ '`''''``^.  ``''``^`                 ......  .``'''``^^
*       ``````^^            .''``````^^.  `````^`       .`````^`       .`````^"  '`````^.   '``'''``^' ``''''``^.  ``''``^`            .''```````^  .``'''``^^
*       ``````^`         .'``````````^^.  `````^'      '````````     .'``''``^"  '``''``'..'`''''```^..``''''``^.  ``''``^`         .'```'''''``^^  .``'''``^^
*       ^```````.  ...'``````````````^".  ^``````.''````````````''```````````^"  '````````````````^^^ .```````^".  ^```````......'``````````````^"  .```````^^
*       ^"^^^^^^^^^^^^^^^^^^^^^"""""",,.  "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"",,  ."^^^^^^^^^^^^^"",,' '"^^^^^"",.  ""^^^^^^^^^^^^^^^^^^^^^^^^^"",,  ."^^^^""""
*/

pragma solidity ^0.8.13;

import "./Initializable.sol";
import "./ReentrancyGuard.sol";
                                                                                                                                                                                            

contract TwaliContract is Initializable, ReentrancyGuard {
  
    address public owner;
    // expert address that is completion contract and recieving payment
    address payable public contract_expert;
    // SOW metadata for work agreed terms 
    string public contract_sowMetaData;

    bool private isInitialized;
    // Werk is approved or not approved yet
    bool public contract_werkApproved; // unassigned variable has default value of 'false'
    // Werk has been paid out 
    bool public contract_werkPaidOut;
    // Werk was refunded 
    bool public contract_werkRefunded;
    // contract creation date
    uint contract_created_on;
    // experts start date in contract
    uint public contract_start_date;
    // End date for werk completion 
    uint public contract_end_date;
    // Completion Date for submitted werk
    // Contract amount to be paid 
    uint256 public contract_payment_amount = 0.0 ether;

    /// @notice This contract has four 'status' stages that transitions through in a full contract cycle.
    /// Draft: Contract is in draft stage awaiting for applications and selection.
    /// Active: Contract is active and funded with pay out amount with a selected Contract Expert to complete werk.
    /// Complete: Contract werk is completed, approved by client, and Expert has recieved payment.
    /// Killed: Contract werk is canceled in draft stage or no longer active and client is refunded.
    enum Status { 
        Draft, Active, Complete, Killed
    }

    /// @dev Status: Contract is set to default status of 'Draft' on contract creation.
    Status private contract_currentStatus;
  
    // Events
    event ReceivedPayout(address, bool, bool);
    event RefundedPayment(address, uint);
    event ContractActivated(address, uint, uint);
    event DepoistedExpertPaynment(address, uint);


    /// @notice Functions cannot be called at the current stage.
    error InvalidCurrentStatus();


    /// Execute on a call to contract if no other functions match given function signature.
    fallback() external payable{}


    receive() external payable{}


    /// @notice This initializer replaces the constructor to is the base input data for a new contract clone instances .
    /// @dev initialize(): Is also called within the clone contract in TwaliCloneFactory.sol.
    /// @param _adminClient the address of the contract owner who is the acting client.
    /// @param _sowMetaData Scope of work of the contract as a URI string.
    /// @param _creationDate is passed in from clone factory as the new contract is created.
    function initialize(
        address _adminClient,
        string memory _sowMetaData,
        uint _contract_payment_amount,
        uint _contract_start_date,
        uint _contract_end_date,
        uint _creationDate
    ) public initializer {
        require(!isInitialized, "Contract is already initialized");
        require(owner == address(0), "Can't do that the contract already initialized");
        owner = _adminClient;
        contract_sowMetaData = _sowMetaData;
        contract_payment_amount = _contract_payment_amount;
        contract_start_date = _contract_start_date;
        contract_end_date = _contract_end_date;
        contract_created_on = _creationDate;
        isInitialized = true;
    }

    /*
    *  Modifiers
    */ 

    /// @notice onlyOwner(): This is added to selected function calls to check and ensure only the 'owner'(client) of the contract is calling the selected function.
    modifier onlyOwner() {
        require(
            msg.sender == owner, 
            "Only owner can call this function"
            );
        _;
    }

    /// @notice This checks that the address being used is the expert address that is activated within the contract. If not, will throw an error.
    /// @dev isExpert(): This modifier is added to calls that need to confirm addresses passed into functions it the contract_expert.
    /// @param _expert is an address passed in to check if it is expert. 
    modifier isExpert(address _expert) {
        require(_expert == contract_expert, "Not contract expert address");
        _;
    }

    /// @notice This checks that an address being passed into a function is a valid address and not a 0 address.
    /// @dev isValid(): Can be used in any function call that passes in a address that is not the contract owner.
    /// @param _addr: is normal wallet / contract address string.
    modifier isValid(address _addr) {
        require(_addr != address(0), "Not a valid address");
        _;
    }

    /// @notice This is added to function calls to be called at at all life cycle status stages,(e.g., only being able to call functions for 'Active' stage).
    /// @dev isStatus(): This is checking concurrently that a function call is being called at it's appropriate set stage order.
    /// @param _contract_currentStatus is setting the appropriate stage as a base parameter to check to with a function call.
    modifier isStatus(Status _contract_currentStatus) {
        if (contract_currentStatus != _contract_currentStatus)
            revert InvalidCurrentStatus();
        _;
    }

    /// @notice Simple check if werk has been paid out or not.
    modifier werkNotPaid() {
        require(contract_werkPaidOut != true, "Werk already paid out!");
        _;
    }

    /// @notice Simple check if werk has not been previously approved, (e.g., to check during a payout instance).
    modifier werkNotApproved() {
        require(contract_werkApproved != true, "Werk already approved!");
        _;
    }

    /// @notice Simple check that funds in contract has not been refunded.
    modifier isNotRefunded() {
        require(contract_werkRefunded != true, "Refunded already!");
        _;
    }

    /// @notice This is added to a function and once it is completed it will then move the contract to its next stage.
    /// @dev setNextStage(): Use's the function 'nextStage()' to transition to contracts next stage with one increment (+1).
    modifier setNextStage() {
        _;
        nextStage();
    }



    /// @notice Gets the current status of contract.
    function getCurrentStatus() public view returns (Status) {
        return contract_currentStatus;
    }

     /// @notice Simple call / read function that returns balance of contract.
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Refunds payment to Owner / Client of Contract
    /// @dev refundClient(): this can only be called within the 'KillDrafContract' function.
    function refundClient() 
        internal 
    {
        contract_werkRefunded = true;
        emit RefundedPayment(owner, contract_payment_amount);
        uint256 balance = address(this).balance;
        contract_payment_amount = 0;
        payable(owner).transfer(balance);
    }

    /// @dev This is the stage transition in the 'setNextStage' modifier.
    function nextStage() internal {
        contract_currentStatus = Status(uint(contract_currentStatus)+1);
    }

    /// @notice This will set a 'draft' contract to 'killed' stage if the contract needs to be closed.
    function killDraftContract() 
        external 
        onlyOwner
        isStatus(Status.Draft)
    {
        contract_currentStatus = Status.Killed;
    }

    /// @notice This enables the Client to deposit funds to the created contract instance for Expert to be paid (escrow form of contract).
    /// @dev depositExpertPayment(): is passed into / called from the activateContract, so that the client can fund the contract in addition to addding in selected Expert.
    /// @param _amount is the amount saved variable that is stored within the contract.
    function depositExpertPayment(uint _amount) public payable {
        require(_amount <= msg.value, "Wrong amount of ETH sent");

        emit DepoistedExpertPaynment(msg.sender, msg.value);
    }

    /// @notice This is a contract activation to intialize Client & Expert Commencing werk.
    /// @dev activateContract(): Add's in selected Expert and activates Contract for Expert to begin completing werk.
    /// @param _contract_expert is the address of who is completing werk and receiving payment for werk completed.
    function activateContract(
        address _contract_expert)
        external
        payable 
        onlyOwner
        isValid(_contract_expert)
        isStatus(Status.Draft)
        setNextStage 
    { 
        emit ContractActivated(contract_expert, 
                               contract_start_date, 
                               contract_payment_amount);
        contract_expert = payable(_contract_expert); 
        depositExpertPayment(contract_payment_amount);
    }

    /// @notice Sets an active contract to 'killed' stage and refunds ETH in contract to the client, who is the set contract 'owner'.
    /// @dev killActiveContract(): 
    function killActiveContract() 
        external 
        onlyOwner
        isNotRefunded 
        nonReentrant 
        isStatus(Status.Active) 
    {
        contract_currentStatus = Status.Killed;
        refundClient();
    }


    /// @notice This is called when an expert completes werk and client will then approve that werk is completed allowing for expert to be paid.
    /// @dev approveWorkSubmitted(): 
    /// 
    function approveWorkSubmitted() 
        public 
        onlyOwner
        werkNotApproved
        werkNotPaid
        isStatus(Status.Active) 
        nonReentrant
        setNextStage 
    {
        contract_werkApproved = true;
        contract_werkPaidOut = true;
        emit ReceivedPayout(contract_expert, 
                            contract_werkPaidOut, 
                            contract_werkApproved);
                            
        uint256 balance = address(this).balance;
        contract_expert.transfer(balance);     
    }

  
}