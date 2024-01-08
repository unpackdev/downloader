pragma solidity ^0.5.16;

import "./CToken.sol";
import "./PriceOracle.sol";

contract ComptrollerStorage {
    address public admin;
    address public pendingAdmin;
    address public comptrollerImplementation;
    address public pendingComptrollerImplementation;

    PriceOracle public oracle;
    uint public closeFactorMantissa;
    uint public liquidationIncentiveMantissa;
    uint public maxAssets;
    mapping(address => CToken[]) public accountAssets;

    struct Market {
        bool isListed;
        uint collateralFactorMantissa;
        mapping(address => bool) accountMembership;
    }

    mapping(address => Market) public markets;

    address public pauseGuardian;
    bool public _mintGuardianPaused;
    bool public _borrowGuardianPaused;
    bool public transferGuardianPaused;
    bool public seizeGuardianPaused;
    bool public borrowSeizeGuardianPaused;
    mapping(address => bool) public mintGuardianPaused;
    mapping(address => bool) public borrowGuardianPaused;

    CToken[] public allMarkets;
    address public borrowCapGuardian;
    mapping(address => uint) public borrowCaps;
}