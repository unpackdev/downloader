// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./ILtoken.sol";

contract Erc20Ltoken is ERC20, ILtoken {
    address public governanceAccount;
    address public treasuryPoolAddress;

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
        governanceAccount = msg.sender;
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "Erc20Ltoken: sender not authorized");
        _;
    }

    function mint(address to, uint256 amount)
        external
        override
        onlyBy(treasuryPoolAddress)
    {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount)
        external
        override
        onlyBy(treasuryPoolAddress)
    {
        _burn(account, amount);
    }

    function balanceOf(address account)
        public
        view
        virtual
        override(ERC20, ILtoken)
        returns (uint256)
    {
        return ERC20.balanceOf(account);
    }

    function isNonFungibleToken() external pure override returns (bool) {
        return false;
    }

    function setTokenAmount(
        uint256, /* token */
        uint256 /* amount */
    ) external pure override {
        revert("Erc20Ltoken: token is not NFT");
    }

    function getTokenAmount(
        uint256 /* token */
    ) external pure override returns (uint256) {
        revert("Erc20Ltoken: token is not NFT");
    }

    function setGovernanceAccount(address newGovernanceAccount)
        external
        onlyBy(governanceAccount)
    {
        require(
            newGovernanceAccount != address(0),
            "Erc20Ltoken: new governance account is the zero address"
        );

        governanceAccount = newGovernanceAccount;
    }

    function setTreasuryPoolAddress(address newTreasuryPoolAddress)
        external
        onlyBy(governanceAccount)
    {
        require(
            newTreasuryPoolAddress != address(0),
            "Erc20Ltoken: new treasury pool address is the zero address"
        );

        treasuryPoolAddress = newTreasuryPoolAddress;
    }

    function _transfer(
        address, /* sender */
        address, /* recipient */
        uint256 /* amount */
    ) internal virtual override {
        // non-transferable between users
        revert("Erc20Ltoken: token is non-transferable");
    }
}
