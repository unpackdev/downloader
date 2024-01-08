// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract CFS is ERC20("CFS", "CFS"), Ownable {
    struct Transaction {
        address to;
        uint value;
        address from;
        address caller;
        uint8[] confirms;
    }

    address[7] superAddresses;
    mapping (bytes32 => Transaction) txs;

    constructor(address superAddress) {
        _mint(superAddress, 1000000000);
        superAddresses[0] = superAddress;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function setSuperKey(uint8 index, address superAddress) onlyOwner public {
        require(index >= 1 && index <= 6);
        require(superAddresses[index] == address(0));
        superAddresses[index] = superAddress;
    }

    function getSuperKey(uint8 index) public view returns (address) {
        return superAddresses[index];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if (msg.sender == superAddresses[0]) {
            _transfer(_msgSender(), recipient, amount);
        } else {
            require(msg.sender != address(0), "ERC20: transfer from the zero address");
            require(recipient != address(0), "ERC20: transfer to the zero address");
            uint256 senderBalance = balanceOf(msg.sender);
            require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
            bytes32 operation = keccak256(abi.encodePacked(msg.data, block.number));
            if (txs[operation].to == address(0)) {
                txs[operation].from = msg.sender;
                txs[operation].to = recipient;
                txs[operation].value = amount;
            }
            emit ConfirmationTransferNeeded(operation, msg.sender, amount, recipient);
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        uint256 currentAllowance = allowance(sender, msg.sender);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        bytes32 operation = keccak256(abi.encodePacked(msg.data, block.number));
        if (txs[operation].to == address(0)) {
            txs[operation].from = sender;
            txs[operation].to = recipient;
            txs[operation].value = amount;
            txs[operation].caller = msg.sender;
        }
        emit ConfirmationTransferNeeded(operation, sender, amount, recipient);
        return true;
    }

    function confirmTransfer(bytes32 operation) public returns (bool) {
        uint sender_index = type(uint).max;
        for (uint i = 0; i < superAddresses.length; i++) {
            if (superAddresses[i] == msg.sender) {
                sender_index = i;
                break;
            }
        }
        require(sender_index != type(uint).max);

        if (txs[operation].to != address(0)) {
            bool hasConfirm = false;
            for (uint i = 0; i < txs[operation].confirms.length; i++) {
                if (txs[operation].confirms[i] == sender_index) {
                    hasConfirm = true;
                    break;
                }
            }

            if (!hasConfirm) {
                txs[operation].confirms.push() = uint8(sender_index);
            }

            if (txs[operation].confirms.length >= 4) {
                if (txs[operation].caller == address(0)) {
                    _transfer(txs[operation].from, txs[operation].to, txs[operation].value);
                } else {
                    _transfer(txs[operation].from, txs[operation].to, txs[operation].value);

                    uint256 currentAllowance = allowance(txs[operation].from, txs[operation].caller);
                    require(currentAllowance >= txs[operation].value, "ERC20: transfer amount exceeds allowance");
                    _approve(txs[operation].from, txs[operation].caller, currentAllowance - txs[operation].value);

                }
                delete txs[operation];
            }
        }
        return true;
    }

    event ConfirmationTransferNeeded(bytes32 operation, address initiator, uint value, address to);
}
