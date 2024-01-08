// contracts/HghEthereum.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Enumerable.sol";
import "./MintableERC20.sol";

contract HghEthereum is 
    ERC20,
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin,
    IMintableERC20 {
/*
    Rupees contract using Cheeth as a blueprint. We love Anonymice.
    Contract functions for staking heroes to earn rupees to use for
    boss fights, upgrades, and eventually Apprentice training, and upgrades.
*/

    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    constructor() ERC20("Matic Mike Juice", "HGH") {
        _setupContractId("HGHMintableERC20");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, _msgSender());
        _initializeEIP712("Matic Mike Juice");
    }

    /* Polygon PoS Bridge Functions */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    /**
     * @dev See {IMintableERC20-mint}.
     */
    function mint(address user, uint256 amount) external override only(PREDICATE_ROLE) {
        _mint(user, amount);
    }
    /* End Polygon PoS Bridge Functions */
}