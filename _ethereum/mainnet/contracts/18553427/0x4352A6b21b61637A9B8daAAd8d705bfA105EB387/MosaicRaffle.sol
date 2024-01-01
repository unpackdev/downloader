// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol"; // Interface for ERC721

interface IRaffleWinnerNFT {
    function mintForAddress(uint256 _mintAmount, address _receiver) external;
}

contract MosaicRaffle is Ownable(msg.sender), Pausable, ReentrancyGuard {
    address payable[] public players;
    uint public raffleId;
    uint public ticketPrice = 0.005 ether;
    bool public isEntryAllowed = true;
    mapping(uint => address) public raffleHistory;
    IRaffleWinnerNFT public raffleWinnerNft;
    IERC721 public mosaicArtClubNFT; // Variable for the Mosaic Art Club NFT contract

    constructor() {
        raffleId = 1;
    }

    modifier entryIsAllowed() {
        require(isEntryAllowed, "Entry to the raffle is not allowed at the moment");
        _;
    }

    function setRaffleWinnerNftAddress(address _raffleWinnerNftAddress) public onlyOwner {
        raffleWinnerNft = IRaffleWinnerNFT(_raffleWinnerNftAddress);
    }

    function setMosaicArtClubNFTAddress(address _nftAddress) public onlyOwner {
        mosaicArtClubNFT = IERC721(_nftAddress);
    }

    function getWinnerByRaffle(uint raffle) public view returns (address) {
        return raffleHistory[raffle];
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function enter(uint256 numberOfTickets) public payable whenNotPaused entryIsAllowed nonReentrant {
        require(numberOfTickets > 0, "Cannot buy zero tickets");
        require(msg.value == numberOfTickets * ticketPrice, "Ether sent is not correct");

        uint256 finalNumberOfTickets = numberOfTickets;

        // Check if the Mosaic Art Club NFT contract is set and if the sender owns an NFT
        if (address(mosaicArtClubNFT) != address(0) && mosaicArtClubNFT.balanceOf(msg.sender) > 0) {
            finalNumberOfTickets *= 2;
        }

        for (uint256 i = 0; i < finalNumberOfTickets; i++) {
            players.push(payable(msg.sender));
        }
    }

    function pickWinner(bytes32 _seed) public onlyOwner whenNotPaused nonReentrant {
        require(address(raffleWinnerNft) != address(0), "RaffleWinnerNFT address not set");
        require(players.length > 0, "No players in the raffle");
        require(_seed != bytes32(0), "Seed not set");

        uint index = getRandomNumber(_seed) % players.length;
        address winner = players[index];

        raffleWinnerNft.mintForAddress(1, winner);

        raffleHistory[raffleId] = winner;
        raffleId++;
        players = new address payable[](0);
    }

    function offChainPickWinner(uint index) public onlyOwner nonReentrant {
        require(address(raffleWinnerNft) != address(0), "RaffleWinnerNFT address not set");
        require(index < players.length, "Invalid index");

        address winner = players[index];
        raffleWinnerNft.mintForAddress(1, winner);

        raffleHistory[raffleId] = winner;
        raffleId++;
        players = new address payable[](0);
    }

    function getRandomNumber(bytes32 _seed) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, players, _seed)));
    }

    function setTicketPrice(uint _ticketPrice) public onlyOwner {
        require(_ticketPrice > 0, "Ticket price must be greater than 0");
        ticketPrice = _ticketPrice;
    }

    function toggleEntry() public onlyOwner {
        isEntryAllowed = !isEntryAllowed;
    }

    function withdraw() public onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
