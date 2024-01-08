// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IERC20Metadata.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

import "./AccessControlUpgradeable.sol";

import "./IAgToken.sol";
import "./ICollateralSettler.sol";
import "./ICore.sol";
import "./IFeeManager.sol";
import "./IOracle.sol";
import "./IPerpetualManager.sol";
import "./IPoolManager.sol";
import "./ISanToken.sol";
import "./IStableMaster.sol";

import "./FunctionUtils.sol";
import "./PausableMapUpgradeable.sol";

/// @title StableMasterEvents
/// @author Angle Core Team
/// @notice `StableMaster` is the contract handling all the collateral types accepted for a given stablecoin
/// It does all the accounting and is the point of entry in the protocol for stable holders and seekers as well as SLPs
/// @dev This file contains all the events of the `StableMaster` contract
contract StableMasterEvents {
    event SanRateUpdated(address indexed _token, uint256 _newSanRate);

    event StocksUsersUpdated(address indexed _poolManager, uint256 _stocksUsers);

    event MintedStablecoins(address indexed _poolManager, uint256 amount, uint256 amountForUserInStable);

    event BurntStablecoins(address indexed _poolManager, uint256 amount, uint256 redeemInC);

    // ============================= Governors =====================================

    event CollateralDeployed(
        address indexed _poolManager,
        address indexed _perpetualManager,
        address indexed _sanToken,
        address _oracle
    );

    event CollateralRevoked(address indexed _poolManager);

    // ========================= Parameters update =================================

    event OracleUpdated(address indexed _poolManager, address indexed _oracle);

    event FeeManagerUpdated(address indexed _poolManager, address indexed newFeeManager);

    event CapOnStableAndMaxInterestsUpdated(
        address indexed _poolManager,
        uint256 _capOnStableMinted,
        uint256 _maxInterestsDistributed
    );

    event SLPsIncentivesUpdated(address indexed _poolManager, uint64 _feesForSLPs, uint64 _interestsForSLPs);

    event FeeArrayUpdated(address indexed _poolManager, uint64[] _xFee, uint64[] _yFee, uint8 _type);
}
