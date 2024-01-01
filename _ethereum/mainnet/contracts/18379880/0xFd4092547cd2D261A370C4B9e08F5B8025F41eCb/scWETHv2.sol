// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "./scErrors.sol";

import "./ERC20.sol";
import "./WETH.sol";
import "./SafeTransferLib.sol";
import "./FixedPointMathLib.sol";
import "./Address.sol";
import "./EnumerableMap.sol";

import "./Constants.sol";
import "./BaseV2Vault.sol";
import "./IAdapter.sol";
import "./IwstETH.sol";
import "./PriceConverter.sol";
import "./Swapper.sol";

/**
 * @title Sandclock WETH Vault version 2
 * @notice Deposit Asset : Weth or Eth
 * This vault leverages the supplied weth using flashloans, stakes the leveraged eth, supplies the wstEth as collateral
 * and subesequently borrows weth on that collateral to payback the flashloan
 * The bulk of the interest is earned from staking eth
 * In contrast to scWETHv1 which used only one pre coded lending market
 * scWETHv2 can use multiple lending markets, which can be controlled by adding or removing adapter contracts into the vault
 */
contract scWETHv2 is BaseV2Vault {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    using Address for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    event Harvested(uint256 profitSinceLastHarvest, uint256 performanceFee);
    event MinFloatAmountUpdated(address indexed user, uint256 newMinFloatAmount);
    event Rebalanced(uint256 totalCollateral, uint256 totalDebt, uint256 floatBalance);
    event SuppliedAndBorrowed(uint256 adapterId, uint256 supplyAmount, uint256 borrowAmount);
    event RepaidAndWithdrawn(uint256 adapterId, uint256 repayAmount, uint256 withdrawAmount);
    event WithdrawnToVault(uint256 amount);

    // total invested during last harvest/rebalance
    uint256 public totalInvested;

    // total profit generated for this vault
    uint256 public totalProfit;

    // since the totalAssets increases after profit, the floatRequired also increases proportionally in case of using a percentage float
    // this will cause the receiveFlashloan method to fail on reinvesting profits (using rebalance) after the multicall, since the actual float in the contract remain unchanged after the multicall
    // this can be fixed by also withdrawing float into the contract in the reinvesting profits multicall but that makes the calculations very complex on the backend
    // a simple solution to that is just using minimumFloatAmount instead of a percentage float
    uint256 public minimumFloatAmount = 1 ether;

    IwstETH constant wstETH = IwstETH(C.WSTETH);

    constructor(address _admin, address _keeper, WETH _weth, Swapper _swapper, PriceConverter _priceConverter)
        BaseV2Vault(_admin, _keeper, _weth, _priceConverter, _swapper, "Sandclock Yield ETH", "scETH")
    {
        zeroExSwapWhitelist[ERC20(C.WSTETH)] = true;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC API
    //////////////////////////////////////////////////////////////*/

    // need to be able to receive eth
    receive() external payable {}

    /// @notice set the minimum amount of weth that must be present in the vault
    /// @param _newMinFloatAmount the new minimum float amount
    function setMinimumFloatAmount(uint256 _newMinFloatAmount) external {
        _onlyAdmin();

        minimumFloatAmount = _newMinFloatAmount;

        emit MinFloatAmountUpdated(msg.sender, _newMinFloatAmount);
    }

    /// @notice the primary method to be used by backend to invest, disinvest or reallocate funds among supported adapters
    /// @dev _totalInvestAmount must be zero in case of disinvest, reallocation or reinvesting profits
    /// @dev also mints performance fee tokens to the treasury based on the profits (if any) made by the vault
    /// @param _totalInvestAmount total amount of float in the strategy to invest in the lending markets in case of a invest
    /// @param _flashLoanAmount the amount to be flashloaned from balancer
    /// @param _multicallData array of bytes containing the series of encoded functions to be called (the functions being one of supplyAndBorrow, repayAndWithdraw, swapWstEthToWeth, swapWethToWstEth, zeroExSwap)
    function rebalance(uint256 _totalInvestAmount, uint256 _flashLoanAmount, bytes[] calldata _multicallData)
        external
    {
        _onlyKeeper();

        if (_totalInvestAmount > _wethBalance()) revert InsufficientDepositBalance();

        // needed otherwise counted as profit during harvest
        totalInvested += _totalInvestAmount;

        _flashLoan(_flashLoanAmount, _multicallData);

        _harvest();

        emit Rebalanced(totalCollateral(), totalDebt(), _wethBalance());
    }

    /// @notice swap weth to wstEth
    /// @dev the keeper will mostly use 0x (zeroExSwap method) for swapping weth to wstEth between rebalancing
    /// @dev this method is just a precaution and to be only used by the keeper in case zeroEx API goes down
    /// @param _wethAmount amount of weth to be swapped to wstEth
    function swapWethToWstEth(uint256 _wethAmount) external {
        _onlyKeeperOrFlashLoan();

        address(swapper).functionDelegateCall(
            abi.encodeWithSelector(Swapper.lidoSwapWethToWstEth.selector, _wethAmount)
        );
    }

    /// @notice swap wstEth to weth
    /// @dev mainly to be used in the multicall to swap withdrawn wstEth to weth to payback the flashloan
    /// @param _wstEthAmount amount of wstEth to be swapped to weth
    /// @param _slippageTolerance the max slippage during steth to eth swap (1e18 meaning 0 slippage tolerance)
    function swapWstEthToWeth(uint256 _wstEthAmount, uint256 _slippageTolerance) external {
        _onlyKeeperOrFlashLoan();

        if (_slippageTolerance > C.ONE) revert InvalidSlippageTolerance();

        uint256 wstEthBalance = _wstEthBalance();

        if (_wstEthAmount > wstEthBalance) {
            _wstEthAmount = wstEthBalance;
        }

        uint256 stEthAmount = wstETH.unwrap(_wstEthAmount);

        uint256 wethAmountOutMin = priceConverter.stEthToEth(stEthAmount).mulWadDown(_slippageTolerance);

        address(swapper).functionDelegateCall(
            abi.encodeWithSelector(Swapper.curveSwapStEthToWeth.selector, stEthAmount, wethAmountOutMin)
        );
    }

    /// @notice withdraw deposited funds from the lending markets to the vault
    /// @param _amount : amount of assets to withdraw to the vault
    function withdrawToVault(uint256 _amount) external {
        _onlyKeeper();

        _withdrawToVault(_amount);
    }

    /// @notice returns the adapter address given the adapterId (only if the adaapterId is supported else returns zero address)
    /// @param _adapterId the id of the adapter to check
    function getAdapter(uint256 _adapterId) external view returns (address adapter) {
        (, adapter) = protocolAdapters.tryGet(_adapterId);
    }

    /// @notice returns the total assets (in WETH) held by the strategy
    function totalAssets() public view override returns (uint256 assets) {
        // value of the supplied collateral + wstEth leftovers (vault's balance) in eth terms using chainlink oracle
        assets = priceConverter.wstEthToEth(totalCollateral() + _wstEthBalance());

        // subtract the debt
        assets -= totalDebt();

        // add float
        assets += _wethBalance();
    }

    /// @notice returns the wstEth deposited of the vault in a particular protocol
    /// @param _adapterId The id the protocol adapter
    function getCollateral(uint256 _adapterId) public view returns (uint256) {
        if (!isSupported(_adapterId)) return 0;

        return IAdapter(protocolAdapters.get(_adapterId)).getCollateral(address(this));
    }

    /// @notice returns the total wstEth supplied as collateral
    function totalCollateral() public view returns (uint256 collateral) {
        uint256 n = protocolAdapters.length();
        address adapter;

        for (uint256 i; i < n; i++) {
            (, adapter) = protocolAdapters.at(i);
            collateral += IAdapter(adapter).getCollateral(address(this));
        }
    }

    /// @notice returns the weth debt of the vault in a particularly protocol
    /// @param _adapterId The id the protocol adapter
    function getDebt(uint256 _adapterId) public view returns (uint256) {
        if (!isSupported(_adapterId)) return 0;

        return IAdapter(protocolAdapters.get(_adapterId)).getDebt(address(this));
    }

    /// @notice returns the total WETH borrowed
    function totalDebt() public view returns (uint256 debt) {
        uint256 n = protocolAdapters.length();
        address adapter;

        for (uint256 i; i < n; i++) {
            (, adapter) = protocolAdapters.at(i);
            debt += IAdapter(adapter).getDebt(address(this));
        }
    }

    /// @notice helper method for the user to directly deposit ETH to this vault instead of weth
    /// @param receiver the address to mint the shares to
    function deposit(address receiver) external payable returns (uint256 shares) {
        uint256 assets = msg.value;

        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // wrap eth
        WETH(payable(address(asset))).deposit{value: assets}();

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    /// @dev called after the flashLoan on rebalance
    function receiveFlashLoan(
        address[] memory,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        _isFlashLoanInitiated();

        // decode user data
        bytes[] memory callData = abi.decode(userData, (bytes[]));

        _multiCall(callData);

        // payback flashloan
        asset.safeTransfer(address(balancerVault), amounts[0] + feeAmounts[0]);

        _enforceFloat();
    }

    /// @notice supplies wstEth as collateral and borrows weth from the respective protocol as specified by adapterId
    /// @dev mainly to be used inside the multicall to supply and borrow assets from the respective lending market
    /// @param _adapterId the id of the adapter for the required protocol
    /// @param _supplyAmount the amount of wstEth to be supplied as collateral
    /// @param _borrowAmount the amount of weth to be borrowed
    function supplyAndBorrow(uint256 _adapterId, uint256 _supplyAmount, uint256 _borrowAmount) external {
        _onlyKeeperOrFlashLoan();

        address adapter = protocolAdapters.get(_adapterId);

        _adapterDelegateCall(adapter, abi.encodeWithSelector(IAdapter.supply.selector, _supplyAmount));
        _adapterDelegateCall(adapter, abi.encodeWithSelector(IAdapter.borrow.selector, _borrowAmount));

        emit SuppliedAndBorrowed(_adapterId, _supplyAmount, _borrowAmount);
    }

    /// @notice repays weth debt and withdraws wstEth collateral from the respective protocol as specified by adapterId
    /// @dev mainly to be used inside the multicall to repay and withdraw assets from the respective lending market
    /// @param _adapterId the id of the adapter for the required protocol
    /// @param _repayAmount the amount of weth to be repaid
    /// @param _withdrawAmount the amount of wstEth to be withdrawn
    function repayAndWithdraw(uint256 _adapterId, uint256 _repayAmount, uint256 _withdrawAmount) external {
        _onlyKeeperOrFlashLoan();

        address adapter = protocolAdapters.get(_adapterId);

        _adapterDelegateCall(adapter, abi.encodeWithSelector(IAdapter.repay.selector, _repayAmount));
        _adapterDelegateCall(adapter, abi.encodeWithSelector(IAdapter.withdraw.selector, _withdrawAmount));

        emit RepaidAndWithdrawn(_adapterId, _repayAmount, _withdrawAmount);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        uint256 balance = _wethBalance();

        // since during withdrawing everything,
        // actual withdrawn amount might be less than totalAsssets
        // (due to slippage incurred during wstEth to weth swap)
        if (assets > balance) {
            assets = balance;
        }

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        uint256 balance = _wethBalance();

        // since during withdrawing everything,
        // actual withdrawn amount might be less than totalAsssets
        // (due to slippage incurred during wstEth to weth swap)
        if (assets > balance) {
            assets = balance;
        }

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL API
    //////////////////////////////////////////////////////////////*/

    function _withdrawToVault(uint256 _amount) internal {
        uint256 n = protocolAdapters.length();
        uint256 flashLoanAmount;
        uint256 totalInvested_ = _totalCollateralInWeth() - totalDebt();
        bytes[] memory callData = new bytes[](n + 1); // +1 for the last call to swap wstEth to weth

        // limit the amount to withdraw to the total invested amount
        if (_amount > totalInvested_) _amount = totalInvested_;

        uint256 id;
        address adapter;
        uint256 repayPerProtocol;
        uint256 withdrawPerProtocol;
        for (uint256 i; i < n; i++) {
            (id, adapter) = protocolAdapters.at(i);
            uint256 collateral = IAdapter(adapter).getCollateral(address(this));

            // skip if there is no position on this protocol
            if (collateral == 0) continue;

            uint256 debt = IAdapter(adapter).getDebt(address(this));
            uint256 assets = priceConverter.wstEthToEth(collateral) - debt;

            // withdraw from each protocol in equal weight (based on the relative allocation)
            withdrawPerProtocol = _amount.mulDivDown(assets, totalInvested_);
            repayPerProtocol = withdrawPerProtocol.mulDivDown(debt, assets);
            flashLoanAmount += repayPerProtocol;

            callData[i] = abi.encodeWithSelector(
                this.repayAndWithdraw.selector,
                id,
                repayPerProtocol,
                priceConverter.ethToWstEth(repayPerProtocol + withdrawPerProtocol)
            );
        }

        // needed otherwise counted as loss during harvest
        totalInvested -= _amount;

        callData[n] = abi.encodeWithSelector(scWETHv2.swapWstEthToWeth.selector, type(uint256).max, slippageTolerance);

        uint256 float = _wethBalance();

        _flashLoan(flashLoanAmount, callData);

        emit WithdrawnToVault(_wethBalance() - float);
    }

    /// @notice reverts if float in the vault is not above the minimum required
    function _enforceFloat() internal view {
        uint256 float = _wethBalance();
        uint256 floatRequired = minimumFloatAmount;

        if (float < floatRequired) revert FloatBalanceTooLow(float, floatRequired);
    }

    function beforeWithdraw(uint256 assets, uint256) internal override {
        uint256 float = _wethBalance();

        if (assets <= float) return;

        uint256 missing = assets + minimumFloatAmount - float;

        _withdrawToVault(missing);
    }

    function _flashLoan(uint256 _totalFlashLoanAmount, bytes[] memory callData) internal {
        address[] memory tokens = new address[](1);
        tokens[0] = address(asset);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _totalFlashLoanAmount;

        _initiateFlashLoan();
        balancerVault.flashLoan(address(this), tokens, amounts, abi.encode(callData));
        _finalizeFlashLoan();
    }

    function _harvest() internal {
        // store the old total
        uint256 oldTotalInvested = totalInvested;
        uint256 assets = priceConverter.wstEthToEth(totalCollateral() + _wstEthBalance()) - totalDebt();

        if (assets > oldTotalInvested) {
            totalInvested = assets;

            // profit since last harvest, zero if there was a loss
            uint256 profit = assets - oldTotalInvested;
            totalProfit += profit;

            uint256 fee = profit.mulWadDown(performanceFee);

            // mint equivalent amount of tokens to the performance fee beneficiary ie the treasury
            _mint(treasury, convertToShares(fee));

            emit Harvested(profit, fee);
        }
    }

    function _totalCollateralInWeth() internal view returns (uint256) {
        return priceConverter.wstEthToEth(totalCollateral());
    }

    function _wethBalance() internal view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function _wstEthBalance() internal view returns (uint256) {
        return wstETH.balanceOf(address(this));
    }
}
