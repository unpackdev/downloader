// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./LandNFT_Roles.sol";

/**
 * @dev Adaptation of OpenZeppelin's ERC20Permit
 */
contract LandNFT_Authorization is LandNFT_Roles, EIP712Upgradeable {

    mapping(address => mapping(bytes32 => bool)) internal _authorizationStates;

    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _AUTHORIZATION_TYPEHASH = keccak256("Authorization(address owner,address operator,bool approved,bytes32 nonce,uint256 deadline)");

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function authorize(
        address owner,
        address operator,
        bool approved,
        bytes32 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyOperator {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "LandNFT_Authorization: expired deadline");
        require(
            !_authorizationStates[owner][nonce],
            "LandNFT_Authorization: authorization is used"
        );

        bytes32 structHash = keccak256(
            abi.encode(
                _AUTHORIZATION_TYPEHASH,
                owner,
                operator,
                approved,
                nonce,
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "LandNFT_Authorization: invalid signature");

        _authorizationStates[owner][nonce] = true;

        _setApprovalForAll(owner, operator, approved);

        emit AuthorizationUsed(owner, nonce);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        require(owner != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[owner][operator] = approved;

        emit ApprovalForAll(owner, operator, approved);
    }

    function authorizationState(address authorizer, bytes32 nonce)
        external
        view
        returns (bool)
    {
        return _authorizationStates[authorizer][nonce];
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

}
