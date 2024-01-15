// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "WriterNFT.sol";

// TODO: make key1 the nft address, can add nft addresses
contract ContentRegistry {

    mapping (address => bytes32[]) public contentMap;
    address[] public nfts;
    address public mgmt;
    event ContentAdded(address indexed nftKey, bytes32 content);

    constructor(address _mgmt) {
        mgmt = _mgmt;
    }

    function addNFT(address nft) external {
        require(msg.sender == mgmt, 'Only management may call this');
        nfts.push(nft);
    }

    function setMgmt(address newMgmt) external {
        require(msg.sender == mgmt, 'Only management may call this');
        mgmt = newMgmt;
    }

    function eligibleWriter(address writer, address nft) public returns (bool) {
        return WriterNFT(nft).balanceOf(writer) > 0;
    }

    function addContent(address nft, bytes32 content) external {
        require(eligibleWriter(msg.sender, nft), 'Must hold NFT to add content');
        contentMap[nft].push(content);
        emit ContentAdded(nft, content);
    }

    function getNFTs() external returns (address[] memory) {
        return nfts;
    }

    function getContent(address nft) external returns (bytes32[] memory) {
        return contentMap[nft];
    }

}
