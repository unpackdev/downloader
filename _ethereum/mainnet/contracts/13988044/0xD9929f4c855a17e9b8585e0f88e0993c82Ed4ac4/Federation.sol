//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./OwnableUpgradeable.sol";
import "./IBridgeInbound.sol";
import "./IFederation.sol";
import "./Utils.sol";
contract Federation is IFederation, OwnableUpgradeable {
    using Utils for *;

    IBridgeInbound public bridge;
    address[] public members;
    uint public required;

    mapping (address => bool) public isMember;
    mapping (bytes32 => mapping (address => bool)) public votes;
    // mapping (bytes32 => uint256) public processed;

    function initialize(uint8 required_, address bridge_) public initializer {
        OwnableUpgradeable.__Ownable_init();
        _setRequired(required_);
        _setBridge(bridge_);
    }

    function processed(bytes32 id) external view returns(uint256) {
        return bridge.processed(id);
    }

    function setBridge(address bridge_) external onlyOwner {
        _setBridge(bridge_);
    }
    function _setBridge(address bridge_) internal {
        require(bridge_ != address(0), "Federation: Empty bridge");
        bridge = IBridgeInbound(bridge_);
        emit BridgeChanged(bridge_);
    }

    function addMember(address _newMember) external onlyOwner {
        require(_newMember != address(0), "Federation: Empty member");
        require(!isMember[_newMember], "Federation: Member already exists");

        isMember[_newMember] = true;
        members.push(_newMember);
        emit MemberAddition(_newMember);
    }

    function removeMember(address _oldMember) external onlyOwner {
        require(_oldMember != address(0), "Federation: Empty member");
        require(isMember[_oldMember], "Federation: Member doesn't exists");
        require(members.length > 1, "Federation: Can't remove all the members");
        require(members.length - 1 >= required, "Federation: Can't have less than required members");
        isMember[_oldMember] =  false;
        for (uint i = 0; i < members.length - 1; i++) {
            if (members[i] == _oldMember) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        emit MemberRemoval(_oldMember);
    }

    function voteTransfer(
        uint256 srcChainID_,
        address srcChainTokenAddress_,
        address dstChainTokenAddress_,
        address receiver_,
        uint256 amount_,
        bytes32 transactionHash_,
        uint32 logIndex_
    ) external override onlyMember {
        if (bridge.isTransferProcessed(
            srcChainID_,
            srcChainTokenAddress_,
            dstChainTokenAddress_,
            receiver_,
            amount_,
            transactionHash_,
            logIndex_)
        ) {
            return;
        }
        bytes32 processId = Utils.getTransferId(
            srcChainID_,
            srcChainTokenAddress_,
            dstChainTokenAddress_,
            receiver_,
            amount_,
            transactionHash_,
            logIndex_
        );

        if (votes[processId][_msgSender()])
            return;

        votes[processId][_msgSender()] = true;

        emit VotedTransfer(
            srcChainID_,
            srcChainTokenAddress_,
            dstChainTokenAddress_,
            receiver_,
            amount_,
            transactionHash_,
            logIndex_,
            _msgSender(),
            processId
        );

        uint voteCount = getVoteCount(processId);
        if ((voteCount >= required) && (voteCount >= members.length / 2 + 1)) {
            bridge.acceptTransfer(
                srcChainID_,
                srcChainTokenAddress_,
                dstChainTokenAddress_,
                receiver_,
                amount_,
                transactionHash_,
                logIndex_
            );

            emit ExecutedTransfer(processId);
        }
    }

    function hasVotedTransfer(
        uint256 srcChainID_,
        address srcChainTokenAddress_,
        address dstChainTokenAddress_,
        address receiver_,
        uint256 amount_,
        bytes32 transactionHash_,
        uint32 logIndex_
    ) external view override returns(bool) {
        bytes32 transferId = Utils.getTransferId(
            srcChainID_,
            srcChainTokenAddress_,
            dstChainTokenAddress_,
            receiver_,
            amount_,
            transactionHash_,
            logIndex_
        );
        return votes[transferId][_msgSender()];
    }

    function isTransferProcessed(
        uint256 srcChainID_,
        address srcChainTokenAddress_,
        address dstChainTokenAddress_,
        address receiver_,
        uint256 amount_,
        bytes32 transactionHash_,
        uint32 logIndex_
    ) external view override returns(bool) {
        return bridge.isTransferProcessed(srcChainID_, srcChainTokenAddress_, dstChainTokenAddress_, receiver_, amount_, transactionHash_, logIndex_);
    }

    // function voteCall(
    //     uint256 srcChainID_,
    //     address srcChainContractAddress_,
    //     address dstChainContractAddress_,
    //     bytes32 transactionHash_,
    //     uint32 logIndex_,
    //     bytes calldata payload
    // ) external override onlyMember {
    //     if (bridge.isCallProcessed(
    //         srcChainID_,
    //         srcChainContractAddress_,
    //         dstChainContractAddress_,
    //         transactionHash_,
    //         logIndex_,
    //         payload
    //     )) {
    //        return;
    //     }
    //     bytes32 callId = Utils.getCallId(
    //         srcChainID_,
    //         srcChainContractAddress_,
    //         dstChainContractAddress_,
    //         transactionHash_,
    //         logIndex_,
    //         payload
    //     );
    //     if (votes[callId][_msgSender()])
    //         return;

    //     votes[callId][_msgSender()] = true;
    //     emit VotedCall(
    //         srcChainID_,
    //         srcChainContractAddress_,
    //         dstChainContractAddress_,
    //         transactionHash_,
    //         logIndex_,
    //         _msgSender(),
    //         callId,
    //         payload
    //     );
    //     uint voteCount = getVoteCount(callId);
    //     if ((voteCount >= required) && (voteCount >= members.length / 2 + 1)) {
    //         bridge.acceptCall(
    //             srcChainID_,
    //             srcChainContractAddress_,
    //             dstChainContractAddress_,
    //             transactionHash_,
    //             logIndex_,
    //             payload
    //         );
    //         emit ExecutedCall(callId);
    //     }

    // }
    // function hasVotedCall(
    //     uint256 srcChainID_,
    //     address srcChainContractAddress_,
    //     address dstChainContractAddress_,
    //     bytes32 transactionHash_,
    //     uint32 logIndex_,
    //     bytes calldata payload
    // ) external view override returns(bool) {
    //     bytes32 callId = Utils.getCallId(
    //         srcChainID_,
    //         srcChainContractAddress_,
    //         dstChainContractAddress_,
    //         transactionHash_,
    //         logIndex_,
    //         payload
    //     );
    //     return votes[callId][_msgSender()];
    // }
    // function isCallProcessed(
    //     uint256 srcChainID_,
    //     address srcChainContractAddress_,
    //     address dstChainContractAddress_,
    //     bytes32 transactionHash_,
    //     uint32 logIndex_,
    //     bytes calldata payload
    // ) external view override returns(bool) {
    //     return bridge.isCallProcessed(srcChainID_, srcChainContractAddress_, dstChainContractAddress_, transactionHash_, logIndex_, payload);
    // }

    function getVoteCount(bytes32 processId) public view override returns(uint) {
        uint count = 0;
        for (uint i = 0; i < members.length; i++) {
            if (votes[processId][members[i]])
                count += 1;
        }
        return count;
    }

    function setRequired(uint _required) external override onlyOwner {
        _setRequired(_required);
    }

    function _setRequired(uint _required) internal {
        required = _required;
        emit RequirementChange(_required);
    }

    modifier onlyMember() {
        require(isMember[_msgSender()], "Federation: Caller not a Federator");
        _;
    }

}
