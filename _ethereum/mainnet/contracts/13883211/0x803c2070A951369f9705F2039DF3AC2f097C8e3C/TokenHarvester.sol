// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Pausable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./ERC165.sol";

contract TokenHarvester is Pausable, ERC165, IERC721Receiver, IERC1155Receiver {

// Amount paid per token harvested
    uint256 public immutable PAID_PER_TOKEN = 1 gwei;

// Burn address
    address public immutable BURN_ADDRESS = address(0xdEaD);

// Harvesting address
    address public immutable HARVEST_ADDRESS = address(this);

// Initialization

    constructor() {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            super.supportsInterface(interfaceId)
        ;
    }

// Balance

    modifier whenBalanceAvailable(uint256 howMany) {
        require(address(this).balance >= PAID_PER_TOKEN * howMany, '402');
        _;
    }

// Authorization

    modifier onlyOperator(address erc721Address) {
        // Can check both ERC721 and ERC1155 since function signature is the same.
        require(IERC721(erc721Address).isApprovedForAll(msg.sender, address(this)), '403');
        _;
    }

// Purchasing

    function sellTokens(address contractAddress, uint256[] memory tokenIds)
        public
        virtual
        whenNotPaused
        whenBalanceAvailable(tokenIds.length)
        onlyOperator(contractAddress)
    {
        _captureERC721Tokens(IERC721(contractAddress), HARVEST_ADDRESS, tokenIds);
        _payForTransaction(msg.sender, tokenIds.length);
    }

// Burning

    function sellAndBurnTokens(address contractAddress, uint256[] memory tokenIds)
        public
        virtual
        whenNotPaused
        whenBalanceAvailable(tokenIds.length)
        onlyOperator(contractAddress)
    {
        _captureERC721Tokens(IERC721(contractAddress), BURN_ADDRESS, tokenIds);
        _payForTransaction(msg.sender, tokenIds.length);
    }

    function sellAndBurnTokens(address contractAddress, uint256 id, uint256 quantity)
        public
        virtual
        whenNotPaused
        whenBalanceAvailable(quantity)
        onlyOperator(contractAddress)
    {
        _captureERC1155Tokens(IERC1155(contractAddress), BURN_ADDRESS, id, quantity);
        _payForTransaction(msg.sender, quantity);
    }

// Receiving

    function onERC721Received(address operator, address, uint256, bytes calldata)
        public
        virtual
        override
        whenNotPaused
        whenBalanceAvailable(1)
        returns (bytes4)
    {
        _payForTransaction(operator, 1);
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address operator, address, uint256, uint256 quantity, bytes calldata)
        public
        virtual
        override
        whenNotPaused
        whenBalanceAvailable(quantity)
        returns (bytes4)
    {
        _payForTransaction(operator, quantity);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        public
        virtual
        override
        returns (bytes4)
    {
        return 0x00000000;
    }

// Internals

    function _captureERC721Tokens(IERC721 erc721Contract, address to, uint256[] memory tokenIds) internal {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            erc721Contract.transferFrom(msg.sender, to, tokenIds[i]);
        }
    }

    function _captureERC1155Tokens(IERC1155 erc1155Contract, address to, uint256 id, uint256 value) internal {
        erc1155Contract.safeTransferFrom(msg.sender, to, id, value, "");
    }

    function _payForTransaction(address to, uint256 howMany) internal {
        (bool sent, ) = payable(to).call{ value: PAID_PER_TOKEN * howMany }("");
        require(sent, '500');
    }
}
