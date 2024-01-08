// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IRootMintableERC20.sol";
import "./NativeMetaTransaction.sol";
import "./ContextMixin.sol";
import "./AccessControlMixin.sol";

contract RootMintableERC20 is ERC20, AccessControlMixin, NativeMetaTransaction, ContextMixin, IRootMintableERC20 {
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    constructor(string memory name_, string memory symbol_, address predicate_) ERC20(name_, symbol_) {
        require(predicate_ != address(0), "Predicate address cannot be 0");
        _setupContractId("RootMintableERC20");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, predicate_);

        
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
        returns (address)
    {
        return ContextMixin.msgSender();
    }
}