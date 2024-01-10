// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Ownable.sol";
import "./UniV2.sol";
import "./UniV3.sol";

contract ArbitratePool is Ownable, UniV2, UniV3 {
    constructor() 
        UniV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) 
        UniV3(0xE592427A0AEce92De3Edee1F18E0157C05861564) {}
    
    function v2ToV3(uint amount, address tokenA, address tokenB, uint24 fee) public onlyOwner {
        uint[] memory amounts = convertV2(amount, tokenA, tokenB);
        uint newBalance = convertV3(amounts[1], tokenB, tokenA, fee);
        require(newBalance > amount * 110 / 100, "operation with loss");
    }

    function v3ToV2(uint amount, address tokenA, address tokenB, uint24 fee) public onlyOwner {
        uint amountOut = convertV3(amount, tokenA, tokenB, fee);
        uint[] memory amounts = convertV2(amountOut, tokenB, tokenA);
        require(amounts[1] > amount * 110 / 100, "operation with loss");
    }

    receive() payable external {}

    function withdraw(address token, uint amount) external onlyOwner {
        TransferHelper.safeTransferFrom(token, address(this), msg.sender, amount);
    }
    
    function withdraw(uint amount) external onlyOwner {
        require(payable(msg.sender).send(amount));
    }

    function finalize() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}