// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721AQueryableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./console.sol";

/**
 * @title Highstack Reward Pool
 * @author highstack.co
 * @notice This is a contract instance that allows users to register NFTs to collect rewards.
 */

contract HighstackRewardPool is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address private constant _burner =
        0x000000000000000000000000000000000000dEaD;

    ERC721AQueryableUpgradeable private erc721Address;
    PoolInfo public pool;

    struct PoolInfo {
        uint256 cumulativeRewards; // supply of rewards tokens ever deposited into this pool.
        uint256 paidOutRewards; // supply of rewards tokens paid out.
        uint256 curRewardsSupply; // current supply of rewards
        uint256 totalTokensRegistered; // current amount of tokens staked (or... total shares)
        uint256 accERC20PerShare; // Accumulated ERC20s per share, mul by 1e36.
    }

    // mapping of ids => reward debt
    mapping(uint256 => uint256) public rewardDebt;
    mapping(uint256 => bool) public isRegistered;
    mapping(uint256 => uint256) public tierById;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    receive() external payable {
        addRewards(msg.value);
    }

    /**
     * @notice The constructor for the Staking Token.
     * @param nftAddress Contract address of token to be staked by users
     */
    function initialize(ERC721AQueryableUpgradeable nftAddress)
        public
        initializer
    {
        erc721Address = nftAddress;
        pool = PoolInfo({
            cumulativeRewards: 0,
            paidOutRewards: 0,
            curRewardsSupply: 0,
            totalTokensRegistered: 0,
            accERC20PerShare: 0
        });
    }

    function setTokenTiers(uint256[] memory _tokenIds, uint8 weighting)
        external
        onlyOwner
    {
        // default is 100;
        for (uint256 _i = 0; _i < _tokenIds.length; _i++) {
            tierById[_tokenIds[_i]] = weighting;
        }
    }

    // This is used to add rewards for ERC20 tokens to be instantly distributed.
    function addRewards(uint256 amount) public nonReentrant {
        require(
            pool.totalTokensRegistered > 0,
            "No one to distribute rewards to :("
        );
        pool.accERC20PerShare =
            pool.accERC20PerShare +
            ((amount * (1e36)) / (pool.totalTokensRegistered));
        pool.cumulativeRewards = pool.cumulativeRewards + (amount);
    }

    function stakedTokenAddress() external view returns (address) {
        return address(erc721Address);
    }

    function registerForRewards(uint256[] memory _tokenIds)
        external
        nonReentrant
    {
        uint256 tokensToRegister = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenID = _tokenIds[i];
            require(
                erc721Address.ownerOf(tokenID) == msg.sender,
                "User does not own token"
            );
            if (!isRegistered[tokenID]) {
                isRegistered[tokenID] = true;
                uint256 tier = (
                    tierById[tokenID] == 0
                        ? uint256(100)
                        : uint256(tierById[tokenID])
                );

                rewardDebt[tokenID] = (pool.accERC20PerShare * tier) / (1e36);

                pool.totalTokensRegistered += tier;
                tokensToRegister++;
            }
        }
        emit Deposit(msg.sender, tokensToRegister);
    }

    function calcHarvestTotForId(uint256 nftId) public view returns (uint256) {
        if (!isRegistered[nftId]) {
            return 0;
        }
        uint256 _accERC20PerShare = pool.accERC20PerShare;
        uint256 tier = tierById[nftId] == 0 ? uint256(100) : tierById[nftId];
        return (_accERC20PerShare * tier) / (1e36) - rewardDebt[nftId];
    }

    function calcHarvestTotForUser(address userAddress)
        public
        view
        returns (uint256)
    {
        uint256[] memory idsOwned = erc721Address.tokensOfOwner(userAddress);
        uint256 harvestTot = 0;
        for (uint256 i = 0; i < idsOwned.length; i++) {
            harvestTot += calcHarvestTotForId(idsOwned[i]);
        }
        return harvestTot;
    }

    function listRegisteredTokens(address userAddress)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory idsOwned = erc721Address.tokensOfOwner(userAddress);
        
        uint256 counter = 0;
        for (uint256 i = 0; i < idsOwned.length; i++) {
            uint256 nftId = idsOwned[i];
            if (isRegistered[nftId]) {
                counter++;
            }
        }
        // This is a result of solidity's non dynamic memory arrays.
        // A potential improvement is recursiveness in solidity :o 
        uint256[] memory registeredIds = new uint256[](counter);
        counter = 0;
        for (uint256 i = 0; i < idsOwned.length; i++) {
            uint256 nftId = idsOwned[i];
            if (isRegistered[nftId]) {
                registeredIds[counter] = nftId;
                counter++;
            }
        }
        return registeredIds;
    }

    function harvestRewards() public {
        uint256[] memory idsOwned = erc721Address.tokensOfOwner(msg.sender);
        for (uint256 i = 0; i < idsOwned.length; i++) {
            uint256 id = idsOwned[i];
            if (!isRegistered[id]) {
                continue;
            }
            harvestForId(id);
        }
    }

    function harvestForId(uint256 id) public nonReentrant {
        uint256 amount = calcHarvestTotForId(id);
        require(
            erc721Address.ownerOf(id) == msg.sender,
            "User does not own nft"
        );
        rewardDebt[id] += amount;
        (bool success, ) = address(msg.sender).call{value: amount}("");
        if (success) {
            pool.curRewardsSupply = address(this).balance;
            pool.paidOutRewards = pool.paidOutRewards + (amount);
        }
    }
}
