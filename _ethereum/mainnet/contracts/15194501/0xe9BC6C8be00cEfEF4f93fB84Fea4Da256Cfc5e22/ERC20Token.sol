// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./ERC20.sol";

/**
 * @title Standard ERC20 token, with minting and pause functionality.
 *
 */
// Initializable,
// ERC20PresetMinterPauserUpgradeSafe
contract ERC20Token is ERC20 {
    address payable public _owner;
    uint256 constant _initMint = 10e10;
    uint8 customDecimals = 18;
    // mapping(address => uint256) values;

    modifier onlyOwner() {
        require(
            _msgSender() == _owner,
            "solo el owner puede ejecutar esta funcion"
        );
        _;
    }


    // Initializer function (replaces constructor)
    constructor(string memory symbol, string memory name, uint8 _decimals) ERC20(name, symbol)
    {
        customDecimals = _decimals;
        _owner = payable(_msgSender());
        _mint(_owner, _initMint * (10**uint256(decimals())));
    }

    function decimals() public view virtual override returns (uint8) {
        return customDecimals;
    }

    function getBalance() public view onlyOwner() returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner() {
        require(address(this).balance > 0, "No hay nada que retirar");
        payable(_msgSender()).transfer(address(this).balance);
    }

    /*function destroy(uint password) public onlyOwner {
        require(password == 995511, "wrong password to destroy");
        selfdestruct(owner);
    }*/
}
