// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721Base.sol";
import "./IERC20.sol";

//UPDATES TO THE ORIGINAL RAFFLE CONTRACT MADE TO ACCEPT CUSTOM ERC20 TOKENS FOR A RAFFLE. THIS CONTRACT ALLOWS THE USE OF MULTIPLE ERC20 TOKENS FOR EACH RAFFLE USING THE BUYTICKET FUNCTION AND THE PID
//UPDATED CODE BY @GENERATIONART_ (TWITTER)

contract NFTRaffleContract {
    address public admin;
    mapping(address => uint256) public entryCounts; // Mapping to store the count of entries per address
    address[] public players; //Array of players who bought tickets
    address[] public playerSelector; //Array of players for random selection
    address[] public winnerOfPrize; //prize winner
    bool public lotteryStatus; //True if the lottery is running
    uint256 public ticketCost;
    address public nftContract; //Address of the NFT contract for the prize
    uint256 public tokenId; //Token ID of the NFT for the prize
    uint256 public totalEntries; //Total number of entries
    uint256 public allow; // 
    
    event NewTicketBought(address player); //Event when someone buys a ticket
    event LotteryStarted();
    event LotteryEnded();
    event Winner(address winner); //Event when someone wins the lottery
    event TicketCostChanged(uint256 newCost); //Event when the ticket cost is updated
    event NFTPrizeSet(address nftContract, uint256 tokenId);
    event BalanceWithdrawn(uint256 amount);
    
    //Declare use of custom ERC20 tokens
    struct TokenInfo {
            IERC20 paytoken;
            uint256 costvalue;
        }
        TokenInfo[] public AllowedCrypto;
        //pushes eligble tokens to the contract
        function addCurrency(
            IERC20 _paytoken,
            uint256 _costvalue
        ) public onlyAdmin {
            AllowedCrypto.push(
                TokenInfo({
                    paytoken: _paytoken,
                    costvalue: _costvalue
                })
            );
        }
    constructor() {
        admin = msg.sender; //The admin is the one who deploys the contract
        lotteryStatus = false; //Lottery is not running
        ticketCost = 0; //Initial ticket cost
        totalEntries = 0; //Initial total entries
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function"); //Sets the admin as the only one who can call functions
        _;
    }

    function isPlayer(address participant) private view returns (bool) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == participant) {
                return true;
            }
        }
        return false;
    }

    function buyTicket(uint256 numberOfTickets, uint256 _pid) public payable {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        uint256 cost;
        cost = tokens.costvalue;
        
        require(lotteryStatus == true, "Lottery is not running"); //Lottery must be running
        allow = paytoken.allowance(msg.sender, address(this));
        paytoken.transferFrom(msg.sender,address(this), cost * numberOfTickets);
        entryCounts[msg.sender] += numberOfTickets;
        totalEntries += numberOfTickets;
        

        if (!isPlayer(msg.sender)) {
            players.push(msg.sender); //Add the player to the players array
        }
        
        for (uint256 i = 0; i < numberOfTickets; i++) {
            playerSelector.push(msg.sender); //Add the player to the playerSelector array
        }

        emit NewTicketBought(msg.sender); //Emit the event that a new ticket was bought
    }

    function startLottery(address _nftContract, uint256 _tokenId) public onlyAdmin {
        require(!lotteryStatus, "Lottery is already running"); //Lottery must not be running
        require(nftContract == address(0), "Prize from previous lottery not transferred");
        require(
            ERC721Base(_nftContract).ownerOf(_tokenId) == admin,
            "Admin does not own the specified NFT."
        ); //Admin must own the NFT

        nftContract = _nftContract;
        tokenId = _tokenId;
        lotteryStatus = true; //Set the lottery status to true
        emit LotteryStarted(); //Emit the event that the lottery has started
        emit NFTPrizeSet(nftContract, tokenId); 
    }

    function endLottery() public onlyAdmin {
        require(lotteryStatus, "Lottery is not running"); //Lottery must be running

        lotteryStatus = false; //Set the lottery status to false
        emit LotteryEnded(); //Emit the event that the lottery has ended
    }

    //Function returns a random number between 0 and the length of the players array
    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.prevrandao,
                        block.timestamp,
                        players.length
                    )
                )
            );
    }

    function resetEntryCounts() private {
        for (uint256 i = 0; i < players.length; i++) {
            entryCounts[players[i]] = 0;
        }
    }

    function pickWinner() public onlyAdmin {
        require(!lotteryStatus, "Lottery is still running"); //Lottery must not be running
        require(playerSelector.length > 0, "No players in the lottery"); //There must be at least one player
        require(nftContract != address(0), "NFT contract not set"); //NFT contract must be set
        delete winnerOfPrize;
        uint256 index = random() % playerSelector.length; //Get a random index
        address winner = playerSelector[index]; //Get the winner address
        emit Winner(winner); //Emit the event that a winner was picked
        winnerOfPrize.push(winner);
        ERC721Base(nftContract).transferFrom(admin, winner, tokenId);
        resetEntryCounts(); //Reset the entry counts
        delete playerSelector; // Reset the playerSelector array
        delete players; // Reset the players array
        lotteryStatus = false; // Set lottery status to completed
        nftContract = address(0); // Reset the NFT contract address
        tokenId = 0; // Reset the token ID
        totalEntries = 0; // Reset the total entries
        
    }

    function changeTicketCost(uint256 _newCost) public onlyAdmin {
        require(!lotteryStatus, "Lottery is still running"); //Lottery must not be running
        ticketCost = _newCost; //Set the new ticket cost
        emit TicketCostChanged(_newCost); //Emit the event that the ticket cost was updated
    }

    function initialize() public  {
         //Set the new ticket cost for initialize purposes. User must override prior to starting raffle
    }

    function getTokenCostInfo(uint256 _pid) public view returns (uint256){
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        uint256 cost;
        cost = tokens.costvalue;
        return cost;
    }

    function getPlayers() public view returns (address[] memory) {
        return players; //Return the players array
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance; //Return the contract balance
    }

    function getWinner() public view returns (address[] memory) {
        return winnerOfPrize;
     }

    // Balance of from ERC721
    function getBalanceERC20(uint256 _pid) public view returns (uint256) {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        return paytoken.balanceOf(address(this)); //Return the contract balance
    }

   function getTokenInfo(uint256 _pid) public view returns (address) {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        return address(paytoken); //Return the contract balance
    }

    function withdrawBalance() public onlyAdmin {
        require(address(this).balance > 0, "No balance to withdraw.");
        uint256 amount = address(this).balance;
        payable(admin).transfer(amount);
        emit BalanceWithdrawn(amount);
    }

     //custom withdraw function
    function withdraw(uint256 _pid) public payable onlyAdmin() {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        paytoken.transfer(msg.sender, paytoken.balanceOf(address(this)));
    }

    //Master reset function to reset the contract
    function resetContract() public onlyAdmin {
        delete playerSelector; // Reset the playerSelector array
        delete players; // Reset the players array
        lotteryStatus = false; // Set lottery status to completed
        nftContract = address(0); // Reset the NFT contract address
        tokenId = 0; // Reset the token ID
        ticketCost = 0; // Reset the ticket cost
        totalEntries = 0; // Reset the total entries
        delete AllowedCrypto;
        delete winnerOfPrize;
        resetEntryCounts(); //Reset the entry counts 
    }
}   