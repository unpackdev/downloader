pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract VIW is ERC20, Ownable {

    mapping(address => bool) public frozenAccount;

    constructor(string memory _name, string memory _symbol, address _to) public ERC20(_name, _symbol) {
        super._mint(_to, 1000000000000000000000000000);
    }

    function freezeAccount(address account) external onlyOwner {
        frozenAccount[account] = true;
    }

    function unFreezeAccount(address account) external onlyOwner {
        frozenAccount[account] = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        require(!frozenAccount[from], "From Frozen");
        require(!frozenAccount[to], "To Frozen");
        super._beforeTokenTransfer(from, to, value);
    }
}
