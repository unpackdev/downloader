// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./CosmoArtPowerERC20.sol";

interface ICosmoArtShort {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint256);
    function isMintedBeforeReveal(uint256 index) external view returns (bool);
}


/**
 * CosmoArtPower Contract (The native token of CosmoArt)
 * https://thecosmoart.com/
 * @dev Extends standard ERC20 contract
 */
contract CosmoArtPower is Ownable, CosmoArtPowerERC20 {
    using SafeMath for uint256;

    // Constants
    uint256 public constant SECONDS_IN_A_DAY = 86400;
    uint256 public constant INITIAL_ALLOTMENT = 183e18;
    uint256 public constant PRE_REVEAL_MULTIPLIER = 2;

    uint256 public constant emissionStart = 1627484400; // 2021-07-28T15:00:00.000Z"
    uint256 public constant emissionEnd = 1942844400; // "2031-07-26T15:00:00.000Z" // emissionStartTimestamp + (SECONDS_IN_A_DAY * 365 * 10)
    uint256 public constant emissionPerDay = 1e18;
    mapping(uint256 => uint256) private _lastClaim;


    constructor() public CosmoArtPowerERC20("CosmoArt Power", "CAP") {
        _setURL("https://thecosmoart.com/");
    }

    /**
     * @dev When accumulated CAPs have last been claimed for a CosmoMask index
     */
    function lastClaim(uint256 tokenIndex) public view returns (uint256) {
        require(ICosmoArtShort(nftAddress).ownerOf(tokenIndex) != address(0), "CosmoArtPower: owner cannot be 0 address");
        require(tokenIndex < ICosmoArtShort(nftAddress).totalSupply(), "CosmoArtPower: CosmoArt at index has not been minted yet");

        uint256 lastClaimed = uint256(_lastClaim[tokenIndex]) != 0
            ? uint256(_lastClaim[tokenIndex])
            : emissionStart;
        return lastClaimed;
    }

    /**
     * @dev Accumulated CAP tokens for a CosmoMask token index.
     */
    function accumulated(uint256 tokenIndex) public view returns (uint256) {
        require(block.timestamp > emissionStart, "CosmoArtPower: emission has not started yet");
        require(ICosmoArtShort(nftAddress).ownerOf(tokenIndex) != address(0), "CosmoArtPower: owner cannot be 0 address");
        require(tokenIndex < ICosmoArtShort(nftAddress).totalSupply(), "CosmoArtPower: CosmoArt at index has not been minted yet");

        uint256 lastClaimed = lastClaim(tokenIndex);

        // Sanity check if last claim was on or after emission end
        if (lastClaimed >= emissionEnd)
            return 0;

        // Getting the min value of both
        uint256 accumulationPeriod = block.timestamp < emissionEnd ? block.timestamp : emissionEnd;
        uint256 totalAccumulated = accumulationPeriod.sub(lastClaimed).mul(emissionPerDay).div(SECONDS_IN_A_DAY);

        // If claim hasn't been done before for the index, add initial allotment (plus prereveal multiplier if applicable)
        if (lastClaimed == emissionStart) {
            uint256 initialAllotment = ICosmoArtShort(nftAddress).isMintedBeforeReveal(tokenIndex) == true
                ? INITIAL_ALLOTMENT.mul(PRE_REVEAL_MULTIPLIER)
                : INITIAL_ALLOTMENT;
            totalAccumulated = totalAccumulated.add(initialAllotment);
        }

        return totalAccumulated;
    }

    /**
     * @dev Permissioning not added because it is only callable once. It is set right after deployment and verified.
     */
    function setNftAddress(address _nftAddress) public onlyOwner {
        require(nftAddress == address(0), "CosmoArt: NFT has already setted");
        require(_nftAddress != address(0), "CosmoArt: new NFT is the zero address");
        nftAddress = _nftAddress;
    }

    /**
     * @dev Claim mints CAPs and supports multiple CosmoMask token indices at once.
     */
    function claim(uint256[] memory tokenIndices) public returns (uint256) {
        require(block.timestamp > emissionStart, "CosmoArtPower: Emission has not started yet");

        uint256 totalClaimQty = 0;
        for (uint256 i = 0; i < tokenIndices.length; i++) {
            // Sanity check for non-minted index
            require(tokenIndices[i] < ICosmoArtShort(nftAddress).totalSupply(), "CosmoArtPower: CosmoArt at index has not been minted yet");
            // Duplicate token index check
            for (uint256 j = i + 1; j < tokenIndices.length; j++)
                require(tokenIndices[i] != tokenIndices[j], "CosmoArtPower: duplicate token index" );

            uint256 tokenIndex = tokenIndices[i];
            require(ICosmoArtShort(nftAddress).ownerOf(tokenIndex) == msg.sender, "CosmoArtPower: sender is not the owner");

            uint256 claimQty = accumulated(tokenIndex);
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty.add(claimQty);
                _lastClaim[tokenIndex] = block.timestamp;
            }
        }

        require(totalClaimQty != 0, "CosmoArtPower: no accumulated tokens");
        _mint(msg.sender, totalClaimQty);
        return totalClaimQty;
    }

    function setURL(string memory newUrl) public onlyOwner {
        _setURL(newUrl);
    }
}
