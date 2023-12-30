// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./SafeMath.sol";
import "./Initializable.sol";
import "./Ownable.sol";


interface StakingPoolI {
    function totalRewards() external returns (uint256);
    function startPool() external;
}

interface DebaseI {
    function totalSupply( ) external view returns(uint256);
    function rebase(uint256 epoch, int256 supplyDelta) external returns (uint256);
}

interface DebasePolicyI {
    function rebase() external;
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
    DebaseI public debase;
    DebasePolicyI public debasePolicy;
    StakingPoolI public debaseDAIPool;
    StakingPoolI public debaseYCurvePool;
    StakingPoolI public degovUNIPool;
    bool public rebaseStarted;
    uint256 public maximumRebaseTime;
    uint256 public rebaseRequiredSupply;

    event LogRebaseStarted(uint256 timeStarted);

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
        address debase_,
        address debasePolicy_,
        address debaseDAIPool_,
        address debaseYCurvePool_,
        address degovUNIPool_,
        uint256 requiredSupplyRatio,
        uint256 oracleStartTimeOffset
    ) external initializer {
        debase = DebaseI(debase_);
        debasePolicy = DebasePolicyI(debasePolicy_);

        debaseDAIPool = StakingPoolI(debaseDAIPool_);
        debaseYCurvePool = StakingPoolI(debaseYCurvePool_);
        degovUNIPool = StakingPoolI(degovUNIPool_);

        maximumRebaseTime = block.timestamp + oracleStartTimeOffset;
        rebaseStarted = false;
        rebaseRequiredSupply = (debase.totalSupply().mul(requiredSupplyRatio)).div(100);
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
            uint256 rewardsDistributed = debaseDAIPool.totalRewards().add(
                debaseYCurvePool.totalRewards()
            );

            require(
                rewardsDistributed >= rebaseRequiredSupply ||
                    block.timestamp >= maximumRebaseTime,
            "Not enough rewards distributed or time less than start time");
            
            //Start degov reward drop
            degovUNIPool.startPool();
            rebaseStarted = true;
            emit LogRebaseStarted(block.timestamp);
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
