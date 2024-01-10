// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./FxBaseRootTunnel.sol";
import "./SubjectTunnel.sol";
import "./SubjectRoot.sol";

contract SubjectRootTunnel is FxBaseRootTunnel, SubjectTunnel {
    constructor(
        address _checkpointManager,
        address _fxRoot,
        address payable _daoAddress
    )
        FxBaseRootTunnel(_checkpointManager, _fxRoot)
        SubjectTunnel(_daoAddress)
    {}

    SubjectRoot public subjectContract;

    modifier onlyOwner(uint256 tokenId) {
        require(
            subjectContract.ownerOf(tokenId) == msg.sender,
            "Only owner can move subject"
        );
        _;
    }

    function _processMessageFromChild(bytes memory data) internal override {
        require(
            address(subjectContract) != address(0),
            "Subject contract hasn't been set yet"
        );
        (
            uint256 tokenId,
            address ownerAddress,
            uint256 gene,
            bool isNotVirgin,
            bool isBoss,
            uint256 genomeChanges
        ) = _decodeMessage(data);

        subjectContract.transferFrom(address(this), ownerAddress, tokenId);

        subjectContract.wormholeUpdateGene(
            tokenId,
            gene,
            isNotVirgin,
            genomeChanges
        );
    }

    function moveThroughWormhole(uint256 tokenId)
        public
        override
        onlyOwner(tokenId)
    {
        subjectContract.transferFrom(msg.sender, address(this), tokenId);
        (bool isBoss, ) = subjectContract.isTokenBoss(tokenId);
        _sendMessageToChild(
            abi.encode(
                tokenId,
                msg.sender,
                subjectContract.geneOf(tokenId),
                subjectContract.isNotVirgin(tokenId),
                isBoss,
                subjectContract.genomeChanges(tokenId)
            )
        );
    }

    function setSubjectContract(address payable contractAddress)
        public
        onlyDAO
    {
        subjectContract = SubjectRoot(contractAddress);
    }
}
