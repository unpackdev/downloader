// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./Ownable.sol";

contract ScholarPresale is Ownable {
    /**
    DECLARE VARIABLES
    This smart contract simply accepts USDC. All accounting for token allocation happens off chain.
    A dashboard for seeing token allocation will be populated shortly after providing an investment in USDC.
    **/


    address public usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // Ethereum Mainnet
    bool public paused = true;

    function acceptUSDC(uint256 amount) public {
        IERC20 USDC = IERC20(usdcAddress);
        require(!paused, "Presale is paused. Please contact sch0lar.io personnel to discuss a presale investment.");
        USDC.transferFrom(msg.sender, address(this), amount);
        paused = true;
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function changeTokenAddress(address _usdcAddress) public onlyOwner {
        usdcAddress = _usdcAddress;
    }

    function withdrawERC20(address _ERC20, address recipient) public onlyOwner {
        IERC20 ERC20Token = IERC20(_ERC20);
        uint256 erc20TokenBalance = ERC20Token.balanceOf(address(this));
        ERC20Token.transfer(recipient, erc20TokenBalance);
    }

    function withdrawEth(address recipient) public onlyOwner {
        require(payable(recipient).send(address(this).balance));
    }
}