// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract WEB3PP_SBTPuzzle {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    string public constant name = "Web3 is Pure and Powerful";
    string public constant symbol = "SBTPuzzle";

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function addressToUint256(address input) internal pure returns (uint256) {
        return uint256(uint160(input));
    }

    function uint256ToAddress(uint256 input) internal pure returns (address) {
        require(input < 1 << 160, "SOUL_INVALID");
        return address(uint160(input));
    }

    function toString(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function balanceOf(address) external pure returns (uint256) {
        return 1;
    }

    function ownerOf(uint256 tokenId) external pure returns (address) {
        return uint256ToAddress(tokenId >> 32);
    }

    function getApproved(uint256) external pure returns (address) {}

    function isApprovedForAll(address, address) external pure returns (bool) {}

    function tokenURI(uint256 tokenId)
        external
        pure
        virtual
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "https://www.mendelverse.com/api/contacts/",
                    toString(abi.encodePacked(uint32(tokenId)))
                )
            );
    }

    function claim(uint32 refNum) public {
        emit Transfer(
            address(0),
            msg.sender,
            (addressToUint256(msg.sender) << 32) | refNum
        );
    }

    function claimTo(address account, uint32 refNum) public {
        require(msg.sender == owner, "Ping Pong");
        emit Transfer(
            address(0),
            account,
            (addressToUint256(account) << 32) | refNum
        );
    }

    function trash(uint32 refNum) public {
        emit Transfer(
            msg.sender,
            address(0),
            (addressToUint256(msg.sender) << 32) | refNum
        );
    }

    function supportsInterface(bytes4) external pure returns (bool supported) {
        supported = true;
    }
}