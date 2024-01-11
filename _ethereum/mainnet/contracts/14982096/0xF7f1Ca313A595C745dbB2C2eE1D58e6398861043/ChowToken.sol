// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Chow Token
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://www.nlbnft.com/

import "./Ownable.sol";
import "./ERC20.sol";
import "./ECDSA.sol";
import "./INLBNFT.sol";

contract ChowToken is ERC20, Ownable {
    using ECDSA for bytes32;

    INLBNFT public immutable nlbToken;
    address public signer; // Used for off chain utility
    mapping(address => bool) public isUtilityAddr;

    uint256 public dailyRate = 5 * 10**decimals();
    bool public stakingActive = false;
    uint64 public rewardDoubledBefore;
    mapping(uint256 => bool) public isLegendary;
    uint256 private genesisCutOff = 1000;

    struct StakedInfo {
        address owner;
        uint64 lockedAt;
    }

    mapping(uint256 => StakedInfo) public tokenStakedInfo;
    mapping(address => uint64) public utilityNonce; // Prevent replay attacks

    constructor(address nlbAddress) ERC20("Chow", "CHOW") {
        nlbToken = INLBNFT(nlbAddress);
        rewardDoubledBefore = uint64(block.timestamp + 30 days);
    }

    //
    // Staking
    //

    /**
     * Stake NLB tokens.
     * @param tokenIds The tokens to be staked.
     */
    function stake(uint256[] memory tokenIds) external {
        require(stakingActive, "ChowToken: Staking not active");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            nlbToken.transferFrom(msg.sender, address(this), tokenId);
            tokenStakedInfo[tokenId] = StakedInfo(msg.sender, uint64(block.timestamp));
        }
    }

    /**
     * Unstake tokens.
     * @param tokenIds The tokens to unstake.
     * @notice Unstaking voids any unclaimed rewards.
     */
    function unstake(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // Check staking info
            StakedInfo memory info = tokenStakedInfo[tokenId];
            require(info.owner == msg.sender, "ChowToken: Only owner can unstake");
            delete tokenStakedInfo[tokenId];
            // Send it back
            nlbToken.transferFrom(address(this), msg.sender, tokenId);
        }
    }

    //
    // Chow rewards
    //

    /**
     * Claim earned rewards.
     * @param tokenIds The tokens to claim rewards for.
     * @notice Only the owner can claim the associated rewards.
     */
    function claim(uint256[] memory tokenIds) external {
        uint256 reward = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // Check staking info
            StakedInfo memory info = tokenStakedInfo[tokenId];
            require(info.owner == msg.sender, "ChowToken: Only owner can claim rewards");
            reward += calculateReward(tokenId, info.lockedAt);
            // Update reward timer
            tokenStakedInfo[tokenId].lockedAt = uint64(block.timestamp);
        }
        // Claim tokens
        _mint(msg.sender, reward);
    }

    /**
     * Calculate the currently earned reward.
     * @param lockedAt The time the token was locked.
     * @return reward The amount of CHOW earned for this lock duration.
     */
    function calculateReward(uint256 tokenId, uint64 lockedAt) public view returns (uint256) {
        uint256 rate = dailyRate;
        if (isLegendary[tokenId]) {
            // Legendary tokens earn an extra 10 per day
            rate += 10 * 10**decimals();
        } else if (tokenId < genesisCutOff) {
            // Non legendary genesis earn an extra 5 per day
            rate += 5 * 10**decimals();
        }
        if (lockedAt < rewardDoubledBefore) {
            // Reward doubles if staked before this time
            rate *= 2;
        }
        uint256 reward = ((block.timestamp - lockedAt) * rate) / 1 days;
        return reward;
    }

    //
    // Signer locked
    //

    /**
     * Checks for a valid signature against the stored signer.
     * @param data The message content.
     * @param signature The signed message.
     */
    modifier signed(bytes memory data, bytes calldata signature) {
        require(_verify(data, signature, signer), "ChowToken: Signature not valid");
        _;
    }

    /**
     * Checks for a valid nonce against the account, and increments it after the call.
     * @param account The caller.
     * @param nonce The expected nonce.
     */
    modifier useNonce(address account, uint64 nonce) {
        require(utilityNonce[account] == nonce, "ChowToken: Nonce not valid");
        _;
        utilityNonce[account]++;
    }

    /**
     * Burn CHOW.
     * @param amount The amount to burn.
     * @param nonce The utility nonce value.
     * @param maxTime The max time this burn event can be processed.
     * @param signature The server signed message.
     * @notice This method can only be called with a server signed message.
     * @dev This method does NOT add decimals.
     */
    function burn(
        uint256 amount,
        uint64 nonce,
        uint64 maxTime,
        bytes calldata signature
    ) external useNonce(msg.sender, nonce) signed(abi.encodePacked(msg.sender, nonce, maxTime, amount), signature) {
        require(maxTime > block.timestamp, "ChowToken: Max time exceeded");
        _burn(msg.sender, amount);
    }

    //
    // Utility locked
    //

    /**
     * Checks the call was made from a utility address.
     */
    modifier fromUtility() {
        require(isUtilityAddr[msg.sender], "ChowToken: Not utility address");
        _;
    }

    /**
     * Mint CHOW from a utility address.
     * @param addr The address to mint to.
     * @param amount The amount to mint.
     * @dev This method does NOT add decimals.
     */
    function utilityMint(address addr, uint256 amount) external fromUtility {
        _mint(addr, amount);
    }

    /**
     * Burn CHOW from a utility address.
     * @param addr The address to burn from.
     * @param amount The amount to burn.
     * @dev This method does NOT add decimals.
     */
    function utilityBurn(address addr, uint256 amount) external fromUtility {
        _burn(addr, amount);
    }

    //
    // Admin
    //

    /**
     * Enable / disable staking.
     * @param _stakingActive The new staking status.
     */
    function setStakingActive(bool _stakingActive) external onlyOwner {
        stakingActive = _stakingActive;
    }

    /**
     * Update the daily rate.
     * @param _dailyRate The new amount earned per day.
     * @dev This method will automatically add the correct amount of decimal places.
     */
    function setDailyRate(uint256 _dailyRate) external onlyOwner {
        dailyRate = _dailyRate * 10**decimals();
    }

    /**
     * Update the staking reward doubling timestamp.
     * @param _rewardDoubledBefore The new timestamp for doubling staking rewards.
     */
    function setRewardDoubledBefore(uint64 _rewardDoubledBefore) external onlyOwner {
        rewardDoubledBefore = _rewardDoubledBefore;
    }

    /**
     * Update the utility signer.
     * @param _signer The new utility signing address.
     */
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /**
     * Update the genesis cut off token id.
     * @param _genesisCutOff The new genesis cut off.
     */
    function setGenesisCutOff(uint256 _genesisCutOff) external onlyOwner {
        genesisCutOff = _genesisCutOff;
    }

    /**
     * Toggle the list of legendary ids.
     * @param legendaryIds The list of legendary ids to be toggled.
     * @dev This can be used to set an unset the legendaries list.
     */
    function toggleLegendaries(uint256[] calldata legendaryIds) external onlyOwner {
        for (uint256 i = 0; i < legendaryIds.length; i++) {
            isLegendary[legendaryIds[i]] = !isLegendary[legendaryIds[i]];
        }
    }

    /**
     * Toggle the an address as a utility address.
     * @param addr The utility address to toggle.
     * @dev This can be used to set an unset the utility address.
     */
    function toggleUtilityAddr(address addr) external onlyOwner {
        isUtilityAddr[addr] = !isUtilityAddr[addr];
    }

    /**
     * Airdrop tokens.
     * @param to The address to drop to.
     * @param amount The amount to airdrop.
     * @dev This method will automatically add the correct amount of decimal places.
     */
    function airdrop(address to, uint256 amount) external onlyOwner {
        _mint(to, amount * 10**decimals());
    }

    /**
     * Airdrop tokens to multiple addresses.
     * @param tos The addresses to drop to.
     * @param amount The amount to airdrop.
     * @dev This method will automatically add the correct amount of decimal places.
     */
    function airdropBatch(address[] calldata tos, uint256 amount) external onlyOwner {
        for (uint256 i = 0; i < tos.length; i++) {
            _mint(tos[i], amount * 10**decimals());
        }
    }

    //
    // View functions
    //

    /**
     * Verify a signature
     * @param data The signature data
     * @param signature The signature to verify
     * @param account The signer account
     */
    function _verify(
        bytes memory data,
        bytes memory signature,
        address account
    ) public pure returns (bool) {
        return keccak256(data).toEthSignedMessageHash().recover(signature) == account;
    }

    /**
     * List all the staked tokens owned by the given address.
     * @dev This is NOT gas efficient as so it is highly recommended you do NOT integrate to this
     * @dev interface in other contracts, except when read only.
     */
    function listStakedTokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 supply = nlbToken.totalSupply();
        uint256[] memory tokenIds = new uint256[](supply);
        uint256 count = 0;
        for (uint256 tokenId = 0; tokenId <= supply; tokenId++) {
            StakedInfo memory info = tokenStakedInfo[tokenId];
            if (info.owner == owner) {
                tokenIds[count] = tokenId;
                count++;
            }
        }
        return resizeArray(tokenIds, count);
    }

    /**
     * List all the rewards for staked tokens owned by the given address.
     * @dev This is NOT gas efficient as so it is highly recommended you do NOT integrate to this
     * @dev interface in other contracts, except when read only.
     */
    function listClaimableRewardsOfOwner(address owner) external view returns (uint256[] memory) {
        uint256[] memory tokenIds = listStakedTokensOfOwner(owner);
        uint256[] memory claimable = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            StakedInfo memory info = tokenStakedInfo[tokenId];
            claimable[i] = calculateReward(tokenId, info.lockedAt);
        }
        return claimable;
    }

    /**
     * Helper function to resize an array.
     * @param input The inproperly sized array.
     * @param length The desired length.
     */
    function resizeArray(uint256[] memory input, uint256 length) public pure returns (uint256[] memory) {
        uint256[] memory output = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            output[i] = input[i];
        }
        return output;
    }
}
