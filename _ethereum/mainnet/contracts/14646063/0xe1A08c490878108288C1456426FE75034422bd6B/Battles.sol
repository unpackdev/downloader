// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./EnumerableSet.sol";

interface IRandomizer {
    function randomMod(uint256,uint256,uint256) external returns (uint256);
}

interface ILandStaker {
    function getStakedBalance(address, uint256) external returns (uint256);
}

interface IIngameItems {
    function addGemToPlayer(uint256, address) external;
    function addTotemToPlayer(uint256, address) external;
    function addGhostToPlayer(uint256, address) external;
}

contract Battles is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private counter;
    uint256 constant public DECIMALS_18 = 1e18;
    IERC20 public paymentToken;
    IERC721 public piratesContract;
    IERC1155 public landContract;
    ILandStaker public landStakingContract;
    IRandomizer public randomizer;
    IIngameItems public ingameItems;
    uint256 public stakingCostInEtherUnits;

    event BattleAdded(uint256 battleId);

    struct Battle {
        uint256 battleId; 
        bool open; // open to add pirates
        bool started;
        bool ended;
        uint256 startTime;
        uint256 endTime;
        EnumerableSet.AddressSet players;
        EnumerableSet.AddressSet xbmfWinners;
        EnumerableSet.AddressSet gemWinners;
        EnumerableSet.AddressSet totemWinners;
        EnumerableSet.AddressSet ghostWinners;
        mapping(address => EnumerableSet.UintSet) piratesByPlayer;
        mapping(uint256 => address) pirateOwners;
        uint256 rewardsInEtherUnits;
        uint256 numXbmfPrizes;
        uint256 numGemPrizes;
        uint256 numGhostPrizes;
        uint256 numTotemPrizes;
        uint256 stakedPiratesCount;
        address[] tickets;
    }

    mapping (uint256 => Battle) battles;

    function addXBMF(uint256 amount) external onlyOwner {
        paymentToken.transferFrom(msg.sender, address(this), amount);
    }

    function setPaymentToken(address _address) external onlyOwner {
        paymentToken = IERC20(_address);
    }

    function setStakingCost(uint256 _stakingCostInEtherUnits) external onlyOwner {
        stakingCostInEtherUnits = _stakingCostInEtherUnits;
    }

    function setLandStakingContract(address _address) external onlyOwner {
        landStakingContract = ILandStaker(_address);
    }

    function setIngameItemsContract(address _address) external onlyOwner {
        ingameItems = IIngameItems(_address);
    }

    function setRandomizerContract(address _address) external onlyOwner {
        randomizer = IRandomizer(_address);
    }

    function setPiratesContract(address _address) external onlyOwner {
        piratesContract = IERC721(_address);
    }

    function setLandContract(address _address) external onlyOwner {
        landContract = IERC1155(_address);
    }

    function addBattle(uint256 _startTime, uint256 _endTime, uint256 _rewardsInEtherUnits, uint256 _numXBmfPrizes, uint256 _numGemPrizes,
        uint256 _numGhostPrizes, uint256 _numTotemPrizes
    ) external onlyOwner {
        Battle storage battle = battles[counter.current()];
        battle.battleId = counter.current();
        battle.started = false;
        battle.ended = false;
        battle.open = false;
        battle.startTime = _startTime;
        battle.endTime = _endTime;
        battle.rewardsInEtherUnits = _rewardsInEtherUnits;
        battle.numXbmfPrizes = _numXBmfPrizes;
        battle.numGemPrizes = _numGemPrizes;
        battle.numGhostPrizes = _numGhostPrizes;
        battle.numTotemPrizes = _numTotemPrizes;

        emit BattleAdded(counter.current());

        counter.increment();
    }

    function getBattleData(uint256 battleId) public view returns (uint256[] memory) {
        Battle storage battle = battles[battleId];
        uint256[] memory data = new uint256[](10);
        data[0] = battle.battleId;
        data[1] = battle.started ? 1 : 0;
        data[2] = battle.ended ? 1 : 0;
        data[3] = battle.startTime;
        data[4] = battle.endTime;
        data[5] = battle.rewardsInEtherUnits;
        data[6] = battle.numXbmfPrizes;
        data[7] = battle.numGemPrizes;
        data[8] = battle.numGhostPrizes;
        data[9] = battle.numTotemPrizes;
        return data;
    }

    function hasLand(address _address) internal returns (bool){
        return landContract.balanceOf(_address, 0) > 0 ||
            landContract.balanceOf(_address, 1) > 0 ||
            landContract.balanceOf(_address, 2) > 0 ||
            landContract.balanceOf(_address, 3) > 0 ||
            landContract.balanceOf(_address, 4) > 0 ||
            landContract.balanceOf(_address, 5) > 0 ||
            landContract.balanceOf(_address, 6) > 0 ||
            landContract.balanceOf(_address, 7) > 0 ||
            landStakingContract.getStakedBalance(_address, 0) > 0 ||
            landStakingContract.getStakedBalance(_address, 1) > 0 ||
            landStakingContract.getStakedBalance(_address, 2) > 0 ||
            landStakingContract.getStakedBalance(_address, 3) > 0 ||
            landStakingContract.getStakedBalance(_address, 4) > 0 ||
            landStakingContract.getStakedBalance(_address, 5) > 0 ||
            landStakingContract.getStakedBalance(_address, 6) > 0 ||
            landStakingContract.getStakedBalance(_address, 7) > 0;
    }

    function addMultiplePiratesToBattleWithLand(uint256 battleId, uint256[] calldata pirateIds) external {
        require(
            battles[battleId].started == false, "Can't add pirates to a started Battle"
        );
        require(
            hasLand(msg.sender), "You need land or skull caves to add a pirate for free"
        );
        for (uint i = 0; i < pirateIds.length; i++){
            addPirateToBattle(battleId, pirateIds[i]);
        }
    }

    function addMultiplePiratesToBattleWithXBMF(uint256 battleId, uint256[] calldata pirateIds, uint256 paymentAmountInEthUnits) external {
        require(
            battles[battleId].started == false, "Can't add pirates to a started Battle"
        );
        require(
            paymentAmountInEthUnits == stakingCostInEtherUnits.mul(pirateIds.length),
            "wrong payment amount"
        );
        require(
            paymentToken.transferFrom(msg.sender, address(this), paymentAmountInEthUnits.mul(DECIMALS_18)),
            "Transfer of payment token could not be made"
        );
        for (uint i = 0; i < pirateIds.length; i++){
            addPirateToBattle(battleId, pirateIds[i]);
        }
    }

    // add pirate to battle:
    // player either pays with xbmf or has a land nft
    // Require approval since function will move the pirate nft
    function addPirateToBattle(uint256 battleId, uint256 pirateId) public { //change to internal _
        // TODO: check if pirate is upgraded

        // require owns pirate
        Battle storage battle = battles[battleId];
        battle.pirateOwners[pirateId] = msg.sender;
        // Add player
        if (!battle.players.contains(msg.sender)) {
             battle.players.add(msg.sender);
        }
        // Add pirate Id mapped to player id
        if (!battle.piratesByPlayer[msg.sender].contains(pirateId)){
            battle.piratesByPlayer[msg.sender].add(pirateId);
        }
        
        // transfer pirate NFT from player to contract
        piratesContract.transferFrom(msg.sender, address(this), pirateId);
        battle.stakedPiratesCount++;
    }

    function removePirateFromBattle(uint battleId, uint256 pirateId) external {
        //check ownership
        Battle storage battle = battles[battleId];
        // remove from players list too? -> use enumerable set
        // if its the last pirate by address, remove address too
        require(battle.piratesByPlayer[msg.sender].contains(pirateId), "Sender doesn't own pirate");
        piratesContract.transferFrom(address(this), msg.sender, pirateId);
        battle.piratesByPlayer[msg.sender].remove(pirateId);
        battle.stakedPiratesCount--;
    }

    function removeAllPiratesFromBattleForPlayer(uint battleId) external { 
       EnumerableSet.UintSet storage pirates =  battles[battleId].piratesByPlayer[msg.sender];
       while (pirates.length() > 0){
           require(battles[battleId].piratesByPlayer[msg.sender].contains(pirates.at(0)), "Sender doesn't own pirate");
           piratesContract.transferFrom(address(this), msg.sender, pirates.at(0));
           pirates.remove(pirates.at(0));
           battles[battleId].stakedPiratesCount--;
       }
    }

    function openBattle(uint256 battleId, bool value) external onlyOwner {
       battles[battleId].open = value;
    }

    function startBattle(uint256 battleId) external onlyOwner {
        battles[battleId].open = false;
        battles[battleId].started = true;
    }

    function endBattle(uint256 battleId) external onlyOwner {
        battles[battleId].ended = true;
        _createTicketList(battleId);
        _pickXbmfWinners(battleId, 0, 0, 0);
        _pickGemWinners(battleId, 0, 1000, 1000);
        _pickTotemWinners(battleId, 0, 2000, 2000);
        _pickGhostWinners(battleId, 0, 3000, 3000);
    }

    function ownsLandType(address _address, uint256 landType) internal returns (bool){
        return landContract.balanceOf(_address, landType) > 0 || landStakingContract.getStakedBalance(_address, landType) > 0;
    }

    function _createTicketList(uint256 battleId) internal {
        // get all players
         for (uint256 i = 0; i < battles[battleId].players.length(); i++) {
            address player = battles[battleId].players.at(i);
            if (ownsLandType(player, 6)) {
                battles[battleId].tickets.push(player);
            }
            if (ownsLandType(player, 7)) {
                battles[battleId].tickets.push(player);
                battles[battleId].tickets.push(player); 
            }
            for (uint256 j = 0; j < battles[battleId].piratesByPlayer[player].length(); j++) {
                battles[battleId].tickets.push(player);
            }
         }
         //console.log("tickets length", battles[battleId].tickets.length);
         //console.log("tickets staked nfts length", battles[battleId].stakedPiratesCount);
    }

    function claimXbmfPrize(uint256 battleId) external {
        bool winner = false;
        for (uint256 i = 0; i < battles[battleId].xbmfWinners.length(); i++) {
            if (battles[battleId].xbmfWinners.at(i) == msg.sender){
                winner = true;
            }
        }
        paymentToken.transfer(msg.sender, battles[battleId].rewardsInEtherUnits.mul(DECIMALS_18));
    }

    function isXbmfWinner(uint256 battleId, address _address) external view returns (bool) {
        bool winner = false;
        for (uint256 i = 0; i < battles[battleId].xbmfWinners.length(); i++) {
            if (battles[battleId].xbmfWinners.at(i) == _address){
                winner = true;
            }
        }
        return winner;
    }

    function getXbmfWinners(uint256 battleId) public view returns (address[] memory){
        if (!battles[battleId].ended){
            return new address[](0);
        }
        uint256 length = battles[battleId].xbmfWinners.length();
        address[] memory arr = new address[](length);//3 winners
        for (uint256 i = 0; i < length; i++){
            arr[i] = battles[battleId].xbmfWinners.at(i);
        }
        return arr;
    }

    function getGemWinners(uint256 battleId) public view returns (address[] memory){
        if (!battles[battleId].ended){
            return new address[](0);
        }
        uint256 length = battles[battleId].gemWinners.length();
        address[] memory arr = new address[](length);
        for (uint256 i = 0; i < length; i++){
            arr[i] = battles[battleId].gemWinners.at(i);
        }
        return arr;
    }

    function getTotemWinners(uint256 battleId) public view returns (address[] memory){
        if (!battles[battleId].ended){
            return new address[](0);
        }
        uint256 length = battles[battleId].totemWinners.length();
        address[] memory arr = new address[](length);
        for (uint256 i = 0; i < length; i++){
            arr[i] = battles[battleId].totemWinners.at(i);
        }
        return arr;
    }

    function getGhostWinners(uint256 battleId) public view returns (address[] memory){
        if (!battles[battleId].ended){
            return new address[](0);
        }
        uint256 length = battles[battleId].ghostWinners.length();
        address[] memory arr = new address[](length);
        for (uint256 i = 0; i < length; i++){
            arr[i] = battles[battleId].ghostWinners.at(i);
        }
        return arr;
    }

    // number of players must be > number of prizes
    function _pickXbmfWinners(uint256 battleId, uint256 count, uint256 nonce, uint256 seed) internal {
        Battle storage battle = battles[battleId];
        while (count < battle.numXbmfPrizes){
            address candidate = battle.tickets[randomizer.randomMod(seed, nonce, battle.tickets.length)];
            if (!battle.xbmfWinners.contains(candidate)){
                battle.xbmfWinners.add(candidate);
                count++;
            }
            nonce++;
        }
    }

    function _pickGemWinners(uint256 battleId, uint256 count, uint256 nonce, uint256 seed) internal {
        while (count < battles[battleId].numGemPrizes){
            address winner = battles[battleId].tickets[randomizer.randomMod(seed, nonce, battles[battleId].tickets.length)];
            ingameItems.addGemToPlayer(battleId, winner);
            battles[battleId].gemWinners.add(winner);
            //battles[battleId].winsByPlayer[winner]["gem"]++;
            count++;
            nonce++;
        }
    }

    function _pickTotemWinners(uint256 battleId, uint256 count, uint256 nonce, uint256 seed) internal {
        while (count < battles[battleId].numTotemPrizes){
            address winner = battles[battleId].tickets[randomizer.randomMod(seed, nonce, battles[battleId].tickets.length)];
            ingameItems.addTotemToPlayer(battleId, winner);
            battles[battleId].totemWinners.add(winner);
            //battles[battleId].winsByPlayer[winner]["totem"]++;
            count++;
            nonce++;
        }
    }

    function _pickGhostWinners(uint256 battleId, uint256 count, uint256 nonce, uint256 seed) internal {
        while (count < battles[battleId].numGhostPrizes){
            address winner = battles[battleId].tickets[randomizer.randomMod(seed, nonce, battles[battleId].tickets.length)];
            ingameItems.addGhostToPlayer(battleId, winner);
            battles[battleId].ghostWinners.add(winner);
            //battles[battleId].winsByPlayer[winner]["ghost"]++;
            count++;
            nonce++;
        }
    }

    function getStakedPiratesForPlayer(uint256 battleId, address playerAddress) view public returns(uint256[] memory) {
        EnumerableSet.UintSet storage pirates = battles[battleId].piratesByPlayer[playerAddress];
        uint256[] memory arr = new uint256[](pirates.length());
        for (uint256 i = 0; i < pirates.length(); i++){
            arr[i] = pirates.at(i);
        }
        return arr;
    }

    function getAllStakedPiratesForBattle(uint256 battleId) view public returns(uint256[] memory) {
        EnumerableSet.AddressSet storage players = battles[battleId].players;
        uint256[] memory arr = new uint256[](battles[battleId].stakedPiratesCount);
        uint256 count = 0;
        for (uint256 i = 0; i < players.length(); i++){
            EnumerableSet.UintSet storage pirates = battles[battleId].piratesByPlayer[players.at(i)];
            for (uint256 j = 0; j < pirates.length(); j++){
                arr[count] = pirates.at(j);
                count++;
            }
        }
        return arr;
    }
    
    // Withdraw

    function withdraw() public payable onlyOwner {
        uint256 bal = address(this).balance;
        require(payable(msg.sender).send(bal));
    }

    function withdrawPaymentToken() public payable onlyOwner {
        uint256 bal = paymentToken.balanceOf(address(this));
        paymentToken.transfer(msg.sender, bal);
    }

}