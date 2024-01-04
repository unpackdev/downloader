// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./CosmoMasksPowerERC20.sol";

interface ICosmoMasksShort {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint256);
    function isMintedBeforeReveal(uint256 index) external view returns (bool);
}


/**
 * CosmoMasksPower Contract (The native token of CosmoMasks)
 * https://TheCosmoMasks.com/
 * @dev Extends standard ERC20 contract
 */
contract CosmoMasksPower is Ownable, CosmoMasksPowerERC20 {
    using SafeMath for uint256;

    // Constants
    uint256 public constant SECONDS_IN_A_DAY = 86400;
    uint256 public constant INITIAL_ALLOTMENT = 1830e18;
    uint256 public constant PRE_REVEAL_MULTIPLIER = 2;

    uint256 public constant emissionStart = 1615734000; // "2021-03-14T15:00:00.000Z"
    uint256 public constant emissionEnd = 1931094000; // "2031-03-12T15:00:00.000Z" // emissionStartTimestamp + (SECONDS_IN_A_DAY * 365 * 10)
    uint256 public constant emissionPerDay = 10e18;
    mapping(uint256 => uint256) private _lastClaim;


    constructor() public CosmoMasksPowerERC20("CosmoMasks Power", "CMP") {
        _setURL("https://TheCosmoMasks.com/");
    }

    /**
     * @dev When accumulated CMPs have last been claimed for a CosmoMask index
     */
    function lastClaim(uint256 tokenIndex) public view returns (uint256) {
        require(ICosmoMasksShort(cosmoMasksAddress).ownerOf(tokenIndex) != address(0), "CosmoMasksPower: owner cannot be 0 address");
        require(tokenIndex < ICosmoMasksShort(cosmoMasksAddress).totalSupply(), "CosmoMasksPower: CosmoMasks at index has not been minted yet");

        uint256 lastClaimed = uint256(_lastClaim[tokenIndex]) != 0
            ? uint256(_lastClaim[tokenIndex])
            : emissionStart;
        return lastClaimed;
    }

    /**
     * @dev Accumulated CMP tokens for a CosmoMask token index.
     */
    function accumulated(uint256 tokenIndex) public view returns (uint256) {
        require(block.timestamp > emissionStart, "CosmoMasksPower: emission has not started yet");
        require(ICosmoMasksShort(cosmoMasksAddress).ownerOf(tokenIndex) != address(0), "CosmoMasksPower: owner cannot be 0 address");
        require(tokenIndex < ICosmoMasksShort(cosmoMasksAddress).totalSupply(), "CosmoMasksPower: CosmoMasks at index has not been minted yet");

        uint256 lastClaimed = lastClaim(tokenIndex);

        // Sanity check if last claim was on or after emission end
        if (lastClaimed >= emissionEnd)
            return 0;

        // Getting the min value of both
        uint256 accumulationPeriod = block.timestamp < emissionEnd ? block.timestamp : emissionEnd;
        uint256 totalAccumulated = accumulationPeriod.sub(lastClaimed).mul(emissionPerDay).div(SECONDS_IN_A_DAY);

        // If claim hasn't been done before for the index, add initial allotment (plus prereveal multiplier if applicable)
        if (lastClaimed == emissionStart) {
            uint256 initialAllotment = ICosmoMasksShort(cosmoMasksAddress).isMintedBeforeReveal(tokenIndex) == true
                ? INITIAL_ALLOTMENT.mul(PRE_REVEAL_MULTIPLIER)
                : INITIAL_ALLOTMENT;
            totalAccumulated = totalAccumulated.add(initialAllotment);
        }

        return totalAccumulated;
    }

    /**
     * @dev Permissioning not added because it is only callable once. It is set right after deployment and verified.
     */
    function setCosmoMasksAddress(address masksAddress) public onlyOwner {
        require(cosmoMasksAddress == address(0), "CosmoMasks: CosmoMasks has already setted");
        require(masksAddress != address(0), "CosmoMasks: CosmoMasks is the zero address");
        cosmoMasksAddress = masksAddress;
    }

    /**
     * @dev Claim mints CMPs and supports multiple CosmoMask token indices at once.
     */
    function claim(uint256[] memory tokenIndices) public returns (uint256) {
        require(block.timestamp > emissionStart, "CosmoMasksPower: Emission has not started yet");

        uint256 totalClaimQty = 0;
        for (uint256 i = 0; i < tokenIndices.length; i++) {
            // Sanity check for non-minted index
            require(tokenIndices[i] < ICosmoMasksShort(cosmoMasksAddress).totalSupply(), "CosmoMasksPower: CosmoMasks at index has not been minted yet");
            // Duplicate token index check
            for (uint256 j = i + 1; j < tokenIndices.length; j++)
                require(tokenIndices[i] != tokenIndices[j], "CosmoMasksPower: duplicate token index" );

            uint256 tokenIndex = tokenIndices[i];
            require(ICosmoMasksShort(cosmoMasksAddress).ownerOf(tokenIndex) == msg.sender, "CosmoMasksPower: sender is not the owner");

            uint256 claimQty = accumulated(tokenIndex);
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty.add(claimQty);
                _lastClaim[tokenIndex] = block.timestamp;
            }
        }

        require(totalClaimQty != 0, "CosmoMasksPower: no accumulated tokens");
        _mint(msg.sender, totalClaimQty);
        return totalClaimQty;
    }

    function setURL(string memory newUrl) public onlyOwner {
        _setURL(newUrl);
    }
}
