// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC20.sol";
import "./IERC20.sol";

contract SatsV1 is ERC20 {
    IERC20 wbtc;

    constructor(address _wbtc) ERC20("Sats", "SATS") {
        wbtc = IERC20(_wbtc);
    }

    function decimals() public pure override returns (uint8) {
        return 10;
    }
    
    function wbtcToSats(address receiver, uint256 btcAmount) external {
        require(wbtc.transferFrom(msg.sender, address(this), btcAmount), "Transfer WBTC failed");
        uint satsAmount = btcAmount * (10 ** decimals());
        _mint(receiver, satsAmount);
    }

    function satsToWbtc(address receiver, uint256 satsAmount) external {
        uint btcAmount = satsAmount / (10 ** decimals());
        _burn(msg.sender, satsAmount);
        require(wbtc.transfer(receiver, btcAmount), "Transfer WBTC failed");
    }
}
