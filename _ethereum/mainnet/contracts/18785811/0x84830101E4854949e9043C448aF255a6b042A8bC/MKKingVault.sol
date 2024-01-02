// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./Ownable.sol";

// Uncomment this line to use console.log
import "./console.sol";

contract MKKingVault is Ownable {
    IERC20 public token;
    mapping(uint256 => bool) public usedTix;
    address public signer;

    constructor(address token_addr, address _signer) Ownable(msg.sender) {
        token = IERC20(token_addr);
        signer = _signer;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function invalidateTix(uint256 tix) public onlyOwner {
        usedTix[tix] = true;
    }

    function withdrawToken() public onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function verifySignature(
        uint256 _amount,
        uint256 tix,
        bytes memory sig
    ) public view returns (bool) {
        bytes32 message = keccak256(abi.encodePacked(msg.sender, _amount, tix));
        return recoverSigner(message, sig) == signer;
    }

    function withdraw(uint256 amount, uint256 tix, bytes memory sig) public {
        require(verifySignature(amount, tix, sig), "invalid sig");
        require(usedTix[tix] == false, "used tix");

        usedTix[tix] = true;
        token.transfer(msg.sender, amount);
    }

    // crypto
    function splitSignature(
        bytes memory sig
    ) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65, "invalid sig");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(
        bytes32 message,
        bytes memory sig
    ) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }
}
