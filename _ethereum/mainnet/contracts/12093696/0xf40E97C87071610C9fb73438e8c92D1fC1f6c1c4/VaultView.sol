// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IERC20.sol";
import "./AggregatorV3Interface.sol";

import "./IVault.sol";
import "./IERC20Metadata.sol";

contract VaultView {

    struct Vault {
        address self;
        uint256 liveTime;
        uint256 settleTime;
        int256 underlyingStart;
        int256 underlyingEnd;
        uint256 primaryConversion;
        uint256 complementConversion;
        uint256 protocolFee;
        uint256 authorFeeLimit;
        uint256 state;
        address oracle;
        uint oracleDecimals;
        address oracleIterator;
        address collateralSplit;
    }

    struct Token {
        address self;
        string name;
        string symbol;
        uint8 decimals;
        uint userBalance;
    }

    struct DerivativeSpecification {
        address self;
        string name;
        string symbol;
        uint denomination;
        uint authorFee;
        uint primaryNominalValue;
        uint complementNominalValue;
        bytes32[] oracleSymbols;
    }

    function getVaultInfo(address _vault)
    external view
    returns (
        Vault memory vaultData,
        DerivativeSpecification memory derivativeSpecificationData,
        Token memory collateralData,
        uint lockedCollateralAmount,
        Token memory primaryData,
        Token memory complementData
    )
    {
        IVault vault = IVault(_vault);

        int256 underlyingStarts = 0;
        if(uint256(vault.state()) > 0) {
            underlyingStarts = vault.underlyingStarts(0);
        }

        int256 underlyingEnds = 0;
        if(vault.primaryConversion() > 0 || vault.complementConversion() > 0) {
            underlyingEnds = vault.underlyingEnds(0);
        }

        vaultData = Vault(
            address(_vault),
            vault.liveTime(),
            vault.settleTime(),
            underlyingStarts,
            underlyingEnds,
            vault.primaryConversion(),
            vault.complementConversion(),
            vault.protocolFee(),
            vault.authorFeeLimit(),
            uint256(vault.state()),
            vault.oracles(0),
            AggregatorV3Interface(vault.oracles(0)).decimals(),
            vault.oracleIterators(0),
            vault.collateralSplit()
        );

        IDerivativeSpecification specification = vault.derivativeSpecification();
        derivativeSpecificationData = DerivativeSpecification(
            address(specification),
            specification.name(),
            specification.symbol(),
            specification.primaryNominalValue() + specification.complementNominalValue(),
            specification.authorFee(),
            specification.primaryNominalValue(),
            specification.complementNominalValue(),
            specification.oracleSymbols()
        );

        IERC20Metadata collateral = IERC20Metadata(vault.collateralToken());
        IERC20 collateralToken = IERC20(address(collateral));
        collateralData = Token(
            address(collateral),
            collateral.name(),
            collateral.symbol(),
            collateral.decimals(),
            collateralToken.balanceOf(msg.sender)
        );
        lockedCollateralAmount = collateralToken.balanceOf(address(vault));

        IERC20Metadata primary = IERC20Metadata(vault.primaryToken());
        primaryData = Token(
            address(primary),
            primary.name(),
            primary.symbol(),
            primary.decimals(),
            IERC20(address(primary)).balanceOf(msg.sender)
        );

        IERC20Metadata complement = IERC20Metadata(vault.complementToken());
        complementData = Token(
            address(complement),
            complement.name(),
            complement.symbol(),
            complement.decimals(),
            IERC20(address(complement)).balanceOf(msg.sender)
        );
    }

    function getVaultTokenBalancesByOwner(
        address _owner,
        address[] calldata _vaults
    )
        external
        view
        returns (uint256[] memory primaries, uint256[] memory complements)
    {
        primaries = new uint256[](_vaults.length);
        complements = new uint256[](_vaults.length);

        IVault vault;
        for (uint256 i = 0; i < _vaults.length; i++) {
            vault = IVault(_vaults[i]);
            primaries[i] = IERC20(vault.primaryToken()).balanceOf(_owner);
            complements[i] = IERC20(vault.complementToken()).balanceOf(_owner);
        }
    }

    function getERC20BalancesByOwner(address _owner, address[] calldata _tokens)
        external
        view
        returns (uint256[] memory balances)
    {
        balances = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            balances[i] = IERC20(_tokens[i]).balanceOf(_owner);
        }
    }
}
