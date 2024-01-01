// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract MultiSender {
    address public owner;

    event TokensSent(address indexed token, address indexed sender, address[] recipients, uint256[] amounts);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function multiSend(address _tokenAddress, address[] calldata _recipients, uint256[] calldata _amounts) external onlyOwner {
        require(_recipients.length == _amounts.length, "Recipients and amounts must be the same length");

        IERC20 token = IERC20(_tokenAddress);
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }

        require(token.allowance(msg.sender, address(this)) >= totalAmount, "Not enough tokens allowed for transfer");

        for (uint256 i = 0; i < _recipients.length; i++) {
            require(token.transferFrom(msg.sender, _recipients[i], _amounts[i]), "Failed to transfer tokens");
        }

        emit TokensSent(_tokenAddress, msg.sender, _recipients, _amounts);
    }

    function multiSendSameAmount(address _tokenAddress, address[] calldata _recipients, uint256 _amount) external onlyOwner {
        require(_recipients.length > 0, "No recipients provided");
        require(_amount > 0, "Amount must be greater than 0");

        IERC20 token = IERC20(_tokenAddress);
        uint256 totalAmount = _amount * _recipients.length;

        require(token.allowance(msg.sender, address(this)) >= totalAmount, "Not enough tokens allowed for transfer");

        for (uint256 i = 0; i < _recipients.length; i++) {
            require(token.transferFrom(msg.sender, _recipients[i], _amount), "Failed to transfer tokens");
        }

        uint256[] memory amounts = new uint256[](_recipients.length);
        for (uint256 i = 0; i < _recipients.length; i++) {
            amounts[i] = _amount;
        }
        emit TokensSent(_tokenAddress, msg.sender, _recipients, amounts);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }
}