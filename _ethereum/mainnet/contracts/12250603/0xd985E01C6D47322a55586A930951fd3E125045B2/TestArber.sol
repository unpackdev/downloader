// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ILFeiPairCallee.sol";
import "./LFeiPair.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";

contract TestArber is ILFeiPairCallee {
    using SafeMath for uint256;
    address public usdc;
    address public fei;

    constructor(address _fei, address _usdc) public {
        fei = _fei;
        usdc = _usdc;
    }

    function lFeiPairCall(
        address sender,
        uint256 amountFeiOut,
        bytes calldata data
    ) external override {
        uint256 amountUsdcToBePaid = abi.decode(data, (uint256));
        TransferHelper.safeTransfer(usdc, msg.sender, amountUsdcToBePaid);
    }

    function flashArb(
        uint256 amountFei,
        uint256 amountUsdc,
        address payable lFeiPair
    ) public {
        LFeiPair(lFeiPair).swap(amountFei, address(this), abi.encode(amountUsdc));
    }
}
