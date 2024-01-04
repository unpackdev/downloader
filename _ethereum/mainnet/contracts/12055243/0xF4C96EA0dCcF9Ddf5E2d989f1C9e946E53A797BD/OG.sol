// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC721.sol";
import "./ECDSA.sol";

contract OG is ERC721 {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    address public owner;
    address public authorizer;
    mapping (address => bool) public purchased;
    
    constructor(address _owner) ERC721("One of the Few", "OG") {
        owner = _owner;
        authorizer = _owner;
        _setBaseURI("https://app.oneofthefew.net/og/");
    }

    function mint(address to, bytes calldata signature) public payable {
        require(msg.value >= 1 ether, "invalid_amount");

        address signer = keccak256(abi.encodePacked(to))
            .toEthSignedMessageHash()
            .recover(signature);

        require(signer == authorizer, "invalid_signature");
        require(!purchased[to], "duplicate");

        string memory suffix = ".json";
        uint256 index = totalSupply();

        purchased[to] = true;
        _mint(to, index);
        _setTokenURI(index, string(abi.encodePacked(toString(abi.encodePacked(to)), suffix)));
    }

    function withdraw(IERC20 token, uint256 amount) public {
        require(owner == msg.sender, "unauthorized");
        token.safeTransfer(msg.sender, amount);
    }

    function withdrawETH(uint256 amount) public {
        require(owner == msg.sender, "unauthorized");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "transfer_failed");
    }

    function toString(bytes memory data) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}