// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./SafeMath.sol";
import "./Initializable.sol";
import "./Ownable.sol";
import "./Debase.sol";
import "./DebasePolicy.sol";

interface YearnRewardsI {
    function startTime() external returns (uint256);

    function totalRewards() external returns (uint256);

    function y() external returns (address);
}

interface DegovDebasePoolI {
    function startPool() external;
}

interface UniV2PairI {
    function sync() external;
}

/**
 * @title Orchestrator
 * @notice The orchestrator is the main entry point for rebase operations. It coordinates the debase policy
 *         actions with external consumers.
 */
contract Orchestrator is Ownable, Initializable {
    using SafeMath for uint256;

    // Stable ordering is not guaranteed.
    Debase public debase;
    DebasePolicy public debasePolicy;
    YearnRewardsI public debaseSUsdV2Pool;
    YearnRewardsI public debaseSUsdPool;
    DegovDebasePoolI public degovDebasePool;
    uint256 public orchestratorStartTime;
    bool public rebaseStarted;

    uint256 constant SYNC_GAS = 50000;
    address constant uniFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    struct UniPair {
        bool enabled;
        UniV2PairI pair;
    }

    UniPair[] public uniSyncs;

    modifier indexInBounds(uint256 index) {
        require(
            index < uniSyncs.length,
            "Index must be less than array length"
        );
        _;
    }

    // https://uniswap.org/docs/v2/smart-contract-integration/getting-pair-addresses/
    function genUniAddr(address left, address right)
        internal
        pure
        returns (UniV2PairI)
    {
        address first = left < right ? left : right;
        address second = left < right ? right : left;
        address pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        uniFactory,
                        keccak256(abi.encodePacked(first, second)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
                    )
                )
            )
        );
        return UniV2PairI(pair);
    }

    function initialize(
        Debase debase_,
        DebasePolicy debasePolicy_,
        address debaseSUsdV2Pool_,
        address debaseSUsdPool_,
        address degovDebasePool_
    ) external initializer {
        debase = debase_;
        debasePolicy = debasePolicy_;
        
        orchestratorStartTime = block.timestamp + 1 days;
        rebaseStarted = false;
        
        debaseSUsdV2Pool = YearnRewardsI(debaseSUsdV2Pool_);
        debaseSUsdPool = YearnRewardsI(debaseSUsdPool_);
        degovDebasePool = DegovDebasePoolI(degovDebasePool_);
    }

    function addPair(address token1, address token2) external onlyOwner {
        uniSyncs.push(UniPair(true, genUniAddr(token1, token2)));
    }

    function removePair(uint256 index) external onlyOwner indexInBounds(index) {
        if (index < uniSyncs.length.sub(1)) {
            uniSyncs[index] = uniSyncs[uniSyncs.length.sub(1)];
        }
        uniSyncs.pop();
    }

    function togglePair(uint256 index) external onlyOwner indexInBounds(index) {
        UniPair storage instance = uniSyncs[index];
        instance.enabled = !instance.enabled;
    }

    /**
     * @notice Main entry point to initiate a rebase operation.
     *         The Orchestrator calls rebase on the debase policy and notifies downstream applications.
     *         Contracts are guarded from calling, to avoid flash loan attacks on liquidity
     *         providers.
     *         If a transaction in the transaction list reverts, it is swallowed and the remaining
     *         transactions are executed.
     */
    function rebase() external {
        // Rebase will only be called when 95% of the total supply has been distributed or current time is 3 weeks since the orchestrator was deployed.
        // To stop the rebase from getting stuck if no enough rewards are distributed. This will also start the degov/debase pool reward drops
        if (rebaseStarted == false) {
            uint256 rewardsDistributed = (
                debaseSUsdV2Pool.totalRewards().add(
                    debaseSUsdPool.totalRewards()
                )
            )
                .mul(1e18);

            uint256 rebaseRequiredSupply = (debase.totalSupply().mul(95)).div(
                100
            );

            require(
                rewardsDistributed >= rebaseRequiredSupply ||
                    block.timestamp >= orchestratorStartTime + 3 weeks
            );
            //Start degov reward drop
            degovDebasePool.startPool();
            rebaseStarted = true;
        } 

        require(msg.sender == tx.origin); // solhint-disable-line avoid-tx-origin
        debasePolicy.rebase();

        for (uint256 i = 0; i < uniSyncs.length; i++) {
            if (uniSyncs[i].enabled) {
                address(uniSyncs[i].pair).call{gas: SYNC_GAS}(
                    abi.encode(uniSyncs[i].pair.sync.selector)
                );
            }
        }
        
    }
}
