// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IQuantumArt.sol";
import "./IQuantumMintPass.sol";
import "./IQuantumSplitter.sol";
import "./ContinuousDutchAuction.sol";
import "./SaleModule.sol";
import "./WhitelistModule.sol";
import "./MintpassModule.sol";
import "./Auth.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./BitMaps.sol";
import "./MerkleProof.sol";

contract SalePlatform is 
    ReentrancyGuard,
    Auth,
    SaleModule,
    WhitelistModule,
    MintpassModule,
    ContinuousDutchAuction 
{
    using BitMaps for BitMaps.BitMap;
    using Strings for uint256;

    event Purchased(uint256 indexed dropId, uint256 tokenId, address to);

    address[] public privilegedContracts;
    IQuantumArt public quantum;
    IQuantumSplitter public splitter;

    BitMaps.BitMap private _disablingLimiter;
    mapping (address => BitMaps.BitMap) private _alreadyBought;

    constructor(
        address quantum_,
        address mintpass_,
        address admin_,
        address authority_,
        address splitter_) Auth(admin_, Authority(authority_)) {
        quantum = IQuantumArt(quantum_);
        mintpass = IQuantumMintPass(mintpass_);
        splitter = IQuantumSplitter(splitter_);
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

    function setSplitter(address splitter_) requiresAuth public {
        splitter = IQuantumSplitter(splitter_);
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

    function flipLimiterForDrop(uint256 dropId) requiresAuth public {
        if (_disablingLimiter.get(dropId)) {
            _disablingLimiter.unset(dropId);
        } else {
            _disablingLimiter.set(dropId);
        }
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

    function _depositToSplitter(uint256 dropId, uint256 amount) internal {
        splitter.deposit{value:amount}(dropId);
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
        _purchase(dropId, amount);
        for(uint256 i = 0; i < amount; i++) {
            uint256 tokenId = quantum.mintTo(dropId, msg.sender);
            emit Purchased(dropId, tokenId, msg.sender);
        }
        _depositToSplitter(dropId, msg.value);
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
        _depositToSplitter(dropId, userPaid);
    }

    function claimWithMintPass(uint256 dropId, uint256 amount) nonReentrant payable public {
        _claimWithMintPass(dropId, amount);
        for(uint256 i = 0; i < amount; i++) {
            uint256 tokenId = quantum.mintTo(dropId, msg.sender);
            emit Purchased(dropId, tokenId, msg.sender);
        }
        if (msg.value > 0) _depositToSplitter(dropId, msg.value);
    }

    function purchaseThroughWhitelist(uint256 dropId, uint256 amount, uint256 index, bytes32[] calldata merkleProof) nonReentrant external payable {
        _purchaseThroughWhitelist(dropId, amount, index, merkleProof);
        uint256 tokenId = quantum.mintTo(dropId, msg.sender);
        emit Purchased(dropId, tokenId, msg.sender);
        _depositToSplitter(dropId, msg.value);
    }
}