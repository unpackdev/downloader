// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./AccessControl.sol";

contract RYLT is ERC20, AccessControl {
    bytes32 public constant MINTER = keccak256("MINTER");

    uint256 private immutable _maxTotalSupply;

    modifier onlyAdminAndMinter() {
        require(
            hasRole(MINTER, _msgSender()) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC20: Only for Admin or Vesting"
        );
        _;
    }

    constructor(
        uint256 maxTotal,
        address _multisig,
        uint256 _amount,
        address owner
    ) ERC20("RYLT", "RYLT") {
        require(
            _multisig != address(0) && owner != address(0),
            "Adresses can't be zero"
        );
        _maxTotalSupply = maxTotal;
        _mint(_multisig, _amount);
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mintTo(address _recipient, uint256 _amount)
        public
        onlyAdminAndMinter
    {
        require(
            totalSupply() + _amount <= _maxTotalSupply,
            "ERC20: Amount > maxTotalSupply"
        );
        _mint(_recipient, _amount);
    }

}
