// SPDX-License-Identifier: (CC-BY-NC-ND-3.0)
// Code and docs are CC-BY-NC-ND-3.0
pragma solidity ^0.8.0;

import "./Vault.sol";
import "./IEthAnchorConversionPool.sol";
import "./SafeERC20Upgradeable.sol";

/**
 * @title Vault
 * @dev Contract in charge of holding usdc tokens and depositing them to Yield Aggregator
 *
 */
contract Vault2 is Vault {
    /**
     * @dev address of the USDC token
     */
    IERC20Upgradeable internal usdcToken;

    /**
     * @dev address of the USDC token
     */
    IERC20Upgradeable internal aUsdcToken;

    /**
     * @dev address of the Chainlink Defender
     */
    address internal backendAddress;

    IConversionPool conversionPool;

    /**
     * @notice initialize init the contract with the following parameters
     * @dev this function is called only once during the contract initialization
     * @param _usdcTokenAddress USDC token contract address
     * @param _backendAddress address of the Chainlink Defender
     */
    function setUpVault(
        address _usdcTokenAddress,
        address _aUsdcTokenAddress,
        address _backendAddress,
        address _conversionPoolAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _usdcTokenAddress != address(0),
            "Vault: USDC token address cannot be address 0!"
        );

        usdcToken = IERC20Upgradeable(_usdcTokenAddress);
        aUsdcToken = IERC20Upgradeable(_aUsdcTokenAddress);
        conversionPool = IConversionPool(_conversionPoolAddress);
        backendAddress = _backendAddress;

        _setupRole(BACKEND_ADMIN_ROLE, _backendAddress);
    }

    function depositUsdcThroughConversionPool(uint256 amount_usdc)
        external
        onlyRole(BACKEND_ADMIN_ROLE)
        whenNotPaused
    {
        require(
            usdcToken.balanceOf(address(this)) >= amount_usdc,
            "Vault: Contract does not have enough balance of USDC."
        );

        // approve to Conversion Pool
        usdcToken.approve(address(conversionPool), amount_usdc);

        // deposit to Conversion Pool
        conversionPool.deposit(amount_usdc);
    }

    function redeemAUsdcFromConversionPool(uint256 amount_ausdc)
        external
        onlyRole(BACKEND_ADMIN_ROLE)
        whenNotPaused
    {
        require(
            aUsdcToken.balanceOf(address(this)) >= amount_ausdc,
            "Vault: Contract does not have enough balance of aUSDC."
        );

        // approve to Conversion Pool
        aUsdcToken.approve(address(conversionPool), amount_ausdc);

        // redeem from Conversion Pool
        conversionPool.redeem(amount_ausdc);
    }

    function version() public pure virtual override returns (string memory) {
        return "2.0.0";
    }
}
