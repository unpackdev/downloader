// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/

pragma solidity ^0.8.17;

import "./ICustomToken.sol"; // includes interfaces L1MintableToken & L1ReverseToken
import "./draft-ERC20PermitUpgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
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

contract FlorinToken is ICustomToken, ERC20PermitUpgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable {
    address private customGatewayAddress;
    address private routerAddress;
    bool private shouldRegisterGateway;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {} // solhint-disable-line

    function initialize(address _customGatewayAddress, address _routerAddress) external initializer {
        _initializeArbitrumBridging(_customGatewayAddress, _routerAddress);
        __ERC20_init_unchained("Florin", "FLR");
        __ERC20Permit_init("Florin");
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

    /// @dev Mints FLR. Protected, only be callable by owner which should be FlorinTreasury
    /// @param receiver receiver of the minted FLR
    /// @param amount amount to mint (18 decimals)
    function mint(address receiver, uint256 amount) external onlyOwner {
        if (amount == 0) {
            revert Errors.MintAmountMustBeGreaterThanZero();
        }
        _mint(receiver, amount);
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
