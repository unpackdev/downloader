//SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;

interface IFederation {
    event VotedTransfer(
        uint256 srcChainID_,
        address srcChainTokenAddress_,
        address dstChainTokenAddress_,
        address receiver_,
        uint256 amount_,
        bytes32 indexed transactionHash_,
        uint32 logIndex_,
        address indexed federator,
        bytes32 indexed processId);
    event VotedCall(
        uint256 srcChainID_,
        address srcChainContractAddress_,
        address dstChainContractAddress_,
        bytes32 indexed transactionHash_,
        uint32 logIndex_,
        address indexed federator,
        bytes32 indexed processId,
        bytes payload
    );

    event ExecutedCall(bytes32 indexed processId);
    event ExecutedTransfer(bytes32 indexed processId);
    event MemberAddition(address indexed member);
    event MemberRemoval(address indexed member);
    event RequirementChange(uint required);
    event BridgeChanged(address bridge);
    function voteTransfer(
        uint256 srcChainID_,
        address srcChainTokenAddress_,
        address dstChainTokenAddress_,
        address receiver_,
        uint256 amount_,
        bytes32 transactionHash_,
        uint32 logIndex_
    ) external;
    function hasVotedTransfer(
        uint256 srcChainID_,
        address srcChainTokenAddress_,
        address dstChainTokenAddress_,
        address receiver_,
        uint256 amount_,
        bytes32 transactionHash_,
        uint32 logIndex_
    ) external view returns(bool);

    function isTransferProcessed(
        uint256 srcChainID_,
        address srcChainTokenAddress_,
        address dstChainTokenAddress_,
        address receiver_,
        uint256 amount_,
        bytes32 transactionHash_,
        uint32 logIndex_
    ) external view returns(bool);


    // function voteCall(
    //     uint256 srcChainID_,
    //     address srcChainContractAddress_,
    //     address dstChainContractAddress_,
    //     bytes32 transactionHash_,
    //     uint32 logIndex_,
    //     bytes calldata payload
    // ) external;

    // function hasVotedCall(
    //     uint256 srcChainID_,
    //     address srcChainContractAddress_,
    //     address dstChainContractAddress_,
    //     bytes32 transactionHash_,
    //     uint32 logIndex_,
    //     bytes calldata payload
    // ) external view returns(bool);

    // function isCallProcessed(
    //     uint256 srcChainID_,
    //     address srcChainContractAddress_,
    //     address dstChainContractAddress_,
    //     bytes32 transactionHash_,
    //     uint32 logIndex_,
    //     bytes calldata payload
    // ) external view returns(bool);

    function getVoteCount(bytes32 processId) external view returns(uint);



    function setRequired(uint _required) external;

}
