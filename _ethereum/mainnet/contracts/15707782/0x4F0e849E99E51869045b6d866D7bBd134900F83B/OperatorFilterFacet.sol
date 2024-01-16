// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Base.sol";
import "./IOperatorFilter.sol";

contract OperatorFilterFacet is Base {
    function setOperatorFilter(address filter) public {
        s.operatorFilter = filter;
    }

    function operatorFilter() public view returns (IOperatorFilter) {
        return IOperatorFilter(s.operatorFilter);
    }
}
