// SPDX-License-Identifier: AGPL-1.0
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract Airdrop is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public treasuryAddress = 0xfcc257B471A66577f1D24A28574C25d2F79A016B;
    
    constructor() {}

    function airdrop(address token, address[] calldata recipients, uint256[] calldata amounts) external {
        require(token != address(0), "TOKEN_ADDRESS_0");
        require(recipients.length == amounts.length, "LIST_LENGTHS_WRONG");
        for(uint256 x; x < recipients.length; x++) {
            IERC20(token).transferFrom(_msgSender(), recipients[x], amounts[x]);
        }
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasuryAddress = _treasury;
    }

    /*******************/
    /*  GENERAL ADMIN  */
    /*******************/

    function withdrawTokens(address _token) external onlyOwner nonReentrant {
        IERC20(_token).safeTransfer(treasuryAddress, IERC20(_token).balanceOf(address(this)));
        emit Withdraw(_msgSender(), _token);
    }
    
    function withdraw() external onlyOwner nonReentrant {
        payable(treasuryAddress).transfer(address(this).balance);
    }

    event Withdraw(address indexed msgSender, address indexed token);
}