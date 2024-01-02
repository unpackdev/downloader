pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./console.sol";

contract StateChainGateway  {

    IERC20 public flip;
    constructor (address flip_) {
        flip = IERC20(flip_);
    }


    function fundStateChainAccount(bytes32 nodeID, uint256 amount) external {
        flip.transferFrom(msg.sender, address(this), amount);
    }

    function executeRedemption(bytes32 nodeID) external returns (address, uint256) {
        bytes32 hash = keccak256(abi.encodePacked(block.timestamp, nodeID));
        uint256 amount = uint256(hash) % 1_000_000*10**18;
        flip.transfer(msg.sender, amount);
        return (msg.sender, amount);
    }
}