//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ERC20.sol";
import "./AccessControl.sol";

contract GoldenNugget is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address minter) ERC20("Golden Nugget", "GN") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        if (minter != address(0)) {
            _grantRole(MINTER_ROLE, minter);
        }
    }

    /**
     * @notice Mints tokens by user.
     * @param _user The user address.
     * @param _amount The amount of minting.
     */
    function mint(address _user, uint256 _amount)
        external
        onlyRole(MINTER_ROLE)
    {
        _mint(_user, _amount);
    }
}
