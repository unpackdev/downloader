pragma solidity ^0.8.7;

import "./IRNG.sol";
import "./IRNGrequestor.sol";
import "./Ownable.sol";


contract randomV2test is IRNGrequestor, Ownable {


    IRNG     rng;

    event Requested(bytes32 reqId);
    event Received(uint256 rand, bytes32 requestId);

    constructor(IRNG r) {
        rng = r;
    }

    function process(uint256 rand, bytes32 requestId) external override {
        require(msg.sender == address(rng),"Invalid source");
        emit Received(rand,requestId);
    }

    function ask() external onlyOwner {
        bytes32 _reqID = rng.requestRandomNumberWithCallback();
        emit Requested(_reqID);
    }

}