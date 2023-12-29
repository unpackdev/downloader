// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract RewardDistributor is Ownable {
    address public signer;
    address public token;
    uint256 public chainId;

    mapping(address => uint256) public nonces;

    event Claimed(address indexed user, uint256 amount);

    constructor(address _token, uint256 _chainId) {
        token = _token;
        chainId = _chainId;
    }

    function claimTokens(uint256 amount, uint256 nonce, uint256 expirationTime, uint256 chainID, bytes memory signature) public {
        require(block.timestamp <= expirationTime, "ClaimableToken: Token claim has expired");
        require(ERC20(token).balanceOf(address(this)) >= amount, "ClaimableToken: Not enough tokens to claim");
        require(nonces[msg.sender]++ == nonce, "ClaimableToken: Invalid nonce");

        bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, amount, nonce, expirationTime, chainID)));
        require(ECDSA.recover(message, signature) == signer, "ClaimableToken: Invalid signature");

        emit Claimed(msg.sender, amount);
        // Transfer the tokens to the user
        ERC20(token).transfer(msg.sender, amount);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }
}
