// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./FixedPoint.sol";
import "./Safe112.sol";
import "./Operator.sol";
import "./Epoch.sol";
import "./ContractGuard.sol";

abstract contract TreasuryState is ContractGuard, Epoch {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using Safe112 for uint112;

    /* ========== STATE VARIABLES ========== */

    // ========== FLAGS
    bool public migrated = false;
    bool public initialized = false;

    // ========== CORE
    address public dai;
    address public cash;
    address public bond;
    address public share;
    address public uniswapRouter;

    address public arthLiquidityBoardroom;
    address public arthBoardroom;
    address public mahaLiquidityBoardroom;

    address public ecosystemFund;

    // oracles
    address public bondOracle;
    address public seigniorageOracle;
    address public gmuOracle;
    address public arthMahaOracle;

    // cash price tracking vars
    uint256 public cashTargetPrice = 1e18;

    // these govern how much bond tokens are issued
    uint256 public cashToBondConversionLimit = 0;
    uint256 public accumulatedBonds = 0;

    // this governs how much cash tokens are issued
    uint256 public accumulatedSeigniorage = 0;

    // flag whether we should considerUniswapLiquidity or not.
    bool public considerUniswapLiquidity = false;

    // used to limit how much of the supply is converted into bonds
    uint256 public maxDebtIncreasePerEpoch = 5; // in %

    // the discount given to bond purchasers
    uint256 public bondDiscount = 20; // in %

    // the band beyond which bond purchase or protocol expansion happens.
    uint256 public safetyRegion = 5; // in %

    // at the most how much % of the supply should be increased
    uint256 public maxSupplyIncreasePerEpoch = 15; // in %

    // the ecosystem fund recieves seigniorage before anybody else; this
    // value decides how much of the new seigniorage is sent to this fund.
    uint256 public ecosystemFundAllocationRate = 2; // in %

    // this controls how much of the new seigniorage is given to bond token holders
    // when we are in expansion mode. ideally 90% of new seigniorate is
    // given to bond token holders.
    uint256 public bondSeigniorageRate = 90; // in %

    // we decide how much allocation to give to the boardrooms. there
    // are currently two boardrooms; one for ARTH holders and the other for
    // ARTH liqudity providers
    //
    // TODO: make one for maha holders and one for the various community pools
    uint256 public arthLiquidityBoardroomAllocationRate = 70; // In %.
    uint256 public arthBoardroomAllocationRate = 20; // IN %.
    uint256 public mahaLiquidityBoardroomAllocationRate = 10; // IN %.

    // stability fee is a special fee charged by the protocol in MAHA tokens
    // whenever a person is going to redeem his/her bonds. the fee is charged
    // basis how much ARTHB is being redeemed.
    //
    // eg: a 1% fee means that while redeeming 100 ARTHB, 1 ARTH worth of MAHA is
    // deducted to pay for stability fees.
    uint256 public stabilityFee = 1; // IN %;

    modifier checkMigration {
        require(!migrated, 'Treasury: migrated');
        _;
    }

    modifier checkOperator {
        require(
            Operator(cash).operator() == address(this) &&
                Operator(bond).operator() == address(this) &&
                Operator(arthLiquidityBoardroom).operator() == address(this) &&
                Operator(arthBoardroom).operator() == address(this) &&
                Operator(mahaLiquidityBoardroom).operator() == address(this),
            'Treasury: need more permission'
        );
        _;
    }
}
