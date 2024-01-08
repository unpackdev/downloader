// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./ERC165Upgradeable.sol";

import "./IRewardPool.sol";
import "./IOwnable.sol";
import "./IPausable.sol";

contract RewardPoolTemplate_R1 is Initializable, ContextUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, OwnableUpgradeable, ERC20Upgradeable, ERC165Upgradeable, IRewardPool {

    uint8 constant public PAYOUT_TYPE_UNIFORM = uint8(0x00);

    uint16 constant public CLAIM_MODE_UNAVAILABLE = uint16(0 << 0);
    uint16 constant public CLAIM_MODE_ERC20 = uint16(1 << 0);
    uint16 constant public CLAIM_MODE_PARACHAIN = uint16(1 << 1);

    struct RewardPayout {
        uint8 payoutType;
        uint128 totalRewards;
        uint64 fromBlock;
        uint32 durationBlocks;
    }

    struct RewardState {
        uint64 firstNotClaimedBlock;
        uint128 pendingRewards;
        uint32 activeRewardPayout;
    }

    RewardPayout[] private _rewardPayouts;
    mapping(address => RewardState) _rewardStates;
    address private _transactionNotary;
    mapping(bytes32 => bool) _verifiedProofs;
    IERC20Upgradeable private _stakingToken;
    uint8 private _decimals;
    address private _multiSigWallet;
    uint16 private _claimMode;
    bool private _burnEnabled;

    function initialize(string calldata symbol, string calldata name, uint8 decimals_, address transactionNotary, address multiSigWallet, IERC20Upgradeable rewardToken, uint16 claimMode) external initializer {
        __Context_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __Ownable_init();
        __ERC20_init(name, symbol);
        __RewardPool_init(decimals_, transactionNotary, multiSigWallet, rewardToken, claimMode);
    }

    function __RewardPool_init(uint8 decimals_, address transactionNotary, address multiSigWallet, IERC20Upgradeable stakingToken, uint16 claimMode) internal {
        // init contract state
        _transactionNotary = transactionNotary;
        _decimals = decimals_;
        _multiSigWallet = multiSigWallet;
        _claimMode = claimMode;
        _stakingToken = stakingToken;
        // do some validations
        if (isTokenClaim()) {
            require(address(stakingToken) != address(0x00), "staking token is required for ERC20 claim mode");
        }
        // make sure contract is paused by default
        _pause();
    }

    function getRewardPayouts() external view returns (RewardPayout[] memory) {
        return _rewardPayouts;
    }

    function getTransactionNotary() external view returns (address) {
        return _transactionNotary;
    }

    function getRewardToken() external view returns (IERC20Upgradeable) {
        return _stakingToken;
    }

    function getStakingToken() external view returns (IERC20Upgradeable) {
        return _stakingToken;
    }

    function getMultiSigWallet() external view returns (address) {
        return _multiSigWallet;
    }

    function getClaimMode() external view returns (uint16) {
        return _claimMode;
    }

    function getCurrentRewardState(address account) external view returns (RewardState memory) {
        return _rewardStates[account];
    }

    function getFutureRewardState(address account) external view returns (RewardState memory) {
        RewardState memory rewardState = _rewardStates[account];
        _calcPendingRewards(balanceOf(account), rewardState);
        return rewardState;
    }

    modifier onlyMultiSig() {
        require(msg.sender == _multiSigWallet, "only multi-sig");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == _transactionNotary, "Operator: not allowed");
        _;
    }

    modifier whenTokenBurnEnabled() {
        require(_burnEnabled, "token burning is not allowed yet");
        _;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function changeMultiSigWallet(address multiSigWallet) external onlyMultiSig {
        _multiSigWallet = multiSigWallet;
    }

    modifier whenZeroSupply() {
        require(totalSupply() == 0, "total supply is not zero");
        _;
    }

    function initZeroRewardPayout(uint256 maxSupply, uint8 payoutType, uint64 fromBlock, uint64 toBlockExclusive, uint256 amount) external onlyMultiSig whenZeroSupply whenPaused override {
        // mint max possible total supply of aDOTp tokens and locked them on smart contract
        _mint(address(this), maxSupply);
        // deposit zero reward payout to init first distribution scheme
        _depositRewardPayout(payoutType, fromBlock, toBlockExclusive, amount);
        // make contract active
        _unpause();
    }

    function depositRewardPayout(uint8 payoutType, uint64 fromBlock, uint64 toBlockExclusive, uint256 amount) external onlyMultiSig whenNotPaused override {
        _depositRewardPayout(payoutType, fromBlock, toBlockExclusive, amount);
    }

    function _depositRewardPayout(uint8 payoutType, uint64 fromBlock, uint64 toBlockExclusive, uint256 amount) internal {
        require(toBlockExclusive > fromBlock, "intersection is not allowed");
        // verify payout type
        require(payoutType == PAYOUT_TYPE_UNIFORM, "invalid payout type");
        // we must be sure that reward payouts are ordered and doesn't intersect to each other
        if (_rewardPayouts.length > 0) {
            RewardPayout memory latestRewardPayout = _rewardPayouts[_rewardPayouts.length - 1];
            require(latestRewardPayout.fromBlock + latestRewardPayout.durationBlocks <= fromBlock, "intersection is not allowed");
        }
        // write new reward payout to storage
        _rewardPayouts.push(RewardPayout({
        totalRewards : uint128(amount),
        fromBlock : fromBlock,
        durationBlocks : uint32(toBlockExclusive - fromBlock),
        payoutType : payoutType
        }));
        // transfer tokens from sender
        if (address(_stakingToken) != address(0x00)) {
            require(_stakingToken.transferFrom(msg.sender, address(this), amount), "can't transfer reward tokens");
        }
        // emit event
        emit RewardPayoutDeposited(payoutType, fromBlock, toBlockExclusive, amount);
    }

    function isClaimUsed(uint256 claimId) external view override returns (bool) {
        return _verifiedProofs[bytes32(claimId)];
    }

    function claimTokensFor(uint256 claimId, uint256 amount, uint256 claimBeforeBlock, address account, bytes memory signature) external nonReentrant whenNotPaused override {
        // do proof verification
        require(block.number < claimBeforeBlock, "claim is expired");
        bytes32 messageHash = keccak256(abi.encode(address(this), claimId, amount, claimBeforeBlock, account));
        require(ECDSAUpgradeable.recover(messageHash, signature) == _transactionNotary, "bad signature");
        // make sure proof can only be used once
        require(!_verifiedProofs[bytes32(claimId)], "proof is already used");
        /* TODO: "tbh we don't need to store claim id, because its enough to remember claimBeforeBlock field instead of it and this operation can safe 20k gas for user" */
        _verifiedProofs[bytes32(claimId)] = true;
        // send tokens to user (advance is included in mint operation, check on transfer hook)
        _transfer(address(this), account, amount);
        // we need to recalculate entire rewards before claim to restore possible lost tokens based on new share amount
        RewardState memory rewardState = _rewardStates[account];
        rewardState.activeRewardPayout = 0;
        rewardState.firstNotClaimedBlock = 0;
        _calcPendingRewards(amount, rewardState);
        _rewardStates[account] = rewardState;
        // emit event
        emit TokensClaimed(claimId, amount, claimBeforeBlock, account);
    }

    function claimableRewardsOf(address account) external view override returns (uint256) {
        RewardState memory rewardState = _rewardStates[account];
        _calcPendingRewards(balanceOf(account), rewardState);
        return uint256(rewardState.pendingRewards);
    }

    function isTokenClaim() public view override returns (bool) {
        return (_claimMode & CLAIM_MODE_ERC20) > 0;
    }

    function isParachainClaim() public view override returns (bool) {
        return (_claimMode & CLAIM_MODE_PARACHAIN) > 0;
    }

    function claimTokenRewards() external nonReentrant whenNotPaused override {
        require(isTokenClaim(), "not supported claim mode");
        address account = address(msg.sender);
        uint256 amount = _chargeRewardsClaim(account);
        require(_stakingToken.transfer(account, amount), "can't send rewards");
        emit ClaimedTokenRewards(account, amount);
    }

    function claimParachainRewards(bytes calldata recipient) external nonReentrant whenNotPaused override {
        require(isParachainClaim(), "not supported claim mode");
        address account = address(msg.sender);
        uint256 amount = _chargeRewardsClaim(account);
        emit ClaimedParachainRewards(account, recipient, amount);
    }

    function _chargeRewardsClaim(address account) internal returns (uint256) {
        RewardState memory rewardState = _rewardStates[account];
        _calcPendingRewards(balanceOf(account), rewardState);
        require(rewardState.pendingRewards > 0, "there is no rewards to be claimed");
        uint256 amount = rewardState.pendingRewards;
        rewardState.pendingRewards = 0;
        _rewardStates[account] = rewardState;
        return amount;
    }

    function _advancePendingRewards(address account) internal {
        // we can't do advance for this because it mints useless rewards otherwise
        if (account == address(this)) {
            return;
        }
        // write new pending reward state from memory to storage
        RewardState memory rewardState = _rewardStates[account];
        _calcPendingRewards(balanceOf(account), rewardState);
        _rewardStates[account] = rewardState;
    }

    function _calcPendingRewards(uint256 balance, RewardState memory rewardState) internal view {
        // don't do any advances before rewards payed or there is active scheme
        if (_rewardPayouts.length == 0 || rewardState.activeRewardPayout >= _rewardPayouts.length) {
            return;
        }
        // do reward distribution
        uint64 latestPayoutBlock = 0;
        uint256 totalRewardPayouts = _rewardPayouts.length;
        for (uint256 i = rewardState.activeRewardPayout; i < totalRewardPayouts; i++) {
            RewardPayout memory rewardPayout = _rewardPayouts[i];
            if (i == totalRewardPayouts - 1) {
                latestPayoutBlock = rewardPayout.fromBlock + rewardPayout.durationBlocks;
            }
            _calcPendingRewardsForPayout(balance, rewardState, rewardPayout);
        }
        // change latest reward payout offset (tiny optimization)
        uint64 blockNumber = uint64(block.number);
        if (blockNumber >= latestPayoutBlock) {
            rewardState.activeRewardPayout = uint32(_rewardPayouts.length);
            rewardState.firstNotClaimedBlock = latestPayoutBlock;
        } else {
            rewardState.activeRewardPayout = uint32(_rewardPayouts.length - 1);
            rewardState.firstNotClaimedBlock = blockNumber + 1;
        }
    }

    function _calcPendingRewardsForPayout(uint256 balance, RewardState memory rewardState, RewardPayout memory currentPayout) internal view {
        (uint256 fromBlock, uint256 toBlockExclusive) = (uint256(currentPayout.fromBlock), uint256(currentPayout.fromBlock + currentPayout.durationBlocks));
        // special case when we're out of allowed block range, just skip this payout scheme
        uint64 blockNumber = uint64(block.number);
        if (blockNumber < fromBlock || rewardState.firstNotClaimedBlock >= toBlockExclusive) {
            return;
        }
        uint256 stakingBlocks = MathUpgradeable.min(blockNumber + 1, toBlockExclusive) - MathUpgradeable.max(fromBlock, rewardState.firstNotClaimedBlock);
        // calc reward distribution based on payout type
        if (currentPayout.payoutType == PAYOUT_TYPE_UNIFORM) {
            uint256 avgRewardsPerBlock = uint256(currentPayout.totalRewards) / currentPayout.durationBlocks;
            uint256 accountShare = 1e18 * balance / totalSupply();
            rewardState.pendingRewards += uint128(accountShare * avgRewardsPerBlock / 1e18 * stakingBlocks);
        } else {
            revert("not supported payout type");
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 /*amount*/) internal override {
        if (from != to) {
            _advancePendingRewards(from);
        }
        _advancePendingRewards(to);
    }

    function toggleTokenBurn(bool isEnabled) external onlyOperator whenNotPaused override {
        _burnEnabled = isEnabled;
    }

    function isTokenBurnEnabled() external view override returns (bool) {
        return _burnEnabled;
    }

    function burnTokens(uint256 amount, bytes calldata recipient) external nonReentrant whenNotPaused whenTokenBurnEnabled override {
        uint256 balance = balanceOf(_msgSender());
        require(balance >= amount, "cannot burn more tokens than available");
        _burn(_msgSender(), amount);
        address account = address(msg.sender);
        emit TokensBurnedForRefund(account, recipient, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId)
        || interfaceId == type(IOwnable).interfaceId
        || interfaceId == type(IPausable).interfaceId
        || interfaceId == type(IERC20Upgradeable).interfaceId
        || interfaceId == type(IERC20MetadataUpgradeable).interfaceId
        || interfaceId == type(IRewardPool).interfaceId;
    }
}
