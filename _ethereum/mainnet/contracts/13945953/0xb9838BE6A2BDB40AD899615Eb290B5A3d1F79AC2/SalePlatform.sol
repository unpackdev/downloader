// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IQuantumArt.sol";
import "./IQuantumMintPass.sol";
import "./ContinuousDutchAuction.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./BitMaps.sol";
import "./MerkleProof.sol";

contract SalePlatform is ContinuousDutchAuction, ReentrancyGuard {
    using BitMaps for BitMaps.BitMap;
    using Strings for uint256;

    struct Sale {
        uint128 price;
        uint64 start;
        uint64 limit;
    }

    struct MPClaim {
        uint64 mpId;
        uint64 start;
        uint128 price;
    }

    struct Whitelist {
        uint192 price;
        uint64 start;
        bytes32 merkleRoot;
    }

    event Purchased(uint256 indexed dropId, uint256 tokenId, address to);

    //mapping dropId => struct
    mapping (uint256 => Sale) public sales;
    mapping (uint256 => MPClaim) public mpClaims;
    mapping (uint256 => Whitelist) public whitelists;
    uint256 public defaultArtistCut; //10000 * percentage
    IQuantumArt public quantum;
    IQuantumMintPass public mintpass;

    BitMaps.BitMap private _usingLimiter;
    mapping (uint256 => BitMaps.BitMap) private _claimedWL;
    mapping (address => BitMaps.BitMap) private _alreadyBought;
    mapping (uint256 => uint256) private _overridedArtistCut; // dropId -> cut
    address payable private _quantumTreasury;

    constructor(
        address deployedQuantum,
        address deployedMP,
        address admin,
        address payable treasury) {
        quantum = IQuantumArt(deployedQuantum);
        mintpass = IQuantumMintPass(deployedMP);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _quantumTreasury = treasury;
        defaultArtistCut = 8000; //default 80% for artist
    }

    modifier checkCaller {
        require(msg.sender.code.length == 0, "Contract forbidden from buying");
        _;
    }

    modifier isFirstTime(uint256 dropId) {
        if (_usingLimiter.get(dropId)) {
            require(!_alreadyBought[msg.sender].get(dropId), string(abi.encodePacked("Already bought drop ", dropId.toString())));
            _alreadyBought[msg.sender].set(dropId);
        }
        _;
    }

    function withdraw(address payable to) onlyRole(DEFAULT_ADMIN_ROLE) public {
        Address.sendValue(to, address(this).balance);
    }

    function setManager(address manager) onlyRole(DEFAULT_ADMIN_ROLE) public {
        grantRole(MANAGER_ROLE, manager);
    }

    function unsetManager(address manager) onlyRole(DEFAULT_ADMIN_ROLE) public {
        revokeRole(MANAGER_ROLE, manager);
    }

    function premint(uint256 dropId, address[] calldata recipients) onlyRole(DEFAULT_ADMIN_ROLE) public {
        for(uint256 i = 0; i < recipients.length; i++) {
            uint256 tokenId = quantum.mintTo(dropId, recipients[i]);
            emit Purchased(dropId, tokenId, recipients[i]);
        }
    }

    function setMintpass(address deployedMP) onlyRole(MANAGER_ROLE) public {
        mintpass = IQuantumMintPass(deployedMP);
    }
    
    function createSale(uint256 dropId, uint128 price, uint64 start, uint64 limit) onlyRole(MANAGER_ROLE) public {
        sales[dropId] = Sale(price, start, limit);
    }

    function createMPClaim(uint256 dropId, uint64 mpId, uint64 start, uint128 price) onlyRole(MANAGER_ROLE) public {
        mpClaims[dropId] = MPClaim(mpId, start, price);
    }

    function createWLClaim(uint256 dropId, uint192 price, uint64 start, bytes32 root) onlyRole(MANAGER_ROLE) public {
        whitelists[dropId] = Whitelist(price, start, root);
    }

    function setDefaultArtistCut(uint256 cut) onlyRole(MANAGER_ROLE) public {
        defaultArtistCut = cut;
    }

    function flipUint64(uint64 x) internal pure returns (uint64) {
        return x > 0 ? 0 : type(uint64).max;
    }

    function flipSaleState(uint256 dropId) onlyRole(MANAGER_ROLE) public {
        sales[dropId].start = flipUint64(sales[dropId].start);
    }

    function flipMPClaimState(uint256 dropId) onlyRole(MANAGER_ROLE) public {
        mpClaims[dropId].start = flipUint64(mpClaims[dropId].start);
    }

    function flipWLState(uint256 dropId) onlyRole(MANAGER_ROLE) public {
        whitelists[dropId].start = flipUint64(whitelists[dropId].start);
    }

    function flipLimiterForDrop(uint256 dropId) onlyRole(MANAGER_ROLE) public {
        if (_usingLimiter.get(dropId)) {
            _usingLimiter.unset(dropId);
        } else {
            _usingLimiter.set(dropId);
        }
    }


    function overrideArtistcut(uint256 dropId, uint256 cut) onlyRole(MANAGER_ROLE) public {
        _overridedArtistCut[dropId] = cut;
    }

    function payout(address artist, uint256 dropId, uint256 amount) internal {
        uint256 artistCut = _overridedArtistCut[dropId] == 0 ? defaultArtistCut : _overridedArtistCut[dropId];
        uint256 payout_ = (amount*artistCut)/10000;
        Address.sendValue(payable(artist), payout_);
        Address.sendValue(_quantumTreasury, amount - payout_);
    }

    function purchase(uint256 dropId, uint256 amount) nonReentrant checkCaller isFirstTime(dropId) payable public {
        Sale memory sale = sales[dropId];
        require(block.timestamp >= sale.start, "PURCHASE:SALE INACTIVE");
        require(amount <= sale.limit, "PURCHASE:OVER LIMIT");
        require(msg.value == amount * sale.price, "PURCHASE:INCORRECT MSG.VALUE");
        for(uint256 i = 0; i < amount; i++) {
            uint256 tokenId = quantum.mintTo(dropId, msg.sender);
            emit Purchased(dropId, tokenId, msg.sender);
        }
        payout(quantum.getArtist(dropId), dropId, msg.value);
    }


    function purchaseThroughAuction(uint256 dropId) nonReentrant checkCaller isFirstTime(dropId) payable public {
        //we use dropId as the auctionId -> one auction per drop only
        uint256 userPaid = verifyBid(dropId);
        uint256 tokenId = quantum.mintTo(dropId, msg.sender);
        emit Purchased(dropId, tokenId, msg.sender);
        payout(quantum.getArtist(dropId), dropId, userPaid);
    }

    function claimWithMintPass(uint256 dropId, uint256 amount) nonReentrant payable public {
        MPClaim memory mpClaim = mpClaims[dropId];
        require(block.timestamp >= mpClaim.start, "MP: CLAIMING INACTIVE");
        require(msg.value == amount * mpClaim.price, "MP:WRONG MSG.VALUE");
        mintpass.burnFromRedeem(msg.sender, mpClaim.mpId, amount); //burn mintpasses
        for(uint256 i = 0; i < amount; i++) {
            uint256 tokenId = quantum.mintTo(dropId, msg.sender);
            emit Purchased(dropId, tokenId, msg.sender);
        }
        if (msg.value > 0) payout(quantum.getArtist(dropId), dropId, msg.value);
    }

    function purchaseThroughWhitelist(uint256 dropId, uint256 amount, uint256 index, bytes32[] calldata merkleProof) nonReentrant external payable {
        Whitelist memory whitelist = whitelists[dropId];
        require(block.timestamp >= whitelist.start, "WL:INACTIVE");
        require(msg.value == whitelist.price * amount, "WL: INVALID MSG.VALUE");
        require(!_claimedWL[dropId].get(index), "WL:ALREADY CLAIMED");
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount, index));
        require(MerkleProof.verify(merkleProof, whitelist.merkleRoot, node),"WL:INVALID PROOF");
        _claimedWL[dropId].set(index);
        uint256 tokenId = quantum.mintTo(dropId, msg.sender);
        emit Purchased(dropId, tokenId, msg.sender);
        payout(quantum.getArtist(dropId), dropId, msg.value);
    }

    function isWLClaimed(uint256 dropId, uint256 index) public view returns (bool) {
        return _claimedWL[dropId].get(index);
    }
}