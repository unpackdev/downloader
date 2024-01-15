pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Detailed.sol";

/**
 * @title BEP20Token
 * @dev Very simple TRC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract BEP20Token is ERC20, ERC20Detailed, Ownable {

    address payable public maintainer;

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor (
        string memory name,
        string memory symbol,
        uint8 decimal,
        uint256 totalSupply
    ) public ERC20Detailed(name, symbol, decimal) {
        _mint(msg.sender, totalSupply * (10 ** uint256(decimals())));
        maintainer = msg.sender;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 value) public onlyOwner {
        _burn(account, value);
    }

    function setMaintainer(address payable _user) public onlyOwner {
        require(maintainer != _user && maintainer != address(0), "new maintainer not acceptable");
        maintainer = _user;
    }

    function collect() external onlyOwner {
        uint256 _balance = address(this).balance;
        bool sent = maintainer.send(_balance);
        require(sent, "Failed to maintainer");
    }

    event ReceiveTransfer(address indexed sender, uint256 value);

    function() external payable {
        emit ReceiveTransfer(msg.sender, msg.value);
    }
}