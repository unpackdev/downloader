// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./VaultControllerStrategy.sol";
import "./IOperatorVault.sol";

/**
 * @title Operator Vault Controller Strategy
 * @notice Implemented strategy for managing multiple Chainlink operator staking vaults
 */
contract OperatorVCS is VaultControllerStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public operatorRewardPercentage;
    uint256 private unclaimedOperatorRewards;

    mapping(address => bool) private vaultMapping;

    event VaultAdded(address indexed operator);
    event WithdrawExtraRewards(address indexed receiver, uint256 amount);
    event SetOperatorRewardPercentage(uint256 rewardPercentage);

    error InvalidPercentage();
    error SenderNotAuthorized();
    error UnauthorizedToken();
    error NoExtraRewards();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice initializes contract
     * @param _token address of LINK token
     * @param _stakingPool address of the staking pool that controls this strategy
     * @param _stakeController address of Chainlink staking contract
     * @param _vaultImplementation address of the implementation contract to use when deploying new vaults
     * @param _fees list of fees to be paid on rewards
     * @param _maxDepositSizeBP basis point amount of the remaing deposit room in the Chainlink staking contract
     * that can be deposited at once
     * @param _operatorRewardPercentage basis point amount of an operator's earned rewards that they receive
     **/
    function initialize(
        address _token,
        address _stakingPool,
        address _stakeController,
        address _vaultImplementation,
        Fee[] memory _fees,
        uint256 _maxDepositSizeBP,
        uint256 _operatorRewardPercentage
    ) public reinitializer(2) {
        if (address(token) == address(0)) {
            __VaultControllerStrategy_init(
                _token,
                _stakingPool,
                _stakeController,
                _vaultImplementation,
                _fees,
                _maxDepositSizeBP
            );
        } else {
            // reassaign values to account for changed storage variables in upgrade
            totalPrincipalDeposits = operatorRewardPercentage;
            indexOfLastFullVault = 0;

            stakeController = IStaking(_stakeController);
            vaultImplementation = _vaultImplementation;
            maxDepositSizeBP = _maxDepositSizeBP;

            for (uint256 i = 0; i < vaults.length; ++i) {
                vaultMapping[address(vaults[i])] = true;
            }
        }

        if (_operatorRewardPercentage > 10000) revert InvalidPercentage();
        operatorRewardPercentage = _operatorRewardPercentage;
    }

    /**
     * @notice ERC677 implementation to receive operator rewards
     * @dev
     * - rewards are paid in the stakingPool LSD token
     * - reverts if transferred token is not stakingPool LSD
     **/
    function onTokenTransfer(
        address,
        uint256,
        bytes calldata
    ) external {
        if (msg.sender != address(stakingPool)) revert UnauthorizedToken();
    }

    function getOperatorRewards() external view returns (uint256, uint256) {
        return (unclaimedOperatorRewards, IERC20Upgradeable(address(stakingPool)).balanceOf(address(this)));
    }

    /**
     * @notice used by vaults to withdraw operator rewards
     * @dev reverts if sender is not an authorized vault
     * @param _receiver address to receive rewards
     * @param _amount amount to withdraw
     */
    function withdrawOperatorRewards(address _receiver, uint256 _amount) external returns (uint256) {
        if (!vaultMapping[msg.sender]) revert SenderNotAuthorized();

        IERC20Upgradeable lsdToken = IERC20Upgradeable(address(stakingPool));
        uint256 withdrawableRewards = lsdToken.balanceOf(address(this));
        uint256 amountToWithdraw = _amount > withdrawableRewards ? withdrawableRewards : _amount;

        unclaimedOperatorRewards -= amountToWithdraw;
        lsdToken.safeTransfer(_receiver, amountToWithdraw);

        return amountToWithdraw;
    }

    /**
     * @notice returns the total amount of fees that will be paid on the next call to updateDeposits()
     * @return total fees
     */
    function getPendingFees() external view override returns (uint256) {
        uint256 totalFees;

        uint256 vaultCount = vaults.length;
        for (uint256 i = 0; i < vaultCount; ++i) {
            totalFees += IOperatorVault(address(vaults[i])).getPendingRewards();
        }

        int256 depositChange = getDepositChange();
        if (depositChange > 0) {
            for (uint256 i = 0; i < fees.length; ++i) {
                totalFees += (uint256(depositChange) * fees[i].basisPoints) / 10000;
            }
        }
        return totalFees;
    }

    /**
     * @notice temporary override used for 0.2 early access period
     * @return maximum deposits
     */
    function getMaxDeposits() public view override returns (uint256) {
        return getTotalDeposits();
    }

    /**
     * @notice updates deposit accounting and calculates fees on newly earned rewards
     * @dev reverts if sender is not stakingPool
     * @param _data encoded minRewards (uint256) - min amount of rewards required to claim (set 0 to skip reward claiming)
     * @return depositChange change in deposits since last update
     * @return receivers list of fee receivers
     * @return amounts list of fee amounts
     */
    function updateDeposits(bytes calldata _data)
        external
        override
        onlyStakingPool
        returns (
            int256 depositChange,
            address[] memory receivers,
            uint256[] memory amounts
        )
    {
        uint256 minRewards = _data.length == 0 ? 0 : abi.decode(_data, (uint256));
        uint256 newTotalDeposits = totalDeposits;
        uint256 vaultDeposits;
        uint256 operatorRewards;

        uint256 vaultCount = vaults.length;
        address receiver = address(this);
        for (uint256 i = 0; i < vaultCount; ++i) {
            (uint256 deposits, uint256 rewards) = IOperatorVault(address(vaults[i])).updateDeposits(minRewards, receiver);
            vaultDeposits += deposits;
            operatorRewards += rewards;
        }

        uint256 balance = token.balanceOf(address(this));
        depositChange = int256(vaultDeposits + balance) - int256(totalDeposits);

        if (operatorRewards != 0) {
            receivers = new address[](1 + (depositChange > 0 ? fees.length : 0));
            amounts = new uint256[](receivers.length);
            receivers[0] = address(this);
            amounts[0] = operatorRewards;
            unclaimedOperatorRewards += operatorRewards;
        }

        if (depositChange > 0) {
            newTotalDeposits += uint256(depositChange);

            if (receivers.length == 0) {
                receivers = new address[](fees.length);
                amounts = new uint256[](receivers.length);

                for (uint256 i = 0; i < receivers.length; ++i) {
                    receivers[i] = fees[i].receiver;
                    amounts[i] = (uint256(depositChange) * fees[i].basisPoints) / 10000;
                }
            } else {
                for (uint256 i = 1; i < receivers.length; ++i) {
                    receivers[i] = fees[i - 1].receiver;
                    amounts[i] = (uint256(depositChange) * fees[i - 1].basisPoints) / 10000;
                }
            }
        } else if (depositChange < 0) {
            newTotalDeposits -= uint256(depositChange * -1);
        }

        if (balance != 0) {
            token.safeTransfer(address(stakingPool), balance);
            newTotalDeposits -= balance;
        }

        totalDeposits = newTotalDeposits;
    }

    /**
     * @notice deploys a new vault and adds it to this strategy
     * @dev reverts if sender is not owner
     * @param _operator address of operator that the vault represents
     * @param _rewardsReceiver address authorized to claim rewards for the vault
     * @param _pfAlertsController address of the price feed alerts contract
     */
    function addVault(
        address _operator,
        address _rewardsReceiver,
        address _pfAlertsController
    ) external onlyOwner {
        bytes memory data = abi.encodeWithSignature(
            "initialize(address,address,address,address,address,address,address)",
            address(token),
            address(this),
            address(stakeController),
            stakeController.getRewardVault(),
            _pfAlertsController,
            _operator,
            _rewardsReceiver
        );
        _deployVault(data);
        vaultMapping[address(vaults[vaults.length - 1])] = true;
        emit VaultAdded(_operator);
    }

    /**
     * @notice sets a vault's operator address
     * @dev reverts if sender is not owner
     * @param _index index of vault
     * @param _operator address of operator that the vault represents
     */
    function setOperator(uint256 _index, address _operator) external onlyOwner {
        IOperatorVault(address(vaults[_index])).setOperator(_operator);
    }

    /**
     * @notice sets the address authorized to claim rewards for a vault
     * @dev reverts if sender is not owner
     * @param _index index of vault
     * @param _rewardsReceiver address of rewards receiver for the vault
     */
    function setRewardsReceiver(uint256 _index, address _rewardsReceiver) external onlyOwner {
        IOperatorVault(address(vaults[_index])).setRewardsReceiver(_rewardsReceiver);
    }

    /**
     * @notice sets the basis point amount of an operator's earned rewards that they receive
     * @dev
     * - stakingPool.updateStrategyRewards is called to credit all past operator rewards at
     *   the old rate before the reward percentage changes
     * - reverts if sender is not owner
     * - reverts if `_operatorRewardPercentage` is > 10000
     * @param _operatorRewardPercentage basis point amount
     */
    function setOperatorRewardPercentage(uint256 _operatorRewardPercentage) public onlyOwner {
        if (_operatorRewardPercentage > 10000) revert InvalidPercentage();

        _updateStrategyRewards();

        operatorRewardPercentage = _operatorRewardPercentage;
        emit SetOperatorRewardPercentage(_operatorRewardPercentage);
    }

    /**
     * @notice updates rewards for all strategies controlled by the staking pool
     * @dev called before operatorRewardPercentage is changed to
     * credit any past rewards at the old rate
     */
    function _updateStrategyRewards() private {
        address[] memory strategies = stakingPool.getStrategies();
        uint256[] memory strategyIdxs = new uint256[](strategies.length);
        for (uint256 i = 0; i < strategies.length; ++i) {
            strategyIdxs[i] = i;
        }
        stakingPool.updateStrategyRewards(strategyIdxs, "");
    }
}
