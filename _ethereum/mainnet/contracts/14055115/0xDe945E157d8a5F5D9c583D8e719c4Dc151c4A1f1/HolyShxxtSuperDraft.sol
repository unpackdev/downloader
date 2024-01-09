// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./draft-EIP712.sol";

interface HolyShxxtLeague {
    function mint(address) external;
}

contract HolyShootSuperDraft is EIP712, Ownable {

    HolyShxxtLeague public constant holyShxxtLeague =
        HolyShxxtLeague(0xe93AAb5779e706c73DAf8Bf849bb8E46Fb183691);

    //for withdrawal
    address payable public constant holyShxxtWallet = payable(0x3606e8DDB3eacf871BaA5C5793534485e96ae498); 

    /**
        EIP712
     */
    bytes32 public constant GIVEAWAY_TYPEHASH =
        keccak256("SignGiveaway(address receiver,uint256 amount)");
    struct SignGiveaway {
        address receiver;
        uint256 amount;
    }

    bytes32 public constant ELITE_WHITELIST_TYPEHASH =
        keccak256("SignEliteWhitelist(address receiver,uint256 amount)");
    struct SignEliteWhitelist {
        address receiver;
        uint256 amount;
    }

    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("SignWhitelist(address receiver,uint256 amount)");
    struct SignWhitelist {
        address receiver;
        uint256 amount;
    }

    /**
        Max HolyShxxt supply
     */
     uint256 public constant MAX_SUPPLY = 8888;

    /**
        Pause mint
    */
    bool public mintPaused = false;

    /**
        Giveaways
     */
    // minted through giveaway
    uint256 public numGiveaways = 0;
    // max giveaways for marketing
    uint256 public constant maxGiveaways = 50;     
    mapping(address => uint256) public giveawaysOf;

    /**
        Whitelists
     */
    // minted through elite whitelist
    uint256 public numEliteWhitelists = 0;
    // max elite whitelists
    uint256 public constant maxEliteWhitelists = 1000; //max 1000 elite whitelistes
    mapping(address => uint256) public eliteWhitelistsOf; 

    // minted through whitelist
    uint256 public numWhitelists = 0;
    // max whitelists
    uint256 public constant maxWhitelists = 6727; //max 6727 whitelists + 50 giveaways
    mapping(address => uint256) public whitelistsOf; 

    // minted through public sale
    uint256 public numPublicSale = 0;
    //max per mint in public sale
    uint256 public maxPerMint = 10;
    
    /**
        Scheduling
     */
    uint256 public elitesOpeningHours = 1642950000; // Sunday, January 23, 2022 3:00:00 PM GMT+0000
    uint256 public constant operationSecondsForElites = 3600 * 72; // 3 days

    uint256 public openingHours = 1644591600; // Friday, February 11, 2022 3:00:00 PM GMT+0000                     
    uint256 public constant operationSecondsForWhitelist = 3600 * 72; // 3 days

    /**
        Price
     */
    uint256 public constant eliteMintPrice = 0.1 ether;
    uint256 public constant whitelistMintPrice = 0.11 ether;
    uint256 public constant publicMintPrice = 0.13 ether;
    

    event SetElitesOpeningHours(uint256 elitesOpeningHours);
    event SetOpeningHours(uint256 openingHours);
    event MintWithGiveaway(address account, uint256 amount);
    event MintWithElitesWhitelist(address account, uint256 amount, uint256 changes);
    event MintWithWhitelist(address account, uint256 amount, uint256 changes);
    event MintHolyShxxt(address account, uint256 amount, uint256 changes);
    event Withdraw(address to);
    event MintPaused(bool mintPaused);
    event SetMaxPerMint(uint256 maxPerMint);

    constructor() EIP712("HolyShxxt", "1") {}

    modifier whenNotPaused() {
        require(
            !mintPaused,
            "Store is closed"
        );
        _;
    }

    modifier whenEliteWhitelistOpened() {
        require(
            block.timestamp >= elitesOpeningHours,
            "Store is not opened for elites and vips"
        );
        require(
            block.timestamp < elitesOpeningHours + operationSecondsForElites,
            "Store is closed for elites and vips"
        );
        _;
    }

    modifier whenWhitelistOpened() {
        require(
            block.timestamp >= openingHours,
            "Store is not opened for whitelist"
        );
        require(
            block.timestamp < openingHours + operationSecondsForWhitelist,
            "Store is closed for whitelist"
        );
        _;
    }

    modifier whenPublicOpened() {
        require(
            block.timestamp >= openingHours + operationSecondsForWhitelist,
            "Store is not opened"
        );
        _;
    }

    function setMintPaused(bool _mintPaused) external onlyOwner{
        mintPaused = _mintPaused;
        emit MintPaused(_mintPaused);
    }

    function setElitesOpeningHours(uint256 _elitesOpeningHours) external onlyOwner {
        elitesOpeningHours = _elitesOpeningHours;
        emit SetElitesOpeningHours(_elitesOpeningHours);
    }

    function setOpeningHours(uint256 _openingHours) external onlyOwner {
        openingHours = _openingHours;
        emit SetOpeningHours(_openingHours);
    }

    function setMaxPerMint(uint256 _maxPerMint) external onlyOwner {
        maxPerMint = _maxPerMint;
        emit SetMaxPerMint(_maxPerMint);
    }

    function mintByGiveaway(
        uint256 _nftAmount,
        uint8 _vSig,
        bytes32 _rSig,
        bytes32 _sSig
    ) external whenNotPaused whenWhitelistOpened {
        //giveaway mint happens during whitelist period
        uint256 myGiveaways = giveawaysOf[msg.sender];
        require(myGiveaways == 0, "Tsk tsk, not too greedy please");

        require(numGiveaways + _nftAmount <= maxGiveaways, "Max number of giveaways reached");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(GIVEAWAY_TYPEHASH, msg.sender, _nftAmount))
        );

        address signer = ecrecover(digest, _vSig, _rSig, _sSig);
        require(signer == owner(), "The signature is not from us, please check again");

        giveawaysOf[msg.sender] = _nftAmount; //update who has claimed their giveaways

        for (uint256 i = 0; i < _nftAmount; i++) {
            holyShxxtLeague.mint(msg.sender);
        }

        numGiveaways += _nftAmount;

        emit MintWithGiveaway(msg.sender, _nftAmount);
    }

    function mintByEliteWhitelist(
        uint256 _nftAmount,
        uint8 _vSig,
        bytes32 _rSig,
        bytes32 _sSig
    ) external payable whenNotPaused whenEliteWhitelistOpened {
        uint256 myEliteWhitelists = eliteWhitelistsOf[msg.sender];
        require(myEliteWhitelists == 0, "Tsk tsk, not too greedy please");

        require(numEliteWhitelists + _nftAmount <= maxEliteWhitelists, "Max number of whitelists reached");

        uint256 totalPrice = eliteMintPrice * _nftAmount;
        require(totalPrice <= msg.value, "Not enough ETH");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(ELITE_WHITELIST_TYPEHASH, msg.sender, _nftAmount))
        );

        address signer = ecrecover(digest, _vSig, _rSig, _sSig);
        require(signer == owner(), "The signature is not from us, please check again");

        eliteWhitelistsOf[msg.sender] = _nftAmount; //update who has claimed their whitelists

        for (uint256 i = 0; i < _nftAmount; i++) {
            holyShxxtLeague.mint(msg.sender);
        }

        numEliteWhitelists += _nftAmount;

        // Refund changes
        uint256 changes = msg.value - totalPrice;
        emit MintWithElitesWhitelist(msg.sender, _nftAmount, changes);

        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    function mintByWhitelist(
        uint256 _nftAmount,
        uint8 _vSig,
        bytes32 _rSig,
        bytes32 _sSig
    ) external payable whenNotPaused whenWhitelistOpened {
        uint256 myWhitelists = whitelistsOf[msg.sender];
        require(myWhitelists == 0, "Tsk tsk, not too greedy please");

        require(numWhitelists + _nftAmount <= maxWhitelists, "Max number of whitelists reached");

        uint256 totalPrice = whitelistMintPrice * _nftAmount;
        require(totalPrice <= msg.value, "Not enough ETH");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(WHITELIST_TYPEHASH, msg.sender, _nftAmount))
        );

        address signer = ecrecover(digest, _vSig, _rSig, _sSig);
        require(signer == owner(), "The signature is not from us, please check again");

        whitelistsOf[msg.sender] = _nftAmount; //update who has claimed their whitelists

        for (uint256 i = 0; i < _nftAmount; i++) {
            holyShxxtLeague.mint(msg.sender);
        }

        numWhitelists += _nftAmount;

        // Refund changes
        uint256 changes = msg.value - totalPrice;
        emit MintWithWhitelist(msg.sender, _nftAmount, changes);

        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    function publicMint(
        uint256 _nftAmount
    ) external payable whenNotPaused whenPublicOpened {
        require(_nftAmount <= maxPerMint, "Cannot exceed max nft per mint");

        require(numGiveaways + numEliteWhitelists + numWhitelists + numPublicSale + _nftAmount <= MAX_SUPPLY, "Max number of mintable reached");

        uint256 totalPrice = publicMintPrice * _nftAmount;
        require(totalPrice <= msg.value, "Not enough ETH");

        for (uint256 i = 0; i < _nftAmount; i++) {
            holyShxxtLeague.mint(msg.sender);
        }

        numPublicSale += _nftAmount;

        // Refund changes
        uint256 changes = msg.value - totalPrice;
        emit MintHolyShxxt(msg.sender, _nftAmount, changes);

        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    // withdraw eth for sold HolyShxxt 
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        // Send eth to designated receiver
        emit Withdraw(holyShxxtWallet);

        holyShxxtWallet.transfer(balance);
    }
}