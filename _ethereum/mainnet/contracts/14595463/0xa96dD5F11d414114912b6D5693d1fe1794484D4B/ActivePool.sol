// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IActivePool.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

import "./CheckContract.sol";

import "./IERC20.sol";

/*
 * The Active Pool holds the ETH collateral and LUSD debt (but not LUSD tokens) for all active troves.
 *
 * When a trove is liquidated, it's ETH and LUSD debt are transferred from the Active Pool, to either the
 * Stability Pool, the Default Pool, or both, depending on the liquidation conditions.
 *
 */
contract ActivePool is AccessControl, Ownable, CheckContract, IActivePool {
    using SafeMath for uint256;

    bytes32 public constant AMO_ROLE = keccak256("AMO_ROLE");
    string public constant NAME = "ActivePool";

    address public borrowerOperationsAddress;
    address public troveManagerAddress;
    address public stabilityPoolAddress;
    address public defaultPoolAddress;
    address public collSurplusPoolAddress;

    IERC20 public weth;
    uint256 public ETH; // deposited ether tracker
    uint256 public LUSDDebt;

    modifier onlyAMOS {
        require(hasRole(AMO_ROLE, _msgSender()), 'ActivePool: not AMO');
        _;
    }

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _stabilityPoolAddress,
        address _defaultPoolAddress,
        address _collSurplusPoolAddress,
        address _governance,
        address _wethAddress
    ) external onlyOwner {
        checkContract(_borrowerOperationsAddress);
        checkContract(_troveManagerAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_defaultPoolAddress);
        checkContract(_wethAddress);
        checkContract(_collSurplusPoolAddress);

        borrowerOperationsAddress = _borrowerOperationsAddress;
        troveManagerAddress = _troveManagerAddress;
        stabilityPoolAddress = _stabilityPoolAddress;
        defaultPoolAddress = _defaultPoolAddress;
        collSurplusPoolAddress = _collSurplusPoolAddress;
        weth = IERC20(_wethAddress);

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);

        _setupRole(DEFAULT_ADMIN_ROLE, _governance);

        _renounceOwnership();
    }

    // --- Getters for public variables. Required by IPool interface ---

    /*
     * Returns the ETH state variable.
     *
     *Not necessarily equal to the the contract's raw ETH balance - ether can be forcibly sent to contracts.
     */
    function getETH() external view override returns (uint256) {
        return ETH;
    }

    function getLUSDDebt() external view override returns (uint256) {
        return LUSDDebt;
    }

    // --- Pool functionality ---

    function sendETH(address _account, uint256 _amount) external override {
        _requireCallerIsBOorTroveMorSP();
        ETH = ETH.sub(_amount);
        emit ActivePoolETHBalanceUpdated(ETH);
        emit EtherSent(_account, _amount);

        if (!_getShouldUseReceiveETH(_account)) {
            weth.transfer(_account, _amount);
        } else {
            weth.approve(_account, _amount);
            IActivePool(_account).receiveETH(_amount);
        }
    }

    function increaseLUSDDebt(uint256 _amount) external override {
        _requireCallerIsBOorTroveM();
        LUSDDebt = LUSDDebt.add(_amount);
        ActivePoolLUSDDebtUpdated(LUSDDebt);
    }

    function decreaseLUSDDebt(uint256 _amount) external override {
        _requireCallerIsBOorTroveMorSP();
        LUSDDebt = LUSDDebt.sub(_amount);
        ActivePoolLUSDDebtUpdated(LUSDDebt);
    }

    function borrow(uint256 amount) external override onlyAMOS {
        require(
            weth.balanceOf(address(this)) > amount,
            'ActivePool: Insufficent funds in the pool'
        );
        require(
            weth.transfer(msg.sender, amount),
            'ActivePool: transfer failed'
        );

        emit Borrow(msg.sender, amount);
    }

    function repay(uint256 amount) external override onlyAMOS {
        require(
            weth.balanceOf(msg.sender) >= amount,
            'ActivePool: balance < required'
        );
         require(
            weth.transferFrom(msg.sender, address(this), amount),
            'ARTHPool: transfer from failed'
        );

        emit Repay(msg.sender, amount);
    }
    // --- 'require' functions ---

    function _getShouldUseReceiveETH(address _account) internal view returns (bool) {
        return (_account == defaultPoolAddress ||
            _account == stabilityPoolAddress ||
            _account == collSurplusPoolAddress);
    }

    function _requireCallerIsBorrowerOperationsOrDefaultPool() internal view {
        require(
            msg.sender == borrowerOperationsAddress || msg.sender == defaultPoolAddress,
            "ActivePool: Caller is neither BO nor Default Pool"
        );
    }

    function _requireCallerIsBOorTroveMorSP() internal view {
        require(
            msg.sender == borrowerOperationsAddress ||
                msg.sender == troveManagerAddress ||
                msg.sender == stabilityPoolAddress,
            "ActivePool: Caller is neither BorrowerOperations nor TroveManager nor StabilityPool"
        );
    }

    function _requireCallerIsBOorTroveM() internal view {
        require(
            msg.sender == borrowerOperationsAddress || msg.sender == troveManagerAddress,
            "ActivePool: Caller is neither BorrowerOperations nor TroveManager"
        );
    }

    // --- Fallback function ---

    function receiveETH(uint256 _amount) external override {
        _requireCallerIsBorrowerOperationsOrDefaultPool();
        weth.transferFrom(msg.sender, address(this), _amount);
        ETH = ETH.add(_amount);
        emit ActivePoolETHBalanceUpdated(ETH);
    }
}
