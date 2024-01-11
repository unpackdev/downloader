// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./Base64.sol";

contract Withdraw is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using Strings for uint256;

    event CreatorWithdraw(string _nonce);

    mapping(string => bool) public _usedNonces;
    address private _checkAddress;

    constructor(address _found) {
        _checkAddress = _found;
    }

    function creatorWithdraw(
        uint256 amount,
        string memory nonce,
        bytes32 hash,
        bytes memory signature
    ) external payable nonReentrant {
        require(!_usedNonces[nonce], "Nonce reused");
        bytes32 calHash = hashTransaction(msg.sender, amount, nonce);
        require(calHash == hash, "Hash failed");
        require(matchSigner(calHash, signature), "Signature not match");
        require(balanceOf() >= amount, "Balance not enough");
        _usedNonces[nonce] = true;
        payable(msg.sender).transfer(amount);
        emit CreatorWithdraw(nonce);
    }

    function balanceOf() public view returns (uint256) {
        return address(this).balance;
    }

    function matchSigner(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return
            _checkAddress == hash.toEthSignedMessageHash().recover(signature);
    }

    function charge() external payable {
        require(msg.value > 0, "value is zoro");
    }

    function hashTransaction(
        address sender,
        uint256 amount,
        string memory nonce
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(sender, Strings.toString(amount), nonce)
            );
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
