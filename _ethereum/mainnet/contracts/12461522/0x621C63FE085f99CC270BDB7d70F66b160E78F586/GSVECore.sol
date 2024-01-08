/*
GAS SAVE PROTOCOL - $GSVE TOKEN!
████████████████████████████████████████████████████████████
███████████████████████▀▀▀▀▀▀▀▀▀▀▀▀▀▀███████████████████████
████████████████▀▀░░░░░░░░░░░░░░░░░░░░░░░░▀▀▀███████████████
██████████████░▄░░░░░░░░░░░░░░░░░░░░░░░░░░░░▄░██████████████
██████████████▄░▀▀░░░▄▄▄░░░░░░░░░░░░░▄▄░░░▀▀▄░██████████████
███████████████░░░▀▀░░░░▄▄▄▄▄▄▄▄▄▄▄▄▄▄░░▀▀░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
██████████████░░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
██████████████▄░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░▀▀░░▄▄▄▄░░░░░░░▀░░░░░▄▄▄░░▀▀░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
██████████████▀░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
██████████████░░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░▄▄░░░░░░░░░░░░▄█░░░░░░░░░░▄▄░░██████████████
███████████████░░░░░▀▀▀▀░░░░░░▄▄░░░░▀▀▀▀░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░▄█░░░░▄░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░██░░░░█░░░░░░░░░██████████████
██████████████░░░░░░░░░░░░░░░░██░░░░█░░░░░░░░░██████████████
██████████████▄░░░░░░░░░░░░░░░██░░░░█░░░░░░░░░██████████████
█████████████████▄▄▄░░░░░░░░░░░░░░░░░░░░░▄▄▄████████████████
██████████████████████████████▄▄▄▄██████████████████████████
████████████████████████████████████████████████████████████
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/**
 * @dev Interface of the wrapped Gas Token Type
 */
interface IGasTokenMint {
    function mint(uint256 value) external; 
    function discountedMint(uint256 value, uint256 discountedFee, address recipient) external; 
}


/**
* @dev Interface for interacting with protocol token
*/
interface IGSVEProtocolToken {
    function burn(uint256 amount) external ;
    function burnFrom(address account, uint256 amount) external;
}

/**
* @dev Interface for interacting with the gas vault
*/
interface IGSVEVault {
    function transferToken(address token, address recipient, uint256 amount) external;
}

contract GSVECore is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    
    //address of our protocol utility token
    address private GSVEToken;
    address private GSVEVault;

    //system is in place to prevent reentrancy from untrusted tokens
    mapping(address => uint256) private _mintingType;
    mapping(address => bool) private _claimable;

    uint256 private _totalStaked;

    //staking  
    mapping(address => uint256) private userStakes;
    mapping(address => uint256) private userStakeTimes;
    mapping(address => uint256) private userTotalRewards;
    mapping(address => uint256) private userClaimTimes;

    //protocol values
    mapping(uint256=>uint256) private tierThreshholds;
    uint256 rewardEnableTime;

    bool rewardsEnabled = false;
    uint256 burnToSaveFee = 25*10**16;
    uint256 burnToClaimGasTokens = 1*10**17;
    uint256 mintingReward = 5*10**17;


    /**
     * @dev A function that enables protocol rewards
     */
    function enableRewards() public onlyOwner {
        require(rewardsEnabled == false, "GSVE: Rewards already enabled");
        rewardsEnabled = true;
        rewardEnableTime = block.timestamp;
        emit protocolUpdated(0x656e61626c655570646174650000000000000000000000000000000000000000, 1);
    }

    /**
    * @dev A function that disables rewards
    */
    function disableRewards() public onlyOwner {
        require(rewardsEnabled, "GSVE: Rewards not already enabled");
        rewardsEnabled = false;
        rewardEnableTime = 0;
        emit protocolUpdated(0x656e61626c655570646174650000000000000000000000000000000000000000, 0);
    }

    /**
     * @dev A function that allows us to update the tier threshold
     */
    function updateTier(uint256 tier, uint256 value) public onlyOwner {
        require(value > 10**18, "GSVE: Tier value seems to be low.");
        tierThreshholds[tier] = value;
        emit TierUpdate(tier, value);
    }

    /**
     * @dev A function that allows us to update the burn gsve:save fee ratio
     */
    function updateBurnSaveFee(uint256 value) public onlyOwner{
        require(value > 10**17, "GSVE: Value seems to be low.");
        burnToSaveFee = value;
        emit protocolUpdated(0x6275726e00000000000000000000000000000000000000000000000000000000, value);
    }

    /**
     * @dev A function that allows us to update the burn gsve:claim gastoken ratio
     */
    function updateBurnClaimFee(uint256 value) public onlyOwner{
        require(value > 10**17, "GSVE: Value seems to be low.");
        burnToClaimGasTokens= value;
        emit protocolUpdated(0x636c61696d000000000000000000000000000000000000000000000000000000, value);
    }

    /**
     * @dev A function that allows us to update the burn gsve:claim gastoken ratio
     */
    function updateMintingReward(uint256 value) public onlyOwner{
        require(value > 10**17, "GSVE: Value seems to be low.");
        mintingReward = value;
        emit protocolUpdated(0x6d696e74696e6700000000000000000000000000000000000000000000000000, value);
    }

    /**
     * @dev A function that allows us to reassign ownership of the contracts that this contract owns. 
     /* Enabling future smartcontract upgrades without the complexity of proxy/proxy upgrades.
     */
    function transferOwnershipOfSubcontract(address ownedContract, address newOwner) public onlyOwner{
        Ownable(ownedContract).transferOwnership(newOwner);
    }

    /**
     * @dev the constructor allows us to set the gsve token
     * as the token we are using for staking and other protocol features
     * also lets us set the vault address.
     */
    constructor(address _tokenAddress, address _vaultAddress, address wchi, address wgst2, address wgst1) {
        GSVEToken = _tokenAddress;
        GSVEVault = _vaultAddress;
        tierThreshholds[1] = 250*(10**18);
        tierThreshholds[2] = 1000*(10**18);
        _claimable[_tokenAddress] = false;

        _claimable[0x0000000000004946c0e9F43F4Dee607b0eF1fA1c] = true;
        _mintingType[0x0000000000004946c0e9F43F4Dee607b0eF1fA1c] = 1;

        _claimable[0x0000000000b3F879cb30FE243b4Dfee438691c04] = true;
        _mintingType[0x0000000000b3F879cb30FE243b4Dfee438691c04] = 1;

        _claimable[0x88d60255F917e3eb94eaE199d827DAd837fac4cB] = true;
        _mintingType[0x88d60255F917e3eb94eaE199d827DAd837fac4cB] = 1;
        

        _claimable[wchi] = true;
        _mintingType[wchi] = 2;

        _claimable[wgst2] = true;
        _mintingType[wgst2] = 2;

        _claimable[wgst1] = true;
        _mintingType[wgst1] = 2;
    }

    /**
     * @dev A function that allows a user to stake tokens. 
     * If they have a rewards from a stake already, they must claim this first.
     */
    function stake(uint256 value) public nonReentrant() {

        if (value == 0){
            return;
        }
        require(IERC20(GSVEToken).transferFrom(msg.sender, address(this), value));
        userStakes[msg.sender] = userStakes[msg.sender].add(value);
        userStakeTimes[msg.sender] = block.timestamp;
        userClaimTimes[msg.sender] = block.timestamp;
        _totalStaked = _totalStaked.add(value);
        emit Staked(msg.sender, value);
    }

    /**
     * @dev A function that allows a user to fully unstake.
     */
    function unstake() public nonReentrant() {
        uint256 stakeSize = userStakes[msg.sender];
        if (stakeSize == 0){
            return;
        }
        userStakes[msg.sender] = 0;
        userStakeTimes[msg.sender] = 0;
        userClaimTimes[msg.sender] = 0;
        _totalStaked = _totalStaked.sub(stakeSize);
        require(IERC20(GSVEToken).transfer(msg.sender, stakeSize));
        emit Unstaked(msg.sender, stakeSize);
    }

    /**
     * @dev A function that allows us to calculate the total rewards a user has not claimed yet.
     */
    function calculateStakeReward(address rewardedAddress) public view returns(uint256){
        if(userStakeTimes[rewardedAddress] == 0){
            return 0;
        }

        if(rewardsEnabled == false){
            return 0;
        }

        uint256 initialTime = Math.max(userStakeTimes[rewardedAddress], rewardEnableTime);
        uint256 timeDifference = block.timestamp.sub(initialTime);
        uint256 rewardPeriod = timeDifference.div((60*60*6));
        uint256 rewardPerPeriod = userStakes[rewardedAddress].div(4000);
        uint256 reward = rewardPeriod.mul(rewardPerPeriod);

        return reward;
    }

    /**
     * @dev A function that allows a user to collect the stake reward entitled to them
     * in the situation where the rewards pool does not have enough tokens
     * then the user is given as much as they can be given.
     */
    function collectReward() public nonReentrant() {
        uint256 remainingRewards = totalRewards();
        require(remainingRewards > 0, "GSVE: contract has ran out of rewards to give");
        require(rewardsEnabled, "GSVE: Rewards are not enabled");

        uint256 reward = calculateStakeReward(msg.sender);
        if(reward == 0){
            return;
        }

        reward = Math.min(remainingRewards, reward);
        userStakeTimes[msg.sender] = block.timestamp;
        userTotalRewards[msg.sender] = userTotalRewards[msg.sender] + reward;
        IGSVEVault(GSVEVault).transferToken(GSVEToken, msg.sender, reward);
        emit Reward(msg.sender, reward);
    }

    /**
     * @dev A function that allows a user to burn some GSVE to avoid paying the protocol mint/wrap fee.
     */
    function burnDiscountedMinting(address gasTokenAddress, uint256 value) public nonReentrant() {
        uint256 mintType = _mintingType[gasTokenAddress];
        require(mintType != 0, "GSVE: Unsupported Token");
        IGSVEProtocolToken(GSVEToken).burnFrom(msg.sender, burnToSaveFee);

        if(mintType == 1){
            convenientMinting(gasTokenAddress, value, 0);
        }
        else if (mintType == 2){
            IGasTokenMint(gasTokenAddress).discountedMint(value, 0, msg.sender);
        }
    }

    /**
     * @dev A function that allows a user to benefit from a lower protocol fee, based on the stake that they have.
     */
    function discountedMinting(address gasTokenAddress, uint256 value) public nonReentrant(){
        uint256 mintType = _mintingType[gasTokenAddress];
        require(mintType != 0, "GSVE: Unsupported Token");
        require(userStakes[msg.sender] >= tierThreshholds[1] , "GSVE: User has not staked enough to discount");

        if(mintType == 1){
            convenientMinting(gasTokenAddress, value, 1);
        }
        else if (mintType == 2){
            IGasTokenMint(gasTokenAddress).discountedMint(value, 1, msg.sender);
        }
    }
    
    /**
     * @dev A function that allows a user to be rewarded tokens by minting or wrapping
     * they pay full fees for this operation.
     */
    function rewardedMinting(address gasTokenAddress, uint256 value) public nonReentrant(){
        uint256 mintType = _mintingType[gasTokenAddress];
        require(mintType != 0, "GSVE: Unsupported Token");
        require(totalRewards() > 0, "GSVE: contract has ran out of rewards to give");
        require(rewardsEnabled, "GSVE: Rewards are not enabled");
        if(mintType == 1){
            convenientMinting(gasTokenAddress, value, 2);
        }
        else if (mintType == 2){
            IGasTokenMint(gasTokenAddress).discountedMint(value, 2, msg.sender);
        }

        IGSVEVault(GSVEVault).transferToken(GSVEToken, msg.sender, mintingReward);
    }

    /**
     * @dev A function that allows us to mint non-wrapped tokens from the convenience of this smart contract.
     * taking a portion of portion of the minted tokens as payment for this convenience.
     */
    function convenientMinting(address gasTokenAddress, uint256 value, uint256 fee) internal {
        uint256 mintType = _mintingType[gasTokenAddress];
        require(mintType == 1, "GSVE: Unsupported Token");

        uint256 userTokens = value.sub(fee);
        require(userTokens > 0, "GSVE: User attempted to mint too little");
        IGasTokenMint(gasTokenAddress).mint(value);
        IERC20(gasTokenAddress).transfer(msg.sender, userTokens);
        if(fee > 0){
            IERC20(gasTokenAddress).transfer(GSVEVault, fee);
        }
    }

    
    /**
     * @dev public entry to the convenient minting function
     */
    function mintGasToken(address gasTokenAddress, uint256 value) public {
        convenientMinting(gasTokenAddress, value, 2);
    }


    /**
     * @dev A function that allows a user to claim tokens from the pool
     * The user burns 1 GSVE for each token they take.
     * They are limited to one claim action every 6 hours, and can claim up to 5 tokens per claim.
     */
    function claimToken(address gasTokenAddress, uint256 value) public nonReentrant() {

        bool isClaimable = _claimable[gasTokenAddress];
        require(isClaimable, "GSVE: Token not claimable");
        require(userStakes[msg.sender] >= tierThreshholds[2] , "GSVE: User has not staked enough to claim from the pool");
        require(block.timestamp.sub(userClaimTimes[msg.sender]) > 60 * 60 * 6, "GSVE: User cannot claim the gas tokens twice in 6 hours");

        uint256 tokensGiven = value;

        uint256 tokensAvailableToClaim = IERC20(gasTokenAddress).balanceOf(GSVEVault);
        tokensGiven = Math.min(Math.min(5, tokensAvailableToClaim), tokensGiven);

        if(tokensGiven == 0){
            return;
        }

        IGSVEProtocolToken(GSVEToken).burnFrom(msg.sender, tokensGiven * burnToClaimGasTokens);
        IGSVEVault(GSVEVault).transferToken(gasTokenAddress, msg.sender, tokensGiven);
        userClaimTimes[msg.sender] = block.timestamp;
        emit Claimed(msg.sender, gasTokenAddress, tokensGiven);
    }

    /**
     * @dev A function that allows us to enable gas tokens for use with this contract.
     */
    function addGasToken(address gasToken, uint256 mintType, bool isClaimable) public onlyOwner{
        _mintingType[gasToken] = mintType;
        _claimable[gasToken] = isClaimable;
    }

    /**
     * @dev A function that allows us to easily check claim type of the token.
     */
    function claimable(address gasToken) public view returns (bool){
        return _claimable[gasToken];
    }

    /**
     * @dev A function that allows us to check the mint type of the token.
     */
    function mintingType(address gasToken) public view returns (uint256){
        return _mintingType[gasToken];
    }

    /**
     * @dev A function that allows us to see the total stake of everyone in the protocol.
     */
    function totalStaked() public view returns (uint256){
        return _totalStaked;
    }

    /**
     * @dev A function that allows us to see the stake size of a specific staker.
     */
    function userStakeSize(address user)  public view returns (uint256){
        return userStakes[user]; 
    }

    /**
     * @dev A function that allows us to see how much rewards the vault has available right now.
     */    
     function totalRewards()  public view returns (uint256){
        return IERC20(GSVEToken).balanceOf(GSVEVault); 
    }

    /**
     * @dev A function that allows us to see how much rewards a user has claimed
     */
    function totalRewardUser(address user)  public view returns (uint256){
        return userTotalRewards[user]; 
    }

    /**
    * @dev A function that allows us to get a tier threshold
    */
    function getTierThreshold(uint256 tier)  public view returns (uint256){
        return tierThreshholds[tier];
    }

    /**
    * @dev A function that allows us to get the time rewards where enabled
    */
    function getRewardEnableTime()  public view returns (uint256){
        return rewardEnableTime;
    }

    /**
    * @dev A function that allows us to get the time rewards where enabled
    */
    function getRewardEnabled()  public view returns (bool){
        return rewardsEnabled;
    }

    /**
    * @dev A function that allows us to get the burnToSaveFee 
    */
    function getBurnToSaveFee()  public view returns (uint256){
        return burnToSaveFee;
    }

    /**
    * @dev A function that allows us to get the burnToClaimGasTokens 
    */
    function getBurnToClaimGasTokens()  public view returns (uint256){
        return burnToClaimGasTokens;
    }

    /**
    * @dev A function that allows us to get the burnToClaimGasTokens 
    */
    function getMintingReward()  public view returns (uint256){
        return mintingReward;
    }

    /**
    * @dev A function that allows us to get the stake times
    */
    function getStakeTimes(address staker)  public view returns (uint256){
        return userStakeTimes[staker];
    }

    /**
    * @dev A function that allows us to get the claim times
    */
    function getClaimTimes(address staker)  public view returns (uint256){
        return userClaimTimes[staker];
    }
    
    event Claimed(address indexed _from, address indexed _token, uint256 _value);

    event Reward(address indexed _from, uint256 _value);

    event Staked(address indexed _from, uint256 _value);

    event Unstaked(address indexed _from, uint256 _value);

    event TierUpdate(uint256 _tier, uint256 _value);

    event protocolUpdated(bytes32 _type, uint256 _value);
}
