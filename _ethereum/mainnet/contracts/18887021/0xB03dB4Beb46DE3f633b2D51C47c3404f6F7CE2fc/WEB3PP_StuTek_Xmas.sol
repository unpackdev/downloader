// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract WEB3PP_StuTek_Xmas {

    string public constant name = "Word of 2023 by StuTek";
    string public constant symbol = "stWORD2023";

    address public owner;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    constructor() {
        owner = msg.sender;
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
                    "https://ipfs.io/ipfs/bafybeibqn6v4mh5pwqutewdia4lbfzl3j7dxft54alh27qkfw7gzvrc3cq/",
                    toString(abi.encodePacked(uint32(tokenId))),
                    ".json"
                )
            );
    }

    function supportsInterface(bytes4) external pure returns (bool supported) {
        supported = true;
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) external payable { revert(); }
    function safeTransferFrom(address, address, uint256) external payable { revert(); }
    function transferFrom(address, address, uint256) external payable { revert(); }
    function approve(address, uint256) external payable { revert(); }
    function setApprovalForAll(address, bool) external pure { revert(); }

    function addressToUint256(address input) internal pure returns (uint256) {
        return uint256(uint160(input));
    }

    function uint256ToAddress(uint256 input) internal pure returns (address) {
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

    function claimTo(address account, uint32 refNum) public {
        require(msg.sender == owner);
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
}