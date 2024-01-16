// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Ownable.sol";
import "./ERC721Instance.sol";

contract FactoryERC721 is Ownable, ReentrancyGuard {

    address public signer;

    mapping(uint256 => bool) public orderIDUsed;

    event NewInstance(uint256 orderID, string name, string symbol, address sender, address instance);

    constructor(address _signer) {
        signer = _signer;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function deployERC721Instance(uint256 orderID, string memory _name, string memory _symbol, uint256 deadline, bytes calldata signature) external nonReentrant {
        require(signer == ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(block.chainid, orderID, _msgSender(), address(this), _name, _symbol, deadline))), signature), "Invalid signature");
        require(deadline >= block.timestamp, "Deadline passed");
        require(!orderIDUsed[orderID], "Order ID already used");
        orderIDUsed[orderID] = true;
        emit NewInstance(orderID, _name, _symbol, _msgSender(), address(new ERC721Instance(_name, _symbol)));
    }
}