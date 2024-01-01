// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC20Burnable.sol";
import "./IERC20Receive.sol";

contract CartelCoin is ERC20, ERC20Burnable, Ownable {
    address public _signer;
    mapping(bytes => bool) private usedSignatures;

    constructor() ERC20("Cartel Coin", "CRTL") {
        _signer = msg.sender;
        _mint(msg.sender, 1000000000000000000000000);
    }

    function mint(
        address _to,
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) external {
        require(!usedSignatures[_signature], "Signature already used");
        usedSignatures[_signature] = true;

        bytes32 messageHash = keccak256(abi.encodePacked(_to, _amount, _nonce));
        bytes32 message = ECDSA.toEthSignedMessageHash(messageHash);
        address receivedAddress = ECDSA.recover(message, _signature);
        require(receivedAddress == _signer, "Invalid signature");

        _mint(_to, _amount);
    }

    function send(address _to, uint256 _tokenId, uint256 _amount) external {
        _approve(msg.sender, _to, _amount);
        IERC20Receive(_to).receiveFor(
            address(this),
            msg.sender,
            _tokenId,
            _amount
        );
    }

    function setSigner(address newSigner) external onlyOwner {
        _signer = newSigner;
    }
}
