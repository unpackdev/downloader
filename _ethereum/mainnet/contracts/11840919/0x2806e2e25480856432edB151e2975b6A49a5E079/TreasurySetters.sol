// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IUniswapV2Router02.sol";

import "./IBoardroom.sol";
import "./IBasisAsset.sol";
import "./ISimpleERCFund.sol";
import "./TreasuryGetters.sol";

abstract contract TreasurySetters is TreasuryGetters {
    function setAllFunds(
        // boardrooms
        address _arthUniLiquidityBoardroom,
        address _arthMlpLiquidityBoardroom,
        address _mahaLiquidityBoardroom,
        address _arthBoardroom,
        // ecosystem fund
        address _fund,
        address _rainyDayFund
    ) public onlyOwner {
        arthLiquidityUniBoardroom = _arthUniLiquidityBoardroom;
        arthLiquidityMlpBoardroom = _arthMlpLiquidityBoardroom;
        mahaLiquidityBoardroom = _mahaLiquidityBoardroom;
        arthBoardroom = _arthBoardroom;

        ecosystemFund = _fund;
        rainyDayFund = _rainyDayFund;
    }

    function setFund(address newFund, uint256 rate) public onlyOwner {
        require(rate <= 100, 'rate >= 0');
        ecosystemFund = newFund;
        ecosystemFundAllocationRate = rate;
    }

    function setBondDiscount(uint256 rate) public onlyOwner returns (uint256) {
        require(rate <= 100, 'rate >= 0');
        bondDiscount = rate;
    }

    function setConsiderUniswapLiquidity(bool val) public onlyOwner {
        considerUniswapLiquidity = val;
    }

    function setMaxDebtIncreasePerEpoch(uint256 rate) public onlyOwner {
        require(rate <= 100, 'rate >= 0');
        maxDebtIncreasePerEpoch = rate;
    }

    function setMaxSupplyIncreasePerEpoch(uint256 rate) public onlyOwner {
        require(rate <= 100, 'rate >= 0');
        maxSupplyIncreasePerEpoch = rate;
    }

    function setSurprise(bool val) public onlyOwner {
        enableSurprise = val;
    }

    function setSafetyRegion(uint256 rate) public onlyOwner returns (uint256) {
        require(rate <= 100, 'rate >= 0');
        safetyRegion = rate;
    }

    function setBondSeigniorageRate(uint256 rate) public onlyOwner {
        require(rate <= 100, 'rate >= 0');
        bondSeigniorageRate = rate;
    }

    function setArthBoardroom(address newFund, uint256 rate) public onlyOwner {
        require(rate <= 100, 'rate >= 0');
        arthBoardroom = newFund;
        arthBoardroomAllocationRate = rate;
    }

    function setArthLiquidityUniBoardroom(address newFund, uint256 rate)
        public
        onlyOwner
    {
        require(rate <= 100, 'rate >= 0');
        arthLiquidityUniBoardroom = newFund;
        arthLiquidityUniAllocationRate = rate;
    }

    function setArthLiquidityMlpBoardroom(address newFund, uint256 rate)
        public
        onlyOwner
    {
        require(rate <= 100, 'rate >= 0');
        arthLiquidityMlpBoardroom = newFund;
        arthLiquidityMlpAllocationRate = rate;
    }

    function setMahaLiquidityBoardroom(address newFund, uint256 rate)
        public
        onlyOwner
    {
        require(rate <= 100, 'rate >= 0');
        mahaLiquidityBoardroom = newFund;
        mahaLiquidityBoardroomAllocationRate = rate;
    }

    // ORACLE
    function setBondOracle(address newOracle) public onlyOwner {
        bondOracle = newOracle;
    }

    function setSeigniorageOracle(address newOracle) public onlyOwner {
        seigniorageOracle = newOracle;
    }

    function setUniswapRouter(address val) public onlyOwner {
        uniswapRouter = val;
    }

    function setGMUOracle(address newOracle) public onlyOwner {
        gmuOracle = newOracle;
    }

    function setArthMahaOracle(address newOracle) public onlyOwner {
        arthMahaOracle = newOracle;
    }

    function setStabilityFee(uint256 _stabilityFee) public onlyOwner {
        require(_stabilityFee <= 100, 'rate >= 0');
        stabilityFee = _stabilityFee;
    }
}
