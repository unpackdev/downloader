// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./Ownable.sol";
import "./OGInterface.sol";

/**
 * @title The interface to access the OG stats contract
 * @author nfttank.eth
 */
interface OGStatsInterface {

    /**
    * @notice Gets the OG stats for a given address
    * @param addressToScan The address to scan
    * @param checkUpToBalance The maxium balance to check for the tiers and enumerate tokens. Means: Whale if more than this quantity.
    */
    function scan(address addressToScan, uint16 checkUpToBalance) external view returns (Stats memory);
}

struct Stats {
    uint256 balance;
    bool ogDozen;
    bool meme;
    bool honorary;
    bool maxedOut;
    uint256[] tokenIds;
}

/**
 * @title Scans OG stats from a given address. Useful for whitelists, premints, free mints or discounts for OG holders.
 * @author nfttank.eth
 */
contract OGStats is Ownable {

    address private _ogContractAddress;
    mapping(uint256 => bool) private _blockedTokens;

    constructor() Ownable() {
    }

    function setOgContract(address ogContractAddress) external onlyOwner {
        _ogContractAddress = ogContractAddress;
    }

    function blockToken(uint256 tokenId) external onlyOwner {
        _blockedTokens[tokenId] = true;
    }

    function unblockToken(uint256 tokenId) external onlyOwner {
        _blockedTokens[tokenId] = false;
    }

    function isTokenBlocked(uint256 tokenId) public view returns (bool) {
        return _blockedTokens[tokenId];
    }

    /**
    * @notice Gets the OG stats for a given address
    * @param addressToScan The address to scan
    * @param checkUpToBalance The maxium balance to check for the tiers and enumerate tokens. Means: If more than this quantity, king.
    */
    function scan(address addressToScan, uint16 checkUpToBalance) public view returns (Stats memory) {

        OGInterface ogContract = OGInterface(_ogContractAddress);
        uint256 balance = ogContract.balanceOf(addressToScan);

        Stats memory stats = Stats(balance, false, false, false, false, new uint256[](balance <= checkUpToBalance ? balance : 0));

        if (balance > checkUpToBalance) {
            stats.maxedOut = true;
            return stats;
        }

        bytes32 ogDozenBytes = keccak256(bytes('OG Dozen'));
        bytes32 memeBytes = keccak256(bytes('Meme'));
        bytes32 honoraryBytes = keccak256(bytes('Honorary'));

        for (uint16 i = 0; i < balance; i++) {

            stats.tokenIds[i] = ogContract.tokenOfOwnerByIndex(addressToScan, i);

            if (isTokenBlocked(stats.tokenIds[i])) {
                stats.tokenIds[i] = 0;
                stats.balance--;
                continue;
            }

            string memory tier = ogContract.tier(stats.tokenIds[i]);
            bytes32 tierBytes = keccak256(bytes(tier));

            if (tierBytes == ogDozenBytes) {
                stats.ogDozen = true;
            } else if (tierBytes == memeBytes) {
                stats.meme = true;
            } else if (tierBytes == honoraryBytes) {
                stats.honorary = true;
            } 
        }

        return stats;
    }
}