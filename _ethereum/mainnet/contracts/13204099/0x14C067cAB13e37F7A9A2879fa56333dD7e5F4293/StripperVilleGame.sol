// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./Administration.sol";
import "./StripperVille.sol";
import "./Strip.sol";
import "./Assets.sol";

contract StripperVilleGame is Administration {
    
    event Claim(address indexed caller, uint tokenId, uint qty);
    event Work(uint tokenId, uint gameId);
    event BuyWorker(address indexed to, uint gameId, bool isThief);
    event WorkerAction(address indexed owner, uint gameId);
    event BuyWearable(uint stripper, uint wearable);
    
    mapping(uint => mapping (uint => uint)) private _poolStripClub;
    mapping(uint => mapping (uint => uint)) private _poolClubEarn;
    mapping(uint => mapping (uint => uint)) public poolClubPercentage;
    mapping(uint => mapping (uint => uint)) private _poolClubStrippersCount;
    mapping(uint => uint) public stripperWearable;
    mapping(uint => Worker[]) private _poolThieves;
    mapping(uint => Worker[]) private _poolCustomers;
    mapping(address => uint) private _addressWithdraw;

    Wearable[] public wearables;
    Strip public COIN;
    StripperVille public NFT;
    Game[] public games;
    uint public weeklyPrize = 250000 ether;
    uint public gamePrize = 250000 ether;
    uint public thiefPrice = 100 ether;
    uint public customerPrice = 100 ether;
    uint constant WEEK = 604800;
    
    modifier ownerOf(uint tokenId) {
        require(NFT.ownerOf(tokenId) == _msgSender(), "OWNERSHIP: Sender is not onwer");
        _;
    }
    
    modifier gameOn(uint gameId){
        require(games[gameId].paused == false && games[gameId].endDate == 0, "GAME FINISHED");
        _;
    }
    
    struct Worker {
        address owner;
        uint tokenId;
    }
    
    struct Game {
        uint prize;
        uint startDate;
        uint endDate;
        uint price;
        uint maxThieves;
        uint maxCustomers;
        uint customerMultiplier;
        bool paused;
    }
    
    struct Wearable {
        string name;
        uint price;
        uint increase;
        bool canBuy;
    }
    
    constructor(){
        wearables.push(Wearable('', 0, 0, false));
    }
    
    function giveawayWorker(uint gameId, address to, bool thief) external onlyAdmin gameOn(gameId) {
        _worker(gameId, to, thief);
    }
    
    function buyWorker(uint gameId, bool thief) external gameOn(gameId) {
        if(thief){
            require(COIN.balanceOf(_msgSender()) >= thiefPrice, "BALANCE: insuficient funds");
        } else {
             require(COIN.balanceOf(_msgSender()) >= customerPrice, "BALANCE: insuficient funds");
        }
        _worker(gameId, _msgSender(), thief);
    }
    
    function _worker(uint gameId, address to, bool thief) internal {
        (, uint index) = _getWorker(gameId,to,thief);
        require(index == 9999, "already had this worker type for this game");
        if(thief){
            require(_poolThieves[gameId].length < games[gameId].maxThieves, "MAX THIEVES REACHED");
            _poolThieves[gameId].push(Worker(to, 0));
        } else {
            require(_poolCustomers[gameId].length < games[gameId].maxCustomers, "MAX CUSTOMERS REACHED");
            _poolCustomers[gameId].push(Worker(to, 0));
        }
        emit BuyWorker(to,gameId, thief);
    }
    
    function putThief(uint gameId, uint clubId) external {
        _workerAction(gameId, clubId, true);
    }
    
    function putCustomer(uint gameId, uint stripperId) external {
        _workerAction(gameId,  stripperId, false);
    }
    
    function _workerAction(uint gameId, uint tokenId, bool thief) internal gameOn(gameId) {
        require((thief && tokenId >= 1000000) || (!thief && tokenId < 1000000), "Incompatible");
        (, uint index) = thief ?  getMyThief(gameId) : getMyCustomer(gameId);
        require(index != 9999, "NOT OWNER");
        if(thief){
            _poolThieves[gameId][index].tokenId = tokenId;
        } else {
            _poolCustomers[gameId][index].tokenId = tokenId;
        }
        emit WorkerAction(_msgSender(), gameId);
    }
    
    function getMyThief(uint gameId) public view returns (Worker memory,uint) {
        return _getWorker(gameId, _msgSender(), true);
    }
    
    function getMyCustomer(uint gameId) public view returns (Worker memory,uint) {
        return _getWorker(gameId, _msgSender(), false);
    }
    
    function _getWorker(uint gameId, address owner, bool thief) internal view returns (Worker memory,uint) {
        Worker memory worker;
        uint index = 9999;
        Worker[] memory workers = thief ? _poolThieves[gameId] : _poolCustomers[gameId];
        for(uint i=0; i< workers.length; i++){
            if(workers[i].owner == owner){
                worker = workers[i];
                index = i;
                break;
            }
        }
        return (worker, index);
    }
    
    function _getThievesByClubId(uint gameId, uint clubId) private view returns (uint) {
        Worker[] memory workers = _poolThieves[gameId];
        uint total = 0;
        for(uint i=0; i< workers.length; i++){
            if(workers[i].tokenId == clubId){
                total++;
            }
        }
        return total;
    }
    
    function wearablesCount() public view returns (uint){
        return wearables.length;
    }
    
    function addWearable(string calldata name, uint price, uint increase, bool canBuy) external onlyAdmin {
        wearables.push(Wearable(name, price, increase, canBuy));
    }
    
    function updateWearable(uint index, bool canBuy) external onlyAdmin {
        wearables[index].canBuy = canBuy;
    }
    
    function buyWearable(uint stripperId, uint wearableId) external ownerOf(stripperId) {
        Wearable memory wearable = wearables[wearableId];
        require(stripperId < 1000000, "wearable is just for strippers");
        require(COIN.balanceOf(_msgSender()) >= wearable.price, "BALANCE: insuficient funds");
        require(wearable.canBuy, "WEARABLE: cannot buy this");
        if(wearable.price > 0) {
            COIN.burnTokens(wearable.price);
        }
        stripperWearable[stripperId] = wearableId;
        emit BuyWearable(stripperId, wearableId);
    }
    
    function setGamePrize(uint newPrize) public onlyAdmin {
        gamePrize = newPrize;
    }
    
    function setWeeklyPrize(uint newPrize) public onlyAdmin {
        weeklyPrize = newPrize;
    }
    
    function setCustomerThiefPrices(uint customer, uint thief) external onlyAdmin {
        thiefPrice = thief;
        customerPrice = customer;
    }
    
    function createGame(uint price, uint maxThieves, uint maxCustomers, uint customersMultiply) external onlyAdmin {
        games.push(Game(gamePrize, block.timestamp, 0, price, maxThieves, maxCustomers, customersMultiply, false));
    }
    
    function pauseGame(uint index) public onlyAdmin {
        games[index].paused = true;
    }
    
    function getActiveGame() public view returns (uint) {
        uint active;
        for(uint i=0; i< games.length; i++){
            Game memory game = games[i];
            if(game.endDate == 0 && !game.paused){
                active = i;
                break;
            }
        }
        return active;
    }
    
    function setStripAddress(address newAddress) public onlyAdmin {
        COIN = Strip(newAddress);
    }
    
    function setStripperVilleAddress(address newAddress) public onlyAdmin {
        NFT = StripperVille(newAddress);
    }
    
    function setContracts(address coin, address nft) public onlyAdmin {
        setStripAddress(coin);
        setStripperVilleAddress(nft);
    }
    
    function nftsBalance() external view returns (uint){
        StripperVille.Asset[] memory assets = NFT.getAssetsByOwner(_msgSender());
        uint balance = 0;
        uint withdrawals = 0;
        if(assets.length == 0){
            return balance;
        }
        for(uint i = 0; i < assets.length; i++){
            balance += assets[i].earn;
            withdrawals += assets[i].withdraw;
        }
        if(withdrawals > balance){
            return 0;
        }
        return balance - withdrawals;
    }
    
    function work(uint stripperId, uint clubId, uint gameId) public ownerOf(stripperId) {
        require(_poolStripClub[gameId][stripperId] < 100000, "GAME: already set for this game");
        require(clubId >= 1000000, "CLUB: token is not a club or is not active");
        (Assets.Asset memory stripper,) = NFT.getAssetByTokenId(stripperId);
        Game memory game = games[gameId];
        require(game.endDate == 0 && !game.paused, "GAME: closed or invalid");
        require(COIN.balanceOf(_msgSender()) >= game.price, "BALANCE: insuficient funds");
        if(game.price > 0) {
            COIN.burnTokens(game.price);
        }
        uint earn = stripper.earn;
        Worker[] memory workers = _poolCustomers[gameId];
        for(uint i=0; i< workers.length; i++){
            if(workers[i].tokenId == stripperId){
                earn = earn * game.customerMultiplier;
                break;
            }
        }
        _poolStripClub[gameId][stripperId] = clubId;
        _poolClubEarn[gameId][clubId] += earn; 
        _poolClubStrippersCount[gameId][clubId]++;
        emit Work(stripperId, gameId);
    }
    
    function getClubStrippersCount(uint gameId, uint clubId) public view returns (uint) {
        Game memory game = games[gameId];
        require(game.endDate > 0, "GAME: not closed");
        return  _poolClubStrippersCount[gameId][clubId];
    }
    
    function closeGame(uint index) public onlyAdmin {
        Game storage game = games[index];
        game.endDate = block.timestamp;
        uint[] memory clubIds = getClubIds();
        for(uint i=0; i < clubIds.length; i++){
            uint one = clubIds[i];
            uint position = 1;
            uint thievesOne = _getThievesByClubId(index, one);
            uint totalOne = thievesOne > 0 ? thievesOne > 9 ? 0 : (_poolClubEarn[index][one] / 10) * (10 - thievesOne) : _poolClubEarn[index][one];
            if(totalOne > 0){
                for(uint j=0; j < clubIds.length; j++){
                    uint two = clubIds[j];
                    if(one != two){
                        uint thievesTwo = _getThievesByClubId(index, two);
                        uint totalTwo = thievesTwo > 0 ? thievesTwo > 9 ? 0 : (_poolClubEarn[index][two] / 10) * (10 - thievesTwo) : _poolClubEarn[index][two];
                        if(totalOne < totalTwo){
                            position++;
                        }
                    }
                }
            } else {
                position = 6;
            }
            if(position < 6){
                uint earn = 5;
                if(position > 2){
                    earn = earn * (6 - position);
                } else if(position == 2){
                    earn = 30;
                } else {
                    earn = 40;
                }
                poolClubPercentage[index][one] = earn;
            }
        }
    }
    
    function getClubIds() public view  returns (uint[] memory){
        uint[] memory ids = new uint[](NFT.clubsCount());
        uint j=0;
        uint initial = 1000000;
        for(uint i=0;i<ids.length;i++){
            ids[j] = i + initial;
            j++;
        }
        return ids;
    }
    
    
    function getWeeklyEarnings(uint earn, uint born) public view returns (uint) {
         return getWeeks(born) * getEarn(earn);
    }
    
    function getWeeks(uint born) public view returns (uint) {
        return ((block.timestamp - born) / WEEK) + 1;
    }
    
    function getEarn(uint value) public view returns (uint) {
        if(value > 100 ether){
            value = 100 ether;
        }
        return ((weeklyPrize / NFT.stripperSupply()) / 100) * (value / 10 ** 18);
    }
    
    function getCustomerMultiply(uint gameId, uint stripperId) public view returns(uint){
        (Worker memory worker, uint index) = getMyCustomer(gameId);
        if(index != 9999 && worker.tokenId == stripperId && games[gameId].customerMultiplier > 1){
            return games[gameId].customerMultiplier;
        }
        return 1;
    }  
    
    function getClaimableTokens(uint tokenId) public view returns (uint) {
        (Assets.Asset memory asset,) = NFT.getAssetByTokenId(tokenId);
        uint earn=0;
        if(asset.tokenType == 0){
            uint  wearableEarn = 0;
            if(stripperWearable[tokenId] > 0){
                Wearable memory wearable = wearables[stripperWearable[tokenId]];
                wearableEarn += wearable.increase;
            }
            uint totalEarn = asset.earn + wearableEarn > 100 ether ? 100 ether : asset.earn + wearableEarn;
            for(uint i=0;i<games.length;i++){
                uint baseEarn = poolClubPercentage[i][_poolStripClub[i][tokenId]];
                uint gameEarn= 0;
                if(games[i].endDate > 0 && baseEarn > 0){
                    gameEarn += (gamePrize / baseEarn) - ((gamePrize / baseEarn) / 10);
                    earn += ((gameEarn / _poolClubStrippersCount[i][_poolStripClub[i][tokenId]] / 100) * (totalEarn / 10 ** 18) * getCustomerMultiply(i, tokenId));
                }
            }
            return earn + getWeeklyEarnings(totalEarn, asset.born) - asset.withdraw;
        } else {
            for(uint i=0;i<games.length;i++){
                uint baseEarn = poolClubPercentage[i][tokenId];
                if(games[i].endDate > 0 && baseEarn > 0){
                    earn += (gamePrize / baseEarn) / 10;
                }
            }
            return earn - asset.withdraw;
        }
    }
    
    function claimTokens(uint tokenId) public ownerOf(tokenId) {
        uint balance = getClaimableTokens(tokenId);
        COIN.approveHolderTokensToGame(balance);
        COIN.transferFrom(COIN.owner(), _msgSender(), balance);
        NFT.withdrawAsset(tokenId, balance);
        emit Claim(_msgSender(), tokenId, balance);
    }

}