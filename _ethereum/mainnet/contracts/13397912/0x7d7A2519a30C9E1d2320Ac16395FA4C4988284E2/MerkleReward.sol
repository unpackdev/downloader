// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./console.sol";

contract MerkleReward is 
    Ownable,
    ReentrancyGuard
{
    uint constant USDC_DECIMALS = 6;
    uint constant STRP_DECIMALS = 18;

    address public strp;
    address public usdc;
    bytes32 public merkleRoot;

    event RewardBought(
        address indexed rewardee, 
        uint strpBought,
        uint usdcPaid
    );

    event RewardClaimed(
        address indexed rewardee, 
        uint amount
    );

    event BuyStopped(
        uint rewardsClaimAfter
    );

    // Rewards program started only after activation
    bool public rewardsActivated;   
    // Fixed STRP price for rewardee
    uint public rewardsStrpPrice;
    // Till this date rewardee can buy tokens, BUT only after that date tokens can be claimed
    uint public rewardsClaimAfter;


    //Information about each rewardee
    struct RewardData {
        // Maximum amount of tokens reserved for rewardee
        uint total; 
        // The amount that rewardee bought before claim period. He can't claim more than he bought even if it's less that total
        uint bought;
    }

    //The full list of rewardees, imported manually
    mapping (address => RewardData) public rewards;

    // Rewardee can buy reward STRP with special price only BEFORE rewardsClaimAfter
    modifier canBuyReward() {
        require(rewardsActivated == true, "REWARDS_NOT_ACTIVATED");
        require(block.timestamp < rewardsClaimAfter, "BUY_PERIOD_PASSED");
        _;
    }

    // Rewardee can claim reward STRP with special price only AFTER rewardsClaimAfter
    modifier canClaimReward(){
        require(rewardsActivated == true, "REWARDS_NOT_ACTIVATED");
        require(block.timestamp >= rewardsClaimAfter, "CLAIM_TOO_EARLY");
        _;
    }


    constructor(address _strp,
                address _usdc) public {
        strp = _strp;
        usdc = _usdc;
    }

    /**
     * @dev DAO can launch rewards STRP distribution program only ONCE
     * @param _rewardsStrpPrice the SPECIAL price in USDC per STRP for all rewardees
     * @param _buyPeriod length of buying period in seconds, started from current time
     **/
    function setReward(
        uint _rewardsStrpPrice,
        uint _buyPeriod,
        bytes32 _merkleRoot
    ) external onlyOwner {
        require(rewardsActivated == false, "ALREADY_ACTIVATED");
        require(_rewardsStrpPrice > 0, "WRONG_BONUS_PRICE");

        rewardsStrpPrice = _rewardsStrpPrice;
        rewardsClaimAfter = block.timestamp + _buyPeriod;

        merkleRoot = _merkleRoot;
        rewardsActivated = true;
    }

    function stopBuy() external onlyOwner {
        rewardsClaimAfter = block.timestamp;

        emit BuyStopped(rewardsClaimAfter);
    }

    /**
     * @dev Reardee can buy STRP only if he is in the list and buying period is not over
     * @param buyAmount amount of STRP that rewardee wants to buy
     * @param totalAmount amount of STRP total
     * @param merkleProof merkleProof generated on client side
     **/

    function buyStrp(uint buyAmount, uint index, uint totalAmount, bytes32[] calldata merkleProof) external nonReentrant canBuyReward {
        _ensureSender(index, totalAmount, merkleProof);

        require(rewards[msg.sender].bought + buyAmount <= rewards[msg.sender].total, "MAXIMUM_EXCEED");
        rewards[msg.sender].bought += buyAmount;

        uint usdcRequired = priceFor(buyAmount);
        require(usdcRequired > 0, "PRICE_CALC_ERROR");

        SafeERC20.safeTransferFrom(IERC20(usdc), msg.sender, owner(), usdcRequired);

        emit RewardBought(
            msg.sender,
            buyAmount,
            usdcRequired
        );
    }

    /**
     * @dev Reardee can claim the bought amount of STRP only after buying period is OVER. 
     *  There is no limit for how long he can claim his rewards
     **/

    function claimRewards() external nonReentrant canClaimReward {
        require(rewards[msg.sender].total > 0, "NO_REWARDEE");

        uint available = rewards[msg.sender].bought;
        require(available > 0, "NO_REWARDS");
        rewards[msg.sender].bought -= available;

        /*Integrity check */
        require (available <= rewards[msg.sender].total, "INTEGRITY_ERROR");

        SafeERC20.safeTransferFrom(IERC20(strp), owner(), msg.sender, available);
       
        emit RewardClaimed(
            msg.sender,
            available
        );
    }

    /**
     * @dev view method that shows how many rewards can rewardee buy. He can buy reards in multiple steps untill Buying period is over
     **/
    function checkAvailableToBuy() external view canBuyReward returns (uint total, uint available){
        total = rewards[msg.sender].total;
        available = rewards[msg.sender].total - rewards[msg.sender].bought;
    }

    /**
     * @dev check how many rewards available for CLAIMING
     **/
    function checkAvailableToClaim() external view canClaimReward returns (uint){
        return rewards[msg.sender].bought;
    }

    /**
     * @dev calc USDC amount required to buy strpAmount of STRP
     * @param strpAmount STRP amount for buying
     * @return USDC cost of strpAmount (USDC decimals is 6)
     **/
    function priceFor(uint strpAmount) public view canBuyReward returns (uint){
        return (strpAmount * rewardsStrpPrice) / (10**uint(STRP_DECIMALS));
    }


    function _ensureSender(uint index, uint totalAmount, bytes32[] calldata merkleProof) internal
    {   
        //First time call, verify proof and create rewardee
        if (rewards[msg.sender].total == 0){
            // Verify the merkle proof.
            bytes32 node = keccak256(abi.encodePacked(index, msg.sender, totalAmount));
            require(MerkleProof.verify(merkleProof, merkleRoot, node), 'INVALID_PROOF');

            rewards[msg.sender].total = totalAmount;
        }

        require(rewards[msg.sender].total > 0, "NO_REWARDEE");
    }
}