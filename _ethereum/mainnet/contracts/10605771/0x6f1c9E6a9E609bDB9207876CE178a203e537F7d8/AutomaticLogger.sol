pragma solidity ^0.6.0;

contract AutomaticLogger {
    event CdpRepay(uint indexed cdpId, address indexed caller, uint amount, uint beforeRatio, uint afterRatio, address logger);
    event CdpBoost(uint indexed cdpId, address indexed caller, uint amount, uint beforeRatio, uint afterRatio, address logger);

    function logRepay(uint cdpId, address caller, uint amount, uint beforeRatio, uint afterRatio) public {
        emit CdpRepay(cdpId, caller, amount, beforeRatio, afterRatio, msg.sender);
    }

    function logBoost(uint cdpId, address caller, uint amount, uint beforeRatio, uint afterRatio) public {
        emit CdpBoost(cdpId, caller, amount, beforeRatio, afterRatio, msg.sender);
    }
}
