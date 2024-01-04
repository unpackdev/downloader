// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./HHH.sol";

contract HHHmainnet is HHH {
    function initialize(string memory name, string memory symbol, address managementContractAddress, address newMintingAddress) public virtual initializer {
        require(managementContractAddress != address(0), "Management contract address cannot be zero.");
        require(newMintingAddress != address(0), "New minting address cannot be zero.");
        HHH.initialize(name, symbol, managementContractAddress);
        mintingAddress = newMintingAddress;
    }

    address private mintingAddress;

    function changeMintingAddress(address newMintingAddress) external virtual onlyAdmin {
        require(newMintingAddress != address(0), "New minting address cannot be zero.");
        mintingAddress = newMintingAddress;
    }

    /**
     * @dev Creates `amount` new tokens for `mingingAddress`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `ADMIN_ROLE`.
     */
    function mint(uint256 amount) public virtual onlyAdmin {
        // require(managementContract.hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint"); // MODIFIED
        _mint(mintingAddress, amount);
    }

    /**
     * @dev Burns `amount` tokens from `mingingAddress`.
     *
     * See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - the caller must have the `ADMIN_ROLE`.
     */
    function burn(uint256 amount) public virtual override onlyAdmin {
        _burn(mintingAddress, amount);
    }
}
