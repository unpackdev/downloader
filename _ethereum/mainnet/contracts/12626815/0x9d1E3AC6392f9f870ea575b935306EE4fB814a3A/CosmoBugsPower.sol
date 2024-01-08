// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./CosmoBugsPowerERC20.sol";

interface ICosmoBugsShort {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint256);
    function isMintedBeforeReveal(uint256 index) external view returns (bool);
}


/**
 * CosmoBugsPower Contract (The native token of CosmoBugs)
 * https://cosmobugs.com/
 * @dev Extends standard ERC20 contract
 */
contract CosmoBugsPower is Ownable, CosmoBugsPowerERC20 {
    using SafeMath for uint256;

    // Constants
    uint256 public constant SECONDS_IN_A_DAY = 86400;
    uint256 public constant INITIAL_ALLOTMENT = 1_830e18;
    uint256 public constant PRE_REVEAL_MULTIPLIER = 2;

    uint256 public constant emissionStart = 1623682800; // "2021-06-14T15:00:00.000Z"
    uint256 public constant emissionEnd = 1939042800; // "2031-06-12T15:00:00.000Z" // emissionStartTimestamp + (SECONDS_IN_A_DAY * 365 * 10)
    uint256 public constant emissionPerDay = 10e18;
    mapping(uint256 => uint256) private _lastClaim;


    constructor() public CosmoBugsPowerERC20("CosmoBugs Power", "CBP") {
        _setURL("https://cosmobugs.com/");
    }

    /**
     * @dev When accumulated CBPs have last been claimed for a CosmoMask index
     */
    function lastClaim(uint256 tokenIndex) public view returns (uint256) {
        require(ICosmoBugsShort(nftAddress).ownerOf(tokenIndex) != address(0), "CosmoBugsPower: owner cannot be 0 address");
        require(tokenIndex < ICosmoBugsShort(nftAddress).totalSupply(), "CosmoBugsPower: CosmoBugs at index has not been minted yet");

        uint256 lastClaimed = uint256(_lastClaim[tokenIndex]) != 0
            ? uint256(_lastClaim[tokenIndex])
            : emissionStart;
        return lastClaimed;
    }

    /**
     * @dev Accumulated CBP tokens for a CosmoMask token index.
     */
    function accumulated(uint256 tokenIndex) public view returns (uint256) {
        require(block.timestamp > emissionStart, "CosmoBugsPower: emission has not started yet");
        require(ICosmoBugsShort(nftAddress).ownerOf(tokenIndex) != address(0), "CosmoBugsPower: owner cannot be 0 address");
        require(tokenIndex < ICosmoBugsShort(nftAddress).totalSupply(), "CosmoBugsPower: CosmoBugs at index has not been minted yet");

        uint256 lastClaimed = lastClaim(tokenIndex);

        // Sanity check if last claim was on or after emission end
        if (lastClaimed >= emissionEnd)
            return 0;

        // Getting the min value of both
        uint256 accumulationPeriod = block.timestamp < emissionEnd ? block.timestamp : emissionEnd;
        uint256 totalAccumulated = accumulationPeriod.sub(lastClaimed).mul(emissionPerDay).div(SECONDS_IN_A_DAY);

        // If claim hasn't been done before for the index, add initial allotment (plus prereveal multiplier if applicable)
        if (lastClaimed == emissionStart) {
            uint256 initialAllotment = ICosmoBugsShort(nftAddress).isMintedBeforeReveal(tokenIndex) == true
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
        require(nftAddress == address(0), "CosmoBugs: NFT has already setted");
        require(_nftAddress != address(0), "CosmoBugs: new NFT is the zero address");
        nftAddress = _nftAddress;
    }

    /**
     * @dev Claim mints CBPs and supports multiple CosmoMask token indices at once.
     */
    function claim(uint256[] memory tokenIndices) public returns (uint256) {
        require(block.timestamp > emissionStart, "CosmoBugsPower: Emission has not started yet");

        uint256 totalClaimQty = 0;
        for (uint256 i = 0; i < tokenIndices.length; i++) {
            // Sanity check for non-minted index
            require(tokenIndices[i] < ICosmoBugsShort(nftAddress).totalSupply(), "CosmoBugsPower: CosmoBugs at index has not been minted yet");
            // Duplicate token index check
            for (uint256 j = i + 1; j < tokenIndices.length; j++)
                require(tokenIndices[i] != tokenIndices[j], "CosmoBugsPower: duplicate token index" );

            uint256 tokenIndex = tokenIndices[i];
            require(ICosmoBugsShort(nftAddress).ownerOf(tokenIndex) == msg.sender, "CosmoBugsPower: sender is not the owner");

            uint256 claimQty = accumulated(tokenIndex);
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty.add(claimQty);
                _lastClaim[tokenIndex] = block.timestamp;
            }
        }

        require(totalClaimQty != 0, "CosmoBugsPower: no accumulated tokens");
        _mint(msg.sender, totalClaimQty);
        return totalClaimQty;
    }

    function setURL(string memory newUrl) public onlyOwner {
        _setURL(newUrl);
    }
}
