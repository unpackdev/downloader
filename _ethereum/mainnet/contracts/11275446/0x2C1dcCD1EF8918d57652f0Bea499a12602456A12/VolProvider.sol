
pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./IStatisticProvider.sol";
import "./IKeep3rOracle.sol";

contract VolProvider is IStatisticProvider, Ownable {
    address immutable tokenA;
    address immutable tokenB;
    IKeep3rOracle public oracle;

    constructor(address tokenA_, address tokenB_, address oracle_) Ownable() public {
        tokenA = tokenA_;
        tokenB = tokenB_;
        oracle = IKeep3rOracle(oracle_);
    }

    function current() public view override returns (uint) {
        return oracle.rVolHourly(
            tokenA,
            tokenB,
            4
        );
    }

    function updateOracle(address newOracle) onlyOwner public {
        oracle = IKeep3rOracle(newOracle);
    }

}