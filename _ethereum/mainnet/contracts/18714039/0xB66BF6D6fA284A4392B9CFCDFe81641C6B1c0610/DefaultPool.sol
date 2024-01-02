// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IDefaultPool.sol";
import "./IActivePool.sol";
import "./ITroveManager.sol";
import "./ERDMath.sol";
import "./Errors.sol";

/*
 * The Default Pool holds the collateral and USDE debt (but not USDE tokens) from liquidations that have been redistributed
 * to active troves but not yet "applied", i.e. not yet recorded on a recipient active trove's struct.
 *
 * When a trove makes an operation that applies its pending collateral and USDE debt, its pending collateral and USDE debt is moved
 * from the Default Pool to the Active Pool.
 */
contract DefaultPool is OwnableUpgradeable, IDefaultPool {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    string public constant NAME = "DefaultPool";

    address public troveManagerAddress;
    address public activePoolAddress;

    uint256 internal USDEDebt; // debt

    // --- Dependency setters ---

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function setAddresses(
        address _troveManagerAddress,
        address _activePoolAddress
    ) external onlyOwner {
        _requireIsContract(_troveManagerAddress);
        _requireIsContract(_activePoolAddress);

        troveManagerAddress = _troveManagerAddress;
        activePoolAddress = _activePoolAddress;

        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
    }

    // --- Getters for public variables. Required by IPool interface ---

    /*
     * Returns the collateral state variable.
     */
    function getTotalCollateral()
        public
        view
        override
        returns (
            uint256 total,
            address[] memory collaterals,
            uint256[] memory amounts
        )
    {
        collaterals = ITroveManager(troveManagerAddress).getCollateralSupport();
        uint256 collLen = collaterals.length;
        amounts = new uint256[](collLen);
        uint256 i = 0;
        for (; i < collLen; ) {
            amounts[i] = IERC20Upgradeable(collaterals[i]).balanceOf(
                address(this)
            );
            total = total.add(amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getCollateralAmount(
        address _collateral
    ) external view override returns (uint256) {
        return IERC20Upgradeable(_collateral).balanceOf(address(this));
    }

    function getUSDEDebt() external view override returns (uint256) {
        return USDEDebt;
    }

    // --- Pool functionality ---

    function sendCollateralToActivePool(
        address[] memory _collaterals,
        uint256[] memory _amounts
    ) external override {
        _requireCallerIsTroveManager();
        address activePool = activePoolAddress; // cache to save an SLOAD
        uint256 collLen = _amounts.length;
        if (collLen == 0 || !ERDMath._arrayIsNonzero(_amounts)) {
            return;
        }

        uint256[] memory collBalance = new uint256[](collLen);
        address collateral;
        uint256 amount;
        uint256 i = 0;
        for (; i < collLen; ) {
            collateral = _collaterals[i];
            amount = _amounts[i];
            if (amount != 0) {
                IERC20Upgradeable(collateral).safeTransfer(activePool, amount);
                collBalance[i] = IERC20Upgradeable(collateral).balanceOf(
                    address(this)
                );
            }
            unchecked {
                ++i;
            }
        }
        emit DefaultPoolCollsBalanceUpdated(_collaterals, collBalance);
        emit CollateralsSent(activePool, _amounts);
    }

    function increaseUSDEDebt(uint256 _amount) external override {
        _requireCallerIsTroveManager();
        USDEDebt = USDEDebt.add(_amount);
        emit DefaultPoolUSDEDebtUpdated(USDEDebt);
    }

    function decreaseUSDEDebt(uint256 _amount) external override {
        _requireCallerIsTroveManager();
        uint256 amount = _amount < USDEDebt ? _amount : USDEDebt;
        USDEDebt = USDEDebt.sub(amount);
        emit DefaultPoolUSDEDebtUpdated(USDEDebt);
    }

    // --- 'require' functions ---

    function _requireIsContract(address _contract) internal view {
        if (!_contract.isContract()) {
            revert Errors.NotContract();
        }
    }

    function _requireCallerIsActivePool() internal view {
        if (msg.sender != activePoolAddress) {
            revert Errors.Caller_NotAP();
        }
    }

    function _requireCallerIsTroveManager() internal view {
        if (msg.sender != troveManagerAddress) {
            revert Errors.Caller_NotTM();
        }
    }
}
