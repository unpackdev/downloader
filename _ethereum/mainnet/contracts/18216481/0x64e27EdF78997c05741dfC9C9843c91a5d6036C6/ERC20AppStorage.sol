// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./IERC20Upgradeable.sol";

library ERC20AppStorage {
    bytes32 private constant STORAGE_SLOT =
        keccak256("niftykit.apps.erc20.storage");

    struct Layout {
        IERC20Upgradeable _erc20ActiveContract;
        mapping(address => uint256) _erc20Revenues;
        mapping(address => IERC20Upgradeable) _erc20ContractsByAddress;
        mapping(uint256 => IERC20Upgradeable) _erc20ContractsByIndex;
        uint256 _erc20ContractsCount;
        uint256 _erc20Price;
        bool _erc20SaleActive;
        bool _erc20PresaleActive;
    }

    function layout() internal pure returns (Layout storage ds) {
        bytes32 position = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }
}
