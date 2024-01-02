// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./SafeERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ICollateralManager.sol";
import "./ICollSurplusPool.sol";
import "./ITroveManager.sol";
import "./IWETH.sol";
import "./ERDMath.sol";
import "./Errors.sol";

contract CollSurplusPool is OwnableUpgradeable, ICollSurplusPool {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    string public constant NAME = "CollSurplusPool";

    address public borrowerOperationsAddress;
    address public troveManagerAddress;
    address public troveManagerLiquidationsAddress;
    address public troveManagerRedemptionsAddress;
    address public activePoolAddress;
    address public wethAddress;

    ICollateralManager public collateralManager;

    // Collateral surplus claimable by trove owners
    // mapping (address => uint[]) internal balances;
    struct Info {
        bool hasBalance;
        mapping(address => uint256) balance;
    }
    mapping(address => Info) internal balances;

    // --- Contract setters ---

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function setAddresses(
        address _borrowerOperationsAddress,
        address _collateralManagerAddress,
        address _troveManagerAddress,
        address _troveManagerLiquidationsAddress,
        address _troveManagerRedemptionsAddress,
        address _activePoolAddress,
        address _wethAddress
    ) external override onlyOwner {
        _requireIsContract(_borrowerOperationsAddress);
        _requireIsContract(_collateralManagerAddress);
        _requireIsContract(_troveManagerAddress);
        _requireIsContract(_troveManagerLiquidationsAddress);
        _requireIsContract(_troveManagerRedemptionsAddress);
        _requireIsContract(_activePoolAddress);
        _requireIsContract(_wethAddress);

        collateralManager = ICollateralManager(_collateralManagerAddress);

        borrowerOperationsAddress = _borrowerOperationsAddress;
        troveManagerAddress = _troveManagerAddress;
        troveManagerLiquidationsAddress = _troveManagerLiquidationsAddress;
        troveManagerRedemptionsAddress = _troveManagerRedemptionsAddress;
        activePoolAddress = _activePoolAddress;
        wethAddress = _wethAddress;

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit TroveManagerLiquidationsAddressChanged(
            _troveManagerLiquidationsAddress
        );
        emit TroveManagerRedemptionsAddressChanged(
            _troveManagerRedemptionsAddress
        );
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit WETHAddressChanged(_wethAddress);
    }

    /* Returns the collateral state variable at ActivePool address. */
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

    function getCollateral(
        address _account,
        address _collateral
    ) external view override returns (uint256) {
        return balances[_account].balance[_collateral];
    }

    // --- Pool functionality ---

    function accountSurplus(
        address _account,
        uint256[] memory _amount
    ) external override {
        _requireCallerIsTMLorTMR();

        address[] memory collaterals = collateralManager.getCollateralSupport();
        uint256[] memory shares = collateralManager.getShares(
            collaterals,
            _amount
        );
        uint256 length = collaterals.length;
        uint256 i = 0;
        for (; i < length; ) {
            address collateral = collaterals[i];
            uint256 share = shares[i];
            if (share != 0) {
                Info storage info = balances[_account];
                info.hasBalance = true;
                info.balance[collateral] = info.balance[collateral].add(share);
            }
            unchecked {
                ++i;
            }
        }

        emit CollBalanceUpdated(_account, balances[_account].hasBalance);
    }

    function claimColl(address _account) external override {
        _requireCallerIsBorrowerOperations();
        address[] memory collaterals = collateralManager.getCollateralSupport();
        uint256 length = collaterals.length;
        Info storage info = balances[_account];
        bool flag = info.hasBalance;
        if (!flag) {
            revert Errors.CSP_CannotClaim();
        }
        info.hasBalance = false;
        uint256[] memory claimableColls = new uint256[](length);
        uint256[] memory shares = new uint256[](length);
        emit CollBalanceUpdated(_account, false);
        bool hasETH;
        uint256 ETHAmount;
        uint256 i = 0;
        for (; i < length; ) {
            address collateral = collaterals[i];
            shares[i] = info.balance[collateral];
            claimableColls[i] = collateralManager.getAmount(
                collateral,
                shares[i]
            );
            if (claimableColls[i] != 0) {
                info.balance[collateral] = 0;
                if (collateral != wethAddress) {
                    IERC20Upgradeable(collateral).safeTransfer(
                        _account,
                        claimableColls[i]
                    );
                } else {
                    hasETH = true;
                    ETHAmount = claimableColls[i];
                }
            }
            unchecked {
                ++i;
            }
        }
        if (hasETH) {
            IWETH(wethAddress).withdraw(ETHAmount);
            (bool success, ) = _account.call{value: ETHAmount}("");
            if (!success) {
                revert Errors.SendETHFailed();
            }
        }
        emit CollateralClaimedSent(_account, shares, claimableColls);
    }

    // --- 'require' functions ---

    function _requireIsContract(address _contract) internal view {
        if (!_contract.isContract()) {
            revert Errors.NotContract();
        }
    }

    function _requireCallerIsBorrowerOperations() internal view {
        if (msg.sender != borrowerOperationsAddress) {
            revert Errors.Caller_NotBO();
        }
    }

    function _requireCallerIsTMLorTMR() internal view {
        if (
            msg.sender != troveManagerLiquidationsAddress &&
            msg.sender != troveManagerRedemptionsAddress
        ) {
            revert Errors.Caller_NotTMLOrTMR();
        }
    }

    function _requireCallerIsActivePool() internal view {
        if (msg.sender != activePoolAddress) {
            revert Errors.Caller_NotAP();
        }
    }

    // --- Fallback function ---

    receive() external payable {}
}
