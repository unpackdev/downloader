pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Oracle.sol";
import "./IOracle.sol";

contract Lock {
    IERC20 public underlying;
    IOracle public oracle;

    mapping(address => uint256) public balances;

    constructor(IERC20 _underlying, IOracle _oracle) {
        underlying = _underlying;
        oracle = _oracle;
    }

    function lock(uint256 amt) public {
        require(!oracle.isExpired(), "Merge has already happened");

        underlying.transferFrom(msg.sender, address(this), amt);
        balances[msg.sender] += amt;
    }

    function unlock(uint256 amt) public {
        require(oracle.isExpired(), "Merge has not happened yet");

        balances[msg.sender] -= amt;
        underlying.transfer(msg.sender, amt);
    }
}
