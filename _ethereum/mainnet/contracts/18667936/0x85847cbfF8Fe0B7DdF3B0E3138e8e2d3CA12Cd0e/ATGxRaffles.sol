// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ERC721Base.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract ATGxRaffles is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Raffle {
        uint256 raffleId; // Unique id for each raffle started
        bool raffleStatus; // True if the raffle is running
        address nftContract; // Address of the NFT contract for the prize
        uint256 tokenId; // Token ID of the NFT for the prize
        uint256 totalEntries; // Total number of entries
        uint256 raffleCost; // Store cost of the raffle ticket
        IERC20 raffleCurrency; // Raffle Currency Contract Address
        address[] players; // Array of players who bought tickets
        address[] playerSelector; // Array of players for random selection
        mapping(address => uint256) entryCounts; // Mapping to store the count of entries per address
        address winner; // Winner of the Raffle
        uint256 endTimeEpoch; // Raffle end time epoch timestamp
        uint256 winningHash; // Winner Hash of the raffle
    }

    IERC20 public ticketToken; // Raffle Currency Token
    mapping(uint256 => Raffle) public raffles; // Store each raffles in contract
    uint256 public eventId; // Incremental event ID
    uint256 public ticketCost; // Default Ticket Cost
    address public admin; // SmartContract Deployer

    event NewTicketBought(address player); //Event when someone buys a ticket
    event RaffleStarted(uint256 eventId); // Start new Raffle
    event RaffleEnded(uint256 eventId); // End Raffle
    event Winner(address winner); // Event when someone wins the raffle
    event TicketCostChanged(uint256 eventId, uint256 newCost); //Event when the ticket cost is updated
    event NFTPrizeSet(address nftContract, uint256 tokenId); // Set Raffle NFT Prize
    event BalanceWithdrawn(uint256 amount); // Withdraw AGC Token
    event ERC20Withdrawn(address admin, address ticketToken, uint256 amount); // Withdraw AGC to Wallet
    event ExtendRaffle(uint256 eventId, uint256 endTimeEpoch); // Change Raffle end Time
    event PrizeSent(address winner);
    event ClearAllRaffle();

    constructor() {
        admin = msg.sender; // Contract Deployer
        eventId = 0; 
        ticketToken = IERC20(0x421859BF91f00eb6b3B66d45283FA925b24AB12D);
        ticketCost = 1000000000000000000;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function"); // Sets the admin as the only one who can call functions
        _;
    }

    /**
    * @notice To check whether the address is a participant of the raffle
    */
    function isPlayer(uint256 _eventId, address participant) private view returns (bool) {
        for (uint256 i = 0; i < raffles[_eventId].players.length; i++) {
            if (raffles[_eventId].players[i] == participant) {
                return true;
            }
        }
        return false;
    }

    /**
    * @notice Only admin can start a new Raffle
    */
    function startRaffle(address _nftContract, uint256 _tokenId, uint256 _endTimeEpoch) public onlyAdmin {
        eventId = eventId + 1; // Increase RaffleId when new event start
        /* 
        require(
            ERC721Base(_nftContract).ownerOf(_tokenId) == admin,
            "Admin does not own the specified NFT."
        ); // Admin must own the NFT
        */
        raffles[eventId].tokenId = _tokenId; // Set token id of the token contract
        raffles[eventId].raffleId = eventId; // Set Raffles ID
        raffles[eventId].raffleCost = ticketCost; // Set Raffles Token Cost
        raffles[eventId].raffleCurrency = ticketToken; // Set Raffle Currency Address
        raffles[eventId].raffleStatus = true; // Set the Raffles status to true
        raffles[eventId].nftContract = _nftContract; // Set Raffle Nft Token
        raffles[eventId].tokenId = _tokenId; // Set Raffle Nft Token Id
        raffles[eventId].totalEntries = 0; // Total Entries of the Raffle
        raffles[eventId].endTimeEpoch = _endTimeEpoch; // End time of the Raffle

        emit RaffleStarted(eventId); // Emit the event that the raffle has started
        emit NFTPrizeSet(_nftContract, _tokenId); // Emit Nft Token has been set
    }   

        /**
    * @notice Anyone can buy raffle ticket if the raffle is running
    */
    function manualEnter(uint256 _eventId, address participant, uint256 numberOfTickets) external onlyAdmin{
        require(raffles[_eventId].raffleStatus == true, "Raffle is not running"); //Raffle must be running

        // Increment the count of entries for the participant
        raffles[_eventId].entryCounts[participant] += numberOfTickets;
        // Increment count of the total entries for the raffle
        raffles[_eventId].totalEntries += numberOfTickets;

        if (!isPlayer(_eventId, participant)) {
            raffles[_eventId].players.push(participant); // Add the player to the players array
        }
        
        for (uint256 i = 0; i < numberOfTickets; i++) {
            raffles[_eventId].playerSelector.push(participant); // Add the player to the playerSelector array
        }

        emit NewTicketBought(msg.sender); //Emit the event that a new ticket was bought
    }

    /**
    * @notice Anyone can buy raffle ticket if the raffle is running
    */
    function buyTicket(uint256 _eventId, uint256 numberOfTickets, uint256 _amount) public {
        require(_amount == raffles[_eventId].raffleCost * numberOfTickets, "Ticket cost is not correct"); //Ticket cost must match the ticketCost variable
        require(raffles[_eventId].raffleStatus == true, "Raffle is not running"); //Raffle must be running
        raffles[eventId].raffleCurrency.transferFrom(msg.sender, address(this), _amount);
        require(block.timestamp < raffles[_eventId].endTimeEpoch, "Raffle has ended");

        // Increment the count of entries for the participant
        raffles[_eventId].entryCounts[msg.sender] += numberOfTickets;
        // Increment count of the total entries for the raffle
        raffles[_eventId].totalEntries += numberOfTickets;

        if (!isPlayer(_eventId, msg.sender)) {
            raffles[_eventId].players.push(msg.sender); // Add the player to the players array
        }
        
        for (uint256 i = 0; i < numberOfTickets; i++) {
            raffles[_eventId].playerSelector.push(msg.sender); // Add the player to the playerSelector array
        }

        emit NewTicketBought(msg.sender); //Emit the event that a new ticket was bought
    }

    /**
    * @notice Function returns a random number between 0 and the length of the players array
    */
    function random(uint256 _eventId, uint256 randVal) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        randVal,
                        raffles[_eventId].playerSelector
                    )
                )
            );
    }

    /**
    * @notice Only admin can pick a winner from a raffle
    */
    function pickWinner(uint256 _eventId, uint256 randVal) public onlyAdmin {

        // Randomize player entry for fairness
        raffles[_eventId].playerSelector = shufflePlayer(raffles[_eventId].playerSelector);
        raffles[_eventId].winningHash = random(_eventId, randVal);
        uint256 index = raffles[_eventId].winningHash % raffles[_eventId].playerSelector.length; // Get a random index
        address winner = raffles[_eventId].playerSelector[index]; // Get the winner address
        raffles[_eventId].winner = winner; // Set Winner into the Raffle

        emit Winner(winner); // Emit the event that a winner was picked
    }

    /**
    * @notice Only admin can change the state of the raffle
    */
    function changeRaffleStatus(uint256 _eventId, bool _state) public onlyAdmin {
        raffles[_eventId].raffleStatus = _state; // Set Raffle Ticket Cost
    }

    /**
    * @notice Only admin can change the cost of the raffle ticket
    */
    function changeTicketCost(uint256 _eventId, uint256 _newCost) public onlyAdmin {
        ticketCost = _newCost; // Set the new ticket cost
        raffles[_eventId].raffleCost = ticketCost; // Set Raffle Ticket Cost

        emit TicketCostChanged(_eventId, _newCost); // Emit the event that the ticket cost was updated
    }

    /**
    * @notice Only admin can change the Raffle NFT Contract Address
    */
    function changeDefaultNFT(uint256 _eventId, address _newNftContract, uint256 _tokenId) public onlyAdmin {
        raffles[_eventId].nftContract = _newNftContract; // Set Raffle NFT contract
        raffles[_eventId].tokenId = _tokenId; // Set Raffle NFT tokenId

        emit NFTPrizeSet(_newNftContract, _tokenId); // Emit the event that the raffle nft haschanged
    }
    /**
    * @notice Only admin can change the Raffle Currency Contract
    */
    function changeRaffleCurrency(address _newCurrency) public onlyAdmin {
        ticketToken = IERC20(_newCurrency);
    }

    /**
    * @notice Get all participants from the raffle
    */
    function getPlayers(uint256 _eventId) external view returns (address[] memory) {
        return raffles[_eventId].players; // Return the players array
    }

    /**
    * @notice Get an array of entry of the raffle
    */
    function getPlayerSelector(uint256 _eventId) external view returns (address[] memory) {
        return raffles[_eventId].playerSelector;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance; // Return the contract balance
    }

    function getBalanceERC20() external view returns (uint256) {
        return ticketToken.balanceOf(address(this));// Return the contract raffle balance ERC20
    }

    /**
    * @notice Get player entry count from a the raffle
    */
    function getPlayersEntriesCount(uint256 _eventId, address participant) external view returns (uint256) {
        return  raffles[_eventId].entryCounts[participant]; 
    }
   
    /**
    * @notice Get total entries of a raffle
    */
    function getTotalEntries(uint256 _eventId) external view returns (uint256) {
        return raffles[_eventId].totalEntries; // Return total raffle entries
    }

    /**
    * @notice Get winner of the Raffle. 
    */
    function getWinner(uint256 _eventId) external view returns (address) {
        return raffles[_eventId].winner; // Return raffle winner
    }

    /**
    * @notice Get status of the Raffle. 
    */
    function getRaffleStatus(uint256 _eventId) external view returns (bool) {
        return raffles[_eventId].raffleStatus; // Return raffle status
    }

    /**
    * @notice Return all Raffles Status 
    */
    function getValidRaffles() external view returns (uint[] memory) {
        uint[] memory validRaffle = new uint[](eventId);
        uint16 index = 0;
        for (uint i = 1; i <= eventId; i++) {
            if (raffles[i].raffleStatus == true) {
                validRaffle[index] = raffles[i].raffleId;
                index++;
            }
        }
        return validRaffle;
    }

    /**
    * @notice Only admin can edit raffle end time
    */
    function extendRaffleEndTime(uint256 _eventId, uint256 _endTimeEpoch) public onlyAdmin {
        raffles[_eventId].endTimeEpoch = _endTimeEpoch; 
        
        emit ExtendRaffle(_eventId, raffles[_eventId].endTimeEpoch); 
    }

    /**
    * @notice Only Admin can end raffle after winner is picked.
    */
    function drawRaffle(uint256 _eventId, uint256 randVal) public onlyAdmin {
        require(raffles[eventId].endTimeEpoch < block.timestamp, 'Raffles is still running'); // Check for raffle end time
        require(raffles[_eventId].raffleStatus, "Raffle is not running"); // Raffle must be running

        raffles[_eventId].raffleStatus = false; // Set the raffle status to false
        pickWinner(_eventId, randVal);

        emit RaffleEnded(_eventId); // Emit the event that the raffle has ended
    }

    /**
    * @notice Only admin can end raffle early 
    */
    function drawRaffleNow(uint256 _eventId, uint256 randVal) public onlyAdmin {
        raffles[_eventId].endTimeEpoch = block.timestamp;
        raffles[_eventId].raffleStatus = false; // Set Raffle status to false
        pickWinner(_eventId, randVal);

        emit RaffleEnded(_eventId); // Emit the event that the raffle has ended
    }

    /**
    * @notice Only admin withdraw balance from the contract (ETH)
    */
    function withdrawBalance() public onlyAdmin {
        require(address(this).balance > 0, "No balance to withdraw.");
        uint256 amount = address(this).balance;
        payable(admin).transfer(amount);

        emit BalanceWithdrawn(amount);
    }

    /**
    * @notice Only admin can withdraw ERC20 balance from contract (AGC)
    */
    function withdrawBalanceERC20() public onlyAdmin {
        require(ticketToken.balanceOf(address(this)) > 0, "No token balance to withdraw."); // Withdraw AGC Token from contract
        uint256 tokenBalance = ticketToken.balanceOf(address(this));
        raffles[eventId].raffleCurrency.safeTransfer(admin, tokenBalance);

        emit ERC20Withdrawn(address(this), address(ticketToken), tokenBalance);
    }

    /**
    * @notice Emergency Withdraw incase default withdraw fail
    */
    function emergencyWithdraw(address _token) public onlyAdmin {
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        require(tokenBalance > 0, "No token balance to withdraw.");
        IERC20(_token).safeTransfer(msg.sender, tokenBalance);

        emit ERC20Withdrawn(msg.sender, _token, tokenBalance);
    }

    /**
    * @notice Only admin can transfer the winner prize
    */
    function transferWinnerPrize(uint256 _eventId) public onlyAdmin {
        require(
            ERC721Base(raffles[_eventId].nftContract).ownerOf(raffles[_eventId].tokenId) == admin,
            "Admin does not own the specified NFT."
        ); // Admin must own the NFT
        require(raffles[_eventId].nftContract != address(0), "NFT contract not set"); // NFT contract must be set

        ERC721Base(raffles[_eventId].nftContract).transferFrom(admin, raffles[_eventId].winner, raffles[_eventId].tokenId);

        emit PrizeSent(raffles[_eventId].winner);
    }

    /**
    * @notice Only admin can delete all raffle records
    */
    function resetAllEvent() public onlyAdmin {

        for (uint256 index = 1; index <= eventId; index++) {
            for (uint256 i = 0; i < raffles[index].players.length; i++) {
                raffles[index].entryCounts[raffles[index].players[i]] = 0;
            }
            delete raffles[index].raffleId; 
            delete raffles[index].raffleStatus; 
            delete raffles[index].nftContract; 
            delete raffles[index].tokenId; 
            delete raffles[index].totalEntries; 
            delete raffles[index].raffleCost; 
            delete raffles[index].raffleCurrency; 
            delete raffles[index].players; 
            delete raffles[index].playerSelector; 
            delete raffles[index].winner; 
            delete raffles[index].endTimeEpoch; 
            delete raffles[index];
        }

        eventId = 0;
        emit ClearAllRaffle();
    }

    function shufflePlayer(address[] memory playerSelector) private view returns (address[] memory) {
        for (uint256 i = 0; i < playerSelector.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        playerSelector))) % (playerSelector.length - i);
            address temp = playerSelector[n];
            playerSelector[n] = playerSelector[i];
            playerSelector[i] = temp;
        }

        return playerSelector;
    }

}
