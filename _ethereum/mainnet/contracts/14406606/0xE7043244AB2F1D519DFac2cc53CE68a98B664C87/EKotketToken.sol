// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./ERC20Burnable.sol";
import "./EGovernanceBase.sol";


contract EKotketToken is EGovernanceBase, ERC20Burnable {
    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `SC_MINTER_ROLE` to the
     * account that deploys the contract.
     *
     */
    constructor(address _governanceAdress, string memory name, string memory symbol) EGovernanceBase(_governanceAdress) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SC_MINTER_ROLE, _msgSender());        
    }


    function decimals() public view virtual override returns (uint8) {
        return 18;
    }


    function mint(address to, uint256 amount) public virtual onlyMinterPermission{
        _mint(to, amount);
    }
}