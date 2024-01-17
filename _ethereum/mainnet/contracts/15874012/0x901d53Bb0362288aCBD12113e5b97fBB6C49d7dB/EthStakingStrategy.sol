// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

import "./SafeDecimalMath.sol";
import "./IFundV3.sol";
import "./IFundForStrategyV2.sol";
import "./IWrappedERC20.sol";
import "./ITrancheIndexV2.sol";

import "./IWithdrawalManager.sol";
import "./NodeOperatorRegistry.sol";

interface IDepositContract {
    function deposit(
        bytes memory pubkey,
        bytes memory withdrawal_credentials,
        bytes memory signature,
        bytes32 deposit_data_root
    ) external payable;
}

/// @notice Strategy for delegating ETH to ETH2 validators and earn rewards.
contract EthStakingStrategy is Ownable, ITrancheIndexV2 {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IWrappedERC20;

    event ReporterUpdated(address reporter);
    event Received(address from, uint256 amount);
    event FeeRateUpdated(uint256 newTotalFeeRate, uint256 newOperatorFeeRate);
    event OperatorWeightUpdated(uint256 indexed id, uint256 newWeight);
    event BalanceReported(
        uint256 indexed epoch,
        uint256 indexed id,
        uint256 beaconBalance,
        uint256 validatorCount,
        uint256 executionLayerRewards
    );

    uint256 private constant MAX_TOTAL_FEE_RATE = 0.5e18;
    uint256 private constant MAX_OPERATOR_WEIGHT = 1e18;
    uint256 private constant DEPOSIT_AMOUNT = 32 ether;
    uint256 private constant MAX_AUTO_DEPOSIT_COUNT = 100;

    /// @dev Little endian representation of the deposit amount in Gwei.
    bytes32 private constant LITTLE_ENDIAN_DEPOSIT_AMOUNT =
        bytes32(
            uint256(
                ((((32e9 >> (8 * 0)) & 0xFF) << (8 * 7)) |
                    (((32e9 >> (8 * 1)) & 0xFF) << (8 * 6)) |
                    (((32e9 >> (8 * 2)) & 0xFF) << (8 * 5)) |
                    (((32e9 >> (8 * 3)) & 0xFF) << (8 * 4)) |
                    (((32e9 >> (8 * 4)) & 0xFF) << (8 * 3)) |
                    (((32e9 >> (8 * 5)) & 0xFF) << (8 * 2)) |
                    (((32e9 >> (8 * 6)) & 0xFF) << (8 * 1)) |
                    (((32e9 >> (8 * 7)) & 0xFF) << (8 * 0))) << 192
            )
        );

    address public immutable fund;
    address private immutable _tokenUnderlying;
    IDepositContract public immutable depositContract;
    NodeOperatorRegistry public immutable registry;

    /// @notice Fraction of profit that goes to the fund's fee collector and node operators.
    uint256 public totalFeeRate;

    /// @notice Fraction of profit that directly goes to node operators.
    uint256 public operatorFeeRate;

    /// @notice Mapping of node operator ID => amount of underlying lost since the last peak.
    ///         Performance fee is charged only when this value is zero.
    mapping(uint256 => uint256) public currentDrawdowns;

    mapping(uint256 => uint256) public operatorWeights;

    /// @notice Reporter that reports validator balances on the Beacon Chain
    address public reporter;

    uint256 public totalValidatorCount;
    uint256 public operatorCursor;
    mapping(uint256 => uint256) public lastBeaconBalances;
    mapping(uint256 => uint256) public lastValidatorCounts;

    constructor(
        address fund_,
        address depositContract_,
        address registry_,
        uint256 totalFeeRate_,
        uint256 operatorFeeRate_
    ) public {
        fund = fund_;
        _tokenUnderlying = IFundV3(fund_).tokenUnderlying();
        depositContract = IDepositContract(depositContract_);
        registry = NodeOperatorRegistry(registry_);
        _updateFeeRate(totalFeeRate_, operatorFeeRate_);
    }

    receive() external payable {}

    modifier onlyReporter() {
        require(reporter == msg.sender, "Only reporter");
        _;
    }

    function updateReporter(address reporter_) public onlyOwner {
        reporter = reporter_;
        emit ReporterUpdated(reporter);
    }

    /// @notice Report profit to the fund for an individual node operator.
    function report(
        uint256 epoch,
        uint256 id,
        uint256 beaconBalance,
        uint256 validatorCount
    ) external onlyReporter {
        (uint256 profit, uint256 loss, uint256 totalFee, uint256 operatorFee) =
            _report(epoch, id, beaconBalance, validatorCount);
        if (profit != 0) {
            uint256 feeQ = IFundForStrategyV2(fund).reportProfit(profit, totalFee, operatorFee);
            IFundV3(fund).trancheTransfer(
                TRANCHE_Q,
                registry.getRewardAddress(id),
                feeQ,
                IFundV3(fund).getRebalanceSize()
            );
        }
        if (loss != 0) {
            IFundForStrategyV2(fund).reportLoss(loss);
        }
    }

    /// @notice Report profit to the fund for multiple node operators.
    function batchReport(
        uint256 epoch,
        uint256[] memory ids,
        uint256[] memory beaconBalances,
        uint256[] memory validatorCounts
    ) external onlyReporter {
        uint256 size = ids.length;
        require(
            beaconBalances.length == size && validatorCounts.length == size,
            "Unaligned params"
        );
        uint256 sumProfit;
        uint256 sumLoss;
        uint256 sumTotalFee;
        uint256 sumOperatorFee;
        uint256[] memory operatorFees = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            require(i == 0 || ids[i] > ids[i - 1], "IDs out of order");
            (uint256 profit, uint256 loss, uint256 totalFee, uint256 operatorFee) =
                _report(epoch, ids[i], beaconBalances[i], validatorCounts[i]);
            sumProfit = sumProfit.add(profit);
            sumLoss = sumLoss.add(loss);
            sumTotalFee = sumTotalFee.add(totalFee);
            sumOperatorFee = sumOperatorFee.add(operatorFee);
            operatorFees[i] = operatorFee;
        }
        if (sumLoss != 0) {
            IFundForStrategyV2(fund).reportLoss(sumLoss);
        }
        if (sumProfit != 0) {
            uint256 totalFeeQ =
                IFundForStrategyV2(fund).reportProfit(sumProfit, sumTotalFee, sumOperatorFee);
            if (sumOperatorFee != 0) {
                uint256 version = IFundV3(fund).getRebalanceSize();
                for (uint256 i = 0; i < size; i++) {
                    if (operatorFees[i] == 0) {
                        continue;
                    }
                    address rewardAddress = registry.getRewardAddress(ids[i]);
                    IFundV3(fund).trancheTransfer(
                        TRANCHE_Q,
                        rewardAddress,
                        totalFeeQ.mul(operatorFees[i]) / sumOperatorFee,
                        version
                    );
                }
            }
        }
    }

    function _report(
        uint256 epoch,
        uint256 id,
        uint256 beaconBalance,
        uint256 validatorCount
    )
        private
        returns (
            uint256 profit,
            uint256 loss,
            uint256 totalFee,
            uint256 operatorFee
        )
    {
        address withdrawalAddress = registry.getWithdrawalAddress(id);
        require(withdrawalAddress != address(0), "Invalid operator id");
        uint256 lastValidatorCount = lastValidatorCounts[id];
        require(validatorCount <= registry.getKeyStat(id).usedCount, "More than deposited");
        require(validatorCount >= lastValidatorCount, "Less than previous");

        uint256 oldBalance =
            (validatorCount - lastValidatorCount).mul(DEPOSIT_AMOUNT).add(lastBeaconBalances[id]);
        lastBeaconBalances[id] = beaconBalance;
        lastValidatorCounts[id] = validatorCount;

        // Get the exectuion layer rewards
        uint256 executionLayerRewards = withdrawalAddress.balance;
        if (executionLayerRewards != 0) {
            IWithdrawalManager(withdrawalAddress).transferToStrategy(executionLayerRewards);
        }
        emit BalanceReported(epoch, id, beaconBalance, validatorCount, executionLayerRewards);
        uint256 newBalance = beaconBalance.add(executionLayerRewards);

        // Update drawdown and calculate fees
        uint256 oldDrawdown = currentDrawdowns[id];
        if (newBalance >= oldBalance) {
            profit = newBalance - oldBalance;
            if (profit <= oldDrawdown) {
                currentDrawdowns[id] = oldDrawdown - profit;
            } else {
                if (oldDrawdown > 0) {
                    currentDrawdowns[id] = 0;
                }
                totalFee = (profit - oldDrawdown).multiplyDecimal(totalFeeRate);
                operatorFee = (profit - oldDrawdown).multiplyDecimal(operatorFeeRate);
            }
        } else {
            loss = oldBalance - newBalance;
            currentDrawdowns[id] = oldDrawdown.add(loss);
        }
    }

    function updateFeeRate(uint256 newTotalFeeRate, uint256 newOperatorFeeRate) external onlyOwner {
        _updateFeeRate(newTotalFeeRate, newOperatorFeeRate);
    }

    function _updateFeeRate(uint256 newTotalFeeRate, uint256 newOperatorFeeRate) private {
        require(newTotalFeeRate <= MAX_TOTAL_FEE_RATE && newTotalFeeRate >= newOperatorFeeRate);
        totalFeeRate = newTotalFeeRate;
        operatorFeeRate = newOperatorFeeRate;
        emit FeeRateUpdated(newTotalFeeRate, newOperatorFeeRate);
    }

    function updateOperatorWeight(uint256 id, uint256 newWeight) external onlyOwner {
        require(newWeight <= MAX_OPERATOR_WEIGHT, "Max weight exceeded");
        require(id < registry.operatorCount(), "Invalid operator ID");
        operatorWeights[id] = newWeight;
        emit OperatorWeightUpdated(id, newWeight);
    }

    /// @notice Select node operators for the given number of new validators. Sum of the returned
    ///         key counts may be less than the parameter.
    /// @param total Number of new validators
    /// @return keyCounts Number of pubkeys to be used from each node operator
    /// @return cursor New cursor of the selection algorithm
    function selectOperators(uint256 total)
        public
        view
        returns (uint256[] memory keyCounts, uint256 cursor)
    {
        uint256 operatorCount = registry.operatorCount();
        keyCounts = new uint256[](operatorCount);
        uint256[] memory limits = new uint256[](operatorCount);
        uint256 totalWeights;
        for (uint256 i = 0; i < operatorCount; i++) {
            uint256 w = operatorWeights[i];
            limits[i] = w;
            totalWeights = totalWeights + w;
        }
        if (totalWeights == 0) {
            return (keyCounts, operatorCursor);
        }
        uint256 newValidatorCount = totalValidatorCount + total;
        for (uint256 i = 0; i < operatorCount; i++) {
            // Round up the limit
            uint256 totalLimit = (limits[i] * newValidatorCount + totalWeights - 1) / totalWeights;
            NodeOperatorRegistry.KeyStat memory stat = registry.getKeyStat(i);
            totalLimit = totalLimit.min(stat.totalCount).min(stat.depositLimit).min(
                stat.verifiedCount
            );
            limits[i] = totalLimit <= stat.usedCount ? 0 : totalLimit - stat.usedCount;
        }

        cursor = operatorCursor;
        uint256 failure = 0;
        while (total > 0 && failure < operatorCount) {
            if (limits[cursor] == 0) {
                failure++;
            } else {
                keyCounts[cursor]++;
                limits[cursor]--;
                total--;
                failure = 0;
            }
            cursor = (cursor + 1) % operatorCount;
        }
    }

    /// @notice Deposit underlying tokens from the fund to the ETH2 deposit contract.
    /// @param amount Amount of underlying transfered from the fund, including cross-chain relay fee
    function deposit(uint256 amount) public {
        require(amount % DEPOSIT_AMOUNT == 0);
        if (address(this).balance < amount) {
            IFundForStrategyV2(fund).transferToStrategy(amount - address(this).balance);
            _unwrap(IERC20(_tokenUnderlying).balanceOf(address(this)));
        }

        uint256[] memory keyCounts;
        (keyCounts, operatorCursor) = selectOperators(amount / DEPOSIT_AMOUNT);
        uint256 total;
        for (uint256 i = 0; i < keyCounts.length; i++) {
            uint256 keyCount = keyCounts[i];
            if (keyCount == 0) {
                continue;
            }
            total += keyCount;
            (NodeOperatorRegistry.Key[] memory vs, bytes32 withdrawalCredential) =
                registry.useKeys(i, keyCount);
            for (uint256 j = 0; j < keyCount; j++) {
                _deposit(vs[j], withdrawalCredential);
            }
        }
        totalValidatorCount = totalValidatorCount + total;
    }

    function onPrimaryMarketCreate() external {
        uint256 balance = IERC20(_tokenUnderlying).balanceOf(fund) + address(this).balance;
        uint256 count = balance / DEPOSIT_AMOUNT;
        if (count > 0) {
            deposit(count.min(MAX_AUTO_DEPOSIT_COUNT) * DEPOSIT_AMOUNT);
        }
    }

    /// @notice Transfer all underlying tokens, both wrapped and unwrapped, to the fund.
    function transferToFund() external onlyOwner {
        uint256 unwrapped = address(this).balance;
        if (unwrapped > 0) {
            _wrap(unwrapped);
        }
        uint256 amount = IWrappedERC20(_tokenUnderlying).balanceOf(address(this));
        IWrappedERC20(_tokenUnderlying).safeApprove(fund, amount);
        IFundForStrategyV2(fund).transferFromStrategy(amount);
    }

    /// @dev Convert ETH into WETH
    function _wrap(uint256 amount) private {
        IWrappedERC20(_tokenUnderlying).deposit{value: amount}();
    }

    /// @dev Convert WETH into ETH
    function _unwrap(uint256 amount) private {
        IWrappedERC20(_tokenUnderlying).withdraw(amount);
    }

    function _deposit(NodeOperatorRegistry.Key memory key, bytes32 withdrawalCredential) private {
        bytes memory pubkey = abi.encodePacked(key.pubkey0, bytes16(key.pubkey1));
        bytes memory signature = abi.encode(key.signature0, key.signature1, key.signature2);
        // Lower 16 bytes of pubkey1 are cleared by the registry
        bytes32 pubkeyRoot = sha256(abi.encode(key.pubkey0, key.pubkey1));
        bytes32 signatureRoot =
            sha256(
                abi.encodePacked(
                    sha256(abi.encode(key.signature0, key.signature1)),
                    sha256(abi.encode(key.signature2, bytes32(0)))
                )
            );
        bytes32 depositDataRoot =
            sha256(
                abi.encodePacked(
                    sha256(abi.encodePacked(pubkeyRoot, withdrawalCredential)),
                    sha256(abi.encodePacked(LITTLE_ENDIAN_DEPOSIT_AMOUNT, signatureRoot))
                )
            );
        depositContract.deposit{value: DEPOSIT_AMOUNT}(
            pubkey,
            abi.encode(withdrawalCredential),
            signature,
            depositDataRoot
        );
    }
}
