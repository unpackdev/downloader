// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract RoyaltyDistribution is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint constant shareOfRoyalty1 = 9800;
    uint constant shareOfRoyalty2 = 100;
    uint constant shareOfRoyalty3 = 100;

    address payable public addr1 = payable(0x5db8Bb85D6065f95350d8AE3934D72Ad0aB3Ae7E);
    address payable public addr2 = payable(0x04d59D5699E1B28161eA972fFD81a6705bFEB8A3);
    address payable public addr3 = payable(0xf08e0469565d481d4193de46D5f98b7c6463FC3d);

    receive() external payable {}

    function claimEther() external nonReentrant {
        uint total = address(this).balance;
        require(total > 0, "Nothing to claim");

        addr1.transfer(total*shareOfRoyalty1/10000);
        addr2.transfer(total*shareOfRoyalty2/10000);
        addr3.transfer(total*shareOfRoyalty3/10000);
    }

    function claimToken(address token) external nonReentrant {
        IERC20 claimableToken = IERC20(token);
        uint total = claimableToken.balanceOf(address(this));
        require(total > 0, "Nothing to claim");
        claimableToken.safeTransfer(addr1, total*shareOfRoyalty1/10000);
        claimableToken.safeTransfer(addr2, total*shareOfRoyalty2/10000);
        claimableToken.safeTransfer(addr3, total*shareOfRoyalty3/10000);
    }
}
