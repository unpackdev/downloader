// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./WeaponsBridgeL2.sol";

interface IERC721 {
    function ownerOf(uint256 id) external view returns (address);

    function burnFrom(address owner, uint256 id) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external;
}

interface IOutbox {
    event OutboxEntryCreated(
        uint256 indexed batchNum,
        uint256 outboxIndex,
        bytes32 outputRoot,
        uint256 numInBatch
    );

    function l2ToL1Sender() external view returns (address);

    function l2ToL1Block() external view returns (uint256);

    function l2ToL1EthBlock() external view returns (uint256);

    function l2ToL1Timestamp() external view returns (uint256);

    function processOutgoingMessages(
        bytes calldata sendsData,
        uint256[] calldata sendLengths
    ) external;
}

interface IInbox {
    function sendL2Message(bytes calldata messageData)
        external
        returns (uint256);

    function sendUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function createRetryableTicket(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function depositEth(uint256 maxSubmissionCost)
        external
        payable
        returns (uint256);

    function bridge() external view returns (IBridge);
}

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    );

    function deliverMessageToInbox(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function executeCall(
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    // These are only callable by the admin
    function setInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // View functions

    function activeOutbox() external view returns (address);

    function allowedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function messageCount() external view returns (uint256);
}

interface IMessageProvider {
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

contract WeaponsBridgeL1 {
    address public l2Target;
    IInbox public inbox;
    IERC721 public weapons;
    mapping(uint256 => bool) public bridged;

    constructor() {
        inbox = IInbox(0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f);
        weapons = IERC721(0xb191FFBA3CAF34b39eaCD8D63e2AcC4b448552d4);
    }

    // This need to be called once L2 ctx is deployed
    function setTarget(address target) public {
        require(l2Target == address(0), "Alreadyset");
        l2Target = target;
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function sendMsgToL2(
        uint256 id, //nft id,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid
    ) public payable returns (uint256) {
        require(!isContract(msg.sender), "only EOA"); //to prevent FL etc..
        require(weapons.ownerOf(id) == msg.sender, "!owner"); //require owner of nft
        require(!bridged[id], "Already minted");
        bridged[id] = true;

        weapons.safeTransferFrom(msg.sender, address(this), id);

        bytes memory data = abi.encodeWithSelector(
            WeaponsBridgeL2.mintWeapon.selector,
            msg.sender, //user
            id // id of nft
        );

        uint256 ticketID = inbox.createRetryableTicket{value: msg.value}(
            l2Target,
            0,
            maxSubmissionCost,
            msg.sender,
            msg.sender,
            maxGas,
            gasPriceBid,
            data
        );

        return ticketID;
    }
}
