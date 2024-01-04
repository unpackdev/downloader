pragma solidity >=0.6.0 <0.7.0;
// SPDX-License-Identifier: MIT

import "./console.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract EthGateway is Ownable {
    IERC20 immutable trade;

    mapping(bytes32 => bool) public processedRequests;

    event TransferredToSmartChain(address from, uint256 amount);
    event TransferredFromSmartChain(
        bytes32 requestTxHash,
        address to,
        uint256 amount
    );

    constructor(IERC20 _trade) public {
        trade = _trade;
    }

    function transferToSmartChain(uint256 amount) external {
        require(amount > 0, "EthGateway: amount should be > 0");
        trade.transferFrom(msg.sender, address(this), amount);
        emit TransferredToSmartChain(msg.sender, amount);
    }

    function transferFromSmartChain(
        bytes32 requestTxHash,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(
            !processedRequests[requestTxHash],
            "EthGateway: request already processed"
        );
        processedRequests[requestTxHash] = true;
        trade.transfer(to, amount);
        emit TransferredFromSmartChain(requestTxHash, to, amount);
    }
}
