// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IQuantumArt.sol";
import "./IQuantumMintPass.sol";
import "./ContinuousDutchAuction.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

contract SalePlatform is ContinuousDutchAuction, ReentrancyGuard {

    struct Sale {
        uint128 price;
        uint128 limit;
        bool active;
    }

    struct MPClaim {
        uint128 mpId;
        uint128 price;
        bool active;
    }

    event Purchased(uint256 indexed dropId, uint256 tokenId, address to);

    mapping (uint256 => Sale) public sales;
    mapping (uint256 => MPClaim) public mpClaims;
    uint256 public defaultArtistCut; //10000 * percentage
    IQuantumArt public quantum;
    IQuantumMintPass public mintpass;

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
        require(!Address.isContract(msg.sender), "Contract forbidden from buying");
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
    
    function createSale(uint256 dropId, uint128 price, uint128 limit) onlyRole(MANAGER_ROLE) public {
        sales[dropId] = Sale({price:price, limit:limit, active:false});
    }

    function createMPClaim(uint256 dropId, uint128 mpId, uint128 price) onlyRole(MANAGER_ROLE) public {
        mpClaims[dropId] = MPClaim({mpId:mpId, price:price, active:false});
    }

    function setDefaultArtistCut(uint256 cut) onlyRole(MANAGER_ROLE) public {
        defaultArtistCut = cut;
    }

    function flipSaleState(uint256 dropId) onlyRole(MANAGER_ROLE) public {
        sales[dropId].active = !sales[dropId].active;
    }

    function flipMPClaimState(uint256 dropId) onlyRole(MANAGER_ROLE) public {
        mpClaims[dropId].active = !mpClaims[dropId].active;
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

    function purchase(uint256 dropId, uint256 amount) checkCaller nonReentrant payable public {
        Sale memory sale = sales[dropId];
        require(sale.active, "PURCHASE:SALE INACTIVE");
        require(amount <= sale.limit, "PURCHASE:OVER LIMIT");
        require(msg.value == amount * sale.price, "PURCHASE:INCORRECT MSG.VALUE");
        for(uint256 i = 0; i < amount; i++) {
            uint256 tokenId = quantum.mintTo(dropId, msg.sender);
            emit Purchased(dropId, tokenId, msg.sender);
        }
        payout(quantum.getArtist(dropId), dropId, msg.value);
    }


    function purchaseThroughAuction(uint256 dropId) checkCaller nonReentrant payable public {
        //we use dropId as the auctionId -> one auction per drop only
        uint256 userPaid = verifyBid(dropId);
        uint256 tokenId = quantum.mintTo(dropId, msg.sender);
        emit Purchased(dropId, tokenId, msg.sender);
        payout(quantum.getArtist(dropId), dropId, userPaid);
    }

    function claimWithMintPass(uint256 dropId, uint256 amount) nonReentrant payable public {
        MPClaim memory mpClaim = mpClaims[dropId];
        require(mpClaim.active, "MP: CLAIMING INACTIVE");
        require(msg.value == amount * mpClaim.price, "MP:WRONG MSG.VALUE");
        mintpass.burnFromRedeem(msg.sender, mpClaim.mpId, amount); //burn mintpasses
        for(uint256 i = 0; i < amount; i++) {
            uint256 tokenId = quantum.mintTo(dropId, msg.sender);
            emit Purchased(dropId, tokenId, msg.sender);
        }
        if (msg.value > 0) payout(quantum.getArtist(dropId), dropId, msg.value);
    }
}