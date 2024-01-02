//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract SignatureRewards is Ownable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    address private _systemAddress;
    address payable public reward;
    mapping(string => bool) public usedNonces;
    mapping(address => uint256) public claimed;

    constructor(address signedAddress, address payable rewardAddress) {
        _systemAddress = signedAddress;
        reward = rewardAddress;
    }

    function claim(
        uint256 amount,
        string memory nonce,
        bytes32 hash,
        bytes memory signature
    ) external payable {
        // signature realted
        require(matchSigner(hash, signature), "Plz mint through website");
        require(!usedNonces[nonce], "Hash reused");
        require(
            hashTransaction(msg.sender, amount, nonce) == hash,
            "Hash failed"
        );

        IERC20(reward).safeTransfer(msg.sender, amount - claimed[msg.sender]);

        usedNonces[nonce] = true;
        claimed[msg.sender] = amount; //amount never decrease
    }

    function matchSigner(
        bytes32 hash,
        bytes memory signature
    ) public view returns (bool) {
        return
            _systemAddress == hash.toEthSignedMessageHash().recover(signature);
    }

    function hashTransaction(
        address sender,
        uint256 amount,
        string memory nonce
    ) public view returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(sender, amount, nonce, address(this))
        );

        return hash;
    }

    function rescure() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function rescure(address token) public onlyOwner {
        IERC20(token).safeTransfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }
}
