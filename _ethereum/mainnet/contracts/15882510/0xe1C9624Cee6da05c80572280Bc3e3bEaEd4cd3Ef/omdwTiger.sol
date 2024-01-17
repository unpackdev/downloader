// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract OMDAOWrappedTigr is ERC20, Pausable, Ownable {
    constructor() ERC20("OM DAO Wrapped Tigr", "omdwTigr") {
        _mint(address(0x30346df38fc57F12c2894618Dcd215045894B109), 4_500_000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public returns (bool){
        _burn(_msgSender(), amount);
        return true;
    }

    function burnFrom(address account, uint256 amount) public returns (bool){
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

}