pragma solidity ^0.8.13;

// solmate
import "./SafeTransferLib.sol";

// olympus
import "./BaseAllocator.sol";

// tokemak
import "./UserVotePayload.sol";
import "./ILiquidityPool.sol";
import "./IRewardHash.sol";
import "./IStaking.sol";
import "./IManager.sol";
import "./IRewards.sol";

/// INLINE

interface ITokemakVoting {
    function vote(UserVotePayload memory userVotePayload) external;
}

uint256 constant nmax = type(uint256).max;

library TokemakAllocatorLib {
    function deposit(address reactor, uint256 amount) internal {
        ILiquidityPool(reactor).deposit(amount);
    }

    function requestWithdrawal(address reactor, uint256 amount) internal {
        ILiquidityPool(reactor).requestWithdrawal(amount);
    }

    function withdraw(address reactor, uint256 amount) internal {
        ILiquidityPool(reactor).withdraw(amount);
    }

    function requestedWithdrawals(address reactor)
        internal
        view
        returns (uint256 minCycle, uint256 amount)
    {
        (minCycle, amount) = ILiquidityPool(reactor).requestedWithdrawals(
            address(this)
        );
    }

    function balanceOf(address reactor, address owner)
        internal
        view
        returns (uint256)
    {
        return ERC20(reactor).balanceOf(owner);
    }

    function nmaxarr(uint256 l) internal pure returns (uint256[] memory arr) {
        arr = new uint256[](l);

        for (uint256 i; i < l; i++) {
            arr[i] = nmax;
        }
    }
}

struct TokemakData {
    address voting;
    address staking;
    address rewards;
    address manager;
}

struct PayloadData {
    uint128 amount;
    uint64 cycle;
    uint64 v;
    bytes32 r;
    bytes32 s;
}

error GeneralizedTokemak_ArbitraryCallFailed();
error GeneralizedTokemak_MustInitializeTotalWithdraw();
error GeneralizedTokemak_WithdrawalNotReady(uint256 tAssetIndex_);

contract GeneralizedTokemak is BaseAllocator {
    using SafeTransferLib for ERC20;
    using TokemakAllocatorLib for address;

    address immutable self;

    ITokemakVoting public voting;
    IStaking public staking;
    IRewards public rewards;
    IManager public manager;

    ERC20 public toke;

    address[] public reactors;

    PayloadData public nextPayloadData;

    bool public mayClaim;

    bool public totalWithdrawInitialized;

    // done for ease of verif at time of deployment
    // if you are intending ANYTHING doublecheck these addr
    constructor()
        BaseAllocator(
            AllocatorInitData(
                IOlympusAuthority(0x1c21F8EA7e39E2BA00BC12d2968D63F4acb38b7A),
                ITreasuryExtender(0xb32Ad041f23eAfd682F57fCe31d3eA4fd92D17af),
                new ERC20[](0)
            )
        )
    {
        self = address(this);

        toke = ERC20(0x2e9d63788249371f1DFC918a52f8d799F4a38C94);

        _setTokemakData(
            TokemakData(
                0x43094eD6D6d214e43C31C38dA91231D2296Ca511, // voting
                0x96F98Ed74639689C3A11daf38ef86E59F43417D3, // staking
                0x79dD22579112d8a5F7347c5ED7E609e60da713C5, // rewards
                0xA86e412109f77c45a3BC1c5870b880492Fb86A14 // manager
            )
        );
    }

    // ######################## ~ SAFETY ~ ########################

    function executeArbitrary(address target, bytes memory data)
        external
        onlyGuardian
    {
        (bool success, ) = target.call(data);
        if (!success) revert GeneralizedTokemak_ArbitraryCallFailed();
    }

    // ######################## ~ IMPORTANT OVERRIDES ~ ########################

    function _update(uint256 id)
        internal
        override
        returns (uint128 gain, uint128 loss)
    {
        uint256 index = tokenIds[id];
        address reactor = reactors[index];
        ERC20 underl = _tokens[index];

        if (mayClaim) {
            PayloadData memory payData = nextPayloadData;

            rewards.claim(
                IRewards.Recipient(1, payData.cycle, self, payData.amount),
                uint8(payData.v),
                payData.r,
                payData.s
            );

            mayClaim = false;
        }

        uint256 bal = toke.balanceOf(self);

        if (0 < bal) {
            toke.approve(address(staking), bal);
            staking.deposit(bal);
        }

        bal = underl.balanceOf(self);

        if (0 < bal) {
            underl.approve(reactor, bal);
            reactor.deposit(bal);
        }

        uint128 current = uint128(reactor.balanceOf(self));
        uint128 last = extender.getAllocatorPerformance(id).gain +
            uint128(extender.getAllocatorAllocated(id));

        if (last <= current) gain = current - last;
        else loss = last - current;
    }

    /// @dev If amounts.length is == _tokens.length then you are requestingWithdrawals,
    /// otherwise you are withdrawing. amount beyond _tokens.length does not matter.
    /// @param amounts amounts to withdraw, if amount for one index is type(uint256).max, then take all
    function deallocate(uint256[] memory amounts) public override onlyGuardian {
        uint256 lt = _tokens.length;
        uint256 la = amounts.length;

        for (uint256 i; i <= lt; i++) {
            if (amounts[i] != 0) {
                address reactor;

                if (i < lt) reactor = reactors[i];

                if (lt + 1 < la) {
                    if (amounts[i] == nmax)
                        amounts[i] = i < lt
                            ? reactor.balanceOf(self)
                            : staking.balanceOf(self);

                    if (0 < amounts[i])
                        if (i < lt) reactor.requestWithdrawal(amounts[i]);
                        else staking.requestWithdrawal(amounts[i], 0);
                } else {
                    uint256 cycle = manager.getCurrentCycleIndex();

                    (uint256 minCycle, uint256 amount) = i < lt
                        ? reactor.requestedWithdrawals()
                        : staking.withdrawalRequestsByIndex(self, 0);

                    if (amounts[i] == nmax) amounts[i] = amount;

                    if (cycle < minCycle)
                        revert GeneralizedTokemak_WithdrawalNotReady(i);

                    if (0 < amounts[i])
                        if (i < lt) reactor.withdraw(amounts[i]);
                        else staking.withdraw(amounts[i]);
                }
            }
        }
    }

    function _prepareMigration() internal override {
        if (!totalWithdrawInitialized) {
            revert GeneralizedTokemak_MustInitializeTotalWithdraw();
        } else {
            deallocate(TokemakAllocatorLib.nmaxarr(reactors.length + 1));
        }
    }

    function _deactivate(bool panic) internal override {
        if (panic) {
            deallocate(TokemakAllocatorLib.nmaxarr(reactors.length + 2));
            totalWithdrawInitialized = true;
        }
    }

    function _activate() internal override {
        totalWithdrawInitialized = false;
    }

    // ######################## ~ SETTERS ~ ########################

    function vote(UserVotePayload calldata payload) external onlyGuardian {
        voting.vote(payload);
    }

    function updateClaimPayload(PayloadData calldata data)
        external
        onlyGuardian
    {
        nextPayloadData = data;
        mayClaim = true;
    }

    function addToken(address token, address reactor) external onlyGuardian {
        ERC20(token).safeApprove(address(extender), type(uint256).max);
        ERC20(reactor).safeApprove(address(extender), type(uint256).max);
        _tokens.push(ERC20(token));
        reactors.push(reactor);
    }

    function setTokemakData(TokemakData memory tokeData) external onlyGuardian {
        _setTokemakData(tokeData);
    }

    // ######################## ~ GETTERS ~ ########################

    function tokeAvailable(uint256 scheduleIndex)
        public
        view
        virtual
        returns (uint256)
    {
        return staking.availableForWithdrawal(self, scheduleIndex);
    }

    function tokeDeposited() public view virtual returns (uint256) {
        return staking.balanceOf(self);
    }

    // ######################## ~ GETTER OVERRIDES ~ ########################

    function amountAllocated(uint256 id)
        public
        view
        override
        returns (uint256)
    {
        return reactors[tokenIds[id]].balanceOf(self);
    }

    function name() external pure override returns (string memory) {
        return "GeneralizedTokemak";
    }

    function utilityTokens() public view override returns (ERC20[] memory) {
        uint256 l = reactors.length + 1;
        ERC20[] memory utils = new ERC20[](l);

        for (uint256 i; i < l - 1; i++) {
            utils[i] = ERC20(reactors[i]);
        }

        utils[l - 1] = toke;
        return utils;
    }

    function rewardTokens() public view override returns (ERC20[] memory) {
        ERC20[] memory reward = new ERC20[](1);
        reward[0] = toke;
        return reward;
    }

    // ######################## ~ INTERNAL SETTERS ~ ########################

    function _setTokemakData(TokemakData memory tokeData) internal {
        voting = ITokemakVoting(tokeData.voting);
        staking = IStaking(tokeData.staking);
        rewards = IRewards(tokeData.rewards);
        manager = IManager(tokeData.manager);
    }
}
