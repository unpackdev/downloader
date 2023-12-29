// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

contract ERC20Distributor {
    function distributeTokens(
        address _tokenAddress,
        uint256 _totalAmount,
        address[] memory _recipients,
        uint[] memory _percentages
    ) public {
        require(_recipients.length == _percentages.length, "Recipients and percentages length mismatch");

        IERC20 token = IERC20(_tokenAddress);
        uint8 decimals = token.decimals();

        uint256 totalDistributed;
        for (uint i = 0; i < _recipients.length; i++) {
            uint256 amount = _totalAmount * _percentages[i] / 10000;
            require(token.transferFrom(msg.sender, _recipients[i], amount), "Transfer failed");
            totalDistributed += amount;
        }

        require(totalDistributed <= _totalAmount, "Distributed more than specified");
    }
}