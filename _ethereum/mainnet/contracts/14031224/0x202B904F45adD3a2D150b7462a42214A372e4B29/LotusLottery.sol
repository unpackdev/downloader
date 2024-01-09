// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./VRFConsumerBase.sol";

contract LotusLottery is ERC721Pausable, Ownable, VRFConsumerBase {
  using Counters for Counters.Counter;
  
  Counters.Counter private _tokenIds;
  Counters.Counter private _season;

  // chainlink variables
  bytes32 private keyHash;
  uint256 private fee;
  // holds the random value returned by chainlink VRF
  uint256 public randomResult;
  
  // lottery variables
  address public treasury = 0x8ec24Ba9896b51664Ef39c35a7B9B9E7ce141Eb4;
  uint public ticketPrice = 0.03 ether;
  uint public maxTicketsPerSeason = 200;
  uint public maxTicketsPerAddress = 200;
  uint public maxTicketsPerTransaction = 10;
  mapping(uint => mapping(address => uint)) public seasonsTicketNumberByAddress;
  mapping(uint => uint) public seasonOfTicket;
  mapping(uint => uint[]) public seasonsParticipantsTokenIds;

  // address of the last drawn lottery winner
  address public lastWinner;
  
  // events for change and progress logging
  event LotteryDrawingRequested(bytes32 requestId, uint season, uint numberOfParticipants, uint lotteryPot);
  event LotteryWon(uint season, address winner, uint tokenID);
  event LotteryPaid(uint season, address to, uint amount);
  event TicketPriceChanged(uint newPrice);
  event MaxTicketsPerAddressChanged(uint newMaxTicketsPerAddress);
  event MaxTicketsPerTransactionChanged(uint newMaxTicketsPerTransaction);
  event MaxTicketsPerSeasonChanged(uint newMaxTicketsPerSeason);
  event NextSeasonStarted(uint newSeason, uint newSeasonStartDate);
  event SeasonToBaseURIChanged(uint season, string newSeasonBaseURI);
  event BaseTicketURIChanged(string newBaseTicketURI);
  
  // ticket artwork ipfs link
  string public baseTicketURI  = "https://ipfs.io/ipfs/";
  mapping (uint => string) public seasonToBaseURI;

  constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyhash, uint _fee) 
    ERC721("LotusLottery", "LL")
    VRFConsumerBase(_VRFCoordinator, _LinkToken)
      {
      keyHash = _keyhash;
      fee = _fee; 
    }
  
  // buy a ticket for the current season
  function buyTicket(uint amount) external payable whenNotPaused {
    require(msg.value == ticketPrice * amount,"incorrect ticket price");
    require((amount > 0) && (amount <= maxTicketsPerTransaction), "incorrect amount input");
    uint currentSeason = getCurrentSeason();
    require(getCurrentSeasonTicketCount(currentSeason) + amount <= maxTicketsPerSeason,"seasontickets sold out");
    require(seasonsTicketNumberByAddress[currentSeason][msg.sender] + amount <= maxTicketsPerAddress, "max tickets per season");
    seasonsTicketNumberByAddress[currentSeason][msg.sender] += amount;
    for(uint i = 0; i < amount; i++){
      _mintTicket(currentSeason);
    }
  }

  function _mintTicket(uint _currentSeason) private {
    _tokenIds.increment();
    uint id = _tokenIds.current();
    seasonOfTicket[id] = _currentSeason;
    seasonsParticipantsTokenIds[_currentSeason].push(id);
    _mint(msg.sender, id);
  }

  // Initiates the Lottery Winner Drawing, by sending a request to Chainlink VRF, to provide a random number
  function requestLotteryWinnerDrawing() external onlyOwner whenNotPaused{
    uint currentSeason = getCurrentSeason();
    uint currentSeasonTicketNumber = getCurrentSeasonTicketCount(currentSeason);
    require( currentSeasonTicketNumber > 1, "need more participants");
    _pause();
    bytes32 drawingRequestId = getRandomNumber();
    emit LotteryDrawingRequested(drawingRequestId, currentSeason, currentSeasonTicketNumber, getCurrentPot());
  }

  // sends request for random number to Chainlink VRF node along with fee
  function getRandomNumber() private returns (bytes32 requestId) {
    require(LINK.balanceOf(address(this)) >= fee, "not enough LINK token");
    return requestRandomness(keyHash, fee);
  }

  // Callback function used by VRF Coordinator
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    randomResult = randomness;
    lastWinner = getWinnerAddress(randomResult);
    payWinnings(lastWinner);
    resetAndStartNextSeason();
  }
  
  // selects winning address randomly from current season entries
  function getWinnerAddress(uint randomVal) private returns (address){
    uint currentSeason = getCurrentSeason();
    uint selectedId = randomVal % getCurrentSeasonTicketCount(currentSeason);
    uint winnerTokenId = seasonsParticipantsTokenIds[currentSeason][selectedId];
    address winnerAddress = ownerOf(winnerTokenId);
    emit LotteryWon(currentSeason, winnerAddress, winnerTokenId);
    return winnerAddress;
  }

  // sends 80% of pot to winner, 20 % to treasury
  function payWinnings(address winner) private {
    (bool d, ) = payable(treasury).call{value: (address(this).balance * 20) / 100}("");
    require(d, "treasury tx failed");
    uint winnings = address(this).balance;
    (bool s,) = payable(winner).call{value: winnings}("");
    require(s, "winner tx failed");
    emit LotteryPaid(getCurrentSeason(), winner, winnings);
  }

  function resetAndStartNextSeason() private {
    _season.increment();
    _unpause();
    emit NextSeasonStarted(getCurrentSeason(), block.timestamp);
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    string memory _tokenURI = "Token with that ID does not exist.";
    if (_exists(tokenId)){
      uint tokensSeason = seasonOfTicket[tokenId];
      if(bytes(seasonToBaseURI[tokensSeason]).length != 0){
        _tokenURI = seasonToBaseURI[tokensSeason];
      }
      else {
        _tokenURI = baseTicketURI;
      }
    }
    return _tokenURI;
  }

  // Setters for lottery parameters
  function changeSeasonToBaseURI(uint _selectedSeason, string memory newSeasonToBaseURI) external onlyOwner {
    seasonToBaseURI[_selectedSeason] = newSeasonToBaseURI;
    emit SeasonToBaseURIChanged(_selectedSeason, newSeasonToBaseURI);
  }

  function changeBaseTicketURI(string memory newBaseTicketURI) external onlyOwner {
    baseTicketURI = newBaseTicketURI;
    emit BaseTicketURIChanged(newBaseTicketURI);
  }

  function changeChainlinkVariables(bytes32 newKeyHash, uint256 newFee) external onlyOwner {
    keyHash = newKeyHash;
    fee = newFee;
  }

  function changeMaxTicketsPerAddress(uint newMaxTicketsPerAddress) external onlyOwner {
    maxTicketsPerAddress = newMaxTicketsPerAddress;
    emit MaxTicketsPerAddressChanged(newMaxTicketsPerAddress);
  }

  function changeMaxticketsPerSeason(uint newMaxTicketsPerSeason) external onlyOwner {
    maxTicketsPerSeason = newMaxTicketsPerSeason;
    emit MaxTicketsPerSeasonChanged(newMaxTicketsPerSeason);
  }
  
  function changeMaxTicketsPerTransaction(uint newMaxTicketsPerTransaction) external onlyOwner {
    maxTicketsPerTransaction = newMaxTicketsPerTransaction;
    emit MaxTicketsPerTransactionChanged(newMaxTicketsPerTransaction);
  }

  function changeTicketPrice(uint newPrice) external onlyOwner {
    ticketPrice = newPrice;
    emit TicketPriceChanged(newPrice);
  }

  // emergency pause control in case drawing process gets stuck on VRF side 
  function switchPauseState() external onlyOwner {
    if(paused()){
      _unpause();
    }
    else {
      _pause();
    }
  }

  // Getters for lottery parameters
  function getCurrentPot() public view returns(uint){
    return (address(this).balance * 80) / 100;
  }

  function getCurrentSeason() public view returns(uint){
    return _season.current();
  }

  function getCurrentSeasonTicketCount(uint _currentSeason) public view returns (uint){
    return seasonsParticipantsTokenIds[_currentSeason].length;
  }

  function getCurrentSeasonTicketsIDs() public view returns(uint[] memory){
    return seasonsParticipantsTokenIds[getCurrentSeason()];
  }

  function totalSupply() public view returns (uint) {
    return _tokenIds.current();
  }
}
