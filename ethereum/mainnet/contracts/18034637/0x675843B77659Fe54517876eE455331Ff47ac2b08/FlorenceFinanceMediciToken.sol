// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/

pragma solidity ^0.8.17;

import "./ICustomToken.sol"; // includes interfaces L1MintableToken & L1ReverseToken
import "./draft-ERC20PermitUpgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20CappedUpgradeable.sol";
import "./OwnableUpgradeable.sol"; // includes ContextUpgradeable

import "./Errors.sol";

/**
 * @title Interface needed to call function registerTokenToL2 of the L1CustomGateway
 */
interface IL1CustomGateway {
    function registerTokenToL2(
        address _l2Address,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        address _creditBackAddress
    ) external payable returns (uint256);
}

/**
 * @title Interface needed to call function setGateway of the L2GatewayRouter
 */
interface IL1GatewayRouter {
    function setGateway(address _gateway, uint256 _maxGas, uint256 _gasPriceBid, uint256 _maxSubmissionCost, address _creditBackAddress) external payable returns (uint256);
}

/// @title Florence Finance Medici Token on Ethereum Mainnet
/// @dev The Florence Finance Medici Token is the base currency for the protocol and its LoanVaults
contract FlorenceFinanceMediciToken is ICustomToken, ERC20PermitUpgradeable, ERC20BurnableUpgradeable, ERC20CappedUpgradeable, OwnableUpgradeable {
    address private customGatewayAddress;
    address private routerAddress;
    bool private shouldRegisterGateway;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {} // solhint-disable-line

    function initialize(address _customGatewayAddress, address _routerAddress) external initializer {
        _initializeArbitrumBridging(_customGatewayAddress, _routerAddress);
        __ERC20_init_unchained("Florence Finance Medici", "FFM");
        __ERC20Permit_init("Florence Finance Medici");
        __ERC20Capped_init(1_000_000_000 * 10 ** 18);
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function initializeArbitrumBridging(address _customGatewayAddress, address _routerAddress) external onlyOwner {
        _initializeArbitrumBridging(_customGatewayAddress, _routerAddress);
    }

    function _initializeArbitrumBridging(address _customGatewayAddress, address _routerAddress) internal {
        customGatewayAddress = _customGatewayAddress;
        routerAddress = _routerAddress;
    }

    /// @dev Mints FFM. Protected, only be callable by owner
    /// @param receiver receiver of the minted FFM
    /// @param amount amount to mint (18 decimals)
    function mint(address receiver, uint256 amount) external onlyOwner {
        if (amount == 0) {
            revert Errors.MintAmountMustBeGreaterThanZero();
        }
        _mint(receiver, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20CappedUpgradeable, ERC20Upgradeable) {
        super._mint(account, amount);
    }

    /// @dev Allows anyone to burn their own FFM tokens
    /// @param amount (uint256) amount to burn (18 decimals)
    function burn(uint256 amount) public override {
        if (amount == 0) {
            revert Errors.BurnAmountMustBeGreaterThanZero();
        }
        _burn(msg.sender, amount);
    }

    /// @dev we only set shouldRegisterGateway to true when in `registerTokenOnL2`
    function isArbitrumEnabled() external view override returns (uint8) {
        require(shouldRegisterGateway, "NOT_EXPECTED_CALL");
        return uint8(0xb1);
    }

    /// @dev See {ICustomToken-registerTokenOnL2}
    function registerTokenOnL2(
        address l2CustomTokenAddress,
        uint256 maxSubmissionCostForCustomGateway,
        uint256 maxSubmissionCostForRouter,
        uint256 maxGasForCustomGateway,
        uint256 maxGasForRouter,
        uint256 gasPriceBid,
        uint256 valueForGateway,
        uint256 valueForRouter,
        address creditBackAddress
    ) public payable override onlyOwner {
        // we temporarily set `shouldRegisterGateway` to true for the callback in registerTokenToL2 to succeed
        bool prev = shouldRegisterGateway;
        shouldRegisterGateway = true;

        IL1CustomGateway(customGatewayAddress).registerTokenToL2{value: valueForGateway}(
            l2CustomTokenAddress,
            maxGasForCustomGateway,
            gasPriceBid,
            maxSubmissionCostForCustomGateway,
            creditBackAddress
        );

        IL1GatewayRouter(routerAddress).setGateway{value: valueForRouter}(customGatewayAddress, maxGasForRouter, gasPriceBid, maxSubmissionCostForRouter, creditBackAddress);

        shouldRegisterGateway = prev;
    }

    /// @dev See {ERC20-transferFrom}
    function transferFrom(address sender, address recipient, uint256 amount) public override(ICustomToken, ERC20Upgradeable) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    /// @dev See {ERC20-balanceOf}
    function balanceOf(address account) public view override(ICustomToken, ERC20Upgradeable) returns (uint256) {
        return super.balanceOf(account);
    }
}
