pragma solidity >=0.8.11;

import "./ERC20.sol";

contract DubaiDevsDAO is ERC20 {
    address payable public owner;
    bool public frozen;

    constructor() payable ERC20("", "DDD") {
        owner = payable(msg.sender);
        _mint(msg.sender, 1000000000000000000000000);
    }

    function mint(uint256 amount) public payable {
        require(msg.sender == owner, "only owner");
        require(!frozen, "minting is frozen");
        _mint(msg.sender, amount);
    }

    function setOwner(address newOwner) public payable {
        require(msg.sender == owner, "only owner");
        owner = payable(newOwner);
    }

    function freezeMint() public payable {
        require(msg.sender == owner, "only owner");
        frozen = true;
    }
}
