// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract RocketTickets is ERC1155, Ownable {

    uint constant public TICKET_ID = 0;

    bool public isTicketsLocked;
    mapping(address => bool) public isOperatorApproved;

    constructor() ERC1155("https://tickets.onedaybae.io/meta/") {
        isTicketsLocked = true;
    }

    // Admin functions region
    function setURI(string memory uri) external onlyOwner {
        _setURI(uri);
    }

    function approveOperator(address operator, bool approved) external onlyOwner {
        isOperatorApproved[operator] = approved;
    }

    function setIsTicketsLocked(bool _isTicketsLocked) external onlyOwner {
        isTicketsLocked = _isTicketsLocked;
    }

    // endregion

    // Mint and Burn functions
    function mint(address[] memory addresses, uint[] memory amounts) external onlyOwner {
        require(addresses.length == amounts.length, "addresses.length != amounts.length");
        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i], TICKET_ID, amounts[i], "");
        }
    }
    // endregion

    // 1151 interface region
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return isOperatorApproved[operator] || super.isApprovedForAll(account, operator);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(!isTicketsLocked, "Transfers locked");
        super._safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(!isTicketsLocked, "Transfers locked");
        super._safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    // endregion
}