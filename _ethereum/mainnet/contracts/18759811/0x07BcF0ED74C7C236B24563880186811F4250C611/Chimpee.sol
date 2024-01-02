// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "./ERC20Pausable.sol";
import "./ChimpeeAccessControl.sol";

contract Chimpee is ERC20Pausable, ChimpeeAccessControl {
    string private _name;
    string private _symbol;

    constructor(
        address admin,
        address minter,
        address pauser
    ) ERC20("Chimpee", "Chimp") ChimpeeAccessControl(admin, minter, pauser) {
        _mint(admin, 360000000000000 * 10 ** decimals());
        _setName("Chimpee");
        _setSymbol("Chimp");
    }

    function setName(string memory newName) public onlyAdmin {
        _setName(newName);
    }

    function setSymbol(string memory newSymbol) public onlyAdmin {
        _setSymbol(newSymbol);
    }

    function mint(address receiver, uint256 amount) public onlyMinter {
        _mint(receiver, amount);
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    function _setName(string memory newName) internal {
        _name = newName;
    }

    function _setSymbol(string memory newSymbol) internal {
        _symbol = newSymbol;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }
}
