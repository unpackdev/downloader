// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./StakerBase.sol";
import "./IStaderStaker.sol";
import "./console.sol";

contract StaderStaker is StakerBase {
    address public constant STADER = 0xcf5EA1b38380f6aF39068375516Daf40Ed70D299;
    address public constant ETH_X = 0xA35b1B31Ce002FBF2058D22F30f95D405200A15b;

    uint256[50] private _gap;

    function initialize() public initializer {
      __Ownable_init();
    }

    receive() external payable {
        IStader(STADER).deposit{value: msg.value}(msg.sender);

        uint256 remaingEthX = IERC20(ETH_X).balanceOf(address(this));
        uint256 remainingEth = address(this).balance;

        require(remaingEthX == 0, "!remaingEthX");
        require(remainingEth == 0, "!remainingEth");
    }
}
