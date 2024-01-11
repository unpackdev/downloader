// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IBasePortfolio} from "IBasePortfolio.sol";
import {IERC20WithDecimals} from "IERC20WithDecimals.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";
import {ProxyWrapper} from "ProxyWrapper.sol";
import {Upgradeable} from "Upgradeable.sol";

abstract contract BasePortfolioFactory is Upgradeable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IBasePortfolio public portfolioImplementation;
    IBasePortfolio[] public portfolios;
    IProtocolConfig public protocolConfig;

    event PortfolioCreated(IBasePortfolio indexed newPortfolio, address indexed manager);
    event PortfolioImplementationChanged(IBasePortfolio indexed newImplementation);

    function initialize(IBasePortfolio _portfolioImplementation, IProtocolConfig _protocolConfig) external initializer {
        __Upgradeable_init(msg.sender, _protocolConfig.pauserAddress());
        portfolioImplementation = _portfolioImplementation;
        protocolConfig = _protocolConfig;
    }

    function setPortfolioImplementation(IBasePortfolio newImplementation) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            portfolioImplementation != newImplementation,
            "BasePortfolioFactory: New portfolio implementation needs to be different"
        );
        portfolioImplementation = newImplementation;
        emit PortfolioImplementationChanged(newImplementation);
    }

    function getPortfolios() external view returns (IBasePortfolio[] memory) {
        return portfolios;
    }

    function _deployPortfolio(bytes memory initData) internal {
        IBasePortfolio newPortfolio = IBasePortfolio(address(new ProxyWrapper(address(portfolioImplementation), initData)));
        portfolios.push(newPortfolio);
        emit PortfolioCreated(newPortfolio, msg.sender);
    }
}
