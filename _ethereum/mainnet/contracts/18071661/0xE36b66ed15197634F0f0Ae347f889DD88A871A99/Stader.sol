// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./StakerBase.sol";
import "./console.sol";

interface IStader {
    function deposit(address receipient) external payable returns (uint256);
}

contract StaderStaker is StakerBase {
    address public constant stader = 0xcf5EA1b38380f6aF39068375516Daf40Ed70D299;
    address public constant ethX = 0xA35b1B31Ce002FBF2058D22F30f95D405200A15b;

    uint256[50] private _gap;

    function initialize() public initializer {
      __Ownable_init();
    }

    receive() external payable {
        IStader(stader).deposit{value: msg.value}(msg.sender);

        uint256 remaingEthX = IERC20(ethX).balanceOf(address(this));
        uint256 remainingEth = address(this).balance;

        require(remaingEthX == 0, "!remaingEthX");
        require(remainingEth == 0, "!remainingEth");
    }
}
