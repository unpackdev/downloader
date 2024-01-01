// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Ownable2StepUpgradeable.sol";
import "./Initializable.sol";

contract CreateToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    Ownable2StepUpgradeable
{

    uint256[50] private ______gap;

    uint256 maxSupply;
    uint256 currentSupply;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address tokenMintedTo) public initializer {
        __ERC20_init("Create", "CREATE");
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable2Step_init();


        // Total supply is 11.1 billion (11,100,000,000). Minting 10% initially
        _mint(tokenMintedTo, 1110000000 * 10 ** decimals());

        currentSupply = 1110000000;
        maxSupply = 11100000000;
    }

    function pause()  external onlyOwner {
        _pause();
    }

    function unpause()  external onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount)  external onlyOwner {
        require(currentSupply + amount <= maxSupply, "Token minting is exceeding the max supply");
        _mint(to, amount);
        currentSupply += amount;
    }

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    function getCurrentSupply() public view returns (uint256) {
        return currentSupply;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
