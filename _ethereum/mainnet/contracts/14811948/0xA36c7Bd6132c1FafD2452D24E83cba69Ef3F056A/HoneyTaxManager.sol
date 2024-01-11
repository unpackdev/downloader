// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./OwnableUpgradeable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IHoney.sol";

contract HoneyTaxManager is OwnableUpgradeable {
    IHoney public HoneyToken;
    IUniswapV2Router02 public router;
    address public teamWallet;

    uint256 public MAX_INT;
    uint256 public taxActionCounter;
    uint256 public taxActionTrigger;
    uint256 public teamActionOffset;
    uint256 public liqActionOffset;

    uint256 public teamAlloc;
    uint256 public liqAlloc;
    uint256 public burnAlloc;

    uint256 public buyTaxTeamPtg;
    uint256 public buyTaxLiqPtg;
    uint256 public buyTaxPtgBase;

    uint256 public sellTaxTeamPtg;
    uint256 public sellTaxLiqPtg;
    uint256 public sellTaxBurnPtg;
    uint256 public sellTaxPtgBase;

    uint256 public spendTaxTeamPtg;
    uint256 public spendTaxLiqPtg;
    uint256 public spendTaxPtgBase;

    bool public dexActive;    

    bool public sellLimitActive;
    uint256 public sellLimitTimePeriod;
    uint256 public sellLimitAmount;
    struct SellLimit {
        uint128 sold;
        uint128 lastSell;
    }
    mapping(address => SellLimit) public userToSellLimit;

    constructor(
        address _honeyToken,
        address _router,
        address _teamWallet
    ) {}

    function initialize(        
        address _honeyToken,
        address _router,
        address _teamWallet
    ) public initializer {
        __Ownable_init();
        
        HoneyToken = IHoney(_honeyToken);
        router = IUniswapV2Router02(_router);
        teamWallet = _teamWallet;

        MAX_INT = ~uint256(0);
        HoneyToken.approve(address(router), MAX_INT);

        taxActionTrigger = 20;
        liqActionOffset = 10;

        sellTaxLiqPtg = 10;
        sellTaxBurnPtg = 20;        

        buyTaxPtgBase = 100;
        sellTaxPtgBase = 100;
        spendTaxPtgBase = 100;

        dexActive = true;
    }


    function swapTokensForEth(uint256 tokenAmount, address recipient) internal {
        address[] memory path = new address[](2);
        path[0] = address(HoneyToken);
        path[1] = router.WETH();

        if (HoneyToken.allowance(address(this), address(router)) < tokenAmount) {
            HoneyToken.approve(address(router), MAX_INT);
        }

        // make the swap
        router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            recipient,
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount, address lpReceiver) internal {
        // approve token transfer to cover all possible scenarios
        if (HoneyToken.allowance(address(this), address(router)) < tokenAmount) {
            HoneyToken.approve(address(router), MAX_INT);
        }

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(HoneyToken),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpReceiver,
            block.timestamp
        );
    }

    function sendToTeam() internal {
        if (teamAlloc > 0) {
            swapTokensForEth(teamAlloc, teamWallet);
        }
    }

    function sendToLiquidity() internal {
        if (liqAlloc > 0) {
            uint256 toEth = liqAlloc / 2;
            uint256 toAKC = liqAlloc - toEth;
            uint256 contractBalance = address(this).balance;
            liqAlloc = 0;

            swapTokensForEth(toEth, address(this));
            uint256 ethAdded = address(this).balance - contractBalance;

            addLiquidity(toAKC, ethAdded, address(this));
        }        
    }

    function shouldDoSendToTeam() internal view returns (bool) {
        return (taxActionCounter + teamActionOffset) % taxActionTrigger == 0 && teamAlloc > 0 && dexActive;
    }

    function shouldDoSendToLiquidity() internal view returns (bool) {
        return (taxActionCounter + liqActionOffset) % taxActionTrigger == 0 && liqAlloc > 0 && dexActive;
    }

    function getBuyTax(address user, uint256 amount) external returns (uint256) {
        require(msg.sender == address(HoneyToken), "Sender not honey");
        
        if (shouldDoSendToTeam())
            sendToTeam();
        if (shouldDoSendToLiquidity())
            sendToLiquidity();

        if (buyTaxTeamPtg + buyTaxLiqPtg > 0)
            taxActionCounter++;

        if (buyTaxTeamPtg != 0)
            teamAlloc += amount * buyTaxTeamPtg / buyTaxPtgBase;
        if (buyTaxLiqPtg != 0)
            liqAlloc += amount * buyTaxLiqPtg / buyTaxPtgBase;

        return amount * (buyTaxLiqPtg + buyTaxTeamPtg) / buyTaxPtgBase;
    }

    function _sellLimit(address user, uint256 amount) internal {
        if (sellLimitActive) {
            SellLimit storage limit = userToSellLimit[user];
            uint256 soldToday;
            uint256 diffSinceLastSell = block.timestamp - limit.lastSell;

            if (diffSinceLastSell >= sellLimitTimePeriod) {
                soldToday = amount;
            } else {
                uint256 nowModule = block.timestamp % sellLimitTimePeriod; // how far we are in the day now
                uint256 lastModulo = limit.lastSell % sellLimitTimePeriod; // how far the last sell was in the day

                // if how far we are in the day now is less than how far we were in the day at last sell then its a new day
                if (nowModule <= lastModulo) {
                    soldToday = amount;
                } else { // if how far we are in the day now is greater than how far we were in the day at last sell then its the same day
                    soldToday = amount + limit.sold;
                }
            }

            require(soldToday <= sellLimitAmount, "Sell exceeds sell limit");

            limit.lastSell = uint128(block.timestamp);
            limit.sold = uint128(soldToday);
        }
    }
    
    function getSellTax(address user, uint256 amount) external returns (uint256) {
        require(msg.sender == address(HoneyToken), "Sender not honey");

        _sellLimit(user, amount);

        if (shouldDoSendToTeam())
            sendToTeam();
        if (shouldDoSendToLiquidity())
            sendToLiquidity();
        
        if (sellTaxTeamPtg + sellTaxLiqPtg + sellTaxBurnPtg > 0)
            taxActionCounter++;

        if (sellTaxTeamPtg != 0)
            teamAlloc += amount * sellTaxTeamPtg / sellTaxPtgBase;
        if (sellTaxLiqPtg != 0)
            liqAlloc += amount * sellTaxLiqPtg / sellTaxPtgBase;
        if (sellTaxBurnPtg != 0)
            burnAlloc += amount * sellTaxBurnPtg / sellTaxPtgBase;

        return amount * (sellTaxLiqPtg + sellTaxTeamPtg + sellTaxBurnPtg) / sellTaxPtgBase;
    }

    function getSpendTax(address user, uint256 amount, bytes memory data) external returns (uint128) {
        require(msg.sender == address(HoneyToken), "Sender not honey");

        if (shouldDoSendToTeam())
            sendToTeam();
        if (shouldDoSendToLiquidity())
            sendToLiquidity();

        if (spendTaxTeamPtg + spendTaxLiqPtg > 0)
            taxActionCounter++;

        if (spendTaxTeamPtg != 0)
            teamAlloc += amount * spendTaxTeamPtg / spendTaxPtgBase;
        if (spendTaxLiqPtg != 0)
            liqAlloc += amount * spendTaxLiqPtg / spendTaxPtgBase;

        return uint128(amount * (spendTaxLiqPtg + spendTaxTeamPtg) / spendTaxPtgBase);
    }

    function withdrawBurnAlloc(address to) external onlyOwner {
        require(burnAlloc > 0, "No burn alloc available");
        HoneyToken.transfer(to, burnAlloc);
        burnAlloc = 0;
    }

    function setHT(address ht) external onlyOwner {
        HoneyToken = IHoney(ht);
    }

    function setRouter(address rtr) external onlyOwner {
        router = IUniswapV2Router02(rtr);
    }

    function setTeamWallet(address tm) external onlyOwner { 
        teamWallet = tm;
    }

    function setTaxActionTrigger(uint256 nv) external onlyOwner {
        taxActionTrigger = nv;
    }

    function setTeamActionOffset(uint256 nv) external onlyOwner {
        teamActionOffset = nv;
    }

    function setLiqActionOffset(uint256 nv) external onlyOwner {
        liqActionOffset = nv;
    }

    function setDexActive(bool _act) external onlyOwner {
        dexActive = _act;
    }

    function setBuyTax(uint256 team, uint256 liq, uint256 base) external onlyOwner {
        buyTaxTeamPtg = team;
        buyTaxLiqPtg = liq;
        buyTaxPtgBase = base;

        require(team + liq <= base, "Buy taxes cannot exeed base");
    }

    function setSellTax(uint256 team, uint256 liq, uint256 brn, uint256 base) external onlyOwner {
        sellTaxTeamPtg = team;
        sellTaxLiqPtg = liq;
        sellTaxBurnPtg = brn;
        sellTaxPtgBase = base;

        require(team + liq + brn <= base, "Sell taxes cannot exeed base");
    }

    function setSpendTax(uint256 team, uint256 liq, uint256 base) external onlyOwner {
        spendTaxTeamPtg = team;
        spendTaxLiqPtg = liq;
        spendTaxPtgBase = base;

        require(team + liq <= base, "Spend taxes cannot exeed base");
    }

    function configureSellLimit(bool _active, uint256 _period, uint256 _amount) external onlyOwner {
        sellLimitActive = _active;
        sellLimitTimePeriod = _period;
        sellLimitAmount = _amount;
    }

    receive() external payable {}
}
