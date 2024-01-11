//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./HOPS.sol";

/*
 * cyberroos.com 
 * @cyber_roos (Twitter)
 * Founder: @vaccarodoteth (Twitter)
 * Contract Author: @blockdaddyy (Twitter)
 * Devs: atreides.eth (front-end), yachovcohen.eth (discord)
 */

contract CyberRoos is ERC721A, Ownable, ReentrancyGuard {

    uint256 public gamifiedCap = 600;
    uint256 public saleCap = 500;

    uint256 public hopsCostToBox = 5000 ether; // Price to Box For a Roo (in $HOPS)

    uint256 public saleState; // 0 = Sale inactive, 1 = BOXING active, 2 = WL sale, 3 = WL + public sale , 4+ future proof

    uint256 public whitelistPrice = 0.059 ether; 
    uint256 public publicPrice = 0.069 ether;

    uint256 public maxPerWLWallet = 5;

    bytes32 public whitelistMerkleRoot;
    mapping(address => uint256) public whitelistMinterClaimAmount;

    // a mapping of game contracts
    mapping(address => bool) public gameContracts;
    uint256 public costToLock = 100000000 ether;  // Price to transfer-lock your token (in $HOPS).

    string public baseURI;
    string public baseExtension;

    uint256 constant SECONDS_PER_DAY                 = 1 days;
    uint256 constant EMMISSION_HALT_TIME             = 1742050800; // 1,000 days from launch. (03/15/2025 : 11:00am ET)

    mapping(uint256 => Roo) public roos;

    struct Roo { // 256-bit struct
        bool lockedInGame;
        uint16 baseHopsPerDay;                          // MaxVal = 65,535 note: mult ether
        uint40 carryOver;                               // unclaimed hops from last owner
        uint96 lastTransferTimestamp;                   // stored in seconds, no chance of overflow
        uint96 lastClaimTimestamp;                      // stored in seconds, no chance of overflow
    }

    // Team allocation
    address public teamAllocationWallet = 0x55f87FaDe4A4a80BDCBccF0253484c8089C990cd;
    address public artist =  0x77e04a00c36874aE346A5bEA2462CF4fBB45D0d1;
    address public discordDev = 0x07c47A72c65ce8A37622Ea8B15765dAD60163120;
    address public dev = 0x4E9f7618F72F3d497f4e252eBB6a731d715e7af5; // B7
    address public frontEndDev = 0xb9111c3c38E0fc07a3c163B1F09f1a8954234f29;
    address public honoraryTeamMember = teamAllocationWallet; // default to a safe addy

    HOPS public hops;

    event SaleStateChanged(uint256 _saleState);
    event HopsClaimed(address recipient, uint256 tokenId, uint256 amount);
    event RooBoxed(bool succesful, address attacker, address winner, uint256 forTokenId);

    constructor(address _hopsAddr) ERC721A("Cyber Roos", "CYBERROOS") {
        hops = HOPS(_hopsAddr); 
        uint96 _currentTime = uint96(block.timestamp);
        baseURI = "https://www.cyberroos.com/api/"; // hosted on ipfs
        // TEAMMEMBER ROOS (NON-TRADABLE & REVOCABLE)
        _mint(teamAllocationWallet, 1);
        _mint(artist, 1);
        _mint(discordDev, 1);
        _mint(dev, 1);
        _mint(frontEndDev, 1);
        _mint(address(this), 7); // decrease batch size to save on gas down the road
        _mint(address(this), 8);
        // ROOS FOR RAFFLES AND PRIZES
        _mint(teamAllocationWallet, 8); // decrease batch size to save on gas down the road
        _mint(teamAllocationWallet, 8);
        _mint(teamAllocationWallet, 7);
        _mint(dev, 7);
        for(uint i = 0; i < 50; i++) { 
            roos[i] = Roo({
                lockedInGame: false,
                baseHopsPerDay: uint16(150),
                carryOver: uint40(150),
                lastTransferTimestamp: _currentTime,
                lastClaimTimestamp: _currentTime
            });
        }
    }

    // MINT NFT's

    function whitelistMint(uint256 _amount, bytes32[] calldata _merkleProof) external payable {
        uint256 _totalMinted = _totalMinted();
        require(_totalMinted + _amount <= saleCap, "Soldout");
        require(whitelistMinterClaimAmount[_msgSender()] + _amount <= maxPerWLWallet, "Exceeds allotment");
        require(saleState > 1, "WL Sale not active");
        require(_amount > 0, "Invalid amount");
        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot ,keccak256(abi.encodePacked(msg.sender))), "Invalid Merkle proof supplied for address");
        require(msg.value == whitelistPrice * _amount, "Invalid price for WL");
        whitelistMinterClaimAmount[_msgSender()] += _amount;
        uint256 _hopsOwed = ((155 - (_totalMinted/9)) * 1 ether) * _amount;
        hops.mint(_msgSender(), _hopsOwed);
        _mint(_msgSender(), _amount);
        uint96 _currentTime = uint96(block.timestamp);
        for(uint i; i < _amount; i++) { 
            roos[_totalMinted + i] = Roo({
                lockedInGame: false,
                baseHopsPerDay: uint16((155 - ((_totalMinted+i)/9))), // 150 for earliest id's, progressing to 100 for later id's
                carryOver: uint40(0),
                lastTransferTimestamp: _currentTime,
                lastClaimTimestamp: _currentTime
            });
        }
    }

    // 5 per tx
    function publicMint(uint256 _amount) external payable {
        uint256 _totalMinted = _totalMinted();
        require(_totalMinted + _amount <= saleCap, "Soldout");
        require(saleState > 2, "Public Sale not active");
        require(_amount > 0 && _amount < 6, "Invalid amount");
        require(msg.value == publicPrice * _amount, "Invalid price for public");
        uint256 _hopsOwed = ((155 - (_totalMinted/9)) * 1 ether) * _amount;
        hops.mint(_msgSender(), _hopsOwed);
        _mint(_msgSender(), _amount);
        uint96 _currentTime = uint96(block.timestamp);
        for(uint i; i < _amount; i++) { 
            roos[_totalMinted + i] = Roo({
                lockedInGame: false,
                baseHopsPerDay: uint16((155 - ((_totalMinted+i)/9))), // 150 for earliest id's, progressing to 100 for later id's
                carryOver: uint40(0),
                lastTransferTimestamp: _currentTime,
                lastClaimTimestamp: _currentTime
            });
        }
    }

    uint256 bounds = 1000; // exclusive

    function boxForRoo(uint256 _attack) external returns(uint256) {
        uint256 _totalMinted = _totalMinted();
        require(_totalMinted < gamifiedCap, "Roo Cap reached");
        require(balanceOf(_msgSender()) > 0, "You dont have a Roo");
        require(saleState == 1 , "Box for Roo inactive");

        uint256 _hopsCostToBox = hopsCostToBox;
        require(hops.balanceOf(_msgSender()) >= _hopsCostToBox, "Not enough HOPS");
        hops.burn(_msgSender(), _hopsCostToBox);
        
        uint256 _outcome = getRandom((_attack + _totalMinted), bounds);
        uint96 _currentTime = uint96(block.timestamp);
        if(_outcome < _totalMinted) {
            address _ownerOfOutcome = ownerOf(_outcome);
            _mint(_ownerOfOutcome, 1);
            roos[_totalMinted] = Roo({
                lockedInGame: false,
                baseHopsPerDay: uint16(100),
                carryOver: uint40(0),
                lastTransferTimestamp: _currentTime,
                lastClaimTimestamp: _currentTime
            });
            emit RooBoxed(false, _msgSender(), _ownerOfOutcome, _totalMinted);
            return 6;
        }
        _mint(_msgSender(), 1);
        roos[_totalMinted] = Roo({
                lockedInGame: false,
                baseHopsPerDay: uint16(100),
                carryOver: uint40(0),
                lastTransferTimestamp: _currentTime,
                lastClaimTimestamp: _currentTime
            });
        emit RooBoxed(true, _msgSender(), _msgSender(), _totalMinted);
        return 7;
    }

    function adminMint(address _to, uint256 _amount, uint16 _baseHops) external onlyOwner {
        uint256 _totalMinted = _totalMinted();
        require(_totalMinted + _amount <= gamifiedCap, "No more");
        require(_amount > 0 && _amount < 6, "Invalid amount");
        require(_baseHops < 151, "150 is the max base");
        _mint(_to, _amount);
        uint96 _currentTime = uint96(block.timestamp);
        for(uint i; i < _amount; i++) { 
            roos[_totalMinted + i] = Roo({
                lockedInGame: false,
                baseHopsPerDay: _baseHops, // 150 for earliest id's, progressing to 100 for later id's
                carryOver: uint40(0),
                lastTransferTimestamp: _currentTime,
                lastClaimTimestamp: _currentTime
            });
        }
    }

    // Futureproofing

    function gamifiedMint(address _to) external {
        uint256 _totalMinted = _totalMinted();
        require(_totalMinted < gamifiedCap, "Roo Cap reached");
        require(saleState == 4, "Not Ready");
        require(gameContracts[_msgSender()], "Cyber Roo Official Contracts Only");
        _mint(_to, 1);
    }

    function lockToGame(uint256[] calldata _tokenIds) external {
        uint256 _costToLock = costToLock;
        require(_tokenIds.length > 0, "You cannot pass an empty array");
        require(saleState == 0);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(ownerOf(_tokenIds[i]) == _msgSender(), "NOT YOUR ROO(S)");
            roos[_tokenIds[i]].lockedInGame = true;
        }
        if(_costToLock > 0) {
            require(hops.balanceOf(_msgSender()) >= costToLock, "You do not have enough HOPS to play");
            hops.burn(_msgSender(), costToLock);
        }
    }

    function unlockFromGame(uint256[] calldata _tokenIds) external {
        require(saleState == 0);
        require(gameContracts[_msgSender()], "Cyber Roos Official Contracts Only");
        require(_tokenIds.length > 0, "You cannot pass an empty array");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            roos[_tokenIds[i]].lockedInGame = false;
        }
    }

    // COLLECT HOPS

    function collectHopsFromMany(uint256[] calldata _tokenIds) external {
        require(tx.origin == _msgSender(), "EOA Only");
        uint256 totalAvailable;
        require(_tokenIds.length > 0, "You cannot pass an empty array");
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(ownerOf(_tokenIds[i]) == _msgSender(), "NOT YOUR ROO(S)");
            uint256 available = hopsAvailable(_tokenIds[i]);
            Roo storage roo = roos[_tokenIds[i]];
            roo.lastClaimTimestamp = uint96(block.timestamp);
            roo.carryOver = uint40(0);
            emit HopsClaimed(_msgSender(), _tokenIds[i], available);
            totalAvailable += available;
        }
        require(totalAvailable > 0, "NO HOPS AVAILABLE");
        hops.mint(_msgSender(), totalAvailable); // trusted
    }

    function hopsAvailable(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        Roo memory roo = roos[tokenId];
        uint256 _currentTimestamp = block.timestamp;
        uint256 _yieldMultiplier = ((_currentTimestamp - uint256(roo.lastTransferTimestamp)) / SECONDS_PER_DAY) + 100;
        if(_yieldMultiplier > 200) _yieldMultiplier = 200;
        
        if (_currentTimestamp > EMMISSION_HALT_TIME) // if its past the emission halt time
        _currentTimestamp = EMMISSION_HALT_TIME; // stop the yield at halt time
        uint256 _lastClaimTimestamp = uint256(roo.lastClaimTimestamp);
        if (_lastClaimTimestamp > _currentTimestamp) return 0; // emmissions have halted

        uint256 _yieldPerSecond = (uint256(roo.baseHopsPerDay) * _yieldMultiplier * 1 ether) / (100 * SECONDS_PER_DAY);
        uint256 _elapsedSeconds = _currentTimestamp - _lastClaimTimestamp;
        return (_yieldPerSecond * _elapsedSeconds) + (uint256(roo.carryOver) * 1 ether);
    }

    /**
    * the amount of HOPS currently available to claim in a set of roos
    * @param _tokenIds the tokens to check HOPS for
    */
    function hopsAvailableInMany(uint256[] calldata _tokenIds) external view returns (uint256) {
        uint256 available;
        uint256 totalAvailable;
        require(_tokenIds.length > 0, "You cannot pass an empty array");
        for (uint i = 0; i < _tokenIds.length; i++) {
        available = hopsAvailable(_tokenIds[i]);
        totalAvailable += available;
        }
        return totalAvailable;
    }

    // HONORARY TEAM MEMBER MUST BE INTERVIEWABLE VIA SPACES
    function chooseHonoraryTeamMember() external onlyOwner returns(address) {
        uint256 _winningToken = _chooseTokenWeightedSequentially();
        require(_winningToken > 49, "THIS TOKEN IS INELIGIBLE.");
        address _winner = ownerOf(_chooseTokenWeightedSequentially());
        honoraryTeamMember = _winner;
        return _winner; // CONGRATS!
    }

    function _chooseTokenWeightedSequentially() internal view returns(uint256) {
        uint256 _winningToken;
        uint256 _totalMinted = _totalMinted();
        uint256 rand1 = getRandom(_totalMinted, _totalMinted);
        uint256 rand2 = getRandom(rand1, _totalMinted);
        unchecked {
            if(rand1 > rand2) {
                _winningToken = rand1 - rand2;
            } else {
                _winningToken = rand2 - rand1;
            }
        }
        return _winningToken;
    }

    // HELPER

    /*
     * @dev _upperbounds is exclusive
     */
    function getRandom(uint256 _seed, uint256 _upperBound) public view returns(uint256) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        _seed))) % _upperBound;
    }

    // SETTER

    function setSaleState(uint256 _intended) external onlyOwner {
        require(saleState != _intended, "This is already the value");
        saleState = _intended;
        emit SaleStateChanged(_intended);
    }

    /**
     * @notice include trailing /
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setBaseExtension(string calldata _baseExtension) external onlyOwner {
        baseExtension = _baseExtension;
    }

    function setWLPrice(uint256 _newWLPrice) external onlyOwner {
        whitelistPrice = _newWLPrice;
    }

    function setPublicPrice(uint256 _newPublicPrice) external onlyOwner {
        publicPrice = _newPublicPrice;
    }

    function setSaleCap(uint256 _newSaleCap) external onlyOwner {
        saleCap = _newSaleCap;
    }

    function setGamifiedCap(uint256 _newGamifiedCap) external onlyOwner {
        gamifiedCap = _newGamifiedCap;
    }

    function setBounds(uint256 _bounds) external onlyOwner {
        bounds = _bounds;
    }

    /**
     * enables a game contract (Cyber Roos official contracts only)
     */
    function addGame(address _game) external onlyOwner {
        gameContracts[_game] = true;
    }

    function removeGame(address _game) external onlyOwner {
        gameContracts[_game] = false;
    }

    function setWhitelistMerkleRoot(bytes32 _newWhitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _newWhitelistMerkleRoot;
    }

    /**
     * @notice ERC20 Migration mechanism
     */
    function setHopsAddr(address _hopsAddr) external onlyOwner {
        hops = HOPS(_hopsAddr);
    }



    // GETTERS

    function getHopsCostToBox() external view returns(uint256) {
        return hopsCostToBox;
    }

    function getBaseHopsPerRoo(uint256 _tokenId) external view returns(uint256) {
        return uint256(roos[_tokenId].baseHopsPerDay);
    }

    // min = 100, max = 200
    function getHopsBonusOfRoo(uint256 _tokenId) external view returns(uint256) {
        Roo memory roo = roos[_tokenId];
        uint256 _yieldMultiplier = ((block.timestamp - uint256(roo.lastTransferTimestamp)) / SECONDS_PER_DAY) + 100;
        if(_yieldMultiplier > 200) _yieldMultiplier = 200;
        return _yieldMultiplier;
    }

    function getHopsPerDayOfRoo(uint256 _tokenId) external view returns(uint256) {
        Roo memory roo = roos[_tokenId];
        uint256 _hopsMultiplier = ((block.timestamp - uint256(roo.lastTransferTimestamp)) / SECONDS_PER_DAY) + 100;
        if(_hopsMultiplier > 200) _hopsMultiplier = 200;
        uint256 _baseHopsPerDay = uint256(roo.baseHopsPerDay);
        return _baseHopsPerDay * _hopsMultiplier;
    }

    // OVERRIDES

    /**
     * @notice token URI
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(baseURI, _toString(_tokenId), baseExtension));
    }

    function _prepareNormalTransfer(uint256 tokenId) internal {
        require(tokenId > 19, "Team allocation Roos can't be transferred");
        Roo storage roo = roos[tokenId];
        require(!roo.lockedInGame, "This Roo is locked in the game");
        uint96 _currentTime = uint96(block.timestamp);
        require(roo.lastClaimTimestamp < _currentTime, "Cannot claim immediately before a transfer");
        roo.carryOver = uint40(hopsAvailable(tokenId) / 1 ether);
        roo.lastClaimTimestamp = _currentTime;
        roo.lastTransferTimestamp = _currentTime;
    }

    /** 
    Override to make sure that transfers can't be frontrun and rewards are accurate
    */
    function transferFrom(address from, address to, uint256 tokenId) public override nonReentrant {
        _prepareNormalTransfer(tokenId);
        super.transferFrom(from, to, tokenId);
    }

    /** 
    Override to make sure that transfers can't be frontrun and rewards are accurate
    */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override nonReentrant {
        _prepareNormalTransfer(tokenId);
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function transferTeamMemberRoo(address _transferTo, uint256 _tokenId) external onlyOwner {
        require(_tokenId < 20, "We can only move team member roos. Purpose: to better align incentives.");
        _transferTeamMemberRoo(ownerOf(_tokenId), _transferTo, _tokenId);
    }

    function sendEth(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to send ether");
    }

    function emergencyWithdraw(address _to) external onlyOwner { // admin trusted by team
        sendEth(_to, address(this).balance);
    }

    function withdrawToTeam() external onlyOwner {
        uint256 balance = address(this).balance;
        sendEth(teamAllocationWallet, balance * 63 / 100);
        sendEth(dev, balance * 18 / 100);
        sendEth(discordDev, balance * 2 / 100);
        sendEth(frontEndDev, balance * 5 / 100);
        sendEth(artist, balance * 8 / 100);
        sendEth(honoraryTeamMember, balance * 4 / 100);
    }
}