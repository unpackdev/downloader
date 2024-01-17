// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./DeSpace_721_NFT.sol";

contract Create_721_NFT {
    address[] private _createdNFTList;
    event Created(address indexed creator, address indexed token);

    function create(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint96 _royalty
    ) external returns (address createdAddr) {
        DeSpace_721_NFT token = new DeSpace_721_NFT(
            _name,
            _symbol,
            _uri,
            payable(msg.sender),
            _royalty
        );
        createdAddr = address(token);
        _createdNFTList.push(createdAddr);
        emit Created(msg.sender, createdAddr);
    }

    function getCreated721s()
        external
        view
        returns (address[] memory, uint256 length)
    {
        return (_createdNFTList, _createdNFTList.length);
    }
}
