//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./Errors.sol";
import "./ZetaFallback.sol";
import "./IZetaERC1155.sol";

abstract contract IVendingMachine is AccessControlEnumerable, ZetaFallback {
    bytes32 public constant DEPLOYER = keccak256("DEPLOYER");

    // tokenId => available stock
    mapping(uint256 => uint256) internal _availableStock;

    IZetaERC1155 internal zetaERC1155;

    constructor(address _zetaERC1155) {
        zetaERC1155 = IZetaERC1155(_zetaERC1155);
        _setupRole(DEPLOYER, _msgSender());
    }

    function setZetaERC1155(address _zetaERC1155) external onlyRole(DEPLOYER) {
        zetaERC1155 = IZetaERC1155(_zetaERC1155);
    }

    function name() external view returns (string memory) {
        if (address(zetaERC1155) == address(0)) {
            return "Zeta Vending Machine";
        }

        return zetaERC1155.name();
    }

    function increaseAvailableStock(uint256 id, uint256 stockIncrease)
        external
        virtual
        onlyRole(DEPLOYER)
    {
        _availableStock[id] += stockIncrease;
    }

    function decreaseAvailableStock(uint256 id, uint256 stockDecrease)
        external
        virtual
        onlyRole(DEPLOYER)
    {
        _safeDecreaseAvailableStock(id, stockDecrease);
    }

    function availableStock(uint256 id)
        external
        view
        virtual
        returns (uint256)
    {
        return _availableStock[id];
    }

    function _safeDecreaseAvailableStock(uint256 id, uint256 stockDecrease)
        internal
        virtual
    {
        if (_availableStock[id] < stockDecrease) {
            revert NotEnoughStock();
        }
        unchecked {
            _availableStock[id] -= stockDecrease;
        }
    }

    function mint(uint256 id, uint256 amount) external payable virtual;
}
