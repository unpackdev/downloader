// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./ERC20.sol";
import "./EGovernanceBase.sol";


contract EKotketToken is EGovernanceBase, ERC20 {
    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the
     * account that deploys the contract.
     *
     */
    constructor(address _governanceAdress, string memory name, string memory symbol, address initialWallet, uint256 amount) EGovernanceBase(_governanceAdress) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());               
        _mint(initialWallet, amount);
    }


    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}