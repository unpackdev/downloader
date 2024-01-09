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
    bool public stakingActive = false;

    struct StakedInfo {
        address owner;
        uint256 unlockTs;
        uint256 reward;
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
     * @param lockMods The period to lock each token (1 = 15 days, 2 = 30 days...).
     * @notice The staking reward is proportional to the staking duration.
     */
    function stakeLions(uint256[] memory tokenIds, uint256[] memory lockMods) external {
        require(stakingActive, "FangsToken: Staking not active");
        require(tokenIds.length == lockMods.length, "FangsToken: Invalid lengths");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 lockMod = lockMods[i];
            require(lockMod > 0 && lockMod < 5, "FangsToken: Must lock for 15, 30, 45 or 60 days");
            uint256 tokenId = tokenIds[i];
            lionsToken.transferFrom(msg.sender, address(this), tokenId);
            tokenStakedInfo[tokenId] = StakedInfo(msg.sender, block.timestamp + (15 days * lockMod), DAY_15_RATE * lockMod);
        }
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
            require(block.timestamp > info.unlockTs, "FangsToken: Lion still locked");
            delete tokenStakedInfo[tokenId];
            reward += info.reward;
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
     * List all the staked and claimable lions owned by the given address.
     * @dev This is NOT gas efficient as so I highly recommend NOT integrating to this
     * @dev interface in other contracts, except when read only.
     */
    function listClaimableLionsOfOwner(address owner) external view returns (uint256[] memory) {
        uint256[] memory tokenIds = listStakedLionsOfOwner(owner);
        uint256[] memory claimable = new uint256[](tokenIds.length);
        uint256 count = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            StakedInfo memory info = tokenStakedInfo[tokenIds[i]];
            if (block.timestamp > info.unlockTs) {
                claimable[count] = tokenIds[i];
                count++;
            }
        }
        return resizeArray(claimable, count);
    }

    /**
     * Return the claimable fangs balance for the given address.
     * @dev This is NOT gas efficient as so I highly recommend NOT integrating to this
     * @dev interface in other contracts, except when read only.
     */
    function claimableBalanceOfOwner(address owner) external view returns (uint256) {
        uint256 claimable = 0;
        uint256[] memory tokenIds = listStakedLionsOfOwner(owner);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            StakedInfo memory info = tokenStakedInfo[tokenIds[i]];
            if (block.timestamp > info.unlockTs) {
                claimable += info.reward;
            }
        }
        if (claimable + totalSupply() > MAX_SUPPLY) {
            claimable = MAX_SUPPLY - totalSupply();
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
