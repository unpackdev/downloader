// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC721Enumerable.sol";

interface IMerkleOrchard is IERC721Enumerable {
    function fundChannel(
        uint256 _channelId,
        address _token,
        uint256 _amount
    ) external;

    function fundChannelWithEth(uint256 _channelId) external payable;

    function setMerkleRoot(
        uint256 _channelId,
        bytes32 _merkleRoot,
        string memory _ipfsHash
    ) external;

    function claim(
        uint256 _channelId,
        address _receiver,
        address _token,
        uint256 _cumalativeAmount,
        bytes32[] calldata _proof
    ) external;
}
