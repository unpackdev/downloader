// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IQuantumArt.sol";
import "./IQuantumMintPass.sol";
import "./ContinuousDutchAuction.sol";
import "./Auth.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./BitMaps.sol";
import "./MerkleProof.sol";

contract SalePlatform is ContinuousDutchAuction, ReentrancyGuard, Auth {
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
    address[] public privilegedContracts;

    BitMaps.BitMap private _disablingLimiter;
    mapping (uint256 => BitMaps.BitMap) private _claimedWL;
    mapping (address => BitMaps.BitMap) private _alreadyBought;
    mapping (uint256 => uint256) private _overridedArtistCut; // dropId -> cut
    address payable private _quantumTreasury;

    constructor(
        address deployedQuantum,
        address deployedMP,
        address admin,
        address payable treasury,
        address authority) Auth(admin, Authority(authority)) {
        quantum = IQuantumArt(deployedQuantum);
        mintpass = IQuantumMintPass(deployedMP);
        _quantumTreasury = treasury;
        defaultArtistCut = 8000; //default 80% for artist
    }

    modifier checkCaller {
        require(msg.sender.code.length == 0, "Contract forbidden");
        _;
    }

    modifier isFirstTime(uint256 dropId) {
        if (!_disablingLimiter.get(dropId)) {
            require(!_alreadyBought[msg.sender].get(dropId), string(abi.encodePacked("Already bought drop ", dropId.toString())));
            _alreadyBought[msg.sender].set(dropId);
        }
        _;
    }

    function setPrivilegedContracts(address[] calldata contracts) requiresAuth public {
        privilegedContracts = contracts;
    }

    function withdraw(address payable to) requiresAuth public {
        Address.sendValue(to, address(this).balance);
    }

    function premint(uint256 dropId, address[] calldata recipients) requiresAuth public {
        for(uint256 i = 0; i < recipients.length; i++) {
            uint256 tokenId = quantum.mintTo(dropId, recipients[i]);
            emit Purchased(dropId, tokenId, recipients[i]);
        }
    }

    function setMintpass(address deployedMP) requiresAuth public {
        mintpass = IQuantumMintPass(deployedMP);
    }

    function setDefaultArtistCut(uint256 cut) requiresAuth public {
        defaultArtistCut = cut;
    }
    
    function createSale(uint256 dropId, uint128 price, uint64 start, uint64 limit) requiresAuth public {
        sales[dropId] = Sale(price, start, limit);
    }

    function createMPClaim(uint256 dropId, uint64 mpId, uint64 start, uint128 price) requiresAuth public {
        mpClaims[dropId] = MPClaim(mpId, start, price);
    }

    function createWLClaim(uint256 dropId, uint192 price, uint64 start, bytes32 root) requiresAuth public {
        whitelists[dropId] = Whitelist(price, start, root);
    }

    function flipUint64(uint64 x) internal pure returns (uint64) {
        return x > 0 ? 0 : type(uint64).max;
    }

    function flipSaleState(uint256 dropId) requiresAuth public {
        sales[dropId].start = flipUint64(sales[dropId].start);
    }

    function flipMPClaimState(uint256 dropId) requiresAuth public {
        mpClaims[dropId].start = flipUint64(mpClaims[dropId].start);
    }

    function flipWLState(uint256 dropId) requiresAuth public {
        whitelists[dropId].start = flipUint64(whitelists[dropId].start);
    }

    function flipLimiterForDrop(uint256 dropId) requiresAuth public {
        if (_disablingLimiter.get(dropId)) {
            _disablingLimiter.unset(dropId);
        } else {
            _disablingLimiter.set(dropId);
        }
    }

    function overrideArtistcut(uint256 dropId, uint256 cut) requiresAuth public {
        _overridedArtistCut[dropId] = cut;
    }

    function setAuction(
        uint256 auctionId,
        uint256 startingPrice,
        uint128 decreasingConstant,
        uint64 start,
        uint64 period
    ) public override requiresAuth {
        super.setAuction(auctionId, startingPrice, decreasingConstant, start, period);
    }

    function payout(address artist, uint256 dropId, uint256 amount) internal {
        uint256 artistCut = _overridedArtistCut[dropId] == 0 ? defaultArtistCut : _overridedArtistCut[dropId];
        uint256 payout_ = (amount*artistCut)/10000;
        Address.sendValue(payable(artist), payout_);
        Address.sendValue(_quantumTreasury, amount - payout_);
    }

    function _isPrivileged(address user) internal view returns (bool) {
        uint256 length = privilegedContracts.length;
        unchecked {
            for(uint i; i < length; i++) {
                /// @dev using this interface because has balanceOf
                if (IQuantumArt(privilegedContracts[i]).balanceOf(user) > 0) {
                    return true;
                }
            }
        }
        return false;
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
        Auction memory auction = _auctions[dropId];
        // if 5 minutes before public auction
        // if holder -> special treatment
        uint256 userPaid = auction.startingPrice;
        if (
            block.timestamp <= auction.start && 
            block.timestamp >= auction.start - 300 &&
            _isPrivileged(msg.sender)
        ) {
            require(msg.value == userPaid, "PURCHASE:INCORRECT MSG.VALUE");

        } else {
            userPaid = verifyBid(dropId);
        }
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