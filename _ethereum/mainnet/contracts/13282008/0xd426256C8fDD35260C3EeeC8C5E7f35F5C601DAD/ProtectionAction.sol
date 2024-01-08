// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IProtectionAction.sol";
import "./Initializable.sol";
import "./Proxied.sol";
import "./FlashLoanReceiverBase.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./SProtection.sol";
import "./FProtectionAction.sol";
import "./FProtection.sol";
import "./IERC20.sol";
import "./CTokens.sol";
import "./CProtectionAction.sol";
import "./ISwapModule.sol";

/// @author Gelato Digital
/// @title Protection Action Contract.
/// @dev Perform protection by repaying the debt with collateral token.
contract ProtectionAction is
    IProtectionAction,
    Initializable,
    Proxied,
    FlashLoanReceiverBase
{
    uint256 public discrepancyBps;
    uint256 public override slippageInBps;

    address internal immutable _aaveServices;
    ISwapModule internal immutable _swapModule;

    event LogProtectionAction(
        bytes32 taskHash,
        uint256 healthFactorBefore,
        uint256 protectionFee, // In Collateral Token
        uint256 flashloanFee, // In Collateral Token
        uint256 colNeededForProtection,
        uint256 debtRepaid,
        address onBehalfOf
    );

    modifier onlyLendingPool() {
        require(
            msg.sender == address(LENDING_POOL),
            "Only Lending Pool can call this function"
        );
        _;
    }

    modifier onlyAaveServices() {
        require(
            msg.sender == _aaveServices,
            "Only Aave Services can call this function"
        );
        _;
    }

    // solhint-disable no-empty-blocks
    constructor(
        ILendingPoolAddressesProvider _addressProvider,
        address __aaveServices,
        ISwapModule __swapModule
    ) FlashLoanReceiverBase(_addressProvider) {
        _aaveServices = __aaveServices;
        _swapModule = __swapModule;
    }

    function initialize() external initializer {
        discrepancyBps = 200;
        slippageInBps = 200;
    }

    /// @dev Set discrepancyBps of how far the final HF can be to the one wanted, capped to 5%.
    function setDiscrepancyBps(uint256 _discrepancyBps)
        external
        onlyProxyAdmin
    {
        require(
            _discrepancyBps <= DISCREPANCY_BPS_CAP,
            "ProtectionAction.setDiscrepancyBps: _discrepancyBps > 5%"
        );
        discrepancyBps = _discrepancyBps;
    }

    ///@dev Set slippageInBps, capped to 5%
    function setSlippageInBps(uint256 _slippageInBps) external onlyProxyAdmin {
        require(
            _slippageInBps <= SLIPPAGE_BPS_CAP,
            "ProtectionAction.setSlippageInBps: slippageInBps > 5%"
        );
        slippageInBps = _slippageInBps;
    }

    /// @dev Safety function for testing.
    function retrieveFunds(address _token, address _to)
        external
        onlyProxyAdmin
    {
        if (_token == ETH) payable(_to).transfer(address(this).balance);
        else
            IERC20(_token).transfer(
                _to,
                IERC20(_token).balanceOf(address(this))
            );
    }

    /// Execution of Protection.
    /// @param _taskHash Task identifier.
    /// @param _data Data needed to perform Protection.
    /// @dev _data is on-chain data, one of the input to produce Task hash of Aave services.
    /// @param _offChainData Data computed off-chain and needed to perform Protection.
    /// @dev _offChainData include the amount of collateral to withdraw
    /// and the amount of debt token to repay, cannot be computed on-chain.
    // solhint-disable function-max-lines
    function exec(
        bytes32 _taskHash,
        bytes memory _data,
        bytes memory _offChainData
    ) external virtual override onlyAaveServices {
        ProtectionPayload memory protectionPayload = _getProtectionPayload(
            _taskHash,
            _data,
            _offChainData
        );

        // Check if the task submitter is the aave user.
        _checkSubmitterIsUser(protectionPayload, _data);

        // Check if AmtToFlashBorrow and AmtOfDebtToRepay are the one given by the formula.
        _checkRepayAndFlashBorrowAmt(
            protectionPayload,
            LENDING_POOL,
            ADDRESSES_PROVIDER,
            this
        );
        // Cannot give to executeOperation the path array through params bytes
        // => Stack too Deep error.

        _flashLoan(LENDING_POOL, address(this), protectionPayload);

        // Fetch User Data After Refinancing

        (, , , , , uint256 healthFactor) = LENDING_POOL.getUserAccountData(
            protectionPayload.onBehalfOf
        );

        // Check if the service didn't keep any dust amt.
        _transferDust(
            address(this),
            protectionPayload.debtToken,
            protectionPayload.onBehalfOf
        );

        // Check if position is safe.
        _requirePositionSafe(
            healthFactor,
            discrepancyBps,
            protectionPayload.wantedHealthFactor
        );
    }

    /// @dev function called by LendingPool after flash borrow.
    /// @param _assets borrowed tokens.
    /// @param _amounts borrowed amounts associated to borrowed tokens.
    /// @param _premiums premiums to repay.
    /// @param _params custom parameters.
    /// @dev _params contains collateral token, amount of Collateral to
    /// wiithdraw, borrow rate mode, the user who need protection and
    /// swap module used to swap collateral token into debt token.
    function executeOperation(
        address[] calldata _assets,
        uint256[] calldata _amounts,
        uint256[] calldata _premiums,
        address _initiator,
        bytes calldata _params
    ) external override onlyLendingPool returns (bool) {
        require(
            _initiator == address(this),
            "Only ProtectionAction can do flashloan"
        );
        FlashLoanData memory flashloanData = FlashLoanData(
            _assets,
            _amounts,
            _premiums,
            _params
        );
        return _executeOperation(flashloanData);
    }

    // solhint-disable function-max-lines
    // repay logic should be here.
    function _executeOperation(FlashLoanData memory _flashloanData)
        internal
        returns (bool)
    {
        FlashLoanParamsData memory paramsData = abi.decode(
            _flashloanData.params,
            (FlashLoanParamsData)
        );

        /// @notice Check if current health factor is below minimum health factor.
        (, , , , , uint256 healthFactorBefore) = LENDING_POOL
            .getUserAccountData(paramsData.onBehalfOf);
        _requirePositionUnSafe(
            healthFactorBefore,
            paramsData.minimumHealthFactor
        );

        /// @notice Swap Collateral token to debt token.

        uint256 debtRepaid = _swap(
            address(this),
            _swapModule,
            paramsData.swapActions,
            paramsData.swapDatas,
            IERC20(paramsData.debtToken),
            IERC20(_flashloanData.assets[0]),
            _flashloanData.amounts[0],
            paramsData.amtOfDebtToRepay
        );

        /// @notice Payback debt.

        _paybackToLendingPool(
            LENDING_POOL,
            paramsData.debtToken,
            debtRepaid,
            paramsData.rateMode,
            paramsData.onBehalfOf
        );

        /// @notice Withdraw collateral (including fees) and flashloan premium.

        uint256 fees = _convertEthToToken(
            ADDRESSES_PROVIDER,
            _flashloanData.assets[0],
            paramsData.protectionFeeInETH
        );

        uint256 amtOfColToWithdraw = _flashloanData.amounts[0] +
            fees +
            _flashloanData.premiums[0];

        _withdrawCollateral(
            LENDING_POOL,
            address(this),
            _flashloanData.assets[0],
            amtOfColToWithdraw,
            paramsData.onBehalfOf
        );

        /// @notice Transfer Fees

        _transferFees(_flashloanData.assets[0], fees);

        /// @notice Approve to retrieve.

        _approveERC20Token(
            _flashloanData.assets[0],
            address(LENDING_POOL),
            _flashloanData.amounts[0] + _flashloanData.premiums[0]
        );

        emit LogProtectionAction(
            paramsData.taskHash,
            healthFactorBefore,
            fees,
            _flashloanData.premiums[0],
            amtOfColToWithdraw,
            debtRepaid,
            paramsData.onBehalfOf
        );

        return true;
    }
}
