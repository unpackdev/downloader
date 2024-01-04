// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IUniswapV2Router02.sol";

import "./IBoardroom.sol";
import "./IBasisAsset.sol";
import "./ISimpleERCFund.sol";
import "./TreasuryGetters.sol";

abstract contract TreasurySetters is TreasuryGetters {
    function setStabilityFee(uint256 _stabilityFee) public onlyOwner {
        require(_stabilityFee <= 100, 'rate >= 0');

        stabilityFee = _stabilityFee;

        emit StabilityFeeChanged(stabilityFee, _stabilityFee);
    }

    function setFund(address newFund, uint256 rate) public onlyOwner {
        require(rate <= 100, 'rate >= 0');

        ecosystemFund = newFund;
        ecosystemFundAllocationRate = rate;

        emit EcosystemFundChanged(newFund, rate);
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

    function setSafetyRegion(uint256 rate) public onlyOwner returns (uint256) {
        require(rate <= 100, 'rate >= 0');

        safetyRegion = rate;
    }

    function setBondSeigniorageRate(uint256 rate) public onlyOwner {
        require(rate <= 100, 'rate >= 0');

        bondSeigniorageRate = rate;

        emit BondSeigniorageRateChanged(rate);
    }

    function setArthBoardroom(address newFund, uint256 rate) public onlyOwner {
        require(rate <= 100, 'rate >= 0');

        arthBoardroom = newFund;
        arthBoardroomAllocationRate = rate;
        emit BoardroomChanged(newFund, rate);
    }

    function setArthLiquidityBoardroom(address newFund, uint256 rate)
        public
        onlyOwner
    {
        require(rate <= 100, 'rate >= 0');

        arthLiquidityBoardroom = newFund;
        arthLiquidityBoardroomAllocationRate = rate;

        emit BoardroomChanged(newFund, rate);
    }

    function setMahaLiquidityBoardroom(address newFund, uint256 rate)
        public
        onlyOwner
    {
        require(rate <= 100, 'rate >= 0');

        mahaLiquidityBoardroom = newFund;
        mahaLiquidityBoardroomAllocationRate = rate;

        emit BoardroomChanged(newFund, rate);
    }

    // ORACLE
    function setBondOracle(address newOracle) public onlyOwner {
        address oldOracle = bondOracle;
        bondOracle = newOracle;
        emit OracleChanged(msg.sender, oldOracle, newOracle);
    }

    function setSeigniorageOracle(address newOracle) public onlyOwner {
        address oldOracle = seigniorageOracle;
        seigniorageOracle = newOracle;
        emit OracleChanged(msg.sender, oldOracle, newOracle);
    }

    function setGMUOracle(address newOracle) public onlyOwner {
        address oldOracle = gmuOracle;
        gmuOracle = newOracle;
        emit OracleChanged(msg.sender, oldOracle, newOracle);
    }

    function setArthMahaOracle(address newOracle) public onlyOwner {
        address oldOracle = arthMahaOracle;
        arthMahaOracle = newOracle;
        emit OracleChanged(msg.sender, oldOracle, newOracle);
    }

    event OracleChanged(
        address indexed operator,
        address oldOracle,
        address newOracle
    );
    event EcosystemFundChanged(address newFund, uint256 newRate);
    event BoardroomChanged(address newFund, uint256 newRate);
    event StabilityFeeChanged(uint256 old, uint256 newRate);
    event BondSeigniorageRateChanged(uint256 newRate);
}
