// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./draft-EIP712.sol";

interface NextTrialRun {
    function mint(address) external;
}

contract NextTrialRunOrientation is EIP712, Ownable {

    NextTrialRun public constant nextTrialRun =
        NextTrialRun(0x052Fe843dF86fc17a75454de73Ba462a6b4e5cBB);

    //for withdrawal
    address payable public constant nextTrialRunWallet = payable(0x7A08b1193E076d4F6693A677c792e94B7fC00942); 

    /**
        EIP712
     */
    bytes32 public constant GIVEAWAY_TYPEHASH =
        keccak256("SignGiveaway(address receiver,uint256 amount)");
    struct SignGiveaway {
        address receiver;
        uint256 amount;
    }

    bytes32 public constant STAGE1_TYPEHASH =
        keccak256("SignStage1Whitelist(address receiver)");
    struct SignStage1Whitelist {
        address receiver;
    }

    bytes32 public constant STAGE2_TYPEHASH =
        keccak256("SignStage2Whitelist(address receiver)");
    struct SignStage2Whitelist {
        address receiver;
    }

    bytes32 public constant STAGE3_TYPEHASH =
        keccak256("SignStage3Whitelist(address receiver)");
    struct SignStage3Whitelist {
        address receiver;
    }

    
    /**
        Max supply
     */
     uint256 public constant MAX_SUPPLY = 6000;

    /**
        Pause mint
    */
    bool public mintPaused = false;

    /**
        Giveaway Mints
     */
    // team mints
    uint256 private constant teamMint = 51;
    // minted through giveaways
    uint256 public numGiveaways = 0;
    // max giveaways
    uint256 public constant maxGiveaways = 59;     
    mapping(address => uint256) public giveawaysOf;

    /**
        Whitelists
     */
    // stage 1 mints
    uint256 public numStage1Whitelists = 0;
    uint256 public maxPerMintStage1 = 2;
    mapping(address => uint256) public stage1WhitelistsOf; 

    // stage 2 mints
    uint256 public numStage2Whitelists = 0;
    uint256 public maxPerMintStage2 = 3;
    mapping(address => uint256) public stage2WhitelistsOf; 

    // stage 3 mints
    uint256 public numStage3Whitelists = 0;
    uint256 public maxPerMintStage3 = 5;
    mapping(address => uint256) public stage3WhitelistsOf;

    // minted through public sale
    uint256 public numPublicSale = 0;
    uint256 public maxPerMint = 50;
    
    /**
        Scheduling
     */
    uint256 public giveawayOpeningHours = 1650628800; // Friday, April 22, 2022 10:00:00 PM GMT+08:00
    uint256 public openingHours = 1650686400; // Saturday, April 23, 2022 12:00:00 PM GMT+08:00
    uint256 public constant operationSecondsForStage1 = 3600 * 4; // 4 hours
    uint256 public constant operationSecondsForStage2 = 3600 * 4; // 4 hours
    uint256 public constant operationSecondsForStage3 = 3600 * 4; // 4 hours

    /**
        Price
     */
    uint256 public constant mintPrice = 0.2 ether;

    event SetGiveawayOpeningHours(uint256 giveawayOpeningHours);
    event SetOpeningHours(uint256 openingHours);

    event MintGiveaway(address account, uint256 amount);
    event MintStage1(address account, uint256 amount, uint256 changes);
    event MintStage2(address account, uint256 amount, uint256 changes);
    event MintStage3(address account, uint256 amount, uint256 changes);
    event MintPublic(address account, uint256 amount, uint256 changes);
    event Withdraw(address to);
    event MintPaused(bool mintPaused);
    event SetMaxPerMint(uint256 maxPerMint);
    event SetMaxPerMintStage1(uint256 maxPerMintStage1);
    event SetMaxPerMintStage2(uint256 maxPerMintStage2);
    event SetMaxPerMintStage3(uint256 maxPerMintStage3);

    constructor() EIP712("NextTrialRunOrientation", "1") {}

    modifier whenNotPaused() {
        require(
            !mintPaused,
            "Store is closed"
        );
        _;
    }

    modifier whenGiveawayOpened() {
        require(
            block.timestamp >= giveawayOpeningHours,
            "Store is not opened for giveaway mints"
        );
        require(
            block.timestamp < openingHours,
            "Store is closed for giveaway mints"
        );
        _;
    }

    modifier whenStage1Opened() {
        require(
            block.timestamp >= openingHours,
            "Store is not opened for stage 1 whitelist"
        );
        require(
            block.timestamp < openingHours + operationSecondsForStage1,
            "Store is closed for stage 1 whitelist"
        );
        _;
    }

    modifier whenStage2Opened() {
        require(
            block.timestamp >= openingHours + operationSecondsForStage1,
            "Store is not opened for stage 2 whitelist"
        );
        require(
            block.timestamp < openingHours + operationSecondsForStage1 + operationSecondsForStage2,
            "Store is closed for stage 2 whitelist"
        );
        _;
    }

    modifier whenStage3Opened() {
        require(
            block.timestamp >= openingHours + operationSecondsForStage1 + operationSecondsForStage2,
            "Store is not opened for stage 3 whitelist"
        );
        require(
            block.timestamp < openingHours + operationSecondsForStage1 + operationSecondsForStage2+ operationSecondsForStage3,
            "Store is closed for stage 3 whitelist"
        );
        _;
    }

    modifier whenPublicOpened() {
        require(
            block.timestamp >= openingHours + operationSecondsForStage1 + operationSecondsForStage2+ operationSecondsForStage3,
            "Store is not opened"
        );
        _;
    }

    function setMintPaused(bool _mintPaused) external onlyOwner{
        mintPaused = _mintPaused;
        emit MintPaused(_mintPaused);
    }

    function setGiveawayOpeningHours(uint256 _giveawayOpeningHours) external onlyOwner {
        giveawayOpeningHours = _giveawayOpeningHours;
        emit SetGiveawayOpeningHours(_giveawayOpeningHours);
    }

    function setOpeningHours(uint256 _openingHours) external onlyOwner {
        openingHours = _openingHours;
        emit SetOpeningHours(_openingHours);
    }

    function setMaxPerMint(uint256 _maxPerMint) external onlyOwner {
        maxPerMint = _maxPerMint;
        emit SetMaxPerMint(_maxPerMint);
    }

    function setMaxPerMintStage1(uint256 _maxPerMintStage1) external onlyOwner {
        maxPerMintStage1 = _maxPerMintStage1;
        emit SetMaxPerMintStage1(_maxPerMintStage1);
    }

    function setMaxPerMintStage2(uint256 _maxPerMintStage2) external onlyOwner {
        maxPerMintStage2 = _maxPerMintStage2;
        emit SetMaxPerMintStage2(_maxPerMintStage2);
    }

    function setMaxPerMintStage3(uint256 _maxPerMintStage3) external onlyOwner {
        maxPerMintStage3 = _maxPerMintStage3;
        emit SetMaxPerMintStage3(_maxPerMintStage3);
    }

    function mintByGiveaway(
        uint256 _nftAmount,
        uint8 _vSig,
        bytes32 _rSig,
        bytes32 _sSig
    ) external whenNotPaused whenGiveawayOpened {
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
            nextTrialRun.mint(msg.sender);
        }

        numGiveaways += _nftAmount;

        emit MintGiveaway(msg.sender, _nftAmount);
    }

    function mintByStage1Whitelist(
        uint256 _nftAmount,
        uint8 _vSig,
        bytes32 _rSig,
        bytes32 _sSig
    ) external payable whenNotPaused whenStage1Opened {
        uint256 myStage1Whitelists = stage1WhitelistsOf[msg.sender];
        require(myStage1Whitelists == 0, "You have already minted for stage 1");

        require(_nftAmount <= maxPerMintStage1, "You cannot mint more than the maximum allowed");

        require(teamMint + numGiveaways + numStage1Whitelists + _nftAmount <= MAX_SUPPLY, "Mints exceeds max supply");

        uint256 totalPrice = mintPrice * _nftAmount;
        require(totalPrice <= msg.value, "Not enough ETH");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(STAGE1_TYPEHASH, msg.sender))
        );

        address signer = ecrecover(digest, _vSig, _rSig, _sSig);
        require(signer == owner(), "The signature is not from us, please check again");

        stage1WhitelistsOf[msg.sender] = _nftAmount; //update who has claimed their whitelists

        numStage1Whitelists += _nftAmount;

        for (uint256 i = 0; i < _nftAmount; i++) {
            nextTrialRun.mint(msg.sender);
        }

        // Refund changes
        uint256 changes = msg.value - totalPrice;
        emit MintStage1(msg.sender, _nftAmount, changes);

        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    function mintByStage2Whitelist(
        uint256 _nftAmount,
        uint8 _vSig,
        bytes32 _rSig,
        bytes32 _sSig
    ) external payable whenNotPaused whenStage2Opened {
        uint256 myStage2Whitelists = stage2WhitelistsOf[msg.sender];
        require(myStage2Whitelists == 0, "You have already minted for stage 2");

        require(_nftAmount <= maxPerMintStage2, "You cannot mint more than the maximum allowed");

        require(teamMint + numGiveaways + numStage1Whitelists + numStage2Whitelists + _nftAmount <= MAX_SUPPLY, "Mints exceeds max supply");

        uint256 totalPrice = mintPrice * _nftAmount;
        require(totalPrice <= msg.value, "Not enough ETH");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(STAGE2_TYPEHASH, msg.sender))
        );

        address signer = ecrecover(digest, _vSig, _rSig, _sSig);
        require(signer == owner(), "The signature is not from us, please check again");

        stage2WhitelistsOf[msg.sender] = _nftAmount; //update who has claimed their whitelists

        numStage2Whitelists += _nftAmount;

        for (uint256 i = 0; i < _nftAmount; i++) {
            nextTrialRun.mint(msg.sender);
        }

        // Refund changes
        uint256 changes = msg.value - totalPrice;
        emit MintStage2(msg.sender, _nftAmount, changes);

        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    function mintByStage3Whitelist(
        uint256 _nftAmount,
        uint8 _vSig,
        bytes32 _rSig,
        bytes32 _sSig
    ) external payable whenNotPaused whenStage3Opened {
        uint256 myStage3Whitelists = stage3WhitelistsOf[msg.sender];
        require(myStage3Whitelists == 0, "You have already minted for stage 3");

        require(_nftAmount <= maxPerMintStage3, "You cannot mint more than the maximum allowed");

        require(teamMint + numGiveaways + numStage1Whitelists + numStage2Whitelists + numStage3Whitelists + _nftAmount <= MAX_SUPPLY, "Mints exceeds max supply");

        uint256 totalPrice = mintPrice * _nftAmount;
        require(totalPrice <= msg.value, "Not enough ETH");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(STAGE3_TYPEHASH, msg.sender))
        );

        address signer = ecrecover(digest, _vSig, _rSig, _sSig);
        require(signer == owner(), "The signature is not from us, please check again");

        stage3WhitelistsOf[msg.sender] = _nftAmount; //update who has claimed their whitelists

        numStage3Whitelists += _nftAmount;

        for (uint256 i = 0; i < _nftAmount; i++) {
            nextTrialRun.mint(msg.sender);
        }

        // Refund changes
        uint256 changes = msg.value - totalPrice;
        emit MintStage3(msg.sender, _nftAmount, changes);

        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    function publicMint(
        uint256 _nftAmount
    ) external payable whenNotPaused whenPublicOpened {
        require(_nftAmount <= maxPerMint, "Cannot exceed max nft per mint");

        require(teamMint + numGiveaways + numStage1Whitelists + numStage2Whitelists + numStage3Whitelists + numPublicSale + _nftAmount <= MAX_SUPPLY, "Mints exceeds max supply");

        uint256 totalPrice = mintPrice * _nftAmount;
        require(totalPrice <= msg.value, "Not enough ETH");

        numPublicSale += _nftAmount;

        for (uint256 i = 0; i < _nftAmount; i++) {
            nextTrialRun.mint(msg.sender);
        }

        // Refund changes
        uint256 changes = msg.value - totalPrice;
        emit MintPublic(msg.sender, _nftAmount, changes);

        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    // withdraw eth for sold HolyShxxt 
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        // Send eth to designated receiver
        emit Withdraw(nextTrialRunWallet);

        nextTrialRunWallet.transfer(balance);
    }
}