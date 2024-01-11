// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./AccessControlMixin.sol";
import "./NativeMetaTransaction.sol";
import "./ContextMixin.sol";
import "./IMintableERC20.sol";

/**
 * PROS is a token native to the Ethereum and Polygon POS blockchains.
 * The token is built as an asset mintable on Polygon that can be transferred to the Ethereum network.
 * https://docs.polygon.technology/docs/develop/ethereum-polygon/mintable-assets/
 */
contract PROSToken is
    ERC20,
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin,
    IMintableERC20,
    ERC20Burnable
{
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

     constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
        _setupContractId("PROSToken");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, _msgSender());

        _initializeEIP712(name_);
    }

    /**
     * @dev See {IMintableERC20-mint}.
     */
    function mint(address user, uint256 amount) external override only(PREDICATE_ROLE) {
        _mint(user, amount);
    }

    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}
