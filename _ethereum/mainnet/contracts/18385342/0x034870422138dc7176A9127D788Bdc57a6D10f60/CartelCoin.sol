// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC20Burnable.sol";
import "./IERC20Receive.sol";

/// @title Native Token of Blockchain Cartel
contract CartelCoin is ERC20, ERC20Burnable, Ownable {
    address public _signer;
    mapping(bytes => bool) private usedSignatures;

    /// @dev Initializes the CartelCoin contract and mints initial supply to the contract deployer.
    constructor() ERC20("Cartel Coin", "CRTL") {
        _signer = msg.sender;
        _mint(msg.sender, 1000000000000000000000000);
    }

    /// @dev Mints new CartelCoin tokens to the specified address, subject to signature verification.
    /// @param _to The address to mint tokens to.
    /// @param _amount The amount of tokens to mint.
    /// @param _nonce The nonce value used for signature verification.
    /// @param _signature The signature used for verification.
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

    /// @dev Sends CartelCoin tokens to the specified address and calls the receiveFor function of the receiving contract.
    /// @param _to The address to send tokens to.
    /// @param _tokenId The token ID associated with the transfer.
    /// @param _amount The amount of tokens to send.
    function send(address _to, uint256 _tokenId, uint256 _amount) external {
        _approve(msg.sender, _to, _amount);
        IERC20Receive(_to).receiveFor(
            msg.sender,
            _tokenId,
            _amount
        );
    }

    /// @dev Sets a new signer address for signature verification.
    /// @param newSigner The new signer address.
    function setSigner(address newSigner) external onlyOwner {
        _signer = newSigner;
    }
}
