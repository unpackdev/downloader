// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20.sol";
import "./IERC721.sol";

abstract contract EthArbBase is OwnableUpgradeable {
    uint256 public constant PROJECT_ID = 100;
    uint256 public constant COUNT = 1;
    uint256 public constant NFT_PRICE = 0.01 ether;


    function withdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(token).transfer(to, amount);
        }
    }

    function withdrawERC721(
        address token,
        address to,
        uint256 tokenId
    ) external onlyOwner {
        IERC721(token).transferFrom(address(this), to, tokenId);
    }
}
