// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IBulletLoans} from "IBulletLoans.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";
import {IManagedPortfolio} from "IManagedPortfolio.sol";
import {IERC20WithDecimals} from "IERC20WithDecimals.sol";
import {ILenderVerifier} from "ILenderVerifier.sol";
import {InitializableManageable} from "InitializableManageable.sol";
import {ProxyWrapper} from "ProxyWrapper.sol";

contract ManagedPortfolioFactory is InitializableManageable {
    IBulletLoans public bulletLoans;
    IProtocolConfig public protocolConfig;
    IManagedPortfolio public portfolioImplementation;
    IManagedPortfolio[] public portfolios;

    event PortfolioCreated(IManagedPortfolio newPortfolio, address manager);

    constructor() InitializableManageable(msg.sender) {}

    function initialize(
        IBulletLoans _bulletLoans,
        IProtocolConfig _protocolConfig,
        IManagedPortfolio _portfolioImplementation
    ) external {
        InitializableManageable.initialize(msg.sender);
        bulletLoans = _bulletLoans;
        protocolConfig = _protocolConfig;
        portfolioImplementation = _portfolioImplementation;
    }

    function createPortfolio(
        string memory name,
        string memory symbol,
        IERC20WithDecimals _underlyingToken,
        ILenderVerifier _lenderVerifier,
        uint256 _duration,
        uint256 _maxSize,
        uint256 _managerFee
    ) public {
        bytes memory initCalldata = abi.encodeWithSelector(
            IManagedPortfolio.initialize.selector,
            name,
            symbol,
            msg.sender,
            _underlyingToken,
            bulletLoans,
            protocolConfig,
            _lenderVerifier,
            _duration,
            _maxSize,
            _managerFee
        );
        IManagedPortfolio newPortfolio = IManagedPortfolio(address(new ProxyWrapper(address(portfolioImplementation), initCalldata)));
        portfolios.push(newPortfolio);
        emit PortfolioCreated(newPortfolio, msg.sender);
    }

    function getPortfolios() public view returns (IManagedPortfolio[] memory) {
        return portfolios;
    }
}
