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
    address public pegbtc; //lfbtc
    address public pegeth;
    address public share; //lift
    address public control; //ctrl
    address public boardroom;

    address public theOracle; 

    // ========== PARAMS
    uint256 public pegPriceCeiling = 103; // lfbtc / wbtc
    uint256 public expansionPercentage = 5;
    
    uint256 public devfundAllocationRate = 5; // DEV FUND
    uint256 public ideafundAllocationRate = 75; // %STABLIZATION

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _lfbtc,
        address _lfeth,
        address _lift,
        address _ctrl,
        address _theOracle,
        address _boardroom,
        address _ideafund,
        address _devfund,
        uint256 _startTime
    ) Epoch(24 hours, _startTime, 0) {
        pegbtc = _lfbtc;
        pegeth = _lfeth;
        share = _lift;
        control = _ctrl;
        theOracle = _theOracle; //PEG
        boardroom = _boardroom;
        ideafund = _ideafund;  
        devfund = _devfund; 
    }

    /* =================== Modifier =================== */
     function setDevFund(address newDevFund) public onlyOperator {
        devfund = newDevFund;
    }

    function setPegPrice(uint256 newPeg) public onlyOperator {
        pegPriceCeiling = newPeg;
    }

    //should pass in a whole number representing the % so 5 = 5%
    function setDevFundAllocationRate(uint256 rate) public onlyOperator {
        devfundAllocationRate = rate;
    }
   
    function setIdeaFund(address newFund) public onlyOperator {
        ideafund = newFund;
    }

    function setBoardroom(address newBoardroom) public onlyOperator {
        boardroom = newBoardroom;
    }

    //should pass in a whole number representing the % so 5 = 5%
    function setIdeaFundAllocationRate(uint256 rate) public onlyOperator {
        ideafundAllocationRate = rate;
    }

    function getPegBTCPriceCeiling() public view returns (uint256 mulPegPrice)
    {
        return IOracle(theOracle).wbtcPriceOne().mul(pegPriceCeiling).div(100);
    }
    
    function getPegETHPriceCeiling() public view returns (uint256 mulPegPrice)
    {
        return IOracle(theOracle).wethPriceOne().mul(pegPriceCeiling).div(100);
    }

    function mintControlForIdeaFund(address sendingTo, uint256 amount) external {
        require(msg.sender == ideafund, 'Treasury: You cant call this!');
        IBasisAsset(control).mint(sendingTo, amount);
    } 

    function burnControlForIdeaFund(address burningFrom, uint256 amount) external {
        require(msg.sender == ideafund, 'Treasury: You cant call this!');
        IBasisAsset(control).burnFrom(burningFrom, amount);
    } 

    function allocateSeigniorageBTC()
        external
        onlyOperator
        onlyOneBlock
        checkStartTime
        checkEpoch
    {
        uint256 pegPrice = IOracle(theOracle).priceOf(pegbtc);

        if (pegPrice <= getPegBTCPriceCeiling()) {
            return; // just advance epoch instead revert
        }

        // circulating supply
        uint256 pegSupply = IERC20(pegbtc).totalSupply();
        
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
        IBasisAsset(pegbtc).mint(address(this), pegMint);

        //Stablization, Idea Funding, Expenses
        if (seigniorage > 0) {
            IERC20(pegbtc).safeTransfer(devfund, seigniorage.mul(devfundAllocationRate).div(100));
            IERC20(pegbtc).safeTransfer(ideafund, seigniorage.mul(ideafundAllocationRate).div(100));
        }

        seigniorage = seigniorage.sub(pegMint);

        // seigniorage - mintedLFBTC * currentvalue(peg)  / control value = number to Mint
        uint256 mintControl = seigniorage.mul(pegPrice).div(IOracle(theOracle).priceOf(control));
        IBasisAsset(control).mint(address(this), mintControl);

        // Boardroom
        if (mintControl > 0) {
            if (IERC20(control).allowance(address(this), boardroom) == 0) {
                IERC20(control).safeApprove(boardroom, mintControl);
            } else if (IERC20(control).allowance(address(this), boardroom) < mintControl) {
                IERC20(control).safeIncreaseAllowance(boardroom, mintControl);
            }
            IBoardroom(boardroom).allocateSeigniorage(mintControl);            
        }
    }

    function allocateSeigniorageETH()
        external
        onlyOperator
        onlyOneBlock
        checkStartTime
        checkEpoch
    {
        uint256 pegPrice = IOracle(theOracle).priceOf(pegeth);

        if (pegPrice <= getPegETHPriceCeiling()) {
            return; // just advance epoch instead revert
        }

        // circulating supply
        uint256 pegSupply = IERC20(pegeth).totalSupply();
        
        //should return Current Peg Percentage (1.05 - 1)
        uint256 percentage = pegPrice.mul(100).div(IOracle(theOracle).wethPriceOne()).sub(100);

        if (percentage > expansionPercentage) {
            percentage = uint256(10e18).div(100);
        } else {
            percentage = percentage.mul(1e18).div(100);
        }
    
        //total seigniorage should be no more than 10% of current supply based on peg / wbtc value
        uint256 seigniorage = pegSupply.mul(percentage).div(1e18);

        uint256 pegMint = seigniorage.mul(ideafundAllocationRate.add(devfundAllocationRate)).div(100);
        //mint in peg token the seigniorage multiplied by the X% for devfund and x% for ideafund
        IBasisAsset(pegeth).mint(address(this), pegMint);

        //Stablization, Idea Funding, Expenses
        if (seigniorage > 0) {
            IERC20(pegeth).safeTransfer(devfund, seigniorage.mul(devfundAllocationRate).div(100));
            IERC20(pegeth).safeTransfer(ideafund, seigniorage.mul(ideafundAllocationRate).div(100));
        }

        seigniorage = seigniorage.sub(pegMint);

        // seigniorage - mintedLFBTC * currentvalue(peg)  / control value = number to Mint
        uint256 mintControl = seigniorage.mul(pegPrice).div(IOracle(theOracle).priceOf(control));
        IBasisAsset(control).mint(address(this), mintControl);

        // Boardroom
        if (mintControl > 0) {
            if (IERC20(control).allowance(address(this), boardroom) == 0) {
                IERC20(control).safeApprove(boardroom, mintControl);
            } else if (IERC20(control).allowance(address(this), boardroom) < mintControl) {
                IERC20(control).safeIncreaseAllowance(boardroom, mintControl);
            }
            IBoardroom(boardroom).allocateSeigniorage(mintControl);            
        }
    }

    /* ========== GOVERNANCE ========== */

    function updateOracle(address newOracle) public onlyOperator {
        theOracle = newOracle;
    }

    function setExpansionPercentage(uint256 newPercentage) public onlyOperator {
        expansionPercentage = newPercentage;
    }

    function migrate(address target) public onlyOperator {
        require(!migrated, 'Treasury: migrated');

        // LFBTC
        Operator(pegbtc).transferOperator(target);
        Operator(pegbtc).transferOwnership(target);
        IERC20(pegbtc).transfer(target, IERC20(pegbtc).balanceOf(address(this)));

        // LFETH
        Operator(pegeth).transferOperator(target);
        Operator(pegeth).transferOwnership(target);
        IERC20(pegeth).transfer(target, IERC20(pegeth).balanceOf(address(this)));

        // LIFT
        Operator(share).transferOperator(target);
        Operator(share).transferOwnership(target);
        IERC20(share).transfer(target, IERC20(share).balanceOf(address(this)));

        // CTRL
        Operator(control).transferOperator(target);
        Operator(control).transferOwnership(target);
        IERC20(control).transfer(target, IERC20(control).balanceOf(address(this)));

        migrated = true;
    }

    // If anyone sends tokens directly to the contract we can refund them.
    function cleanUpDust(uint256 amount, address tokenAddress, address sendTo) onlyOperator public  {     
        IERC20(tokenAddress).safeTransfer(sendTo, amount);
    }
}
