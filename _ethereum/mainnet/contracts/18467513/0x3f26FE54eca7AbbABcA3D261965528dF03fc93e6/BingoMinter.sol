// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Pausable.sol";
import "./IERC1363.sol";
import "./IERC1363Receiver.sol";

interface BingoCardsNFT {
    function mintTo(address to) external;
    function mintBatch(address to, uint256 quantity) external;
}

contract BingoMinter is AccessControl, IERC1363Receiver, Pausable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    BingoCardsNFT public bingoCardsNFT;
    IERC1363 public immutable token;
    address public beneficiary;
    uint priceInREG = 1000 * 10 ** 18; // 1000 REG
    uint priceInETH = 100 * 10 ** 14;  // .01 ETH

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        token = IERC1363(0x78b5C6149C87c82EDCffC73C230395abbc56DdD5);   // REG mainnet
        bingoCardsNFT = BingoCardsNFT(0xA99cAb29165914300C9Ec34c87a33E89C9f38769); // bingo card NFT mainnet
        beneficiary = msg.sender;
    }

// mint

    function mint(address _to) public whenNotPaused payable {
        require(msg.value >= priceInETH, "invalid payment value");
        (bool success, ) = payable(beneficiary).call{value: priceInETH}("");
        require(success, "Transfer failed");
        bingoCardsNFT.mintTo(_to);
    }

    function mintBatch(address _to, uint256 quantity) public whenNotPaused payable {
        require(quantity > 0, "Quantity must be greater than 0");
        uint256 totalEthRequired = priceInETH * quantity;
        require(msg.value >= totalEthRequired, "Invalid payment value");
        bingoCardsNFT.mintBatch(_to, quantity);

        // Transfer ETH to the beneficiary
        (bool success, ) = payable(beneficiary).call{value: totalEthRequired}("");
        require(success, "Transfer failed");

        // Refund any excess ETH sent
        if (msg.value > totalEthRequired) {
            payable(msg.sender).transfer(msg.value - totalEthRequired);
        }
    }

    function onTransferReceived(address operator, address from, uint256 value, bytes memory data) public whenNotPaused virtual returns (bytes4) {
        require(msg.sender == address(token));
        uint256 quantity = abi.decode(data, (uint256));
        require(priceInREG > 0, "item price not set");
        uint256 totalPrice = priceInREG * quantity;
        require(value >= totalPrice, "invalid payment value");

        // Mint the items
        bingoCardsNFT.mintBatch(operator, quantity); 

        // move token to beneficiary
        token.transfer(beneficiary, totalPrice);
        if (value > totalPrice) {
            token.transfer(from, value - totalPrice);
        }

        // Return magic value
        return IERC1363Receiver.onTransferReceived.selector;
    }

// admin

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setBeneficiary(address newBeneficiary) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newBeneficiary != address(0), "New beneficiary is the zero address");
        beneficiary = newBeneficiary;
    }

    function setREGPrice(uint256 newprice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        priceInREG = newprice;
    }

    function setETHPrice(uint256 newprice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        priceInETH = newprice;
    }

    function withdrawETH() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint balance = address(this).balance;
        require(balance > 0, "No ETH available for withdrawal");
        payable(beneficiary).transfer(balance);
    }

    function withdrawREG() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint balance = token.balanceOf(address(this));
        require(balance > 0, "No REG available for withdrawal");
        token.transfer(beneficiary, balance);
    }

// overrides

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}