pragma solidity ^0.8.2;

import "./ERC721Enumerable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./MetashotToken.sol";

contract MetaclubbersStakeHolder is Initializable, IERC721ReceiverUpgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    struct Stake {
        uint256 tokenId;
        uint80 lastClaimTimestamp;
        address owner;
    }
    struct StackReward {
        uint256 amount;
        uint256 reward;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event TokenClaimed(uint256 tokenId, uint256 owed);
    event BalanceClaimed(uint256 tokenId, uint256 owed);

    // References to other contracts
    ERC721Enumerable token;
    MetashotToken currency;

    // Which NFT is currently the holder contract?
    mapping(uint256 => Stake) public staked;

    // Stake inventory
    mapping(address => mapping(uint256 => uint256)) public _stakedTokens;
    mapping(address => uint256) public _stakedTokensCount;
    mapping(uint256 => uint256) public _stakedTokensIndex;

    uint256 public constant DAILY_CURRENCY_RATE = 5 ether;
    uint256 public constant BONUS_CURRENCY_RATE = 35 ether;
    uint256 public constant BONUS_TIME_DELAY = 30 days;
    StackReward[] public STACK_REWARDS;
    uint256 public constant STACK_REWARDS_TIME_DELAY = 7 days;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(ERC721Enumerable token_, MetashotToken currency_) initializer public {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        token = token_;
        currency = currency_;

        STACK_REWARDS.push(StackReward({
            amount: 1,
            reward: 10 ether
        }));
        STACK_REWARDS.push(StackReward({
            amount: 3,
            reward: 35 ether
        }));
        STACK_REWARDS.push(StackReward({
            amount: 5,
            reward: 80 ether
        }));
        STACK_REWARDS.push(StackReward({
            amount: 10,
            reward: 200 ether
        }));
        STACK_REWARDS.push(StackReward({
            amount: 20,
            reward: 500 ether
        }));
    }

    function addManyToHolder(address account, uint256[] calldata tokenIds) external {
        require(account == _msgSender() || _msgSender() == address(token), "MetaclubbersStakeHolder: you cannot give your tokens away");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(token.ownerOf(tokenIds[i]) == _msgSender(), "MetaclubbersStakeHolder: not your token");

            if (tokenIds[i] == 0) {
                continue;
            }

            token.transferFrom(_msgSender(), address(this), tokenIds[i]);
            _addTokenToHolder(account, tokenIds[i]);
        }
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "MetaclubbersStakeHolder: balance query for the zero address");
        return _stakedTokensCount[owner];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < balanceOf(owner), "MetaclubbersStakeHolder: owner index out of bounds");
        return _stakedTokens[owner][index];
    }

    function _addTokenToHolder(address account, uint256 tokenId) internal whenNotPaused {
        // Update stake inventory
        _stakedTokens[account][_stakedTokensCount[account]] = tokenId;
        _stakedTokensIndex[tokenId] = _stakedTokensCount[account];
        _stakedTokensCount[account]++;

        // Set staked
        staked[tokenId] = Stake({
            owner: account,
            tokenId: tokenId,
            lastClaimTimestamp: uint80(block.timestamp)
        });

        // Emit token staked event
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    function _calculateStackTokenBalance(uint256[] calldata tokenIds, bool skipOwnerShipCheck) internal view returns (uint256 owed) {
        uint256 amount = tokenIds.length;
        uint80 mostRecentClaimTimestamp;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Stake memory stake = staked[tokenId];

            if(skipOwnerShipCheck == false) {
                require(stake.owner == _msgSender(), "MetaclubbersStakeHolder: not your token");
            }

            if(stake.lastClaimTimestamp > mostRecentClaimTimestamp) {
                mostRecentClaimTimestamp = stake.lastClaimTimestamp;
            }
        }

        if(amount == 0 || mostRecentClaimTimestamp == 0) {
            owed = 0;
            return owed;
        }

        StackReward memory applicableStackReward;
        for (uint i = 0; i < STACK_REWARDS.length; i++) {
            StackReward memory stackReward = STACK_REWARDS[i];

            if(amount >= stackReward.amount) {
                applicableStackReward = stackReward;
            } else {
                break;
            }
        }

        if(applicableStackReward.amount != 0) {
            uint256 stakeTime = (block.timestamp - mostRecentClaimTimestamp);
            owed = uint(stakeTime / STACK_REWARDS_TIME_DELAY) * applicableStackReward.reward;
        } else {
            owed = 0;
        }
    }

    function _calculateTokenBalance(uint256 tokenId) internal view returns (uint256 owed) {
        Stake memory stake = staked[tokenId];

        // Check if stake exists
        if(stake.owner != address(0x0) && stake.lastClaimTimestamp != 0) {
            uint256 stakeTime = (block.timestamp - stake.lastClaimTimestamp);
            uint256 stakeBalance = stakeTime * DAILY_CURRENCY_RATE / 1 days;
            uint256 bonusBalance = (uint(stakeTime / BONUS_TIME_DELAY) * BONUS_CURRENCY_RATE);
            owed = stakeBalance + bonusBalance;
        } else {
            owed = 0;
        }
    }

    function _claimSingleFromHolder(uint256 tokenId) internal returns (uint256 owed) {
        Stake memory stake = staked[tokenId];
        require(stake.owner == _msgSender(), "MetaclubbersStakeHolder: you cannot claim this");

        owed = _calculateTokenBalance(tokenId);

        token.safeTransferFrom(address(this), _msgSender(), tokenId, "");

        delete staked[tokenId];
        _removeTokenFromStakeEnumeration(_msgSender(), tokenId);

        emit TokenClaimed(tokenId, owed);
    }

    function _balanceClaimSingle(uint256 tokenId) internal returns (uint256 owed) {
        Stake memory stake = staked[tokenId];
        require(stake.owner == _msgSender(), "MetaclubbersStakeHolder: you cannot claim funds for this");

        owed = _calculateTokenBalance(tokenId);

        staked[tokenId].lastClaimTimestamp = uint80(block.timestamp);

        emit BalanceClaimed(tokenId, owed);
    }

    function _removeTokenFromStakeEnumeration(address owner, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex = _stakedTokensCount[owner] - 1;
        uint256 tokenIndex = _stakedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _stakedTokens[owner][lastTokenIndex];

            _stakedTokens[owner][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _stakedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _stakedTokensIndex[tokenId];
        delete _stakedTokens[owner][lastTokenIndex];
        _stakedTokensCount[owner]--;
    }

    function claimManyFromHolder(uint256[] calldata tokenIds) external whenNotPaused {
        uint256 owed = _calculateStackTokenBalance(tokenIds, false);
        for (uint i = 0; i < tokenIds.length; i++) {
            owed += _claimSingleFromHolder(tokenIds[i]);
        }
        if (owed == 0) return;

        if(currency.totalSupply() + owed <= currency.maxSupply()) {
            currency.mint(_msgSender(), owed);
        }
    }

    function balanceClaimMany(uint256[] calldata tokenIds) external whenNotPaused {
        uint256 owed = _calculateStackTokenBalance(tokenIds, false);
        for (uint i = 0; i < tokenIds.length; i++) {
            owed += _balanceClaimSingle(tokenIds[i]);
        }
        if (owed == 0) return;

        if(currency.totalSupply() + owed <= currency.maxSupply()) {
            currency.mint(_msgSender(), owed);
        }
    }

    function balance(uint256[] calldata tokenIds) external view returns(uint256) {
        uint256 owed = _calculateStackTokenBalance(tokenIds, true);
        for (uint i = 0; i < tokenIds.length; i++) {
            owed += _calculateTokenBalance(tokenIds[i]);
        }
        return owed;
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "MetaclubbersStakeHolder: you cannot send tokens directly to contract");
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
