// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";


contract GoTekERC20 is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, OwnableUpgradeable {

//    constructor() {
//        _disableInitializers();
//    }

    bool private initialized;

    function initialize() initializer public {

        require(!initialized, "Contract instance has already been initialized");
        initialized = true;

        __ERC20_init("GPlus", "GPlus");
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
        _mint(msg.sender, 10000000000000000000000000000);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    mapping(address => Transaction[]) public transactions;

    struct Transaction {
        address from;
        address to;
        uint256 amount;
        uint256 time;
    }

    function mint(address owner, uint256 amount) public onlyOwner {
        _mint(owner, amount);
        Transaction memory transaction = Transaction(msg.sender, owner, amount, block.timestamp);
        transactions[owner].push(transaction);
    }

    function transfer(
        address from,
        address to,
        uint256 amount
    ) public onlyOwner {
        allowance(from, to);
        transferFrom(from, to, amount);
        Transaction memory transaction = Transaction(from, to, amount, block.timestamp);
        transactions[from].push(transaction);
        transactions[to].push(transaction);
    }

    function burn(address owner, uint256 amount) public onlyOwner {
        _burn(owner, amount);
        Transaction memory transaction = Transaction(owner, msg.sender, amount, block.timestamp);
        transactions[owner].push(transaction);
    }

    function getTransaction(address owner) public view returns (Transaction[] memory){
        return transactions[owner];
    }

    function getTransactionAll(address owner) public view returns (Transaction[] memory){
        return transactions[owner];
    }

}
