//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IChainlinkOracle.sol";

contract VotersTcLpRequester is Ownable { 
    using SafeERC20 for IERC20;

    IChainlinkOracle gasOracle;
    uint public lastRequest;
    uint public requestCount;
    mapping(uint => bytes) public requests; 

    event Requested(uint index, bytes addr);
    event Withdrawal(uint amount);
    event UpdatedLastRequest(uint index);

    constructor(address oracle) Ownable() {
        gasOracle = IChainlinkOracle(oracle);
    }

    function requestsSince(uint index) external view returns (bytes[] memory) {
        if (index >= requestCount) {
            index = requestCount;
        }
        bytes[] memory list = new bytes[](requestCount-index);
        for (uint i = index; i < requestCount; i++) {
            list[i-index] = requests[index];
        }
        return list;
    }

    function currentCost() public view returns (uint) {
        uint gas = uint(gasOracle.latestAnswer());
        return 600000 * gas * 1e9 / 1e8;
    }

    function request(bytes calldata addr) external payable {
        require(msg.value >= currentCost(), "must pay cost");
        requests[requestCount] = addr;
        emit Requested(requestCount, addr);
        requestCount += 1;
    }

    function withdraw(uint amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
        emit Withdrawal(amount);
    }

    function setLastRequest(uint index) external onlyOwner {
        lastRequest = index;
        emit UpdatedLastRequest(index);
    }
}
