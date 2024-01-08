// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./CosmoDoodlePowerERC20.sol";

interface ICosmoDoodleShort {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint256);
    function isMintedBeforeReveal(uint256 index) external view returns (bool);
}


/**
 * CosmoDoodlePower Contract (The native token of CosmoDoodle)
 * https://thecosmodoodle.com/
 * @dev Extends standard ERC20 contract
 */
contract CosmoDoodlePower is Ownable, CosmoDoodlePowerERC20 {
    using SafeMath for uint256;

    // Constants
    uint256 public constant SECONDS_IN_A_DAY = 86400;
    uint256 public constant INITIAL_ALLOTMENT = 1_830e18;
    uint256 public constant PRE_REVEAL_MULTIPLIER = 2;

    uint256 public constant emissionStart = 1625410800; // "2021-07-04T15:00:00.000Z"
    uint256 public constant emissionEnd = 1940770800; // "2031-07-02T15:00:00.000Z" // emissionStartTimestamp + (SECONDS_IN_A_DAY * 365 * 10)
    uint256 public constant emissionPerDay = 10e18;
    mapping(uint256 => uint256) private _lastClaim;


    constructor() public CosmoDoodlePowerERC20("CosmoDoodle Power", "CDP") {
        _setURL("https://thecosmodoodle.com/");
    }

    /**
     * @dev When accumulated CDPs have last been claimed for a CosmoMask index
     */
    function lastClaim(uint256 tokenIndex) public view returns (uint256) {
        require(ICosmoDoodleShort(nftAddress).ownerOf(tokenIndex) != address(0), "CosmoDoodlePower: owner cannot be 0 address");
        require(tokenIndex < ICosmoDoodleShort(nftAddress).totalSupply(), "CosmoDoodlePower: CosmoDoodle at index has not been minted yet");

        uint256 lastClaimed = uint256(_lastClaim[tokenIndex]) != 0
            ? uint256(_lastClaim[tokenIndex])
            : emissionStart;
        return lastClaimed;
    }

    /**
     * @dev Accumulated CDP tokens for a CosmoMask token index.
     */
    function accumulated(uint256 tokenIndex) public view returns (uint256) {
        require(block.timestamp > emissionStart, "CosmoDoodlePower: emission has not started yet");
        require(ICosmoDoodleShort(nftAddress).ownerOf(tokenIndex) != address(0), "CosmoDoodlePower: owner cannot be 0 address");
        require(tokenIndex < ICosmoDoodleShort(nftAddress).totalSupply(), "CosmoDoodlePower: CosmoDoodle at index has not been minted yet");

        uint256 lastClaimed = lastClaim(tokenIndex);

        // Sanity check if last claim was on or after emission end
        if (lastClaimed >= emissionEnd)
            return 0;

        // Getting the min value of both
        uint256 accumulationPeriod = block.timestamp < emissionEnd ? block.timestamp : emissionEnd;
        uint256 totalAccumulated = accumulationPeriod.sub(lastClaimed).mul(emissionPerDay).div(SECONDS_IN_A_DAY);

        // If claim hasn't been done before for the index, add initial allotment (plus prereveal multiplier if applicable)
        if (lastClaimed == emissionStart) {
            uint256 initialAllotment = ICosmoDoodleShort(nftAddress).isMintedBeforeReveal(tokenIndex) == true
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
        require(nftAddress == address(0), "CosmoDoodle: NFT has already setted");
        require(_nftAddress != address(0), "CosmoDoodle: new NFT is the zero address");
        nftAddress = _nftAddress;
    }

    /**
     * @dev Claim mints CDPs and supports multiple CosmoMask token indices at once.
     */
    function claim(uint256[] memory tokenIndices) public returns (uint256) {
        require(block.timestamp > emissionStart, "CosmoDoodlePower: Emission has not started yet");

        uint256 totalClaimQty = 0;
        for (uint256 i = 0; i < tokenIndices.length; i++) {
            // Sanity check for non-minted index
            require(tokenIndices[i] < ICosmoDoodleShort(nftAddress).totalSupply(), "CosmoDoodlePower: CosmoDoodle at index has not been minted yet");
            // Duplicate token index check
            for (uint256 j = i + 1; j < tokenIndices.length; j++)
                require(tokenIndices[i] != tokenIndices[j], "CosmoDoodlePower: duplicate token index" );

            uint256 tokenIndex = tokenIndices[i];
            require(ICosmoDoodleShort(nftAddress).ownerOf(tokenIndex) == msg.sender, "CosmoDoodlePower: sender is not the owner");

            uint256 claimQty = accumulated(tokenIndex);
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty.add(claimQty);
                _lastClaim[tokenIndex] = block.timestamp;
            }
        }

        require(totalClaimQty != 0, "CosmoDoodlePower: no accumulated tokens");
        _mint(msg.sender, totalClaimQty);
        return totalClaimQty;
    }

    function setURL(string memory newUrl) public onlyOwner {
        _setURL(newUrl);
    }
}
