
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20PresetMinterPauser.sol";
import "./ERC721Enumerable.sol";

/**
 * @title SOUR Token - Native Token of UncoolCats
 * @dev ERC20 from OpenZeppelin
 */
contract SourMilk is ERC20PresetMinterPauser("Sour Milk", "SOUR") {
    // @notice 10 SOUR a day keeps the doctor away
    uint256 public constant DAILY_EMISSION = 10 ether;

    /// @notice Start date for SOUR emissions from contract deployment
    uint256 public immutable emissionStart;

    /// @notice End date for SOUR emissions to Uncool Cat holders
    uint256 public immutable emissionEnd;

    /// @dev A record of last claimed timestamp for UncoolCat holders
    mapping(uint256 => uint256) private _lastClaim;

    /// @dev Contract address for Uncool Cats
    address private _nftAddress;

    /**
     * @notice Construct the SOUR token
     * @param emissionStartTimestamp Timestamp of deployment
     */
    constructor(uint256 emissionStartTimestamp) {
        emissionStart = emissionStartTimestamp;
        emissionEnd = emissionStartTimestamp + (1 days * 365 * 3); //3 years
    }

    // External functions
    /**
     * @notice Set the contract address to the appropriate ERC-721 token contract
     * @param nftAddress Address of verified Uncool Cats contract
     * @dev Only callable once
     */
    function setNFTAddress(address nftAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_nftAddress == address(0), "Already set");
        _nftAddress = nftAddress;
    }

    // Public functions
    /**
     * @notice Check last claim timestamp of accumulated SOUR for given Uncool Cat
     * @param tokenIndex Index of Uncool Cat NFT
     * @return Last claim timestamp
     */
    function getLastClaim(uint256 tokenIndex) public view returns (uint256) {
        require(tokenIndex <= ERC721Enumerable(_nftAddress).totalSupply(), "NFT at index not been minted");
        require(ERC721Enumerable(_nftAddress).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        uint256 lastClaimed = uint256(_lastClaim[tokenIndex]) != 0 ? uint256(_lastClaim[tokenIndex]) : emissionStart;
        return lastClaimed;
    }

    /**
     * @notice Check accumulated SOUR tokens for an UncoolCat NFT
     * @param tokenIndex Index of Uncool Cat NFT
     * @return Total SOUR accumulated and ready to claim
     */
    function accumulated(uint256 tokenIndex) public view returns (uint256) {
        require(block.timestamp > emissionStart, "Emission has not started yet");

        uint256 lastClaimed = getLastClaim(tokenIndex);
        // Sanity check if last claim was on or after emission end
        if (lastClaimed >= emissionEnd) return 0;

        uint256 accumulationPeriod = block.timestamp < emissionEnd ? block.timestamp : emissionEnd; // Getting the min value of both
        uint256 totalAccumulated = ((accumulationPeriod - lastClaimed) * DAILY_EMISSION) / 1 days;
        return totalAccumulated;
    }

    /**
     * @notice Check total SOUR tokens for all UncoolCat NFTs
     * @param tokenIndices Indexes of NFTs to check balance
     * @return Total SOUR accumulated and ready to claim
     */
    function accumulatedMultiCheck(uint256[] memory tokenIndices) public view returns (uint256) {
        require(block.timestamp > emissionStart, "Emission has not started yet");
        uint256 totalClaimableQty = 0;
        for (uint256 i = 0; i < tokenIndices.length; i++) {
            uint256 tokenIndex = tokenIndices[i];
            // Sanity check for non-minted index
            require(tokenIndex <= ERC721Enumerable(_nftAddress).totalSupply(), "NFT at index not been minted");
            uint256 claimableQty = accumulated(tokenIndex);
            totalClaimableQty = totalClaimableQty + claimableQty;
        }
        return totalClaimableQty;
    }

    /**
     * @notice Mint and claim available SOUR for each unCool Cat
     * @param tokenIndices Indexes of NFTs to claim for
     * @return Total SOUR claimed
     */
    function claim(uint256[] memory tokenIndices) public returns (uint256) {
        require(block.timestamp > emissionStart, "Emission has not started yet");

        uint256 totalClaimQty = 0;
        for (uint256 i = 0; i < tokenIndices.length; i++) {
            // Sanity check for non-minted index
            require(tokenIndices[i] <= ERC721Enumerable(_nftAddress).totalSupply(), "NFT at index not been minted");
            // Duplicate token index check
            for (uint256 j = i + 1; j < tokenIndices.length; j++) {
                require(tokenIndices[i] != tokenIndices[j], "Duplicate token index");
            }

            uint256 tokenIndex = tokenIndices[i];
            require(ERC721Enumerable(_nftAddress).ownerOf(tokenIndex) == _msgSender(), "Sender is not the owner");

            uint256 claimQty = accumulated(tokenIndex);
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty + claimQty;
                _lastClaim[tokenIndex] = block.timestamp;
            }
        }

        require(totalClaimQty != 0, "No accumulated SOUR");
        _mint(_msgSender(), totalClaimQty);
        return totalClaimQty;
    }
}