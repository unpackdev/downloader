// SPDX-License-Identifier: MIT
// ____                            ___       ______                                           
///\  _`\   __                    /\_ \     /\__  _\   __                                     
//\ \ \L\ \/\_\    __  _     __   \//\ \    \/_/\ \/  /\_\      __        __    _ __    ____  
// \ \ ,__/\/\ \  /\ \/'\  /'__`\   \ \ \      \ \ \  \/\ \   /'_ `\    /'__`\ /\`'__\ /',__\ 
//  \ \ \/  \ \ \ \/>  </ /\  __/    \_\ \_     \ \ \  \ \ \ /\ \L\ \  /\  __/ \ \ \/ /\__, `\
//   \ \_\   \ \_\ /\_/\_\\ \____\   /\____\     \ \_\  \ \_\\ \____ \ \ \____\ \ \_\ \/\____/
//    \/_/    \/_/ \//\/_/ \/____/   \/____/      \/_/   \/_/ \/___L\ \ \/____/  \/_/  \/___/ 
//                                                              /\____/                       
//                                                              \_/__/    
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ERC20.sol";
import "./Ownable.sol";

interface iPixelTigers {
    function ownerGenesisCount(address owner) external view returns(uint256);
    function numberOfLegendaries(address owner) external view returns(uint256);
    function numberOfUniques(address owner) external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function tokenGenesisOfOwner(address owner) external view returns(uint256[] memory);
}

contract PixelERC20 is ERC20, Ownable {

    uint256 constant public BASE_RATE = 10 ether;
    uint256 constant public UNIQUE_RATE= 12 ether;
    uint256 constant public LEGENDARY_RATE= 15 ether;
    uint256 constant public TICKET_PRICE = 10 ether;

    uint256 public amountLeftForReserve = 145000 ether;
    uint256 public amountTakenFromReserve;
    uint256 public numEntriesMain;
    uint256 public numEntriesSub;
    uint256 public START;

    bool public rewardPaused = false;
    bool public mainRaffleActive = false;
    bool public subRaffleActive = false;

    mapping(address => uint256) private minttime;
    mapping(address => uint256) private storeRewards;
    mapping(address => uint256) private lastUpdate;

    mapping(address => bool) public allowedAddresses;
    mapping(uint256 => bool) public tigerClaimedInitialReward;

    iPixelTigers public PixelTigers;

    event enteredMainRaffle(uint256 numTickets);
    event enteredSubRaffle(uint256 numTickets);

    constructor(address nftAddress) ERC20("PIXEL", "PXL") {
        PixelTigers = iPixelTigers(nftAddress);
        START = block.timestamp;
    }

    function airdrop(address[] calldata to, uint256 amount) external onlyOwner {
        uint256 totalamount = to.length * amount * 1000000000000000000;
        require(totalamount <= amountLeftForReserve, "No more reserved");
        for(uint256 i; i < to.length; i++){
            _mint(to[i], amount * 1000000000000000000);
        }
        amountLeftForReserve -= totalamount;
        amountTakenFromReserve += totalamount;
    }

    function timeStamp(address user) external {
        require(msg.sender == address(PixelTigers));
        minttime[user] = block.timestamp;
    }

    function enterMainRaffle(uint256 numTickets) external {
        require(PixelTigers.balanceOf(msg.sender) > 0, "Do not own any Tigers");
        require(mainRaffleActive, "Main Raffle not active");
        _burn(msg.sender, (numTickets*TICKET_PRICE));

        numEntriesMain += numTickets;
    }

    function enterSubRaffle(uint256 numTickets) external {
        require(PixelTigers.balanceOf(msg.sender) > 0, "Do not own any Tigers");
        require(subRaffleActive, "Sub Raffle not active");
        _burn(msg.sender, (numTickets*TICKET_PRICE));

        numEntriesSub += numTickets;
    }

    function burn(address user, uint256 amount) external {
        require(allowedAddresses[msg.sender] || msg.sender == address(PixelTigers), "Address does not have permission to burn");
        _burn(user, amount);
    }

    function claimReward() external {
        require(!rewardPaused, "Claiming of $pixel has been paused"); 
        _mint(msg.sender, pendingReward(msg.sender) + storeRewards[msg.sender]);
        storeRewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.timestamp;
    }

    //called when transfers happened, to ensure new users will generate tokens too
    function rewardSystemUpdate(address from, address to) external {
        require(msg.sender == address(PixelTigers));
        if(from != address(0)){
            storeRewards[from] += pendingReward(from);
            lastUpdate[from] = block.timestamp;
        }
        if(to != address(0)){
            storeRewards[to] += pendingReward(to);
            lastUpdate[to] = block.timestamp;
        }
    }

    function totalTokensClaimable(address user) external view returns(uint256) {    
        return pendingReward(user) + storeRewards[user];
        
    }

    function pendingReward(address user) internal view returns(uint256) {
        if (PixelTigers.numberOfLegendaries(user)>0){
            return (PixelTigers.ownerGenesisCount(user)- PixelTigers.numberOfLegendaries(user))* BASE_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) /86400 + PixelTigers.numberOfLegendaries(user)* LEGENDARY_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) /86400;
        } else if (PixelTigers.numberOfUniques(user)>0){
            return (PixelTigers.ownerGenesisCount(user)- PixelTigers.numberOfUniques(user))* BASE_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) /86400 + PixelTigers.numberOfUniques(user)* UNIQUE_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) /86400;
        } else{
            return PixelTigers.ownerGenesisCount(user) * BASE_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) /86400;
        }
    }

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }

    //if address of contract of genesis collection changes
    function setERC721(address ERC721Address) external onlyOwner {
        PixelTigers = iPixelTigers(ERC721Address);
    }

    function toggleReward() public onlyOwner {
        rewardPaused = !rewardPaused;
    }

    function clearMainRaffleList() external onlyOwner{
        numEntriesMain = 0;
    }

    function clearSubRaffleList() external onlyOwner{
        numEntriesSub = 0;
    }

    function toggleMainRaffle() public onlyOwner {
        mainRaffleActive = !mainRaffleActive;
    }

    function toggleSubRaffle() public onlyOwner {
        subRaffleActive = !subRaffleActive;
    }
}