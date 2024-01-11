// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./draft-EIP712.sol";

interface HolyShxxtLeague {
    function mint(address) external;
}

contract HolyShootPreSeasonDraft is EIP712, Ownable {

    HolyShxxtLeague public constant holyShxxtLeague =
        HolyShxxtLeague(0xe93AAb5779e706c73DAf8Bf849bb8E46Fb183691);

    /**
        EIP712
     */

    bytes32 public constant VIP_TYPEHASH =
        keccak256("SignVIPWhitelist(address receiver)");
    struct SignVIPWhitelist {
        address receiver;
    }

    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("SignWhitelist(address receiver)");
    struct SignWhitelist {
        address receiver;
    }

    /**
        Pause mint
    */
    bool public mintPaused = false;

    /**
        Whitelists
     */
    // minted through VIP whitelist
    uint256 public numVIPWhitelists = 0;
    mapping(address => uint256) public VIPWhitelistsOf; 

    // minted through whitelist
    uint256 public numWhitelists = 0;
    mapping(address => uint256) public whitelistsOf; 

    //max per mint in public sale
    uint256 public maxPerMint = 10;
    
    /**
        Scheduling
     */
    uint256 public VIPOpeningHours = 1654833600; // Friday, June 10, 2022 4:00:00 AM GMT+0
    uint256 public openingHours = 1654866000; // Friday, June 10, 2022 1:00:00 PM GMT+0                 
    uint256 public constant operationSecondsForWhitelist = 3600 * 3; // 3 hours

    /**
        Price
     */
    uint256 public constant VIPMintPrice = 0.07 ether;
    uint256 public constant whitelistMintPrice = 0.11 ether;

    event SetVIPOpeningHours(uint256 VIPOpeningHours);
    event SetOpeningHours(uint256 openingHours);
    event MintWithVIPWhitelist(address account, uint256 amount, uint256 changes);
    event MintWithWhitelist(address account, uint256 amount, uint256 changes);
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

    modifier whenVIPWhitelistOpened() {
        require(
            block.timestamp >= VIPOpeningHours,
            "Store is not opened for vips"
        );
        require(
            block.timestamp < openingHours,
            "Store is closed for vips"
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
            "Store is closed"
        );
        _;
    }

    function setMintPaused(bool _mintPaused) external onlyOwner{
        mintPaused = _mintPaused;
        emit MintPaused(_mintPaused);
    }

    function setVIPOpeningHours(uint256 _VIPOpeningHours) external onlyOwner {
        VIPOpeningHours = _VIPOpeningHours;
        emit SetVIPOpeningHours(_VIPOpeningHours);
    }

    function setOpeningHours(uint256 _openingHours) external onlyOwner {
        openingHours = _openingHours;
        emit SetOpeningHours(_openingHours);
    }

    function setMaxPerMint(uint256 _maxPerMint) external onlyOwner {
        maxPerMint = _maxPerMint;
        emit SetMaxPerMint(_maxPerMint);
    }

    function mintByVIPWhitelist(
        uint256 _nftAmount,
        uint8 _vSig,
        bytes32 _rSig,
        bytes32 _sSig
    ) external payable whenNotPaused whenVIPWhitelistOpened {
        uint256 myVIPWhitelists = VIPWhitelistsOf[msg.sender];
        require(myVIPWhitelists == 0, "Tsk tsk, not too greedy please");

        require(_nftAmount <= maxPerMint, "You cannot mint more than the maximum allowed");

        uint256 totalPrice = VIPMintPrice * _nftAmount;
        require(totalPrice <= msg.value, "Not enough ETH");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(VIP_TYPEHASH, msg.sender))
        );

        address signer = ecrecover(digest, _vSig, _rSig, _sSig);
        require(signer == owner(), "The signature is not from us, please check again");

        VIPWhitelistsOf[msg.sender] = _nftAmount; //update who has claimed their whitelists

        for (uint256 i = 0; i < _nftAmount; i++) {
            holyShxxtLeague.mint(msg.sender);
        }

        numVIPWhitelists += _nftAmount;

        // Refund changes
        uint256 changes = msg.value - totalPrice;
        emit MintWithVIPWhitelist(msg.sender, _nftAmount, changes);

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

        require(_nftAmount <= maxPerMint, "You cannot mint more than the maximum allowed");

        uint256 totalPrice = whitelistMintPrice * _nftAmount;
        require(totalPrice <= msg.value, "Not enough ETH");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(WHITELIST_TYPEHASH, msg.sender))
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


    // withdraw eth for sold HolyShxxt 
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }
}