pragma solidity ^0.4.18;

contract ERC20 {
    function transfer(address _to, uint256 _value) public returns (bool);

    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success);
}

contract ApplAirdrop {
    ERC20 public token;
    mapping(address => bool) public Wallets;

    function ApplAirdrop(address _tokenAddr) public {
        token = ERC20(_tokenAddr);
    }

    function getAirdrop() public {
        if (!Wallets[msg.sender]) {
            token.transfer(msg.sender, 5000000000000000000);
            Wallets[msg.sender] = true;
        } else {
            revert("You have already received ;)");
        }
    }
}