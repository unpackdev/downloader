// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IBooster.sol";
import "./IApr.sol";
import "./ICvxMining.sol";
import "./IRewardStaking.sol";
import "./IAddressProvider.sol";
import "./IExchangeRegistry.sol";
import "./ICurveMetaRegistry.sol";
import "./ICurve.sol";

///
/// @title Curve Convex Strategy Protocol
/// @author Fija
/// @notice Hold protocol references and constants used in the strategy
/// @dev Inherited by both peripery and main strategy contract
///
contract CurveConvexStrategyProtocol {
    uint256 internal constant CURVE_EXCHANGE_ID = 2;

    uint256 internal constant PRECISION_18 = 10 ** 18;

    uint256 internal constant PRECISION_30 = 10 ** 30;

    uint256 internal constant BASIS_POINTS_DIVISOR = 10000;

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address internal constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    address internal constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

    ///
    /// @dev Reference to Curve meta registry. Used for abstracting
    /// operations on pools with different interfaces
    ///
    ICurveMetaRegistry internal constant Curve_ICurveMetaRegistry =
        ICurveMetaRegistry(0xF98B45FA17DE75FB1aD0e7aFD971b0ca00e379fC);

    ///
    /// @dev Reference to Convex booster contract. Used when staking,
    /// unstaking Curve LP tokens from Convex pools
    ///
    IBooster internal constant Convex_IBooster =
        IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    ///
    /// @dev Reference to Convex library. Used to calculate CVX rewards
    /// based on CRV rewards
    ///
    ICvxMining internal constant Convex_ICvxMining =
        ICvxMining(0x3c75BFe6FbfDa3A94E7E7E8c2216AFc684dE5343);

    ///
    /// @dev Reference to Curve address provider which is used to get
    /// various Curve contracts consistently, specifically meta exchange
    ///
    IAddressProvider internal constant Curve_IAddressProvider =
        IAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383);

    ///
    /// @dev Reference to Curve APR contract used to calculate CRV and CVX
    /// APR rates
    ///
    IApr internal constant Convex_IApr =
        IApr(0x5Fba69a794F395184b5760DAf1134028608e5Cd1);
}
