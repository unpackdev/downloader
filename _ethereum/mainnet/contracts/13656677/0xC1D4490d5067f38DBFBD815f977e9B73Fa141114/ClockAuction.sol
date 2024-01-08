// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./TradeableERC721Token.sol";

/**
 * @title ClockAuction
 * ClockAuction - a contract for my non-fungible creatures.
 */
contract ClockAuction is ERC721Tradable{
    uint256 public constant maxSupply = 6400;
    uint256 public constant MAX_PREMINT = 64;
    uint256 public constant maxPerAddr = 16;

    uint256 public minPrice = 40000000000000000;
    uint256 public maxPrice = 129000000000000000;

    uint256 public premintCount;
    uint256 public maxPresaleSupply = 2000;
    uint256 public maxPerPresale = 2;
    uint256 public maxPerTxn = 8;

    uint256 public auctionEnds;
    uint256 public reclaimEnds;

    address private constant _adminSigner = 0x7F668e4597B6DA8256C67AB80100b2474266735F;
    address payable public treasury = payable(0x90BB2FBC33600277C5184816D32230d6279daF28);
    address payable public technician = payable(0xeCA7676e3D770B8EFe6BB66f8AbC920Da23A621c);

    bool public yeeYee;
    bool public auctionLive;
    bool public reclaimLive;
    bool public uriFrozen;
    bool public saleNumFrozen;
    bool public limitFrozen;

    struct Bid {
        uint256 numTokens;  // number of desired tokens
        uint256 totalBid;  // total bid price
        bool won;
        bool claimed;  // indicator if the user has claimed against their bid
    }
    mapping(address => Bid) public bids;
    mapping(address => uint256) private addrMintCount;
    mapping(bytes32 => bool) public signatureUsed;

    event Bidder(address user);
    event SaleMode(bool publicOn);
    event SupplyCount(uint256 supplyCount);

    string private metadataURL = "https://sejb7xxndg.execute-api.us-west-1.amazonaws.com/api/metadata/";
    constructor(address _proxyRegistryAddress) ERC721Tradable("enclock", "CLCK", _proxyRegistryAddress) { }

    /**
    * @dev Override the baseTokenURI to return the metadata
    */
    function baseTokenURI() override public view returns (string memory) {
        return metadataURL;
    }

    /**
     * @dev Set new base URL to return the metadata
     * @param _metadataURL str of the new metadataURL
     * @param _freeze boolean whether or not to freeze the baseTokenURI
     */
    function setBaseTokenURI(string calldata _metadataURL, bool _freeze) external onlyOwner {
        require(!uriFrozen, "Metadata URL frozen");
        metadataURL = _metadataURL;
        uriFrozen = _freeze;
    }

    // auction functions
    /**
     * @dev Submit bid
     * @param _numTokens uint256 number of tokens to bid on
     */
    function submitBid(uint256 _numTokens) payable external {
        require(auctionLive, "Not live yet");
        require(block.timestamp <= auctionEnds, "Auction ended");
        require(_numTokens <= maxPerTxn, "Exceeds limit");
        require(0 < _numTokens, "Min. 1 token");

        Bid storage userBid = bids[msg.sender];
        uint256 newTotal = userBid.totalBid + msg.value;
        require(minPrice <= (newTotal / _numTokens), "Below min. bid");
        require((newTotal / _numTokens) <= maxPrice, "Exceeds max bid");
        if (userBid.numTokens == 0){
            emit Bidder(msg.sender);
        }
        userBid.totalBid = newTotal;
        userBid.numTokens = _numTokens;
    }

    /**
     * @dev Assign winners
     * @param _winners address[] winning addresses
     */
    function assignWinners(address[] calldata _winners) external onlyOwner {
        for (uint256 i = 0; i < _winners.length; i++){
            bids[_winners[i]].won = true;
        }
    }

    /**
     * @dev Winners claim their tokens
     */
    function claimTokens() external {
        Bid storage bid = bids[msg.sender];
        require(bid.won, "Not a winner");
        require(!bid.claimed, "Already claimed");
        bid.claimed = true;
        uint256 ts = totalSupply();
        for (uint256 i = 0; i < bid.numTokens; i++){
            _safeMint(msg.sender, ts++);
        }
    }

    /**
     * @dev Reclaim losing bids
     */
    function reclaim() external {
        Bid storage bid = bids[msg.sender];
        require(reclaimLive, "Cannot reclaim yet");
        require(!bid.won, "Winners cannot reclaim");
        require(!bid.claimed, "Already claimed");
        bid.claimed = true;
        payable(msg.sender).transfer(bid.totalBid);
    }


    // minting functions
    /**
     * @dev Creator's preminting function
     * @param _to address of where the premint will go
     */
    function creatorMint(address _to, uint256 amount) external onlyOwner {
        premintCount += amount;
        require(premintCount <= MAX_PREMINT, "No premints left");
        uint256 ts = totalSupply();
        for (uint256 i = 0; i < amount; i++){
            _safeMint(_to, ts++);
        }
    }

    /**
     * @dev whitelist minting
     * @param amount number of tokens to mint
     * @param _hash bytes32 message hash from a signed message
     * @param _r bytes32 from a signed message (first 32 bytes of signature)
     * @param _s bytes32 from a signed message (second 32 bytes of a signature)
     * @param _v uint8 from a signed message (final bytes of signature)
     */
    function whitelistMint(uint256 amount, bytes32 _hash, bytes32 _r, bytes32 _s, uint8 _v) payable external {
        require(0 < amount, "Cannot mint 0");
        require(minPrice * amount <= msg.value, "Not enough ether");
        require(amount <= maxPerPresale, "Minting beyond wallet limit");

        address signer = ecrecover(_hash, _v, _r, _s);
        require(signer == _adminSigner, "Forged signature");
        require(!signatureUsed[_hash], "Signature already used");
        signatureUsed[_hash] = true;

        uint256 ts = totalSupply();
        require(ts + amount <= maxPresaleSupply, "Beyond presale limit");
        for (uint256 i = 0; i < amount; i++){
            _safeMint(msg.sender, ts++);
        }
        emit SupplyCount(totalSupply());
    }
    
    /**
     * @dev YEEYUH
     * must be live
     * cannot exceed txn limits
     * must be within wallet allowance
     * must not exceed max maxSupply
     * @param amount uint256 number of clocks to mint
     */
    function yeeYeeMint(uint256 amount) payable external {
        require(yeeYee, "Not active yet");
        require(amount <= maxPerTxn, "Exceeds limit");
        require(minPrice * amount <= msg.value, "Not enough ether");
        require(addrMintCount[msg.sender] + amount <= maxPerAddr, "Minting beyond wallet limit");
        uint256 ts = totalSupply();
        require(ts + amount <= maxSupply, "Not enough left to mint");
        addrMintCount[msg.sender] += amount;
        for (uint256 i = 0; i < amount; i++){
            _safeMint(msg.sender, ts++);
        }
        emit SupplyCount(totalSupply());
    }


    // --------------------
    // phase toggling:
    // --------------------
    /**
     * @dev public launch
     */
    function setPublicLive() external onlyOwner {
        yeeYee = true;
        emit SaleMode(yeeYee);
    }

    /**
     * @dev Auction launch
     * @param _auctionEnds uint256 timestamp (seconds) of when the auction ends
     */
    function setAuctionLive(uint256 _auctionEnds) external onlyOwner {
        auctionLive = true;
        auctionEnds = _auctionEnds;
    }

    /**
     * @dev Enable reclaim
     * @param _reclaimEnds uint256 timestamp (seconds) of when reclaim is over
     * @param _reclaimLive bool whether or not reclaim is live
     */
    function setReclaimLive(uint256 _reclaimEnds, bool _reclaimLive) external onlyOwner {
        reclaimEnds = _reclaimEnds;
        reclaimLive = _reclaimLive;
    }


    // --------------------
    // sale configuration:
    // --------------------
    /**
     * @dev Set sale numbers
     * @param _minPrice uint256 the minimum price for whitelist, FCFS, or auction
     * @param _maxPrice uint256 the maximumm price for auctions
     * @param _freeze bool whether or not these numbers are changeable afterwards
     */
    function setSaleNumbers(uint256 _minPrice, uint256 _maxPrice, bool _freeze) external onlyOwner {
        require(!saleNumFrozen, "Numbers Frozen");
        minPrice = _minPrice;
        maxPrice = _maxPrice;
        saleNumFrozen = _freeze;
    }

    /**
     * @dev Set limits for minting
     * @param _maxPerPresale uint256 maximum amount of tokens for presale per address
     * @param _maxPerTxn uint256 maximum amount of tokens for FCFS / auction bids
     * @param _maxPresaleSupply uint256 global maximum amount of presale tokens
     * @param _freeze bool whether or not these numbers are changeable afterwards
     */
    function setLimits(uint256 _maxPerPresale, uint256 _maxPerTxn, uint256 _maxPresaleSupply, bool _freeze) external onlyOwner {
        require(!limitFrozen, "Numbers Frozen");
        maxPerPresale = _maxPerPresale;
        maxPerTxn = _maxPerTxn;
        maxPresaleSupply = _maxPresaleSupply;
        limitFrozen = _freeze;
    }


    // --------------------
    // treasury stuff:
    // --------------------
    /**
     * @dev Set the treasury address for withdrawing proceeds
     * @param _treasury address, the treasury
     * @param _technician address, the technician's addrress
     */
    function setWithdrawAddresses(address payable _treasury, address payable _technician) external onlyOwner {
        treasury = _treasury;
        technician = _technician;
    }

    /**
     * @dev Withdraw to the treasury and technician
     */
    function withdraw() external onlyOwner{
        require(reclaimLive, "Reclaim must be enabled");
        require(reclaimEnds <= block.timestamp, "Cannot withdraw before reclaim period");
        require(technician != address(0x0), "technician cannot be 0x0");
        require(treasury != address(0x0), "treasury cannot be 0x0");
        technician.transfer(address(this).balance / 4);
        treasury.transfer(address(this).balance);
    }
}