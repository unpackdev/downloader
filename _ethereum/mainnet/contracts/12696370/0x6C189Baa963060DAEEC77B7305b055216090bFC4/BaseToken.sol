// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./ERC20Pausable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./IMintBurn.sol";
import "./IPause.sol";

contract BaseToken is ERC20Pausable, AccessControl, IMintBurn, IPause{
    bytes32 public constant MINTER_ROLE ="MINTER_ROLE";
    bytes32 public constant BURNER_ROLE ="BURNER_ROLE";
    bytes32 public constant LIQUIDATION = "LIQUIDATION";
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimal_,
        address admin
    ) public ERC20(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupDecimals(decimal_);
    }

    function mint(address account, uint amount) public virtual override onlyMinter{
        _mint(account, amount);
    }

    function burn(address account, uint amount) public virtual override onlyBurner{
        _burn(account, amount);
    }

    function pause() public override onlyLiquidation {
        _pause();
    }

    function unpause() public override onlyLiquidation {
        _unpause();
    }

    // minter will only be tunnel
    modifier onlyMinter {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _;
    }

    modifier onlyBurner {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        _;
    }

    modifier onlyLiquidation {
        require(hasRole(LIQUIDATION, msg.sender), "Caller is not liquidation contract");
        _;
    }
}