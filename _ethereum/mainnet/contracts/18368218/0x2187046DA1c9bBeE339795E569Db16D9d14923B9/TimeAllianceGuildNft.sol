// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ITimeAllianceGuildNft.sol";
import "./SimpleERC1155.sol";

contract TimeAllianceGuildNft is ITimeAllianceGuildNft, SimpleERC1155 {
    /// @dev Authorized addresses to issue and burn
    mapping(address => bool) public authorized;

    constructor(
        string memory name,
        string memory symbol,
        string memory metadataUri_
    ) SimpleERC1155(symbol, name) {
        setBaseURI(metadataUri_);
        setAuthorized(msg.sender, true);
    }

    /**
     * @notice Mint tokens as authorized
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) public onlyAuthorized(msg.sender) {
        _mint(account, id, amount, "");
    }

    /**
     * @notice Burn tokens as authorized
     */
    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) public onlyAuthorized(msg.sender) {
        _burn(account, id, amount);
    }

    /**
     * @notice Batch burn tokens as authorized
     */
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public onlyAuthorized(msg.sender) {
        _burnBatch(account, ids, values);
    }

    /**
     * @notice Toggle authorized state
     */
    function setAuthorized(address minter, bool status) public onlyOwner {
        authorized[minter] = status;
    }

    modifier onlyAuthorized(address address_) {
        require(authorized[address_], "Unauthorized");
        _;
    }
}
