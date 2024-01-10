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
    uint256 DAILY_WHALES_BASE_RATE;
    uint256 DAILY_WHALES_RATE_TIER_1;
    uint256 DAILY_WHALES_RATE_TIER_2;
    uint256 DAILY_WHALES_RATE_TIER_3;
    uint256 DAILY_WHALES_RATE_TIER_4;
    uint256 DAILY_WHALES_RATE_TIER_5;
    uint256 DAILY_WHALES_RATE_LEGENDRY;

    uint256 INITIAL_MINT_REWARD_TIER_1;
    uint256 INITIAL_MINT_REWARD_TIER_2;
    uint256 INITIAL_MINT_REWARD_TIER_3;
    uint256 INITIAL_MINT_REWARD_TIER_4;
    uint256 INITIAL_MINT_REWARD_LEGENDRY_TIER;

    // amount of $WHALES earned so far
    // number of Blues in the ocean
    uint128 public totalBluesStaked;
    // the last time $WHALES was claimed
    //uint16 public lastInteractionTimeStamp;
    // max $WHALES supply

    IERC721 Blues;
    IWhales Whales;

    mapping(address => uint256) public totalWhalesEarnedPerAddress;
    mapping(address => uint256) public lastInteractionTimeStamp;
    mapping(address => uint256) public userMultiplier;
    mapping(address => uint16) public totalBluesStakedPerAddress;
    mapping(address => bool) public userFirstInteracted;
    mapping(uint256 => bool) public initialMintClaimLedger;
    mapping(address => uint8) public legendryHoldingsPerUser;

    address[5600] public ocean;

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

    // entry point and main staking function.
    // takes an array of tokenIDs, and checks if the caller is
    // the owner of each token.
    // It then transfers the token to the Ocean contract.
    // At the end, it sets the userFirstInteracted mapping to true.
    // This is to prevent rewards calculation BEFORE having anything staked.
    // Otherwise, it leads to massive rewards.
    // The lastInteractionTimeStamp mapping is also updated.
    function addManyBluesToOcean(uint16[] calldata tokenIds)
        external
        nonReentrant
        whenNotPaused
        updateRewardsForUser(msg.sender)
    {
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

    // This function recalculate the user's holders multiplier
    // whenever they stake or unstake.
    // There are a total of 5 yeild tiers..depending on the number of tokens staked.
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
        //todo add support for the other 1/1 for the public mint

        if (staking) {
            if (tokenId > 5555 || isLegendary(tokenId))
                legendryHoldingsPerUser[msg.sender]++;
        } else {
            if (tokenId > 5555 || isLegendary(tokenId))
                legendryHoldingsPerUser[msg.sender]--;
        }
    }

    // claims the rewards owed till now and updates the lastInteractionTimeStamp mapping.
    // also emits an event, etc..
    // finally, it sets the totalWhalesEarnedPerAddress to 0.
    function claimWhalesWithoutUnstaking()
        external
        nonReentrant
        whenNotPaused
        updateRewardsForUser(msg.sender)
    {
        require(userFirstInteracted[msg.sender], "Stake some blues first");
        require(
            totalWhalesEarnedPerAddress[msg.sender] > 0,
            "No whales to claim"
        );

        Whales.mint(msg.sender, totalWhalesEarnedPerAddress[msg.sender]);
        emit WhalesMinted(msg.sender, totalWhalesEarnedPerAddress[msg.sender]);
        totalWhalesEarnedPerAddress[msg.sender] = 0;
    }

    // same as the previous function, except this one unstakes as well.
    // it verfied the owner in  the Stake struct to be the msg.sender
    // it also verifies the the current owner is this contract.
    // it then decrease the total number staked for the user
    // and then calls safeTransferFrom.
    // it then mints the tokens.
    // finally, it calls _adjustUserDailyWhalesMultiplier
    function claimWhalesAndUnstake(uint256[] calldata tokenIds)
        public
        nonReentrant
        whenNotPaused
        updateRewardsForUser(msg.sender)
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

    // Each minting tier is elligble for a token claim based on how early they minted.
    // first 500 tokenIds get 50 whales for instance.
    // there are 3 tiers.
    function claimInitialMintingRewards(uint256[] calldata tokenIds)
        public
        nonReentrant
        whenNotPaused
    {
        uint256 rewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                Blues.ownerOf(tokenIds[i]) == msg.sender,
                "You are not the owner of this token"
            );
            require(
                initialMintClaimLedger[tokenIds[i]] == false,
                "Rewards already claimed for this token"
            );
            initialMintClaimLedger[tokenIds[i]] = true;

            if (tokenIds[i] <= 500) rewards += INITIAL_MINT_REWARD_TIER_1;
            else if (tokenIds[i] > 500 && tokenIds[i] < 1500)
                rewards += INITIAL_MINT_REWARD_TIER_2;
            else if (tokenIds[i] > 5555 || isLegendary(i))
                rewards += INITIAL_MINT_REWARD_LEGENDRY_TIER;
            else rewards += INITIAL_MINT_REWARD_TIER_3;
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
            tokenID == 451
        ) return true;

        return false;
    }

    // The main accounting modifier.
    // It runs when the user interacts with any other function.
    // and before the function itself.
    // stores the owed results till now in the totalWhalesEarnedPerAddress
    // mapping. It then sets the lastInteractionTimeStamp to the current block.timestamp
    modifier updateRewardsForUser(address account) {
        if (userFirstInteracted[msg.sender]) {
            totalWhalesEarnedPerAddress[msg.sender] +=
                ((block.timestamp - lastInteractionTimeStamp[msg.sender]) *
                    totalBluesStakedPerAddress[msg.sender] *
                    userMultiplier[msg.sender]) /
                1 days;

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

    //read only function.
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

    // only owner
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
