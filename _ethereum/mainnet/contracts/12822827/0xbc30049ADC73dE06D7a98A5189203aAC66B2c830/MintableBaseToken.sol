// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BaseToken.sol";
import "./IMintable.sol";

contract MintableBaseToken is BaseToken, IMintable {

    mapping (address => bool) public vaults;

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) public BaseToken(_name, _symbol, _initialSupply) {
    }

    modifier onlyVault() {
        require(vaults[msg.sender], "MintableBaseToken: forbidden");
        _;
    }

    function addVault(address _vault) external onlyGov {
        vaults[_vault] = true;
    }

    function removeVault(address _vault) external onlyGov {
        vaults[_vault] = false;
    }

    function mint(address _account, uint256 _amount) external override onlyVault {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external override onlyVault {
        _burn(_account, _amount);
    }
}
