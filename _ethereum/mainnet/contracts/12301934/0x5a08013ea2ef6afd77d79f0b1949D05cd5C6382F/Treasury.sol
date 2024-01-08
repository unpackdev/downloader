// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

//Contract deployed by LK Tech Club Incubator 2021 dba Lift.Kitchen - 4/24/2021

import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./IOracle.sol";
import "./IBoardroom.sol";
import "./IBasisAsset.sol";

import "./Babylonian.sol";
import "./FixedPoint.sol";

import "./Operator.sol";
import "./Epoch.sol";
import "./ContractGuard.sol";

/**
 * @title Lift.Kitchen Treasury contract
 * @notice Monetary policy logic to adjust supplies of Lift.Kitchen assets
 * @author CryptoGambler & Gruffin
 */

// At expansion DevFund Contract collects 5% (variable below) in lfBTC
// At expansion IdeaFund Contract collects 75% (variable below) in lfBTC
// At expansion Boardroom Contract collects 20% (variable below) in CTRL
contract Treasury is Operator, ContractGuard, Epoch {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    // ========== FLAGS
    bool public migrated = false;

    // ========== CORE
    address public devfund;
    address public ideafund;
    address public peg; //lfbtc
    address public share; //lift
    address public control; //ctrl
    address public boardroom;

    address public theOracle; 

    // ========== PARAMS
    uint256 public pegPriceCeiling = 105; // lfbtc / wbtc
    uint256 public expansionPercentage = 5;
    
    uint256 public devfundAllocationRate = 5; // DEV FUND
    uint256 public ideafundAllocationRate = 75; // %STABLIZATION

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _lfbtc,
        address _lift,
        address _ctrl,
        address _theOracle,
        address _boardroom,
        address _ideafund,
        address _devfund,
        uint256 _startTime
    ) Epoch(24 hours, _startTime, 0) {
        peg = _lfbtc;
        share = _lift;
        control = _ctrl;
        theOracle = _theOracle; //PEG
        boardroom = _boardroom;
        ideafund = _ideafund;  
        devfund = _devfund; 
    }

    /* =================== Modifier =================== */

    modifier checkMigration {
        require(!migrated, 'Treasury: migrated');

        _;
    }

    modifier checkOperator {
        require(
            IBasisAsset(peg).operator() == address(this) &&
            IBasisAsset(control).operator() == address(this) &&
            Operator(boardroom).operator() == address(this),
            'Treasury: need more permission'
        );
        _;
    }

     function setDevFund(address newDevFund) public onlyOperator {
        devfund = newDevFund;
        emit DevFundChanged(msg.sender, newDevFund);
    }

    //should pass in a whole number representing the % so 5 = 5%
    function setDevFundAllocationRate(uint256 rate) public onlyOperator {
        devfundAllocationRate = rate;
        emit DevFundRateChanged(msg.sender, rate);
    }
   
    function setIdeaFund(address newFund) public onlyOperator {
        ideafund = newFund;
        emit IdeaFundChanged(msg.sender, newFund);
    }

    function setBoardroom(address newBoardroom) public onlyOperator {
        boardroom = newBoardroom;
        emit BoardroomChanged(msg.sender, newBoardroom);
    }

    //should pass in a whole number representing the % so 5 = 5%
    function setIdeaFundAllocationRate(uint256 rate) public onlyOperator {
        ideafundAllocationRate = rate;
        emit IdeaFundRateChanged(msg.sender, rate);
    }

    function getPegPriceCeiling() public view returns (uint256 mulPegPrice)
    {
        return IOracle(theOracle).wbtcPriceOne().mul(pegPriceCeiling).div(100);
    }

    function mintControlForIdeaFund(address sendingTo, uint256 amount) external {
        require(msg.sender == ideafund, 'Treasury: You cant call this!');
        IBasisAsset(control).mint(sendingTo, amount);
    } 

    function burnControlForIdeaFund(address burningFrom, uint256 amount) external {
        require(msg.sender == ideafund, 'Treasury: You cant call this!');
        IBasisAsset(control).burnFrom(burningFrom, amount);
    } 

    function allocateSeigniorage()
        external
        onlyOperator
        onlyOneBlock
        checkMigration
        checkStartTime
        checkEpoch
        checkOperator
    {
        uint256 pegPrice = IOracle(theOracle).priceOf(peg);

        if (pegPrice <= getPegPriceCeiling()) {
            return; // just advance epoch instead revert
        }

        // circulating supply
        uint256 pegSupply = IERC20(peg).totalSupply();
        
        //should return Current Peg Percentage (1.05 - 1)
        uint256 percentage = pegPrice.mul(100).div(IOracle(theOracle).wbtcPriceOne()).sub(100);

        if (percentage > expansionPercentage) {
            percentage = uint256(10e18).div(100);
        } else {
            percentage = percentage.mul(1e18).div(100);
        }
    
        //total seigniorage should be no more than 10% of current supply based on peg / wbtc value
        uint256 seigniorage = pegSupply.mul(percentage).div(1e18);

        uint256 pegMint = seigniorage.mul(ideafundAllocationRate.add(devfundAllocationRate)).div(100);
        //mint in peg token the seigniorage multiplied by the X% for devfund and x% for ideafund
        IBasisAsset(peg).mint(address(this), pegMint);

        //Stablization, Idea Funding, Expenses
        if (seigniorage > 0) {
            IERC20(peg).safeTransfer(devfund, seigniorage.mul(devfundAllocationRate).div(100));
            IERC20(peg).safeTransfer(ideafund, seigniorage.mul(ideafundAllocationRate).div(100));
        }

        emit DevFundFunded(block.timestamp, seigniorage.mul(devfundAllocationRate).div(100));
        emit IdeaFundFunded(block.timestamp, seigniorage.mul(ideafundAllocationRate).div(100));

        seigniorage = seigniorage.sub(pegMint);

        // seigniorage - mintedLFBTC * currentvalue(peg)  / control value = number to Mint
        uint256 mintControl = seigniorage.mul(pegPrice).div(IOracle(theOracle).priceOf(control));
        IBasisAsset(control).mint(address(this), mintControl);

        // Boardroom
        if (mintControl > 0) {
            IERC20(control).safeApprove(boardroom, mintControl);
            IBoardroom(boardroom).allocateSeigniorage(mintControl);            
        }
        emit BoardroomFunded(block.timestamp, mintControl);
    }

    /* ========== GOVERNANCE ========== */

    function updateOracle(address newOracle) public onlyOperator {
        theOracle = newOracle;
    }

    function setExpansionPercentage(uint256 newPercentage) public onlyOperator {
        expansionPercentage = newPercentage;
    }

    function migrate(address target) public onlyOperator checkOperator {
        require(!migrated, 'Treasury: migrated');

        // LFBTC
        Operator(peg).transferOperator(target);
        Operator(peg).transferOwnership(target);
        IERC20(peg).transfer(target, IERC20(peg).balanceOf(address(this)));

        // LIFT
        Operator(share).transferOperator(target);
        Operator(share).transferOwnership(target);
        IERC20(share).transfer(target, IERC20(share).balanceOf(address(this)));

        // CTRL
        Operator(control).transferOperator(target);
        Operator(control).transferOwnership(target);
        IERC20(control).transfer(target, IERC20(control).balanceOf(address(this)));

        migrated = true;
        emit Migration(target);
    }

    // If anyone sends tokens directly to the contract we can refund them.
    function cleanUpDust(uint256 amount, address tokenAddress, address sendTo) onlyOperator public  {     
        IERC20(tokenAddress).safeTransfer(sendTo, amount);
    }

    // GOV
    event Migration(address indexed target);
    event DevFundChanged(address indexed operator, address newDevFund);
    event DevFundRateChanged(address indexed operator, uint256 newRate);
    event IdeaFundChanged(address indexed operator, address newFund);
    event IdeaFundRateChanged(address indexed operator, uint256 newRate);
    event BoardroomChanged(address indexed operator, address newBoardroom);

    // CORE
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event DevFundFunded(uint256 timestamp, uint256 seigniorage);
    event BoardroomFunded(uint256 timestamp, uint256 seigniorage);
    event IdeaFundFunded(uint256 timestamp, uint256 seigniorage);
}
