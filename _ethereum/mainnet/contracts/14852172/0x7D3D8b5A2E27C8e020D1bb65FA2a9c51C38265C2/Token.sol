// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2;

import "./Initializable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract Token is Initializable, ERC20PausableUpgradeable, UUPSUpgradeable, OwnableUpgradeable {

    mapping (bytes32 => bool) private _minted;
    address private _minter;

    function minter() external view returns (address) {
        return _minter;
    }

    function initialize() initializer public {
      __ERC20_init("Wrapped QOIN", "wQOIN");
      __Ownable_init();
      __UUPSUpgradeable_init();
      _minter = msg.sender;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function mint(address account, uint256 amount)
        external
        onlyMinter
    {
        _mint(account, amount);
    }

    function getMessageHash(address to, uint256 amount, bytes32 txID) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(to, amount, txID));
    }

    function getEthSignedMessageHash(bytes32 messageHash)
        internal
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    function userMint(uint256 amount, bytes32 txID, bytes calldata signature)
        external
    {
        require(_minted[txID] == false, "userMint: Already minted");

        bytes32 messageHash = getMessageHash(msg.sender, amount, txID);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        require(recoverSigner(ethSignedMessageHash, signature) == _minter, "userMint: Not authorized");

        _minted[txID] = true;
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount)
        external
    {
        require(amount <= balanceOf(msg.sender), "burn: Insuficient balance");
        _burn(msg.sender, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setMinter(address minter_) public onlyOwner {
        require(minter_ != address(0), "setMinter: Minter cannot be 0");
        _minter = minter_;
    }

    function recoverSigner(bytes32 message, bytes memory signature)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(signature);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory signature)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(signature, 32))
            // second 32 bytes
            s := mload(add(signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(signature, 96)))
        }

        return (v, r, s);
    }

    modifier onlyMinter() {
        require(msg.sender == _minter, "onlyMinter: caller is not the minter");
        _;
    } 
}
