// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";
import "Ownable.sol";
import "IERC20.sol";

contract GameRewards is Context, Ownable {
    IERC20 public token;
    address public holdingWallet;
    address public authWallet;
    mapping(address => uint256) public claimed;

    constructor(
        address tokenAddress,
        address holding,
        address auth
    ) {
        token = IERC20(tokenAddress);
        holdingWallet = holding;
        authWallet = auth;
    }

    function redeem(
        uint256 total,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 hash = keccak256(
            abi.encode("GameRewards_redeem", _msgSender(), total)
        );
        address signer = ecrecover(hash, v, r, s);
        require(signer == authWallet, "Invalid signature");
        token.transferFrom(
            holdingWallet,
            _msgSender(),
            total - claimed[_msgSender()]
        );
        claimed[_msgSender()] = total;
    }

    function setHoldingWallet(address wallet) external onlyOwner {
        holdingWallet = wallet;
    }

    function setAuthWallet(address wallet) external onlyOwner {
        authWallet = wallet;
    }
}
