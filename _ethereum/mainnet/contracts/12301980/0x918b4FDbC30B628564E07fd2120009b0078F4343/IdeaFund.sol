// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

//Contract deployed by LK Tech Club Incubator 2021 dba Lift.Kitchen - 4/24/2021

import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./IOracle.sol";
import "./ITreasury.sol";
import "./IHedgeFund.sol";

import "./UniswapV2Library.sol";
import "./Babylonian.sol";
import "./FixedPoint.sol";

import "./Operator.sol";
import "./Epoch.sol";
import "./ContractGuard.sol";

contract IdeaFund is Operator, ContractGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
        
    address public wbtc;
    address public peg; // LFBTC
    address public share; // LIFT
    address public control; // CTRL
    address public hedge; // HAIF 
    address public hedgefund; // HedgeFund.sol
    address public treasury;
    address public theOracle;

    uint256 private _haifSupply = 0;
    uint256 public variableReduction = 2;

    // modifier variables
    bool _isctrlRedeemable = false;
    
    IUniswapV2Router02 public router;
    
    constructor(
        address _wbtc,  //wBTC
        address _peg, //lfBTC
        address _share, // LIFT
        address _control, //CTRL
        address _hedge, // HAIF
        address _hedgefund, // HedgeFund
        address _router
    ) {
        wbtc = _wbtc;
        peg = _peg;
        share = _share;
        control = _control;
        hedge = _hedge;
        hedgefund = _hedgefund;

        router = IUniswapV2Router02(_router);
    }

    modifier ctrlRedeemable {
        require(_isctrlRedeemable, 'Idea Fund: cannot currently redeem CTRL');
        _;
    }

    //(IdeaFund Total Value) divide by (2) divide by (2) / control Supply = CTRL Value
    // the first divide by 2 is for the lfbtc, lift and control tokens representing value in the hedgefund (HAIF Value)
    // the second divide by 2 leaves funds in the idea fund to also stablize and invest should all owners of control decide to sell
    function getControlPrice() public view returns(uint256) {
        //calculate value   
        return (_haifSupply.mul(IOracle(theOracle).priceOf(hedge)).div(2) + IERC20(wbtc).balanceOf(address(this)).mul(1e10).mul(IOracle(theOracle).wbtcPriceOne())).div(variableReduction).div(IERC20(control).totalSupply());
    }

    /* ==== CTRL BUY and SELL ====== */

    //You can trade lfBTC and LIFT into the IdeaFund for CTRL Tokens at current values.
    //Allow users to sell the IdeaFund LIFT and lfBTC for CTRL this exchange is done at current prices
    //we should consider a TAX on this transaction - if not today,  maybe a variable we set in the future.  LPs charge .3% ++
    function buyCTRL(address token, uint256 amount)
        external
        onlyOneBlock
        ctrlRedeemable
    {
        require(amount > 0, 'Idea Fund: cannot sell you zero ctrl');
        require(IERC20(token).allowance(msg.sender, address(this)) >= amount, 'Idea Fund: You have not approved the transfer of your token to Idea Fund');
        require(IOracle(theOracle).priceOf(wbtc).mul(105) > IOracle(theOracle).priceOf(peg).mul(100), 'Idea Fund: Peg is too high to exchange right now');
        
        uint256 valueofToken = 0;
        if(token == peg){
            valueofToken = amount.mul(IOracle(theOracle).priceOf(peg));
        } else if (token == share) {
            valueofToken = amount.mul(IOracle(theOracle).priceOf(share));
        } else { 
            require(false, 'Idea Fund: We only buy the protocol peg token and share token');
        }

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        //Have to request Treasury sends mint to the lfbtc/lift seller
        uint256 ctrlToMint = valueofToken.div(IOracle(theOracle).priceOf(control));
        ITreasury(treasury).mintControlForIdeaFund(msg.sender, ctrlToMint);

        emit SoldCTRL(msg.sender, ctrlToMint);
    }

    function redeemCTRL(uint256 amount) 
        external
        onlyOneBlock
        ctrlRedeemable
    {
        require(amount > 0, 'Idea Fund: cannot redeem CTRL with zero amount');

        uint256 toSend = amount.mul(getControlPrice()).div(IOracle(theOracle).wbtcPriceOne()).div(1e10);
                
        require(
            IERC20(wbtc).balanceOf(address(this)) >= toSend,
            'Idea Fund: Treasury does not currently hold enough wBTC to purchase'
        );

        require(amount <= IERC20(control).allowance(msg.sender, address(treasury)), 
            'Treasury: is not approved to burn your CTRL');

        ITreasury(treasury).burnControlForIdeaFund(msg.sender, amount);
        
        IERC20(wbtc).safeTransfer(msg.sender, toSend);
        
        emit RedeemedCTRL(msg.sender, toSend);
    }
   
    function investInHedgeFund(address token, uint256 amount) public onlyOperator {
        require(IERC20(token).balanceOf(address(this)) >= amount,
            'Idea Fund: Not enough token balance to transfer');

        IERC20(token).approve(hedgefund, amount);
        _haifSupply += (uint256(IHedgeFund(hedgefund).depositToHedgeFund(token, amount))); 
    }

    //regardless of what you submit to the hedgefund, this will always return wbtc
    function withdrawFromHedgeFund(uint256 amount) public onlyOperator {
        require(IERC20(hedge).balanceOf(address(this)) > amount,
        'Idea Fund: Does not have that much hedge token to transfer'
        );

        IERC20(hedge).approve(hedgefund, amount);
        _haifSupply.sub(IHedgeFund(hedgefund).withdrawFromHedgeFund(amount));
    }
    
    // tokenA (wbtc, lfbtc or lift) is what we are buying, with numTokens of tokenB (wbtc, lfbtc, lift)
    function ideaFundBuyingTokenAwithTokenB(address tokenA, address tokenB, uint256 numTokens) public onlyOperator
    {
        require(numTokens > 0, 'Idea Fund: cannot purchase tokenA with zero amount');
        require(IERC20(tokenB).balanceOf(address(this)) >= numTokens, 'Idea Fund: we dont have that many tokens to trade fool!');

        address[] memory pathTo;
        IERC20(tokenB).approve(address(router), numTokens);

        if (tokenA == share){
            if (tokenB == wbtc) {
                pathTo = new address[](3);
                pathTo[0] = wbtc;
                pathTo[1] = peg;
                pathTo[2] = share;
            } else {
                pathTo = new address[](2);
                pathTo[0] = peg;
                pathTo[1] = share;
            }
        } else if (tokenA == peg) {
            if (tokenB == wbtc){
                pathTo = new address[](2);
                pathTo[0] = wbtc;
                pathTo[1] = peg;
            } else {
                pathTo = new address[](2);
                pathTo[0] = share;
                pathTo[1] = peg;
            }
        } else if (tokenA == wbtc) {
            if (tokenB == peg) {
                pathTo = new address[](2);
                pathTo[0] = peg;
                pathTo[1] = wbtc;
            } else if (tokenB == share) {
                pathTo = new address[](3);
                pathTo[0] = share;
                pathTo[1] = peg;
                pathTo[2] = wbtc;
            }
        } else {
            require(false, 'Idea Fund: Not sure what you are selling but we dont sell that here');
        }
      
        router.swapExactTokensForTokens(
            numTokens,
            0,
            pathTo,
            address(this),
            block.timestamp + 15
        );
    
        emit IdeaFundBoughtlfBTC(msg.sender, numTokens);
    }

    // In case IdeaFund ends up holding any tokens other than the above
    function cleanUpDust(uint256 amount, address tokenAddress, address sendTo) onlyOperator public  {     
        IERC20(tokenAddress).safeTransfer(sendTo, amount);
    }

    /* ========== Operator ========== */
    function setRedemptions(address _treasury, bool isredeemable) external onlyOperator {
        treasury = _treasury;
        _isctrlRedeemable = isredeemable;
    }

    function updateOracle(address newOracle) public onlyOperator {
        theOracle = newOracle;
    }

    function updateAddresses(address newTreasury, address newHedgeFund) public onlyOperator {
        treasury = newTreasury;
        hedgefund = newHedgeFund;
    }

    function setvariableReduction(uint256 newReduction) public onlyOperator {
        variableReduction = newReduction;
    }

    event Migration(address indexed target);
    event IdeaFundBoughtlfBTC(address indexed from, uint256 amount);
    event IdeaFundSoldlfBTC(address indexed from, uint256 amount);
    event RedeemedCTRL(address indexed from, uint256 amount);
    event SoldCTRL(address indexed from, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
