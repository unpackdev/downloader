pragma solidity ^0.7.0;


import "./ERC20.sol";
import "./Ownable.sol";


contract WrappedTON is ERC20, Ownable {
    constructor() ERC20("Wrapped TON Crystal", "WTON") {
        _setupDecimals(9);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
}
