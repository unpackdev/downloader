// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IRouterClient.sol";
import "./OwnerIsCreator.sol";
import "./Client.sol";
import "./LinkTokenInterface.sol";
import "./CCIPReceiver.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A {
   function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

        /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract BridgeETH is CCIPReceiver, OwnerIsCreator {

    //SENDER
    IERC20 public LINK;
    IERC721A public NFT;
    uint public priceTransfer;
    
    // Custom errors to provide more descriptive revert messages.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance.

    // Event emitted when a message is sent to another chain.
    event MessageSent(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        uint[] idNFT, // The text being sent.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the CCIP message.
    );

    IRouterClient router;
    LinkTokenInterface linkToken;

    // @notice Constructor initializes the contract with the router address.
    // @param _router The address of the router contract.
    // @param _link The address of the link contract.
    constructor(address _router, address _link, IERC721A _addrNFT) CCIPReceiver(_router) {
        router = IRouterClient(_router);
        linkToken = LinkTokenInterface(_link);
        NFT = _addrNFT;
    }

    function transferToPolygon(
        uint64 destinationChainSelector,
        address receiver,
        uint[] memory idNFT
    ) external payable returns (bytes32 messageId) {
        require(msg.value >= priceTransfer);

        for (uint i=0; i<idNFT.length; i++) {
            NFT.transferFrom(msg.sender, address(this), idNFT[i]);
        }
        
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver), 
            data: abi.encode(idNFT, msg.sender), 
            tokenAmounts: new Client.EVMTokenAmount[](0), 
            extraArgs: Client._argsToBytes(

                Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
            ),
            feeToken: address(linkToken)
        });

        // Get the fee required to send the message
        uint256 fees = router.getFee(destinationChainSelector, evm2AnyMessage);

        if (fees > linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(linkToken.balanceOf(address(this)), fees);

        // approve the Router to transfer LINK tokens on contract's behalf. It will spend the fees in LINK
        linkToken.approve(address(router), fees);

        // Send the message through the router and store the returned message ID
        messageId = router.ccipSend(destinationChainSelector, evm2AnyMessage);

        // Emit an event with message details
        emit MessageSent(
            messageId,
            destinationChainSelector,
            receiver,
            idNFT,
            address(linkToken),
            fees
        );

        // Return the message ID
        return messageId;
    }

    // RECEVIER
    // Event emitted when a message is received from another chain.
    event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        string text // The text that was received.
    );

    bytes32 private lastReceivedMessageId; // Store the last received messageId.
    string private lastReceivedText; // Store the last received text.
    uint[] public idNFTs;
    address public addr;
    
    /// handle a received message
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        lastReceivedMessageId = any2EvmMessage.messageId; // fetch the messageId

        (uint[] memory _idNFTs, address _addr) = abi.decode(any2EvmMessage.data,(uint[], address));
        idNFTs = _idNFTs;
        addr = _addr;

        for (uint i=0; i<_idNFTs.length; i++) {
            NFT.transferFrom(address(this), _addr, _idNFTs[i]);
        }

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector, // fetch the source chain identifier (aka selector)
            abi.decode(any2EvmMessage.sender, (address)), // abi-decoding of the sender address,
            abi.decode(any2EvmMessage.data, (string))
        );
    }

    /// @notice Fetches the details of the last received message.
    /// @return messageId The ID of the last received message.
    /// @return text The last received text.
    function getLastReceivedMessageDetails()
        external
        view
        returns (bytes32 messageId, string memory text)
    {
        return (lastReceivedMessageId, lastReceivedText);
    }

    //Admin Functions
    function setPrice(uint _price) public onlyOwner {
        priceTransfer = _price;
    }

    function withdrawLink(uint _amount) public onlyOwner {
        LINK.transfer(msg.sender, _amount);
    }

    function withdrawNFT(uint _id, address _addr) public onlyOwner {
        NFT.transferFrom(address(this), _addr, _id);
    }

    function setContracts(IERC721A _addrNFT, address _router, address _link, IERC20 _linkForWithdraw) public onlyOwner {
        NFT = _addrNFT;
        router = IRouterClient(_router);
        linkToken = LinkTokenInterface(_link);
        LINK = _linkForWithdraw;
    }

}
