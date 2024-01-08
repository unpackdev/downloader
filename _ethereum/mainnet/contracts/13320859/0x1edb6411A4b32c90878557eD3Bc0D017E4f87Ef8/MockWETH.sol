// SPDX-License-Identifier: Unlicensed

pragma solidity 0.6.12;

import "./MockERC20.sol";

contract MockWETH is MockERC20 {
    constructor() public MockERC20("Wrapped Ether", "WETH") {
        _mint(msg.sender, 1000000e18);
    }

    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        (bool success, ) = msg.sender.call{ value: amount }(new bytes(0));
        require(success, "ETH burn transfer failed");

        _burn(msg.sender, amount);
    }
}
