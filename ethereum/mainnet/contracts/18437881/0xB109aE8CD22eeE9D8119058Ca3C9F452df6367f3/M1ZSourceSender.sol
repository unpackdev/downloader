// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IRouterClient.sol";

import "./LinkTokenInterface.sol";
import "./M1ZPrices.sol";
import "./Withdraw.sol";
import "./MissingOnez.sol";

contract M1ZSourceSender is M1ZPrices, Withdraw {
    address public i_router;
    address immutable i_link;

    event MessageSent(bytes32 messageId);

    uint256 public maxBatch = 5;
    uint256 public crossChainGasLimit = 1000000;

    MissingOnez public m1z;
    mapping(uint64 => bool) public allowedDestinations;
    bool public canMintCrossChain;

    constructor(
        address initialOwner,
        address router,
        address link,
        uint256 _unitPrice,
        address m1zAddress
    ) M1ZPrices(_unitPrice) Withdraw(initialOwner) {
        i_router = router;
        i_link = link;
        m1z = MissingOnez(m1zAddress);
    }

    receive() external payable {}

    //////////////////////////////////////////
    // FEES GETTER
    //////////////////////////////////////////

    function getMintFee(
        uint256 amount,
        uint64 destinationChainSelector,
        address receiver,
        PayFeesIn payFeesIn
    ) external view returns (uint256) {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encodeCall(MissingOnez.mint, (amount, _msgSender())),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: crossChainGasLimit, strict: false})),
            feeToken: payFeesIn == PayFeesIn.LINK ? i_link : address(0)
        });

        return IRouterClient(i_router).getFee(destinationChainSelector, message);
    }

    function getTransferFee(
        uint256[] calldata tokenIds,
        uint256[] calldata ids,
        uint64 destinationChainSelector,
        address receiver,
        PayFeesIn payFeesIn
    ) external view returns (uint256) {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encodeCall(MissingOnez.mintFromCrossChainTransfer, (tokenIds, ids, _msgSender(), block.chainid)),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: crossChainGasLimit, strict: false})),
            feeToken: payFeesIn == PayFeesIn.LINK ? i_link : address(0)
        });

        return IRouterClient(i_router).getFee(destinationChainSelector, message);
    }

    //////////////////////////////////////////
    // CROSS-CHAIN
    //////////////////////////////////////////

    /**
     * Cross-chain mint method.
     * This method should be called by users willing to mint from a chain to another through CCIP.
     * @param amount The amount of NFTs to mint.
     * @param destinationChainSelector The destination chainSelector.
     * @param receiver Address of the destination EVM chain contract.
     * @param payFeesIn Whether to pay the fees in native or LINK currency
     */
    function mint(uint256 amount, uint64 destinationChainSelector, address receiver, PayFeesIn payFeesIn) external payable {
        require(allowedDestinations[destinationChainSelector], 'M1ZSourceSender: destination chain is not allowed');
        require(canMintCrossChain, 'M1ZSourceSender: mint is not permitted from this chain to another chain');
        require(amount > 0, 'M1ZSourceSender: must mint at least one');
        require(amount <= maxBatch, 'M1ZSourceSender: cannot mint more than maxBatch at once');

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encodeCall(MissingOnez.mint, (amount, _msgSender())),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: crossChainGasLimit, strict: false})),
            feeToken: payFeesIn == PayFeesIn.LINK ? i_link : address(0)
        });

        uint256 price = getPrice(amount);
        require(msg.value >= price, 'M1ZSourceSender: did not send enough native tokens to pay');

        uint256 fee = IRouterClient(i_router).getFee(destinationChainSelector, message);
        bytes32 messageId;

        if (payFeesIn == PayFeesIn.LINK) {
            require(LinkTokenInterface(i_link).balanceOf(address(this)) >= fee, 'M1ZSourceSender: contract does not have enough LINK');
            LinkTokenInterface(i_link).approve(i_router, fee);
            messageId = IRouterClient(i_router).ccipSend(destinationChainSelector, message);
        } else {
            require(msg.value >= price + fee, 'M1ZSourceSender: did not send enough native tokens to cover the fees');
            messageId = IRouterClient(i_router).ccipSend{value: fee}(destinationChainSelector, message);
        }

        emit MessageSent(messageId);
    }

    /**
     * Burn an array of nfts from the local chain and send a message to the destination chain to mint them there.
     * @param tokenIds Array of nft tokenIds.
     * @param destinationChainSelector The destination chainSelector.
     * @param receiver Address of the destination EVM chain contract.
     * @param payFeesIn Whether to pay the fees in native or LINK currency
     */
    function sendToOtherChain(
        uint256[] calldata tokenIds,
        uint256[] calldata ids,
        uint64 destinationChainSelector,
        address receiver,
        PayFeesIn payFeesIn
    ) external payable {
        require(allowedDestinations[destinationChainSelector], 'M1ZSourceSender: destination chain is not allowed');
        require(tokenIds.length == ids.length, 'M1ZSourceSender: arrays lengths do not match');
        require(tokenIds.length > 0, 'M1ZSourceSender: must send at least 1 M1Z');
        require(tokenIds.length <= maxBatch, 'M1ZSourceSender: cannot transfer more than maxBatch at once');

        for (uint i = 0; i < tokenIds.length; i++) {
            require(m1z.revealedTokenIds(tokenIds[i]), 'M1ZSourceSender: cannot transfer to another chain if not revealed');
            m1z.burn(tokenIds[i]);
        }

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encodeCall(MissingOnez.mintFromCrossChainTransfer, (tokenIds, ids, _msgSender(), block.chainid)),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: crossChainGasLimit, strict: false})),
            feeToken: payFeesIn == PayFeesIn.LINK ? i_link : address(0)
        });

        uint256 fee = IRouterClient(i_router).getFee(destinationChainSelector, message);

        bytes32 messageId;
        if (payFeesIn == PayFeesIn.LINK) {
            require(LinkTokenInterface(i_link).balanceOf(address(this)) >= fee, 'M1ZSourceSender: contract does not have enough LINK');
            LinkTokenInterface(i_link).approve(i_router, fee);
            messageId = IRouterClient(i_router).ccipSend(destinationChainSelector, message);
        } else {
            require(msg.value >= fee, 'M1ZSourceSender: did not send enough native tokens to cover the fees');
            messageId = IRouterClient(i_router).ccipSend{value: fee}(destinationChainSelector, message);
        }

        emit MessageSent(messageId);
    }

    //////////////////////////////////////////
    // SETTER
    //////////////////////////////////////////

    function setRouter(address router) external onlyOwner {
        i_router = router;
    }

    function setM1Z(address m1zAddress) external onlyOwner {
        m1z = MissingOnez(m1zAddress);
    }

    function setAllowedDestinations(uint64[] calldata _allowedDestinations, bool isAllowed) external onlyOwner {
        for (uint i = 0; i < _allowedDestinations.length; i++) {
            allowedDestinations[_allowedDestinations[i]] = isAllowed;
        }
    }

    function setCanMintCrossChain(bool _canMintCrossChain) external onlyOwner {
        canMintCrossChain = _canMintCrossChain;
    }

    function setMaxBatch(uint256 _maxBatch) external onlyOwner {
        maxBatch = _maxBatch;
    }

    function setCrossChainGasLimit(uint256 _crossChainGasLimit) external onlyOwner {
        crossChainGasLimit = _crossChainGasLimit;
    }
}
