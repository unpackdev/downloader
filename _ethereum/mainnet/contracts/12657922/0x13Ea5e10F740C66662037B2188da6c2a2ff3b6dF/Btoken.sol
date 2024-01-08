// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./IBtoken.sol";

contract Btoken is ERC20, IBtoken {
    address public governanceAccount;
    address public farmingPoolAddress;

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
        governanceAccount = msg.sender;
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "Btoken: sender not authorized");
        _;
    }

    function mint(address to, uint256 amount)
        external
        override
        onlyBy(farmingPoolAddress)
    {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount)
        external
        override
        onlyBy(farmingPoolAddress)
    {
        _burn(account, amount);
    }

    function setGovernanceAccount(address newGovernanceAccount)
        external
        onlyBy(governanceAccount)
    {
        require(
            newGovernanceAccount != address(0),
            "Btoken: new governance account is the zero address"
        );

        governanceAccount = newGovernanceAccount;
    }

    function setFarmingPoolAddress(address newFarmingPoolAddress)
        external
        onlyBy(governanceAccount)
    {
        require(
            newFarmingPoolAddress != address(0),
            "Btoken: new farming pool address is the zero address"
        );

        farmingPoolAddress = newFarmingPoolAddress;
    }

    function _transfer(
        address, /* sender */
        address, /* recipient */
        uint256 /* amount */
    ) internal virtual override {
        // non-transferable between users
        revert("Btoken: token is non-transferable");
    }
}
