// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";

import "./ERC1155Receiver.sol";
import "./Address.sol";

contract ReDDrop is ERC1155Receiver {
    
    /// ============ Storage ============

    // Boolean that represents if the contract has been initialized
    bool private _initialized;
    // {SliceCore} address
    address private immutable _sliceCoreAddress;
    // The account who receives ETH from the sales
    address private immutable _collector; 
    // The account who sent the slices to the contract
    address private _slicesSupplier; 
    // The tokenId related to the slicer linked to this contract
    uint256 private _tokenId;
    // Price of each slice
    uint256 private SLICE_PRICE = 2 ether;
    
    /// ============ Errors ============
    
    /// @notice Thrown if contract has been initialized
    error Initialized();
    /// @notice Thrown if contract has not been initialized
    error NotInitialized();
    /// @notice Thrown if contract receives ERC1155 not related to slicers
    error NotSlicer();
    /// @notice Thrown if caller doesn't have the right permission
    error NotAuthorized();
    /// @notice Thrown if the value sent is not sufficient to claim
    error InsufficientPayment();

    /// ============ Events ============

    /// @notice Emitted when slices are claimed
    event Claimed(address indexed to, uint256 amount, uint256 _tokenId);
    /// @notice Emitted when the sale is marked as closed
    event SaleClosed(address slicesSupplier, uint256 slicesAmount);

    /// ============ Constructor ============

    /**
     * @notice Initializes the contract.
     *
     * @param sliceCoreAddress_ {SliceCore} address
     * @param collector_ Address of the account that receives ETH from sales
     *
     * @dev Claims will revert once there are no more slices in the contract.
     */
    constructor(
        address sliceCoreAddress_,
        address collector_
    ) {
        _sliceCoreAddress = sliceCoreAddress_;
        _collector = collector_;
    }

    /// ============ Functions ============

    /**
     * @notice Sends all ETH received from the sale to the appointed collector.
     */
    function releaseToCollector() external {
        Address.sendValue(payable(_collector), address(this).balance);
    }

    /**
     * @notice Sends all slices received back to the address who supplied them.
     *
     * @dev Safe measure in case the sale needs to be cancelled, or it has unclaimed slices.
     * @dev Can only be called by the slices supplier.
     */
    function _closeSale() external {
        if (msg.sender != _slicesSupplier) revert NotAuthorized();
        uint256 slices = IERC1155Upgradeable(_sliceCoreAddress).balanceOf(address(this), _tokenId);
        IERC1155Upgradeable(_sliceCoreAddress).safeTransferFrom(address(this), _slicesSupplier, _tokenId, slices, "");
        emit SaleClosed(_slicesSupplier, slices);
    }

    /// @notice Returns information about the sale.
    function saleInfo() external view returns(
        uint256 tokenId,
        address collector,
        uint256 slicePrice
    ) {
        return (_tokenId, _collector, SLICE_PRICE);
    }

    function slicesLeft() external view returns(uint256) {
      return IERC1155Upgradeable(_sliceCoreAddress).balanceOf(address(this), _tokenId);
    }

    /**
     * @notice Allows users to claim slices by paying the price.
     *
     * @param quantity Number of slices to claim.
     */
    function claim(uint256 quantity) external payable {
        if (!_initialized) revert NotInitialized();

        // Revert if value doesn't cover the claim price
        if (msg.value < SLICE_PRICE * quantity) revert InsufficientPayment();

        // Send slices to his address
        IERC1155Upgradeable(_sliceCoreAddress).safeTransferFrom(address(this), msg.sender, _tokenId, quantity, "");
        
        // Emit claim event
        emit Claimed(msg.sender, _tokenId, quantity);
    }

    /**
     * @notice Initializes the contract upon reception of the first transfer of slices.
     *
     * @dev Supports only slice transfer, not mint.
     * @dev Can only receive slices once.
     * @dev Can only receive Slice ERC1155 tokens
     */
    function onERC1155Received(
        address, 
        address from, 
        uint256 tokenId_, 
        uint256, 
        bytes memory
    ) 
        external 
        virtual 
        override 
        returns (bytes4) 
    {
        if (msg.sender != _sliceCoreAddress) revert NotSlicer();
        if (_initialized) revert Initialized();
        _initialized = true;
        _slicesSupplier = from;
        _tokenId = tokenId_;
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See `onERC1155Received`
     */
    function onERC1155BatchReceived(
        address, 
        address, 
        uint256[] memory, 
        uint256[] memory, 
        bytes memory
    ) 
        public 
        virtual 
        override 
        returns (bytes4) 
    {
        revert(); 
    }

}