// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./INSFWToken.sol";

/**
 * @title NotSafeForWork (NSFW+)
 * @notice (🎟,👁)
 */
contract NotSafeForWorkToken is ERC20, Ownable, INSFWToken {
    uint256 private immutable _SUPPLY_CAP;

    /**
     * @notice Constructor
     * @param _receiver address that receives the premint
     * @param _amount Amount of supply to distribute as per [NIP-4]
     * @param _cap supply cap (to prevent abusive mint)
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _receiver,
        uint256 _amount,
        uint256 _cap
    ) ERC20(_name, _symbol) {
        _mint(_receiver, _amount);
        _SUPPLY_CAP = _cap;
    }

    /**
     * @notice Mint NSFW tokens
     * @param account address to receive tokens
     * @param amount amount to mint
     * @return status true if mint is successful, false if not
     */
    function mint(address account, uint256 amount) external override onlyOwner returns (bool status) {
        if (totalSupply() + amount <= _SUPPLY_CAP) {
            _mint(account, amount);
            return true;
        }
        return false;
    }

    /**
     * @notice View supply cap
     */
    function SUPPLY_CAP() external view override returns (uint256) {
        return _SUPPLY_CAP;
    }
}
