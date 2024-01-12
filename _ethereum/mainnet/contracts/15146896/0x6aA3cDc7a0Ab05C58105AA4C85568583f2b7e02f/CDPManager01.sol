// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov (az@unit.xyz).
*/
pragma solidity ^0.8.15;

import "./IOracleRegistry.sol";
import "./IOracleUsd.sol";
import "./IWETH.sol";
import "./IVault.sol";
import "./ICDPRegistry.sol";
import "./IVaultManagerParameters.sol";
import "./IVaultParameters.sol";
import "./IToken.sol";

import "./ReentrancyGuard.sol";

/**
 * @title CDPManager01
 **/
contract CDPManager01 is ReentrancyGuard {

    IVault public immutable vault;
    IVaultManagerParameters public immutable vaultManagerParameters;
    IOracleRegistry public immutable oracleRegistry;
    ICDPRegistry public immutable cdpRegistry;
    address payable public immutable WETH;

    uint public constant Q112 = 2 ** 112;
    uint public constant DENOMINATOR_1E5 = 1e5;

    /**
     * @dev Trigger when joins are happened
    **/
    event Join(address indexed asset, address indexed owner, uint main, uint gcd);

    /**
     * @dev Trigger when exits are happened
    **/
    event Exit(address indexed asset, address indexed owner, uint main, uint gcd);

    /**
     * @dev Trigger when liquidations are initiated
    **/
    event LiquidationTriggered(address indexed asset, address indexed owner);

    modifier checkpoint(address asset, address owner) {
        _;
        cdpRegistry.checkpoint(asset, owner);
    }

    /**
     * @param _vaultManagerParameters The address of the contract with Vault manager parameters
     * @param _oracleRegistry The address of the oracle registry
     * @param _cdpRegistry The address of the CDP registry
     **/
    constructor(address _vaultManagerParameters, address _oracleRegistry, address _cdpRegistry) {
        require(
            _vaultManagerParameters != address(0) && 
            _oracleRegistry != address(0) && 
            _cdpRegistry != address(0),
                "GCD Protocol: INVALID_ARGS"
        );
        vaultManagerParameters = IVaultManagerParameters(_vaultManagerParameters);
        vault = IVault(IVaultParameters(IVaultManagerParameters(_vaultManagerParameters).vaultParameters()).vault());
        oracleRegistry = IOracleRegistry(_oracleRegistry);
        WETH = IVault(IVaultParameters(IVaultManagerParameters(_vaultManagerParameters).vaultParameters()).vault()).weth();
        cdpRegistry = ICDPRegistry(_cdpRegistry);
    }

    // only accept ETH via fallback from the WETH contract
    receive() external payable {
        require(msg.sender == WETH, "GCD Protocol: RESTRICTED");
    }

    /**
      * @notice Depositing tokens must be pre-approved to Vault address
      * @notice position actually considered as spawned only when debt > 0
      * @dev Deposits collateral and/or borrows GCD
      * @param asset The address of the collateral
      * @param assetAmount The amount of the collateral to deposit
      * @param gcdAmount The amount of GCD token to borrow
      **/
    function join(address asset, uint assetAmount, uint gcdAmount) public nonReentrant checkpoint(asset, msg.sender) {
        require(gcdAmount != 0 || assetAmount != 0, "GCD Protocol: USELESS_TX");

        require(IToken(asset).decimals() <= 18, "GCD Protocol: NOT_SUPPORTED_DECIMALS");

        if (gcdAmount == 0) {

            vault.depositMain(asset, msg.sender, assetAmount);

        } else {

            _ensureOracle(asset);

            bool spawned = vault.debts(asset, msg.sender) != 0;

            if (!spawned) {
                // spawn a position
                vault.spawn(asset, msg.sender, oracleRegistry.oracleTypeByAsset(asset));
            }

            if (assetAmount != 0) {
                vault.depositMain(asset, msg.sender, assetAmount);
            }

            // mint GCD to owner
            vault.borrow(asset, msg.sender, gcdAmount);

            // check collateralization
            _ensurePositionCollateralization(asset, msg.sender);

        }

        // fire an event
        emit Join(asset, msg.sender, assetAmount, gcdAmount);
    }

    /**
      * @dev Deposits ETH and/or borrows GCD
      * @param gcdAmount The amount of GCD token to borrow
      **/
    function join_Eth(uint gcdAmount) external payable {

        if (msg.value != 0) {
            IWETH(WETH).deposit{value: msg.value}();
            require(IWETH(WETH).transfer(msg.sender, msg.value), "GCD Protocol: WETH_TRANSFER_FAILED");
        }

        join(WETH, msg.value, gcdAmount);
    }

    /**
      * @notice Tx sender must have a sufficient GCD balance to pay the debt
      * @dev Withdraws collateral and repays specified amount of debt
      * @param asset The address of the collateral
      * @param assetAmount The amount of the collateral to withdraw
      * @param gcdAmount The amount of GCD to repay
      **/
    function exit(address asset, uint assetAmount, uint gcdAmount) public nonReentrant checkpoint(asset, msg.sender) returns (uint) {

        // check usefulness of tx
        require(assetAmount != 0 || gcdAmount != 0, "GCD Protocol: USELESS_TX");

        uint debt = vault.debts(asset, msg.sender);

        // catch full repayment
        if (gcdAmount > debt) { gcdAmount = debt; }

        if (assetAmount == 0) {
            _repay(asset, msg.sender, gcdAmount);
        } else {
            if (debt == gcdAmount) {
                vault.withdrawMain(asset, msg.sender, assetAmount);
                if (gcdAmount != 0) {
                    _repay(asset, msg.sender, gcdAmount);
                }
            } else {
                _ensureOracle(asset);

                // withdraw collateral to the owner address
                vault.withdrawMain(asset, msg.sender, assetAmount);

                if (gcdAmount != 0) {
                    _repay(asset, msg.sender, gcdAmount);
                }

                vault.update(asset, msg.sender);

                _ensurePositionCollateralization(asset, msg.sender);
            }
        }

        // fire an event
        emit Exit(asset, msg.sender, assetAmount, gcdAmount);

        return gcdAmount;
    }

    /**
      * @notice Repayment is the sum of the principal and interest
      * @dev Withdraws collateral and repays specified amount of debt
      * @param asset The address of the collateral
      * @param assetAmount The amount of the collateral to withdraw
      * @param repayment The target repayment amount
      **/
    function exit_targetRepayment(address asset, uint assetAmount, uint repayment) external returns (uint) {

        uint gcdAmount = _calcPrincipal(asset, msg.sender, repayment);

        return exit(asset, assetAmount, gcdAmount);
    }

    /**
      * @notice Withdraws WETH and converts to ETH
      * @param ethAmount ETH amount to withdraw
      * @param gcdAmount The amount of GCD token to repay
      **/
    function exit_Eth(uint ethAmount, uint gcdAmount) public returns (uint) {
        gcdAmount = exit(WETH, ethAmount, gcdAmount);
        require(IWETH(WETH).transferFrom(msg.sender, address(this), ethAmount), "GCD Protocol: WETH_TRANSFER_FROM_FAILED");
        IWETH(WETH).withdraw(ethAmount);
        (bool success, ) = msg.sender.call{value:ethAmount}("");
        require(success, "GCD Protocol: ETH_TRANSFER_FAILED");
        return gcdAmount;
    }

    /**
      * @notice Repayment is the sum of the principal and interest
      * @notice Withdraws WETH and converts to ETH
      * @param ethAmount ETH amount to withdraw
      * @param repayment The target repayment amount
      **/
    function exit_Eth_targetRepayment(uint ethAmount, uint repayment) external returns (uint) {
        uint gcdAmount = _calcPrincipal(WETH, msg.sender, repayment);
        return exit_Eth(ethAmount, gcdAmount);
    }

    // decreases debt
    function _repay(address asset, address owner, uint gcdAmount) internal {
        uint fee = vault.calculateFee(asset, owner, gcdAmount);
        vault.chargeFee(vault.gcd(), owner, fee);

        // burn GCD from the owner's balance
        uint debtAfter = vault.repay(asset, owner, gcdAmount);
        if (debtAfter == 0) {
            // clear unused storage
            vault.destroy(asset, owner);
        }
    }

    function _ensurePositionCollateralization(address asset, address owner) internal view {
        // collateral value of the position in USD
        uint usdValue_q112 = getCollateralUsdValue_q112(asset, owner);

        // USD limit of the position
        uint usdLimit = usdValue_q112 * vaultManagerParameters.initialCollateralRatio(asset) / Q112 / 100;

        // revert if collateralization is not enough
        require(vault.getTotalDebt(asset, owner) <= usdLimit, "GCD Protocol: UNDERCOLLATERALIZED");
    }
    
    // Liquidation Trigger

    /**
     * @dev Triggers liquidation of a position
     * @param asset The address of the collateral token of a position
     * @param owner The owner of the position
     **/
    function triggerLiquidation(address asset, address owner) external nonReentrant {

        _ensureOracle(asset);

        // USD value of the collateral
        uint usdValue_q112 = getCollateralUsdValue_q112(asset, owner);
        
        // reverts if a position is not liquidatable
        require(_isLiquidatablePosition(asset, owner, usdValue_q112), "GCD Protocol: SAFE_POSITION");

        uint liquidationDiscount_q112 = usdValue_q112 * 
            vaultManagerParameters.liquidationDiscount(asset)
            / DENOMINATOR_1E5;

        uint initialLiquidationPrice = (usdValue_q112 - liquidationDiscount_q112) / Q112;

        // sends liquidation command to the Vault
        vault.triggerLiquidation(asset, owner, initialLiquidationPrice);

        // fire an liquidation event
        emit LiquidationTriggered(asset, owner);
    }

    function getCollateralUsdValue_q112(address asset, address owner) public view returns (uint) {
        return IOracleUsd(oracleRegistry.oracleByAsset(asset)).assetToUsd(asset, vault.collaterals(asset, owner));
    }

    /**
     * @dev Determines whether a position is liquidatable
     * @param asset The address of the collateral
     * @param owner The owner of the position
     * @param usdValue_q112 Q112-encoded USD value of the collateral
     * @return boolean value, whether a position is liquidatable
     **/
    function _isLiquidatablePosition(
        address asset,
        address owner,
        uint usdValue_q112
    ) internal view returns (bool) {
        uint debt = vault.getTotalDebt(asset, owner);

        // position is collateralized if there is no debt
        if (debt == 0) return false;

        return debt * 100 * Q112 / usdValue_q112 >= vaultManagerParameters.liquidationRatio(asset);
    }

    function _ensureOracle(address asset) internal view {
        uint oracleType = oracleRegistry.oracleTypeByAsset(asset);
        require(oracleType != 0, "GCD Protocol: INVALID_ORACLE_TYPE");
        address oracle = oracleRegistry.oracleByType(oracleType);
        require(oracle != address(0), "GCD Protocol: DISABLED_ORACLE");
    }

    /**
     * @dev Determines whether a position is liquidatable
     * @param asset The address of the collateral
     * @param owner The owner of the position
     * @return boolean value, whether a position is liquidatable
     **/
    function isLiquidatablePosition(
        address asset,
        address owner
    ) public view returns (bool) {
        uint usdValue_q112 = getCollateralUsdValue_q112(asset, owner);

        return _isLiquidatablePosition(asset, owner, usdValue_q112);
    }

    /**
     * @dev Calculates current utilization ratio
     * @param asset The address of the collateral
     * @param owner The owner of the position
     * @return utilization ratio
     **/
    function utilizationRatio(
        address asset,
        address owner
    ) public view returns (uint) {
        uint debt = vault.getTotalDebt(asset, owner);
        if (debt == 0) return 0;
        
        uint usdValue_q112 = getCollateralUsdValue_q112(asset, owner);

        return debt * 100 * Q112 / usdValue_q112;
    }
    

    /**
     * @dev Calculates liquidation price
     * @param asset The address of the collateral
     * @param owner The owner of the position
     * @return Q112-encoded liquidation price
     **/
    function liquidationPrice_q112(
        address asset,
        address owner
    ) external view returns (uint) {

        uint debt = vault.getTotalDebt(asset, owner);
        if (debt == 0) return type(uint).max;
        
        uint collateralLiqPrice = debt * 100 * Q112 / vaultManagerParameters.liquidationRatio(asset);

        require(IToken(asset).decimals() <= 18, "GCD Protocol: NOT_SUPPORTED_DECIMALS");

        return collateralLiqPrice / vault.collaterals(asset, owner) / 10 ** (18 - IToken(asset).decimals());
    }

    function _calcPrincipal(address asset, address owner, uint repayment) internal view returns (uint) {
        uint fee = vault.stabilityFee(asset, owner) * (block.timestamp - vault.lastUpdate(asset, owner)) / 365 days;
        return repayment * DENOMINATOR_1E5 / (DENOMINATOR_1E5 + fee);
    }
}
