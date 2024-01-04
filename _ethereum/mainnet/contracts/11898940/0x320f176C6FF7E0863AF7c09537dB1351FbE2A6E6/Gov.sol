//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IXVIX.sol";

contract Gov {
    address public xvix;
    uint256 public govHandoverTime;

    address public admin;

    constructor(address _xvix, uint256 _govHandoverTime) public {
        xvix = _xvix;
        govHandoverTime = _govHandoverTime;
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Gov: forbidden");
        _;
    }

    function setAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }

    function extendHandoverTime(uint256 _govHandoverTime) public onlyAdmin {
        require(_govHandoverTime > govHandoverTime, "Gov: invalid handover time");
        govHandoverTime = _govHandoverTime;
    }

    function setGov(address _gov) public onlyAdmin {
        require(block.timestamp > govHandoverTime, "Gov: handover time has not passed");
        IXVIX(xvix).setGov(_gov);
    }
}
