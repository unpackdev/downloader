// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

import "./AggregatorV3Interface.sol";

import "./VaultCalculator.sol";

/// @title IVault Interface
interface IVault {
    function getAccessor() external view returns (address);
}

/// @title IComptroller Interface
interface IComptroller {
    function calcGav(bool) external returns (uint256, bool);

    function getDenominationAsset() external view returns (address);
}

/// @title IFundValueCalculatorUsdWrapper interface
interface IFundValueCalculatorUsdWrapper {
    function calcNetValueForSharesHolder(
        address _vaultProxy,
        address _sharesHolder
    ) external returns (uint256 netValue_);
}

/// @title IFundValueCalculator interface
interface IFundValueCalculatorRouter {
    function calcNetValueForSharesHolder(
        address _vaultProxy,
        address _sharesHolder
    ) external returns (address denominationAsset_, uint256 netValue_);

    function calcNetValueForSharesHolderInAsset(
        address _vaultProxy,
        address _sharesHolder,
        address _quoteAsset
    ) external returns (uint256 netValue_);
}

/// @title EnzymeCurrencyCalculatorCustom
/// @dev This contract is used as an adapter to get a calculated dollar value for an Enzyme Vault
contract EnzymeCurrencyCalculatorCustom is IVaultCalculator {
    address calculator;
    address sharesHolder;

    constructor(address _calculator, address _sharesHolder) {
        require(
            _calculator != address(0),
            "calculator can not be the zero address"
        );
        require(
            _sharesHolder != address(0),
            "share holder can not be the zero address"
        );

        calculator = _calculator;
        sharesHolder = _sharesHolder;
    }

    /// @notice The decimals are assumed to be 18, and the security is dependant on the Enzyme implementation
    /// @dev Read the dollar denominated value with a custom calculator for a given vault
    /// @param vaultProxy The address of an Enzyme vault
    function calculate(address vaultProxy)
        external
        override
        returns (uint256 answer)
    {
        answer = IFundValueCalculatorUsdWrapper(calculator)
            .calcNetValueForSharesHolder(vaultProxy, sharesHolder);
    }
}

/// @title EnzymeCurrencyCalculatorStandard
/// @dev This contract is used as an adapter to get a calculated dollar value for an Enzyme Vault
contract EnzymeCurrencyCalculatorStandard is IVaultCalculator {
    AggregatorV3Interface price;

    constructor(AggregatorV3Interface _price) {
        price = _price;
    }

    /// @notice The decimals are assumed to be 18, and the security is dependant on the Enzyme implementation
    /// @dev Read the dollar denominated value with of a vault using a Chainlink price feed and the denomination token
    /// quantity
    /// @param vault The address of an Enzyme vault
    function calculate(address vault) external override returns (uint256) {
        IComptroller accessor = IComptroller(IVault(vault).getAccessor());

        address denominationAsset = accessor.getDenominationAsset();

        uint256 answer;
        (answer, ) = IComptroller(accessor).calcGav(false);

        int256 latestRoundData;
        (, latestRoundData, , , ) = AggregatorV3Interface(price)
            .latestRoundData();

        uint256 decimals = uint256(ERC20(denominationAsset).decimals());
        uint256 priceDecimals = uint256(
            AggregatorV3Interface(price).decimals()
        );

        require(latestRoundData > 0, "price feed error");
        require(
            18 >= decimals && 18 >= priceDecimals,
            "invalid token decimals"
        );

        uint256 priceFeed = uint256(latestRoundData);

        return
            (answer * priceFeed * 10**uint256(18 - priceDecimals)) /
            10**uint256(decimals); // return (answer * priceFeed) / 10**8;
    }
}

/// @title EnzymeCurrencyCalculatorStandard
/// @dev This contract is used as an adapter to get a calculated token value for an Enzyme Vault
contract EnzymeTokenCalculatorCustom is IVaultCalculator {
    address calculator;
    address sharesHolder;

    constructor(address _calculator, address _sharesHolder) {
        require(
            _calculator != address(0),
            "calculator can not be the zero address"
        );
        require(
            _sharesHolder != address(0),
            "share holder can not be the zero address"
        );

        calculator = _calculator;
        sharesHolder = _sharesHolder;
    }

    /// @notice The decimals are assumed to be 18, and the security is dependant on the Enzyme implementation
    /// @dev Read the token quantity value with a custom calculator for a given vault
    /// @param vaultProxy The address of an Enzyme vault
    function calculate(address vaultProxy) external override returns (uint256) {
        address denominationAsset;
        (denominationAsset, ) = IFundValueCalculatorRouter(calculator)
            .calcNetValueForSharesHolder(vaultProxy, sharesHolder);

        return
            IFundValueCalculatorRouter(calculator)
                .calcNetValueForSharesHolderInAsset(
                    vaultProxy,
                    sharesHolder,
                    denominationAsset
                );
    }
}

/// @title EnzymeCurrencyCalculatorStandard
/// @dev This contract is used as an adapter to get a calculated token value for an Enzyme Vault
contract EnzymeTokenCalculatorStandard is IVaultCalculator {
    /// @notice The decimals are assumed to be 18, and the security is dependant on the Enzyme implementation
    /// @dev Read the token quantity value calling the peripheral contract directly
    /// @param vault The address of an Enzyme vault
    function calculate(address vault) external override returns (uint256) {
        IComptroller accessor = IComptroller(IVault(vault).getAccessor());

        address denominationAsset = accessor.getDenominationAsset();

        uint256 answer;
        (answer, ) = accessor.calcGav(false);

        uint256 decimals = uint256(ERC20(denominationAsset).decimals());

        require(18 >= decimals);

        return answer * 10**uint256(18 - decimals);
    }
}
