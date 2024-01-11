pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract G3S is ERC20, Ownable {

    mapping(address => bool) public fronzenAccount;

    constructor(string memory _name, string memory _symbol, address _to) public ERC20(_name, _symbol) {
        super._mint(_to,500000000000000000000000000);
    }

    function freezeAccount(address account) external onlyOwner {
        fronzenAccount[account] = true;
    }

    function unFreezeAccount(address account) external onlyOwner {
        fronzenAccount[account] = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        require(!fronzenAccount[from], "From Frozen");
        require(!fronzenAccount[to], "To Frozen");
        super._beforeTokenTransfer(from, to, value);
    }
}
