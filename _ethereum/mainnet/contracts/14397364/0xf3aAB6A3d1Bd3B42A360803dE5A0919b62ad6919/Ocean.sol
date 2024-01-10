import "./IERC721ReceiverUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";

pragma solidity ^0.8.0;

interface IWhales {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}

interface IBlues {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getOwnerLedger(address addr)
        external
        view
        returns (uint16[] memory);
}

contract Ocean is
    IERC721ReceiverUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    event TokenStaked(address owner, uint128 tokenId);
    event WhalesMinted(address owner, uint256 amount);
    event TokenUnStaked(address owner, uint128 tokenId);
    // base reward rate
    uint256 DAILY_WHALES_BASE_RATE; //////////////////////////////////////////////////////
    uint256 DAILY_WHALES_RATE_TIER_1; ////////////////////////////////////////////////////
    uint256 DAILY_WHALES_RATE_TIER_2; ////////////////////////////////////////////////////
    uint256 DAILY_WHALES_RATE_TIER_3; ////////////////////////////////////////////////////
    uint256 DAILY_WHALES_RATE_TIER_4; ////////////////////////////////////////////////////
    uint256 DAILY_WHALES_RATE_TIER_5; ////////////////////////////////////////////////////
    uint256 DAILY_WHALES_RATE_LEGENDRY; //////////////////////////////////////////////////
    uint256 INITIAL_MINT_REWARD_TIER_1; //////////////////////////////////////////////////
    uint256 INITIAL_MINT_REWARD_TIER_2; //////////////////////////////////////////////////
    uint256 INITIAL_MINT_REWARD_TIER_3; //////////////////////////////////////////////////
    uint256 INITIAL_MINT_REWARD_TIER_4; //////////////////////////////////////////////////
    uint256 INITIAL_MINT_REWARD_LEGENDRY_TIER; ///////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////
    uint128 public totalBluesStaked; /////////////////////////////////////////////////////
    IERC721 Blues; ///////////////////////////////////////////////////////////////////////
    IWhales Whales; //////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////
    mapping(address => uint256) public totalWhalesEarnedPerAddress; //////////////////////
    mapping(address => uint256) public lastInteractionTimeStamp; /////////////////////////
    mapping(address => uint256) public userMultiplier; ///////////////////////////////////
    mapping(address => uint16) public totalBluesStakedPerAddress; ////////////////////////
    mapping(address => bool) public userFirstInteracted; /////////////////////////////////
    mapping(uint256 => bool) public initialMintClaimLedger; //////////////////////////////
    mapping(address => uint8) public legendryHoldingsPerUser; ////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////
    address[5600] public ocean; //////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////
    IBlues Blues_V2; /////////////////////////////////////////////////////////////////////
    mapping(address => uint256) public userHoldingsMultiplier; ///////////////////////////
    mapping(address => uint256) public passiveYeildTimeStamp; ////////////////////////////
    mapping(address => bool) public userTimestampInit; ///////////////////////////////////
    mapping(address => uint256) public totalWhalesPassivelyEarned; ///////////////////////
    mapping(address => uint256) public legendariesUnstaked; //////////////////////////////
    bool stakingPaused; //////////////////////////////////////////////////////////////////
    uint256 seedTimestamp; ///////////////////////////////////////////////////////////////

    function initialize(address _whales, address _blues) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        Blues = IERC721(_blues);
        Whales = IWhales(_whales);
        DAILY_WHALES_BASE_RATE = 10 ether;
        DAILY_WHALES_RATE_TIER_1 = 11 ether;
        DAILY_WHALES_RATE_TIER_2 = 12 ether;
        DAILY_WHALES_RATE_TIER_3 = 13 ether;
        DAILY_WHALES_RATE_TIER_4 = 14 ether;
        DAILY_WHALES_RATE_TIER_5 = 15 ether;
        DAILY_WHALES_RATE_LEGENDRY = 50 ether;

        INITIAL_MINT_REWARD_LEGENDRY_TIER = 100 ether;
        INITIAL_MINT_REWARD_TIER_1 = 50 ether;
        INITIAL_MINT_REWARD_TIER_2 = 20 ether;
        INITIAL_MINT_REWARD_TIER_3 = 10 ether;
    }

    /* entry point and main staking function.
     * takes an array of tokenIDs, and checks if the caller is
     * the owner of each token.
     * It then transfers the token to the Ocean contract.
     * At the end, it sets the userFirstInteracted mapping to true.
     * This is to prevent rewards calculation BEFORE having anything staked.
     * Otherwise, it leads to massive rewards.
     * The lastInteractionTimeStamp mapping is also updated.
     */
    function addManyBluesToOcean(uint16[] calldata tokenIds)
        external
        nonReentrant
        whenNotPaused
        updateRewardsForUser
    {
        require(!stakingPaused, "staking is now paused");
        userMultiplier[msg.sender] = DAILY_WHALES_BASE_RATE;
        require(tokenIds.length >= 1, "need at least 1 blue");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                Blues.ownerOf(tokenIds[i]) == msg.sender,
                "You are not the owner of this blue"
            );
            _adjustUserLegendryWhalesMultiplier(tokenIds[i], true);
            totalBluesStakedPerAddress[msg.sender]++;
            _addBlueToOcean(msg.sender, tokenIds[i]);
        }

        _adjustUserDailyWhalesMultiplier(
            totalBluesStakedPerAddress[msg.sender]
        );

        // only runs one time, the first time the user calls this function.
        if (userFirstInteracted[msg.sender] == false) {
            lastInteractionTimeStamp[msg.sender] = block.timestamp;
            userFirstInteracted[msg.sender] = true;
        }
    }

    // internal utility function that transfers the token and emits an event.
    function _addBlueToOcean(address account, uint16 tokenId)
        internal
        whenNotPaused
    {
        ocean[tokenId] = account;
        Blues.safeTransferFrom(msg.sender, address(this), tokenId);
        emit TokenStaked(msg.sender, tokenId);
    }

    /* This function recalculate the user's holders multiplier
     *  whenever they stake or unstake.
     *  There are a total of 5 yeild tiers..depending on the number of tokens staked.
     */
    function _adjustUserDailyWhalesMultiplier(uint256 stakedBlues) internal {
        if (stakedBlues < 5)
            userMultiplier[msg.sender] = DAILY_WHALES_BASE_RATE;
        else {
            if (stakedBlues >= 5 && stakedBlues <= 9)
                userMultiplier[msg.sender] = DAILY_WHALES_RATE_TIER_1;
            else if (stakedBlues >= 10 && stakedBlues <= 19)
                userMultiplier[msg.sender] = DAILY_WHALES_RATE_TIER_2;
            else if (stakedBlues >= 20 && stakedBlues <= 39)
                userMultiplier[msg.sender] = DAILY_WHALES_RATE_TIER_3;
            else if (stakedBlues >= 40 && stakedBlues <= 79)
                userMultiplier[msg.sender] = DAILY_WHALES_RATE_TIER_4;
            else userMultiplier[msg.sender] = DAILY_WHALES_RATE_TIER_5;
        }
    }

    function _adjustUserLegendryWhalesMultiplier(uint256 tokenId, bool staking)
        internal
    {
        if (staking) {
            if (isLegendary(tokenId)) legendryHoldingsPerUser[msg.sender]++;
        } else {
            if (isLegendary(tokenId)) legendryHoldingsPerUser[msg.sender]--;
        }
    }

    /* claims the rewards owed till now and updates the lastInteractionTimeStamp mapping.
     * also emits an event, etc..
     * finally, it sets the totalWhalesEarnedPerAddress to 0.
     */
    function claimWhalesWithoutUnstaking()
        external
        nonReentrant
        whenNotPaused
        updateRewardsForUser
        updatePassiveRewardsForUser
    {
        uint256 rewards = totalWhalesEarnedPerAddress[msg.sender] +
            totalWhalesPassivelyEarned[msg.sender];

        Whales.mint(msg.sender, rewards);
        emit WhalesMinted(msg.sender, rewards);

        totalWhalesEarnedPerAddress[msg.sender] = 0;
        totalWhalesPassivelyEarned[msg.sender] = 0;
    }

    /* same as the previous function, except this one unstakes as well.
     * it verfied the owner in  the Stake struct to be the msg.sender
     * it also verifies the the current owner is this contract.
     * it then decrease the total number staked for the user
     * and then calls safeTransferFrom.
     * it then mints the tokens.
     * finally, it calls _adjustUserDailyWhalesMultiplier
     */
    function claimWhalesAndUnstake(uint16[] calldata tokenIds)
        public
        nonReentrant
        whenNotPaused
        updateRewardsForUser
    {
        require(userFirstInteracted[msg.sender], "Stake some blues first");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                Blues.ownerOf(tokenIds[i]) == address(this),
                "This Blue is not staked"
            );
            require(
                ocean[tokenIds[i]] == msg.sender,
                "You are not the owner of this blue"
            );
            _adjustUserLegendryWhalesMultiplier(tokenIds[i], false);
            delete ocean[tokenIds[i]];
            totalBluesStakedPerAddress[msg.sender]--;
            Blues.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }

        _adjustUserDailyWhalesMultiplier(
            totalBluesStakedPerAddress[msg.sender]
        );

        Whales.mint(msg.sender, totalWhalesEarnedPerAddress[msg.sender]);
        emit WhalesMinted(msg.sender, totalWhalesEarnedPerAddress[msg.sender]);
        totalWhalesEarnedPerAddress[msg.sender] = 0;
    }

    /* Each minting tier is elligble for a token claim based on how early they minted.
     * first 500 tokenIds get 50 whales for instance.
     * there are 3 tiers.
     */
    function claimInitialMintingRewards(uint256[] calldata tokenIds)
        external
        nonReentrant
        whenNotPaused
    {
        uint256 rewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {

            if (Blues.ownerOf(tokenIds[i]) == address(this))
                require(ocean[tokenIds[i]] == msg.sender, "Non owner of blue");

            else 
                require(Blues.ownerOf(tokenIds[i]) == msg.sender, "Non owner");

            require(
                initialMintClaimLedger[tokenIds[i]] == false,
                "Rewards already claimed for this token"
            );

            initialMintClaimLedger[tokenIds[i]] = true;

            if (tokenIds[i] <= 500) rewards += INITIAL_MINT_REWARD_TIER_1;
            else if (tokenIds[i] > 500 && tokenIds[i] < 1500)
                rewards += INITIAL_MINT_REWARD_TIER_2;
            else rewards += INITIAL_MINT_REWARD_TIER_3;

            if (isLegendary(tokenIds[i]))
                rewards += INITIAL_MINT_REWARD_LEGENDRY_TIER;
        }

        Whales.mint(msg.sender, rewards);
        emit WhalesMinted(msg.sender, rewards);
    }

    function isLegendary(uint256 tokenID) public pure returns (bool) {
        if (
            tokenID == 756 ||
            tokenID == 2133 ||
            tokenID == 1111 ||
            tokenID == 999 ||
            tokenID == 888 ||
            tokenID == 435 ||
            tokenID == 891 ||
            tokenID == 918 ||
            tokenID == 123 ||
            tokenID == 432 ||
            tokenID == 543 ||
            tokenID == 444 ||
            tokenID == 333 ||
            tokenID == 222 ||
            tokenID == 235 ||
            tokenID == 645 ||
            tokenID == 898 ||
            tokenID == 1190 ||
            tokenID == 3082 ||
            tokenID == 3453 ||
            tokenID == 2876 ||
            tokenID == 5200 ||
            tokenID == 451 ||
            tokenID > 5555
        ) return true;

        return false;
    }

    /* The main accounting modifier.
     * It runs when the user interacts with any other function.
     * and before the function itself.
     * stores the owed results till now in the totalWhalesEarnedPerAddress
     * mapping. It then sets the lastInteractionTimeStamp to the current block.timestamp
     */
    modifier updateRewardsForUser() {
        if (userFirstInteracted[msg.sender]) {
            totalWhalesEarnedPerAddress[msg.sender] +=
                (((block.timestamp - lastInteractionTimeStamp[msg.sender]) *
                    totalBluesStakedPerAddress[msg.sender] *
                    userMultiplier[msg.sender]) / 1 days) << 1;

            // now accounting if they are holding legendries.
            if (legendryHoldingsPerUser[msg.sender] > 0) {
                totalWhalesEarnedPerAddress[msg.sender] +=
                    ((block.timestamp - lastInteractionTimeStamp[msg.sender]) *
                        (legendryHoldingsPerUser[msg.sender] *
                            DAILY_WHALES_RATE_LEGENDRY)) /
                    1 days;
            }

            lastInteractionTimeStamp[msg.sender] = block.timestamp;
        }
        _;
    }

    // ----------------------- PASSIVE REWARDS ACCOUNTING ------------------------- //

    /*
     * @dev The main accounting modifier for held blues.
     * It calculates the yeild by taking into account only the unstaked Blues.
     * First time it is called, it calculates the yeild since a pre-determined timestamp.
     * Then, it sets the timestamp is set to be the last timestamp this function is called at.
     * it gets the held tokens from the Blues contract using getOwnerLegder
     * the mapping totalWhalesPassivelyEarned[msg.sender] stores WHALES earned through holding.
     */
    modifier updatePassiveRewardsForUser() {
        uint16[] memory userLedger = Blues_V2.getOwnerLedger(msg.sender);

        if (userLedger.length > 0) {
            if (!userTimestampInit[msg.sender]) {
                passiveYeildTimeStamp[msg.sender] = seedTimestamp;
                userTimestampInit[msg.sender] = true;
            }

            _adjustMultiplierForPassiveYeild(userLedger.length, msg.sender);

            totalWhalesPassivelyEarned[msg.sender] +=
                (
                    ((block.timestamp - passiveYeildTimeStamp[msg.sender]) *
                        userLedger.length *
                        userHoldingsMultiplier[msg.sender])
                ) /
                1 days;

            _adjustLegendaryMultiplierForPassiveYeild(userLedger, msg.sender);

            if (legendariesUnstaked[msg.sender] > 0) {
                totalWhalesPassivelyEarned[msg.sender] +=
                    (
                        ((block.timestamp - passiveYeildTimeStamp[msg.sender]) *
                            (legendariesUnstaked[msg.sender] *
                                DAILY_WHALES_RATE_LEGENDRY))
                    ) /
                    1 days;
            }

            passiveYeildTimeStamp[msg.sender] = block.timestamp;
        }

        delete userLedger;

        _;
    }

    /*
     * @dev The claiming function for the passive rewards
     * calls the modifier and then mint the tokens.
     */
    function claimPassiveRewardsForUser()
        external
        nonReentrant
        whenNotPaused
        updatePassiveRewardsForUser
    {
        Whales.mint(msg.sender, totalWhalesPassivelyEarned[msg.sender]);
        emit WhalesMinted(msg.sender, totalWhalesPassivelyEarned[msg.sender]);
        totalWhalesPassivelyEarned[msg.sender] = 0;
    }

    /*
     * @dev This function gets the stored rewards up to now without minting.
     * Becuase this will depend on the last interacted timestamp, the user will need to
     * call at least 1 other functon that uses the passive yeild modifier before calling this function.
     */
    function burnWhalesOnHand(uint256 amount)
        external
        whenNotPaused
        nonReentrant
    {   
  
        require(
            amount <= Whales.balanceOf(msg.sender),
            "Not enough whales to burn"
        );
        Whales.burn(msg.sender, amount);
    }

    /*
     * @dev This function adjusts the Legendry muliplier for the holder
     * This accounts for the held non-staked legendries.
     * @param tokenIds is the list of held tokens to check for.
     */
    function _adjustLegendaryMultiplierForPassiveYeild(
        uint16[] memory tokenIds,
        address account
    ) internal {
        legendariesUnstaked[account] = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (isLegendary(tokenIds[i])) legendariesUnstaked[account]++;
        }
    }

    function _adjustMultiplierForPassiveYeild(uint256 holdings, address account)
        internal
    {
        if (holdings < 5)
            userHoldingsMultiplier[account] = DAILY_WHALES_BASE_RATE;
        else {
            if (holdings >= 5 && holdings <= 9)
                userHoldingsMultiplier[account] = DAILY_WHALES_RATE_TIER_1;
            else if (holdings >= 10 && holdings <= 19)
                userHoldingsMultiplier[account] = DAILY_WHALES_RATE_TIER_2;
            else if (holdings >= 20 && holdings <= 39)
                userHoldingsMultiplier[account] = DAILY_WHALES_RATE_TIER_3;
            else if (holdings >= 40 && holdings <= 79)
                userHoldingsMultiplier[account] = DAILY_WHALES_RATE_TIER_4;
            else userHoldingsMultiplier[account] = DAILY_WHALES_RATE_TIER_5;
        }
    }

    // ----------------------- PASSIVE REWARDS ACCOUNTING ------------------------- //

    function getDailyYield(address account) external view returns (uint256) {
        uint256 yeild = (totalBluesStakedPerAddress[account] *
            userMultiplier[account]);
        yeild += (legendryHoldingsPerUser[account] *
            DAILY_WHALES_RATE_LEGENDRY);

        return yeild;
    }

    function getOcean() external view returns (address[5600] memory) {
        return ocean;
    }

    function setBlues(address _blues) external onlyOwner {
        Blues = IERC721(_blues);
    }

    function setWhales(address _whales) external onlyOwner {
        Whales = IWhales(_whales);
    }

    function setStakingPaused(bool _state) external onlyOwner {
        stakingPaused = _state;
    }

    // only owner
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function mintForTesting(uint256 amount, address addr) external onlyOwner {
        Whales.mint(addr, amount);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setBluesV2(address _blues_v2) external onlyOwner {
        Blues_V2 = IBlues(_blues_v2);
    }

    function setSeedTimestamp(uint256 seed) external onlyOwner {
        seedTimestamp = seed;
    }
}
