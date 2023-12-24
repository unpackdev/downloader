// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./NonblockingLzApp.sol";
import "./clipFinanceNFT.sol";

/// @title A LayerZero example sending a cross chain message from a source chain to a destination chain to increment a counter
contract MintFullFill is NonblockingLzApp {
    ClipFinanceNFT nftContractAddress;

    constructor(
        address _lzEndpoint,
        ClipFinanceNFT _nftContract
    ) NonblockingLzApp(_lzEndpoint) {
        nftContractAddress = _nftContract;
    }

    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        (
            uint256 _numberOfTokens,
            address _minterAddress,
            uint256 _team
        ) = decode(_payload);
        nftContractAddress.crossChainMint(
            _minterAddress,
            _numberOfTokens,
            _team
        );
    }

    function decode(
        bytes memory data
    ) public pure returns (uint256, address, uint256) {
        uint256 nr;
        address addr;
        uint256 team;

        assembly {
            nr := mload(add(data, 32))
            addr := mload(add(data, 52))
            team := mload(add(data, 84))
        }

        return (nr, addr, team);
    }
}
