// contracts/MyToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./Address.sol";

contract MoKiCoinOfficial is ERC20, AccessControl {
    using Address for address;

    address public EToken = address(0x1597F069D3ec65d5A4625527054e40F69533f27E);
    mapping(address => bool) public isBot;

    constructor(address principal) ERC20("MoKi Coin Official", "MCC") {
        // Grant the minter role to a specified account
        _grantRole(DEFAULT_ADMIN_ROLE, principal);

        _mint(principal, 1000000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a minter or admin");

        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function modifiyEToken(address newToken) public {
        // Check that the calling account has the minter role
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a admin");
        EToken = newToken;
    }

    function getEtokenBalance() public view returns (uint256) {
        // Check that the calling account has the minter role
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a admin");
        IERC20 eToken = IERC20(EToken);
        return eToken.balanceOf(address(this));
    }

    function withDrawEtoken() public {
        // Check that the calling account has the minter role
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a admin");
        IERC20 eToken = IERC20(EToken);
        eToken.transfer(msg.sender, eToken.balanceOf(address(this)));
    }

    function blockBot(address account, bool state) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a admin");
        isBot[account] = state;
    }

    function _update(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");

        require(!isBot[sender] && !isBot[recipient], "You can't transfer tokens");

        super._update(sender, recipient, amount);
    }
}
