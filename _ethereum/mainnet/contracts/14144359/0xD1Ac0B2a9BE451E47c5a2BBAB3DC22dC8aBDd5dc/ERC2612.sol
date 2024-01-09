/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "./EIP712.sol";
import "./IERC2612.sol";
import "./ERC20.sol";

/**
 * @title Permit
 * @notice An alternative to approveWithAuthorization, provided for
 * compatibility with the draft EIP2612 proposed by Uniswap.
 * @dev Differences:
 * - Uses sequential nonce, which restricts transaction submission to one at a
 *   time, or else it will revert
 * - Has deadline (= validBefore - 1) but does not have validAfter
 * - Doesn't have a way to change allowance atomically to prevent ERC20 multiple
 *   withdrawal attacks
 */
abstract contract ERC2612 is ERC20, IERC2612 {
    bytes32 public immutable PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    bytes32 public DOMAIN_SEPARATOR;

    string public version;

    mapping(address => uint256) public nonces;

    /**
     * @notice Initialize EIP712 Domain Separator
     * @param _name        name of contract
     * @param _version     version of contract
     */
    function _initDomainSeparator(string memory _name, string memory _version) internal {
        version = _version;
        DOMAIN_SEPARATOR = EIP712.hashDomainSeperator(_name, _version, address(this));
    }

    /**
     * @notice Verify a signed approval permit and execute if valid
     * @param owner     Token owner's address (Authorizer)
     * @param spender   Spender's address
     * @param value     Amount of allowance
     * @param deadline  The time at which this expires (unix time)
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual {
        require(owner != address(0), "ERC2612/Invalid-address-0");
        require(deadline >= block.timestamp, "ERC2612/Expired-time");

        unchecked {
            bytes32 digest = EIP712.hashMessage(
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            );

            address recovered = ecrecover(digest, v, r, s);
            require(recovered != address(0) && recovered == owner, "ERC2612/Invalid-Signature");
        }

        _approve(owner, spender, value);
    }
}
