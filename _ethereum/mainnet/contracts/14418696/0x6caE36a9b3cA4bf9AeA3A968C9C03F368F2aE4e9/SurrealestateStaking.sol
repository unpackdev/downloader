// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

import "./Ownable.sol";
import "./ERC721Holder.sol";

// The NFT that can be staked here.
interface IPPASurrealestates {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// A listening contract can implement this function to get notified any time a user stakes or unstakes.
interface IStakingListener {
    function notifyChange(address account) external;
}

contract SurrealestateStaking is ERC721Holder, Ownable {
    constructor() public {}

    IPPASurrealestates surrealestates;
    address surrealestateContractAddress;

    // The period which people can lock their funds up for to get an xtra multiplier on rewards earned.
    uint256 stakingLockPeriod = 7776000; // 90 days in seconds.

    // (UserAddress => (TokenID => Owned?))
    mapping(address => mapping(uint256 => bool)) public ownerships;
    // Helper list for easy lookup of what Surrealestates an individual has ever staked.
    mapping(address => uint256[]) public tokensTouched;
    // How many Surrealestates an individual is currently staking.
    mapping(address => uint256) public numStakedByAddress;
    // How many Surrealestates are locked in staking by this invididual.
    mapping(address => uint256) public numLockedByAddress;
    // Whether a token is currently recorded as locked.
    mapping(uint256 => bool) public lockedTokens;
    // (TokenID => Timestamp))
    mapping(uint256 => uint256) public tokenLockedUntil;
    // Any time a user interacts with the contract, their rewards up to that point will be calculated and saved.
    mapping(address => uint256) private _tokensEarnedBeforeLastRefresh;
    // Each user has a particular staking refresh timestamp (i.e. last time their rewards were calculated and saved)/
    mapping(address => uint256) private _stakingRefreshTimestamp;
    // Addresses that are allowed to do things like deduct tokens from a user's account or award earning multipliers.
    mapping(address => bool) public approvedManagers;
    // A multiplier defaults to 1 but can be set by a manager in the future for a particular address. This increases
    // the overall rate of earning.
    mapping(address => StakingMultiplier) public stakingMultiplier;

    IStakingListener[] listeners;

    struct StakingMultiplier {
        uint256 numeratorMinus1; // Store as "minus 1" because we want this to default to 1, but uninitialized vars default to 0.
        uint256 denominatorMinus1;
    }

    // Number of seconds a surrealestate must be staked in order to earn 1 token.
    uint256 public earnPeriod = 60;

    modifier onlyApprovedManager() {
        require(
            owner() == msg.sender || approvedManagers[msg.sender],
            "Caller is not an approved manager"
        );
        _;
    }

    /**
     * To stake a Surrealestate, the user sends the ERC721 token to this contract address, which invokes
     * this function.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public virtual override returns (bytes4) {
        require(
            msg.sender == surrealestateContractAddress,
            "Can only receive Surrealestates NFTs"
        );
        refreshTokensEarned(from);

        ownerships[from][tokenId] = true;
        tokensTouched[from].push(tokenId);
        numStakedByAddress[from]++;
        _notifyAllListeners(from);

        return super.onERC721Received(operator, from, tokenId, data);
    }

    function _notifyAllListeners(address account) internal {
        for (uint256 i = 0; i < listeners.length; i++) {
            listeners[i].notifyChange(account);
        }
    }

    /**
     * User can lock their staking in for the stakingLockPeriod, which increases their multiplier.
     */
    function lockStaking(uint256 tokenId) public {
        require(
            ownerships[msg.sender][tokenId],
            "Caller does not own the token"
        );
        refreshTokensEarned(msg.sender);
        _lockStakingForSingleToken(tokenId);
    }

    /**
     * Lock up staking for all tokens the user has.
     */
    function lockStakingForAll() public {
        refreshTokensEarned(msg.sender);
        for (uint256 i = 0; i < tokensTouched[msg.sender].length; i++) {
            uint256 tokenId = tokensTouched[msg.sender][i];
            if (ownerships[msg.sender][tokenId]) {
                _lockStakingForSingleToken(tokenId);
            }
        }
    }

    function _lockStakingForSingleToken(uint256 tokenId) internal {
        if (tokenLockedUntil[tokenId] > block.timestamp) {
            // Token is already locked
            return;
        }
        if (!lockedTokens[tokenId]) {
            numLockedByAddress[msg.sender]++;
            lockedTokens[tokenId] = true;
        }
        tokenLockedUntil[tokenId] = block.timestamp + stakingLockPeriod;
    }

    function refreshTokensEarned(address addr) internal {
        uint256 totalTokensEarned = calculateTokensEarned(addr);
        _tokensEarnedBeforeLastRefresh[addr] = totalTokensEarned;
        _stakingRefreshTimestamp[addr] = block.timestamp;
    }

    function calculateTokensEarned(address addr) public view returns (uint256) {
        uint256 secondsStakedSinceLastRefresh = block.timestamp -
            _stakingRefreshTimestamp[addr];

        uint256 earnPeriodsSinceLastRefresh = secondsStakedSinceLastRefresh /
            earnPeriod;

        uint256 tokensEarnedAfterLastRefresh = (earnPeriodsSinceLastRefresh *
            (numStakedByAddress[addr] + numLockedByAddress[addr]) *
            (stakingMultiplier[addr].numeratorMinus1 + 1)) /
            (stakingMultiplier[addr].denominatorMinus1 + 1);
        return
            _tokensEarnedBeforeLastRefresh[addr] + tokensEarnedAfterLastRefresh;
    }

    /**
     * To unstake, the user calls this function with the tokenID they want to unstake.
     */
    function unstake(uint256 tokenId) public {
        require(
            ownerships[msg.sender][tokenId],
            "Caller is not currently staking the provided tokenId"
        );

        refreshTokensEarned(msg.sender);
        _unstakeSingle(tokenId);
        _notifyAllListeners(msg.sender);
    }

    /**
     * User can unstake all their NFTs at once.
     */
    function unstakeAll() public {
        refreshTokensEarned(msg.sender);
        for (uint256 i = 0; i < tokensTouched[msg.sender].length; i++) {
            uint256 tokenId = tokensTouched[msg.sender][i];
            if (ownerships[msg.sender][tokenId]) {
                _unstakeSingle(tokenId);
            }
        }
        _notifyAllListeners(msg.sender);
    }

    function _unstakeSingle(uint256 tokenId) internal {
        if (tokenLockedUntil[tokenId] > block.timestamp) {
            // Skip ones that are locked.
            return;
        }

        // If we are past the token locktime, then we need to update the the lockedTokens map as well.
        if (lockedTokens[tokenId]) {
            lockedTokens[tokenId] = false;
            numLockedByAddress[msg.sender]--;
        }

        surrealestates.transferFrom(address(this), msg.sender, tokenId);

        ownerships[msg.sender][tokenId] = false;
        numStakedByAddress[msg.sender]--;
    }

    function addApprovedManager(address managerAddr) public onlyOwner {
        approvedManagers[managerAddr] = true;
    }

    function removeApprovedManager(address managerAddr) public onlyOwner {
        approvedManagers[managerAddr] = false;
    }

    function setStakingLockPeriod(uint256 newPeriod)
        public
        onlyApprovedManager
    {
        stakingLockPeriod = newPeriod;
    }

    function setEarnPeriod(uint256 newSeconds) public onlyApprovedManager {
        earnPeriod = newSeconds;
    }

    function setEarningMultiplier(
        address addr,
        uint256 numerator,
        uint256 denominator
    ) public onlyApprovedManager {
        refreshTokensEarned(addr);
        stakingMultiplier[addr] = StakingMultiplier(
            numerator - 1,
            denominator - 1
        );
    }

    function setSurrealestateContract(address newAddress) public onlyOwner {
        surrealestateContractAddress = newAddress;
        surrealestates = IPPASurrealestates(newAddress);
    }

    function addStakingListener(address contractAddress) public onlyOwner {
        listeners.push(IStakingListener(contractAddress));
    }

    function resetStakingListeners() public onlyOwner {
        delete listeners;
    }

    // Only for use in emergency. Can be called by owner to unstake.
    function unstakeAllAsOwner(address addr) public onlyOwner {
        for (uint256 i = 0; i < tokensTouched[addr].length; i++) {
            uint256 tokenId = tokensTouched[addr][i];
            if (ownerships[addr][tokenId]) {
                surrealestates.transferFrom(address(this), addr, tokenId);
                ownerships[addr][tokenId] = false;
                numStakedByAddress[addr]--;
            }
        }
    }
}
