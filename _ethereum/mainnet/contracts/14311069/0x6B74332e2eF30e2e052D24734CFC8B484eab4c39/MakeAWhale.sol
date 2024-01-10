// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0<8.12.0;

import "./Ownable.sol";
import "./WhaleWinnerVault.sol";

/*

███╗░░░███╗░█████╗░██╗░░██╗███████╗  ░█████╗░  ░██╗░░░░░░░██╗██╗░░██╗░█████╗░██╗░░░░░███████╗
████╗░████║██╔══██╗██║░██╔╝██╔════╝  ██╔══██╗  ░██║░░██╗░░██║██║░░██║██╔══██╗██║░░░░░██╔════╝
██╔████╔██║███████║█████═╝░█████╗░░  ███████║  ░╚██╗████╗██╔╝███████║███████║██║░░░░░█████╗░░
██║╚██╔╝██║██╔══██║██╔═██╗░██╔══╝░░  ██╔══██║  ░░████╔═████║░██╔══██║██╔══██║██║░░░░░██╔══╝░░
██║░╚═╝░██║██║░░██║██║░╚██╗███████╗  ██║░░██║  ░░╚██╔╝░╚██╔╝░██║░░██║██║░░██║███████╗███████╗
╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝  ╚═╝░░╚═╝  ░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝╚══════╝
@poseidonsnonce
makeawhale.com
*/

contract MakeAWhale is Ownable {

    // Entry Fee 
    uint128 public entryFee;

    // Current Pot
    uint128 public currentPot;
    
    // max limit for entrantsArrayReturn
    uint64 public maxLimit;

    // winner percentage
    uint8 public winnerSplit;

    // Address of the don
    address public don;

     // End Block 
    uint256 public endBlock;

    // Is Make a Whale Running
    bool public running;

    // Address of the company 
    address payable public company;

    // Initialize the Whale Vault  
    WhaleWinnerVault public WhaleVault;

    // entrant address => entered ( true or false )
    mapping(address => bool) public Entrants;

    // array of all entrants entered in lottery
    address[] public EntrantsArray;
    
    //Events
    event NewEntrant(address indexed entrant);
    event Started(uint indexed startblock, uint indexed endblock);
    event NewWhale(address indexed newwhale, uint indexed winningpot);

    modifier onlyDon {
      require(msg.sender == don, "Only the don can start Make a Whale");
      _;
   }

    modifier onlyCompany {
      require(msg.sender == company, "Only the company can call this function");
      _;
   }

    constructor(address _don, address payable _company) {
        entryFee = 40000000000000000;
        don = _don;
        company = _company;
        maxLimit = 10;
        winnerSplit = 85; 
        WhaleVault = new WhaleWinnerVault();
    }

    function setEntryFee(uint128 _entryfee) external onlyDon {
        entryFee = _entryfee;
    }

    function setMaxLimit(uint64 _maxLimit) public onlyOwner{
        maxLimit = _maxLimit;
    }

    //only don can set new don? or owner? 
    function setNewDon(address _address) external onlyOwner {
        don = _address;
    }

    // set new company address
    function setNewCompany(address payable _address) external onlyOwner {
        company = _address;
    }

    function setWinnerSplit(uint8 _split) external onlyCompany {
        require(_split > 0, "split has to be greater than 0");
        require(_split <= 100, "split has to be 10 or less");
        winnerSplit = _split;
    }

    function getEntrantsArray(uint256 limit, uint256 offset) view external returns(address[] memory entrantsArraySlice) {
        
        uint256 numberofentrants = EntrantsArray.length;

        uint256 size = numberofentrants < limit  ? numberofentrants : limit;

        size = size < maxLimit ? size : maxLimit;

        entrantsArraySlice = new address[](size);

        for(uint256 i = 0; i < size; i++){
            entrantsArraySlice[i] = EntrantsArray[numberofentrants - 1 - i - offset];
        }

        return entrantsArraySlice;
    }

    function getEntrantsArrayLength() view external returns(uint256) {
        return EntrantsArray.length;
    }

    function checkIfAddressIsEntered(address _address)  view external returns(bool){
        return Entrants[_address];
    }

    // Handle the entering of new Entrants 
    function enter(address payable _newentrant) payable external {
        //require the corect entry fee
        require(msg.value == entryFee, "Sending wrong cost of entry");
        
        //require that address is not already entered
        require(Entrants[_newentrant] == false, "Address has already entered");

        // require to be running
        require(running == true, "Make a Whale has to be running");

        //update entry status of new entrant
        Entrants[_newentrant] = true;

        //add entrant address to address payable array
        EntrantsArray.push(_newentrant);

        //add 90% of new entry to pot
        currentPot += entryFee;

        emit NewEntrant(_newentrant);
    }

    function Start(uint256 _blocktime) external onlyDon {
        
        require(running == false, "Make a whale can only start if it is ended");
        require(EntrantsArray.length == 0, "All old entrants must be cleared before starting. ");

        running = true;
        uint256 currentBlockNumber = block.number;
        endBlock = currentBlockNumber + _blocktime;
        emit Started(currentBlockNumber, endBlock);
    }

    // --- handle ending  --- 
    function End() external onlyDon {

        // require that the current block number is larger than our end date
        require(block.number > endBlock, "Sufficient time has not past yet");

        // require that the make a whale hasnt already ended
        require(running == true, "Make a whale isn't running");
        
        //set running to false
        running = false;
        
        uint256 numberOfEntrants = EntrantsArray.length;

        // need to handle case where EntrantsArray is null ( 0 entrants ) 
        if(numberOfEntrants > 0){
            // payout to random winner    
            payout(EntrantsArray[random()], (currentPot / 100) * winnerSplit);
        }
    }

    // ---- handle paying out to the vault of the new whale --- 
    function payout(address winner, uint256 pot) internal {
        // use local pot variable to help prevent re entrancy ( even though this function is internal and only callable by don)
        currentPot = 0;

        // Send pot value with winner to vault deposit contract for future withdraw by winner
        WhaleVault.deposit{value: pot}(winner);
        emit NewWhale(winner, pot);
       
    }

    // moved this to seperate function to handle deleting entrants data in case entrants array grows to large 
    function deleteEntrantsData(uint256 amount) external onlyDon {
        require(running == false, "The lottery cannot be running when clearing entrants data");
        require(EntrantsArray.length >= amount,"The number of entrants to delete can't be greater than the number of entrants");

        uint256 numberOfEntrants = EntrantsArray.length;

        // iterate through our entrants mapping using EntrantsArray as keys and reset their values to false
        for(uint i=0; i< amount; i++){
            delete Entrants[EntrantsArray[numberOfEntrants - 1 - i]]; 
            EntrantsArray.pop();
        }
    }

     // withdraw company % - this will be remaining in contract after pot is transfered to winner vault
     // this can only be called when running is false which can only happen in the End function call 
     // this is security against company rug pulling the entire pot balance when running 
    function withdrawToCompany() external onlyCompany {
        require(running == false);
        company.transfer(address(this).balance);
    }

    // pseudorandom number generator to get random number from range 0 - # of particpants 
    // pseudorandomness is not a problem here since this function is only called by the don in the End function
    function random() internal view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));

        return (seed % EntrantsArray.length);
    }
}