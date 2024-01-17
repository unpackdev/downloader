//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155Supply.sol";

contract HypeXOrigin is ERC1155Supply, Ownable, ReentrancyGuard {
    using Address for address;

    uint256 private constant TOKEN_ID = 1;

    bool public isActive;
    uint256 public price = 1e17;
    uint256 public maxSupply = 2000;
    uint256 public saleEndTime;

    address public operator;

    mapping(address => bool) public whitelistedRecipients;

    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner() || msg.sender == operator, "Origin: PERMISSION_DENIED");
        _;
    }

    // solhint-disable-next-line
    constructor() ERC1155("") {}

    function withdraw() external onlyOwner {
        // solhint-disable-next-line
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Origin: WITHDRAW_FAILED");
    }

    function setOperator(address newOperator) external onlyOwner {
        require(newOperator != address(0), "Origin: INVALID_OPERATOR");
        operator = newOperator;
    }

    function setSaleEndTime(uint256 endTime) external onlyOwner {
        // solhint-disable-next-line
        require(endTime >= block.timestamp, "Origin: PASSED_TIME");
        saleEndTime = endTime;
    }

    function startSale(uint256 endTime) external onlyOwnerOrOperator {
        isActive = true;
        saleEndTime = endTime;
    }

    function stopSale() external onlyOwnerOrOperator {
        isActive = false;
    }

    function setPrice(uint256 newPrice) external onlyOwnerOrOperator {
        price = newPrice;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwnerOrOperator {
        require(newMaxSupply >= totalSupply(TOKEN_ID), "Origin: ALREADY_MINTED_OVER");
        maxSupply = newMaxSupply;
    }

    function setWhitelistedRecipients(address[] calldata recipients, bool[] calldata approved)
        external
        onlyOwnerOrOperator
    {
        for (uint256 i; i < recipients.length; i++)
            whitelistedRecipients[recipients[i]] = approved[i];
    }

    function mintNFTs(uint256 amount) external payable nonReentrant {
        require(isActive, "Origin: SALE_INACTIVE");
        // solhint-disable-next-line
        if (saleEndTime > 0) require(block.timestamp <= saleEndTime, "Origin: SALE_ENDED");
        require(amount > 0, "Origin: ZERO_AMOUNT");
        require(totalSupply(TOKEN_ID) + amount <= maxSupply, "Origin: INSUFFICIENT_AMOUNT");

        if (whitelistedRecipients[msg.sender]) {
            require(msg.value == (amount - 1) * price, "Origin: FREE_FOR_WHITELISTS");
            whitelistedRecipients[msg.sender] = false;
        } else {
            require(msg.value == amount * price, "Origin: INVALID_PRICE");
        }
        _mint(msg.sender, TOKEN_ID, amount, "");
    }

    function safeBatchMint(address[] calldata accounts, uint256[] calldata amounts)
        external
        nonReentrant
        onlyOwner
    {
        uint256 length = accounts.length;
        for (uint256 i; i < length; i += 1) _mint(accounts[i], TOKEN_ID, amounts[i], "");
    }

    function setURI(string memory uri) external onlyOwnerOrOperator {
        super._setURI(uri);
    }
}
