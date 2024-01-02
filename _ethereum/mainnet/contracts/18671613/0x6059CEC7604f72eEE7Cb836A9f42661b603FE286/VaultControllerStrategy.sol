// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./MathUpgradeable.sol";
import "./ERC1967Proxy.sol";

import "./IERC677.sol";
import "./Strategy.sol";
import "./IVault.sol";
import "./IStaking.sol";

/**
 * @title Vault Controller Strategy
 * @notice Base strategy for managing multiple Chainlink staking vaults
 */
abstract contract VaultControllerStrategy is Strategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Fee {
        address receiver;
        uint256 basisPoints;
    }

    IStaking public stakeController;
    Fee[] internal fees;

    address public vaultImplementation;

    IVault[] internal vaults;
    uint256 internal totalDeposits;
    uint256 public totalPrincipalDeposits;
    uint256 public indexOfLastFullVault;

    uint256 public maxDepositSizeBP;

    uint256[9] private __gap;

    event UpgradedVaults(uint256 startIndex, uint256 numVaults, bytes data);
    event SetMaxDepositSizeBP(uint256 maxDepositSizeBP);
    event SetVaultImplementation(address vaultImplementation);

    error InvalidBasisPoints();

    /**
     * @notice initializes contract
     * @param _token address of LINK token
     * @param _stakingPool address of the staking pool that controls this strategy
     * @param _stakeController address of Chainlink staking contract
     * @param _vaultImplementation address of the implementation contract to use when deploying new vaults
     * @param _fees list of fees to be paid on rewards
     * @param _maxDepositSizeBP basis point amount of the remaing deposit room in the Chainlink staking contract
     * that can be deposited at once
     **/
    function __VaultControllerStrategy_init(
        address _token,
        address _stakingPool,
        address _stakeController,
        address _vaultImplementation,
        Fee[] memory _fees,
        uint256 _maxDepositSizeBP
    ) public onlyInitializing {
        __Strategy_init(_token, _stakingPool);

        stakeController = IStaking(_stakeController);

        require(_isContract(_vaultImplementation), "Vault implementation address must belong to a contract");
        vaultImplementation = _vaultImplementation;

        for (uint256 i = 0; i < _fees.length; ++i) {
            fees.push(_fees[i]);
        }
        require(_totalFeesBasisPoints() <= 5000, "Total fees must be <= 50%");

        if (_maxDepositSizeBP > 10000) revert InvalidBasisPoints();
        maxDepositSizeBP = _maxDepositSizeBP;
    }

    /**
     * @notice returns a list of all vaults controlled by this contract
     * @return  list of vault addresses
     */
    function getVaults() external view returns (IVault[] memory) {
        return vaults;
    }

    /**
     * @notice deposits tokens into this strategy from the staking pool
     * @dev reverts if sender is not stakingPool
     * @param _amount amount to deposit
     */
    function deposit(uint256 _amount) external onlyStakingPool {
        token.safeTransferFrom(msg.sender, address(this), _amount);

        (uint256 vaultMinDeposits, uint256 vaultMaxDeposits) = getVaultDepositLimits();

        uint256 startIndex = indexOfLastFullVault + 1;
        if (vaults[0].getPrincipalDeposits() < vaultMaxDeposits) {
            startIndex = 0;
        }

        uint256 deposited = _depositToVaults(startIndex, token.balanceOf(address(this)), vaultMinDeposits, vaultMaxDeposits);
        totalDeposits += deposited;
        totalPrincipalDeposits += deposited;

        if (deposited != _amount) {
            token.safeTransfer(address(stakingPool), _amount - deposited);
        }
    }

    /**
     * @notice withdrawals are not yet implemented
     */
    function withdraw(uint256) external view onlyStakingPool {
        revert("withdrawals not yet implemented");
    }

    /**
     * @notice returns the deposit change since deposits were last updated
     * @dev deposit change could be positive or negative depending on reward rate and whether
     * any slashing occurred
     * @return deposit change
     */
    function getDepositChange() public view returns (int) {
        uint256 totalBalance = token.balanceOf(address(this));
        for (uint256 i = 0; i < vaults.length; ++i) {
            totalBalance += vaults[i].getTotalDeposits();
        }
        return int(totalBalance) - int(totalDeposits);
    }

    /**
     * @notice returns the total amount of fees that will be paid on the next call to updateDeposits()
     * @dev fees are only paid when the depositChange since the last update is positive
     * @return total fees
     */
    function getPendingFees() external view virtual override returns (uint256) {
        int256 depositChange = getDepositChange();
        uint256 totalFees;

        if (depositChange > 0) {
            for (uint256 i = 0; i < fees.length; ++i) {
                totalFees += (uint256(depositChange) * fees[i].basisPoints) / 10000;
            }
        }
        return totalFees;
    }

    /**
     * @notice updates deposit accounting and calculates fees on newly earned rewards
     * @dev reverts if sender is not stakingPool
     * @return depositChange change in deposits since last update
     * @return receivers list of fee receivers
     * @return amounts list of fee amounts
     */
    function updateDeposits(bytes calldata)
        external
        virtual
        onlyStakingPool
        returns (
            int256 depositChange,
            address[] memory receivers,
            uint256[] memory amounts
        )
    {
        depositChange = getDepositChange();
        uint256 newTotalDeposits = totalDeposits;

        if (depositChange > 0) {
            newTotalDeposits += uint256(depositChange);

            receivers = new address[](fees.length);
            amounts = new uint256[](fees.length);

            for (uint256 i = 0; i < fees.length; ++i) {
                receivers[i] = fees[i].receiver;
                amounts[i] = (uint256(depositChange) * fees[i].basisPoints) / 10000;
            }
        } else if (depositChange < 0) {
            newTotalDeposits -= uint256(depositChange * -1);
        }

        uint256 balance = token.balanceOf(address(this));
        if (balance != 0) {
            token.safeTransfer(address(stakingPool), balance);
            newTotalDeposits -= balance;
        }

        totalDeposits = newTotalDeposits;
    }

    /**
     * @notice returns the total amount of deposits as tracked in this strategy
     * @return total deposits
     */
    function getTotalDeposits() public view override returns (uint256) {
        return totalDeposits;
    }

    /**
     * @notice returns the maximum that can be deposited into this strategy
     * @return maximum deposits
     */
    function getMaxDeposits() public view virtual override returns (uint256) {
        (, uint256 vaultMaxDeposits) = getVaultDepositLimits();
        return
            totalDeposits +
            (
                stakeController.isActive()
                    ? MathUpgradeable.min(
                        vaults.length * vaultMaxDeposits - totalPrincipalDeposits,
                        ((stakeController.getMaxPoolSize() - stakeController.getTotalPrincipal()) * maxDepositSizeBP) / 10000
                    )
                    : 0
            );
    }

    /**
     * @notice returns the minimum that must remain this strategy
     * @return minimum deposits
     */
    function getMinDeposits() public view virtual override returns (uint256) {
        return totalDeposits;
    }

    /**
     * @notice returns the vault deposit limits for vaults controlled by this strategy
     * @return minimum amount of deposits that a vault can hold
     * @return maximum amount of deposits that a vault can hold
     */
    function getVaultDepositLimits() public view returns (uint256, uint256) {
        return stakeController.getStakerLimits();
    }

    /**
     * @notice upgrades vaults to a new implementation contract
     * @dev reverts if sender is not owner
     * @param _startIndex index of first vault to upgrade
     * @param _numVaults number of vaults to upgrade starting at _startIndex
     * @param _data optional encoded function call to be executed after upgrade
     */
    function upgradeVaults(
        uint256 _startIndex,
        uint256 _numVaults,
        bytes memory _data
    ) external onlyOwner {
        for (uint256 i = _startIndex; i < _startIndex + _numVaults; ++i) {
            _upgradeVault(i, _data);
        }
        emit UpgradedVaults(_startIndex, _numVaults, _data);
    }

    /**
     * @notice returns a list of all fees and fee receivers
     * @return list of fees
     */
    function getFees() external view returns (Fee[] memory) {
        return fees;
    }

    /**
     * @notice adds a new fee
     * @dev
     * - reverts if sender is not owner
     * - reverts if total fees exceed 50%
     * @param _receiver receiver of fee
     * @param _feeBasisPoints fee in basis points
     **/
    function addFee(address _receiver, uint256 _feeBasisPoints) external onlyOwner {
        fees.push(Fee(_receiver, _feeBasisPoints));
        require(_totalFeesBasisPoints() <= 5000, "Total fees must be <= 50%");
    }

    /**
     * @notice updates an existing fee
     * @dev
     * - reverts if sender is not owner
     * - reverts if total fees exceed 50%
     * @param _index index of fee
     * @param _receiver receiver of fee
     * @param _feeBasisPoints fee in basis points
     **/
    function updateFee(
        uint256 _index,
        address _receiver,
        uint256 _feeBasisPoints
    ) external onlyOwner {
        require(_index < fees.length, "Fee does not exist");

        if (_feeBasisPoints == 0) {
            fees[_index] = fees[fees.length - 1];
            fees.pop();
        } else {
            fees[_index].receiver = _receiver;
            fees[_index].basisPoints = _feeBasisPoints;
        }

        require(_totalFeesBasisPoints() <= 5000, "Total fees must be <= 50%");
    }

    /**
     * @notice sets the basis point amount of the remaing deposit room in the Chainlink staking contract
     * that can be deposited at once
     * @param _maxDepositSizeBP basis point amount
     */
    function setMaxDepositSizeBP(uint256 _maxDepositSizeBP) external onlyOwner {
        if (_maxDepositSizeBP > 10000) revert InvalidBasisPoints();
        maxDepositSizeBP = _maxDepositSizeBP;
        emit SetMaxDepositSizeBP(_maxDepositSizeBP);
    }

    /**
     * @notice sets a new vault implementation contract to be used when deploying/upgrading vaults
     * @dev
     * - reverts if sender is not owner
     * - reverts if `_vaultImplementation` is not a contract
     * @param _vaultImplementation address of implementation contract
     */
    function setVaultImplementation(address _vaultImplementation) external onlyOwner {
        require(_isContract(_vaultImplementation), "Address must belong to a contract");
        vaultImplementation = _vaultImplementation;
        emit SetVaultImplementation(_vaultImplementation);
    }

    /**
     * @notice deposits tokens into vaults
     * @dev vaults will be deposited into in ascending order starting with `_startIndex`
     * @param _startIndex index of first vault to deposit into
     * @param _toDeposit amount to deposit
     * @param _minDeposits minimum amount of deposits that a vault can hold
     * @param _maxDeposits minimum amount of deposits that a vault can hold
     */
    function _depositToVaults(
        uint256 _startIndex,
        uint256 _toDeposit,
        uint256 _minDeposits,
        uint256 _maxDeposits
    ) internal virtual returns (uint256) {
        uint256 toDeposit = _toDeposit;
        uint256 lastFullVault;
        for (uint256 i = _startIndex; i < vaults.length; ++i) {
            IVault vault = vaults[i];
            uint256 deposits = vault.getPrincipalDeposits();
            uint256 canDeposit = _maxDeposits - deposits;

            if (deposits < _minDeposits && toDeposit < (_minDeposits - deposits)) {
                break;
            } else if (toDeposit > canDeposit) {
                lastFullVault = i;
                vault.deposit(canDeposit);
                toDeposit -= canDeposit;
            } else {
                if (toDeposit == canDeposit) lastFullVault = i;
                vault.deposit(toDeposit);
                toDeposit = 0;
                break;
            }
        }
        indexOfLastFullVault = lastFullVault;
        return _toDeposit - toDeposit;
    }

    /**
     * @notice deploys a new vault and adds it to this strategy
     * @param _data optional encoded function call to be executed after deployment
     */
    function _deployVault(bytes memory _data) internal {
        address vault = address(new ERC1967Proxy(vaultImplementation, _data));
        token.safeApprove(vault, type(uint256).max);
        vaults.push(IVault(vault));
    }

    /**
     * @notice upgrades a vault controlled by this strategy
     * @param _vaultIdx index of vault to upgrade
     * @param _data optional encoded function call to be executed after upgrade
     */
    function _upgradeVault(uint256 _vaultIdx, bytes memory _data) internal {
        IVault vault = vaults[_vaultIdx];
        if (_data.length == 0) {
            vault.upgradeTo(vaultImplementation);
        } else {
            vault.upgradeToAndCall(vaultImplementation, _data);
        }
    }

    /**
     * @notice returns the sum of all fees
     * @return sum of fees in basis points
     **/
    function _totalFeesBasisPoints() private view returns (uint256) {
        uint256 totalFees;
        for (uint i = 0; i < fees.length; ++i) {
            totalFees += fees[i].basisPoints;
        }
        return totalFees;
    }

    /**
     * @notice returns whether an address belongs to a contract
     * @param _address address to check
     * @return true if address is contract, false otherwise
     */
    function _isContract(address _address) private view returns (bool) {
        uint256 length;
        assembly {
            length := extcodesize(_address)
        }
        return length > 0;
    }
}
