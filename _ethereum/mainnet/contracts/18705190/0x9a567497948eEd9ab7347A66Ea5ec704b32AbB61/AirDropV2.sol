pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Airdrop {
    // Modifier to restrict who can perform the airdrop
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function airdropTokens(
        address tokenAddress,
        address[] memory recipients,
        uint256[] memory amounts
    ) public onlyOwner {
        require(recipients.length == amounts.length, "Mismatch between addresses and amounts");

        IERC20 token = IERC20(tokenAddress);

        for (uint i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], amounts[i]), "Transfer failed");
        }
    }
}
