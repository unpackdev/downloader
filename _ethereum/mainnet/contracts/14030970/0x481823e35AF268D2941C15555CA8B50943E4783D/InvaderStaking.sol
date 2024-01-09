// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


import "./ERC20Capped.sol";
import "./Ownable.sol";
import "./IERC721Enumerable.sol";

contract InvaderStaking is ERC20Capped, Ownable  {
    uint256 public MAX_WALLET_STAKED = 30;
    uint256 public EMISSIONS_RATE = 115740740740740; // 10e18 (Rate by Decimals)/ 86400 (Daily Secs)
    address public ADDRESS = 0x246e29ef6987637e48e7509F91521Ce64EB8c831;
    address public VAULT = 0x563e6750e382fe86E458153ba520B89F986471aa;
    bool public stakingLive = true;

    mapping(uint256 => uint256) internal TokenIdTimeStaked;
    mapping(uint256 => address) internal TokenIdToStaker;
    mapping(address => uint256[]) internal StakerToTokenIds;
    
    IERC721Enumerable private _IERC721Enumerable = IERC721Enumerable(ADDRESS);

    constructor() ERC20("Catnip", "CATNIP")  ERC20Capped(2000000000 * (10**uint256(18))) {
        _mint(VAULT, 500000000 * (10**uint256(18)));
    }

    modifier stakingEnabled {
        require(stakingLive, "STAKING_NOT_LIVE");
        _;
    } 

    function getTokensStaked(address staker) public view returns (uint256[] memory) {
        return StakerToTokenIds[staker];
    }
    
    function getStakedCount(address staker) public view returns (uint256) {
        return StakerToTokenIds[staker].length;
    }

    function removeTokenIdFromArray(uint256[] storage array, uint256 tokenId) internal {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == tokenId) {
                length--;
                if (i < length) {
                    array[i] = array[length];
                }
                array.pop();
                break;
            }
        }
    }

    // Stake tokens by specific IDs
    function stakeTokensByIds(uint256[] memory tokenIds) public stakingEnabled {
        require(getStakedCount(msg.sender) + tokenIds.length <= MAX_WALLET_STAKED, "MAX_TOKENS_STAKED_PER_WALLET");
        require(totalSupply() < cap(), "CAP_REACHED");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(_IERC721Enumerable.ownerOf(id) == msg.sender && TokenIdToStaker[id] == address(0), "TOKEN_IS_NOT_YOURS");
            _IERC721Enumerable.transferFrom(msg.sender, address(this), id);

            StakerToTokenIds[msg.sender].push(id);
            TokenIdTimeStaked[id] = block.timestamp;
            TokenIdToStaker[id] = msg.sender;
        }
    }

    // Unstake all and claim all rewards
    function unstakeAll() public {
        require(getStakedCount(msg.sender) > 0, "NEED_ONE_STAKED");
        uint256 totalRewards = 0;

        for (uint256 i = StakerToTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = StakerToTokenIds[msg.sender][i - 1];

            _IERC721Enumerable.transferFrom(address(this), msg.sender, tokenId);
            totalRewards += ((block.timestamp - TokenIdTimeStaked[tokenId]) * EMISSIONS_RATE);
            StakerToTokenIds[msg.sender].pop();
            TokenIdToStaker[tokenId] = address(0);
        }

        _mint(msg.sender, totalRewards);
    }

    // Unstake specific tokens
    function unstakeTokensByIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(TokenIdToStaker[id] == msg.sender, "NOT_ORIGINAL_STAKER");

            _IERC721Enumerable.transferFrom(address(this), msg.sender, id);
            totalRewards += ((block.timestamp - TokenIdTimeStaked[id]) * EMISSIONS_RATE);

            removeTokenIdFromArray(StakerToTokenIds[msg.sender], id);
            TokenIdToStaker[id] = address(0);
        }

        _mint(msg.sender, totalRewards);
    }

    // Claim reward by specific token ID
    function claimByTokenId(uint256 tokenId) public {
        require(TokenIdToStaker[tokenId] == msg.sender, "NOT_STAKED_BY_YOU");
        _mint(msg.sender, ((block.timestamp - TokenIdTimeStaked[tokenId]) * EMISSIONS_RATE));
        TokenIdTimeStaked[tokenId] = block.timestamp;
    }

    // Claim all rewards without unstaking
    function claimAll() public {
        uint256 totalRewards = 0;

        uint256[] memory tokenIds = StakerToTokenIds[msg.sender];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(TokenIdToStaker[id] == msg.sender, "NOT_STAKED_BY_YOU");
            totalRewards += ((block.timestamp - TokenIdTimeStaked[id]) * EMISSIONS_RATE);
            TokenIdTimeStaked[id] = block.timestamp;
        }

        _mint(msg.sender, totalRewards);
    }

    // Get user pending rewards
    function getAllRewards(address staker) public view returns (uint256) {
        uint256 totalRewards = 0;

        uint256[] memory TokenIds = StakerToTokenIds[staker];
        for (uint256 i = 0; i < TokenIds.length; i++) {
            totalRewards += ((block.timestamp - TokenIdTimeStaked[TokenIds[i]]) * EMISSIONS_RATE);
        }

        return totalRewards;
    }

    // Get rewards by that specific ID
    function getRewardsByTokenId(uint256 tokenId) public view returns (uint256) {
        require(TokenIdToStaker[tokenId] != address(0), "TOKEN_NOT_STAKED");

        uint256 secondsStaked = block.timestamp - TokenIdTimeStaked[tokenId];
        return secondsStaked * EMISSIONS_RATE;
    }

    // Get staker of a certain Token ID
    function getTokenStaker(uint256 tokenId) public view returns (address) {
        return TokenIdToStaker[tokenId];
    }

    // Toggle staking live
    function toggle() external onlyOwner {
        stakingLive = !stakingLive;
    }

    // For future halvening
    function setEmissionRate(uint256 rate) external onlyOwner {
        EMISSIONS_RATE = rate;
    }

    // Change vault address if needed
    function setVaultAddress(address addr) external onlyOwner {
       VAULT = addr;
    }

    // Airdrop Catnip for Offchain collection
    function airdrop(address add, uint256 amount) external onlyOwner {
       _mint(add, amount);
    }
}