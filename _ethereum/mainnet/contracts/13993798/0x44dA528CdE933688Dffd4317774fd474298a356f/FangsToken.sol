// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Fangs Token
/// @author @MilkyTasteEth MilkyTaste:8662 https://milkytaste.xyz
/// https://www.hawaiianlions.world/

import "./Ownable.sol";
import "./ERC20.sol";

import "./IHawaiianLionsToken.sol";

contract FangsToken is ERC20, Ownable {
    IHawaiianLionsToken public immutable lionsToken;

    uint256 public constant DAY_15_RATE = 5 * 15;
    uint256 public constant MAX_SUPPLY = 100000;
    uint8[5] public rateMultipliers = [0, 100, 112, 125, 150];
    bool public stakingActive = false;

    struct StakedInfo {
        address owner;
        uint256 lockedAt;
    }

    mapping(uint256 => StakedInfo) public tokenStakedInfo;

    constructor(address _lionsAddress) ERC20("Fangs", "FANG") {
        lionsToken = IHawaiianLionsToken(_lionsAddress);
        _mint(0x6716D41029631116c5245096c46b04aca47D0Bd0, MAX_SUPPLY / 10);
    }

    /**
     * Cannot fractionalise a $FANG.
     */
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    /**
     * Stake lions.
     * @param tokenIds The lion tokens to be staked.
     * @notice The staking reward is proportional to the staking duration.
     */
    function stakeLions(uint256[] memory tokenIds) external {
        require(stakingActive, "FangsToken: Staking not active");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            lionsToken.transferFrom(msg.sender, address(this), tokenId);
            tokenStakedInfo[tokenId] = StakedInfo(msg.sender, block.timestamp);
        }
    }

    function calculateReward(uint256 lockedAt) public view returns (uint256) {
        uint256 period = (block.timestamp - lockedAt) / 15 days;
        uint8 multiplier = rateMultipliers[period > 4 ? 4 : period];
        return DAY_15_RATE * period *  multiplier / 100;
    }

    /**
     * Unstake a lion and claim the fangs reward.
     */
    function unstakeAndClaim(uint256[] memory tokenIds) external {
        uint256 reward = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            StakedInfo memory info = tokenStakedInfo[tokenId];
            require(info.owner == msg.sender, "FangsToken: Only owner can unstake");
            delete tokenStakedInfo[tokenId];
            reward += calculateReward(info.lockedAt);
            // Send lion back
            lionsToken.transferFrom(address(this), msg.sender, tokenId);
        }
        // Claim tokens
        if (reward + totalSupply() > MAX_SUPPLY) {
            reward = MAX_SUPPLY - totalSupply();
        }
        _mint(msg.sender, reward);
    }

    /**
     * Enable/disable staking
     */
    function setStakingActive(bool _stakingActive) external onlyOwner {
        stakingActive = _stakingActive;
    }

    // Helper functions

    /**
     * List all the unstaked lions owned by the given address.
     * @notice This is here because I didn't add enumerable in the original contract... :shrug:
     * @dev This is NOT gas efficient as so I highly recommend NOT integrating to this
     * @dev interface in other contracts, except when read only.
     */
    function listUnstakedLionsOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 lionsSupply = lionsToken.totalSupply();
        uint256[] memory tokenIds = new uint256[](lionsSupply);
        uint256 count = 0;
        for (uint256 tokenId = 1; tokenId <= lionsSupply; tokenId++) {
            if (lionsToken.ownerOf(tokenId) == owner){
                tokenIds[count] = tokenId;
                count++;
            }
        }
        return resizeArray(tokenIds, count);
    }

    /**
     * List all the staked lions owned by the given address.
     * @dev This is NOT gas efficient as so I highly recommend NOT integrating to this
     * @dev interface in other contracts, except when read only.
     */
    function listStakedLionsOfOwner(address owner) public view returns (uint256[] memory){
        uint256 lionsSupply = lionsToken.totalSupply();
        uint256[] memory tokenIds = new uint256[](lionsSupply);
        uint256 count = 0;
        for (uint256 tokenId = 1; tokenId <= lionsSupply; tokenId++) {
            StakedInfo memory info = tokenStakedInfo[tokenId];
            if (info.owner == owner){
                tokenIds[count] = tokenId;
                count++;
            }
        }
        return resizeArray(tokenIds, count);
    }

    /**
     * List all the rewards for staked lions owned by the given address.
     * @dev This is NOT gas efficient as so I highly recommend NOT integrating to this
     * @dev interface in other contracts, except when read only.
     */
    function listClaimableRewardsOfOwner(address owner) external view returns (uint256[] memory) {
        uint256[] memory tokenIds = listStakedLionsOfOwner(owner);
        uint256[] memory claimable = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            StakedInfo memory info = tokenStakedInfo[tokenIds[i]];
            claimable[i] = calculateReward(info.lockedAt);
        }
        return claimable;
    }

    /**
     * Helper function to resize an array.
     */
    function resizeArray(uint256[] memory input, uint256 length) public pure returns (uint256[] memory) {
        uint256[] memory output = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            output[i] = input[i];
        }
        return output;
    }
}
