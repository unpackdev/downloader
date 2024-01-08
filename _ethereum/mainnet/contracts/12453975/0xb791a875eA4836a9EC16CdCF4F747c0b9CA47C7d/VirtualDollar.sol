// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./draft-ERC20Permit.sol";
import "./ERC20Burnable.sol";
import "./SafeERC20.sol";
import "./Governed.sol";

/// @title Virtual Dollar (DV), A stablecoin pegged to the US Dollar, backed by interest-generating collateral.
contract VirtualDollar is ERC20Permit, ERC20Burnable, Governed {
    using SafeERC20 for IERC20;

    address public minter;
    address public treasury;

    event UpdatedMinter(address indexed previousMinter, address indexed newMinter);
    event UpdatedTreasury(address indexed previousTreasury, address indexed newTreasury);

    constructor(address _treasury) ERC20Permit("Virtual Dollar") ERC20("Virtual Dollar", "DV") {
        require(_treasury != address(0), "treasury-address-is-zero");
        treasury = _treasury;
        emit UpdatedTreasury(address(0), _treasury);
    }

    modifier onlyMinter() {
        require(_msgSender() == minter, "caller-is-not-minter");
        _;
    }

    /**
     * @notice Mint DV, only minter can call this.
     * @param _to Address where DV will be minted
     * @param _amount DV amount to mint
     */
    function mint(address _to, uint256 _amount) external onlyMinter {
        _mint(_to, _amount);
    }

    /**
     * @notice Transfer tokens to multiple recipient
     * @dev Address array and amount array are 1:1 and are in order.
     * @param _recipients array of receipient addresses
     * @param _amounts array of token amounts
     * @return true/false
     */
    function multiTransfer(address[] memory _recipients, uint256[] memory _amounts) external returns (bool) {
        require(_recipients.length == _amounts.length, "input-length-mismatch");
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(transfer(_recipients[i], _amounts[i]), "multi-transfer-failed");
        }
        return true;
    }

    /**
     * @notice Update DV minter address
     * @param _newMinter new minter address
     */
    function updateMinter(address _newMinter) external onlyGovernor {
        require(_newMinter != address(0), "minter-address-is-zero");
        require(minter != _newMinter, "same-minter");
        emit UpdatedMinter(minter, _newMinter);
        minter = _newMinter;
    }

    /**
     * @notice Update DV treasury address
     * @param _newTreasury new treasury address
     */
    function updateTreasury(address _newTreasury) external onlyGovernor {
        require(_newTreasury != address(0), "treasury-address-is-zero");
        require(treasury != _newTreasury, "same-treasury");
        emit UpdatedTreasury(treasury, _newTreasury);
        treasury = _newTreasury;
    }
}
