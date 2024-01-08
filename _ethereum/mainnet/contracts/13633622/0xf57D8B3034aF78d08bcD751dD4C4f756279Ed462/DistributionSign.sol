// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ReentrancyGuarded.sol";
import "./EIP712.sol";
import "./EIP1271.sol";
import "./IERC20.sol";
import "./AccessControl.sol";
import "./console.sol";

contract DistributionSign is AccessControl, ReentrancyGuarded, EIP712 {
    event Claimed(address user, uint256 amount);
    event UserBatchAdded(address[] users, uint256[] amounts);
    event UserAdded(address user, uint256 amount);
    event UserRemoved(address user);

    struct Order {
        /* Order maker address. */
        address maker;
        /** The address to which the token will be sent */
        address target;
        /* token address */
        address token;
        /* Order price. */
        uint256 amount;
        /* Order expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order salt to prevent duplicate hashes. */
        uint256 salt;
    }

    mapping(address => uint256) public claimed;
    mapping(address => mapping(bytes32 => uint256)) public fills;

    bytes internal personalSignPrefix = "\x19Ethereum Signed Message:\n";
    /* Order typehash for EIP 712 compatibility. */
    bytes32 constant ORDER_TYPEHASH =
        keccak256(
            "Order(address maker,address target,address token,uint256 amount,uint256 expirationTime,uint256 salt)"
        );

    IERC20 public token;
    string public constant name = "Distribution";

    string public constant version = "1";

    constructor(uint256 chainId) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        DOMAIN_SEPARATOR = hash(
            EIP712Domain({
                name: name,
                version: version,
                chainId: chainId,
                verifyingContract: address(this)
            })
        );
    }

    function hashOrder(Order memory order) public pure returns (bytes32 hash) {
        /* Per EIP 712. */
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.maker,
                    order.target,
                    order.token,
                    order.amount,
                    order.expirationTime,
                    order.salt
                )
            );
    }

    function hashToSign(bytes32 orderHash) public view returns (bytes32 hash) {
        /* Calculate the string a user must sign. */
        return
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, orderHash)
            );
    }

    function isClaimed(address _user) public view returns (bool) {
        if (claimed[_user] > 0) {
            return true;
        }
    }

    function isFilled(address _owner, bytes32 _ownerOrderHash)
        external
        view
        returns (bool)
    {
        if (fills[_owner][_ownerOrderHash] > 0) {
            return true;
        }
    }

    function validateOrderAuthorization(
        bytes32 hash,
        address maker,
        bytes memory signature
    ) public view returns (bool) {
        /* Calculate hash which must be signed. */
        bytes32 calculatedHashToSign = hashToSign(hash);

        (uint8 v, bytes32 r, bytes32 s) = abi.decode(
            signature,
            (uint8, bytes32, bytes32)
        );

        if (ecrecover(calculatedHashToSign, v, r, s) == maker) {
            return true;
        } else if (
            ecrecover(
                keccak256(
                    abi.encodePacked(
                        personalSignPrefix,
                        "32",
                        calculatedHashToSign
                    )
                ),
                v,
                r,
                s
            ) == maker
        ) {
            return true;
        }

        return false;
    }

    function validateOrderParameters(Order memory order, bytes32)
        public
        view
        returns (bool)
    {
        /* Order must be listed and not be expired. */
        if (
            order.expirationTime != 0 && order.expirationTime <= block.timestamp
        ) {
            return false;
        }

        return true;
    }

    function claim(
        Order memory owner,
        Order memory claimer,
        bytes memory signatures
    ) public reentrancyGuard {
        /* CHECKS */
        /* Check first order validity. */
        require(
            msg.sender == owner.target,
            "claim: You have no right for this"
        );

        /* Calculate first order hash. */
        bytes32 firstHash = hashOrder(owner);

        /* Check first order validity. */
        require(
            validateOrderParameters(owner, firstHash),
            "claim: First order has invalid parameters"
        );

        /* Calculate second order hash. */
        bytes32 secondHash = hashOrder(claimer);

        /* Check second order validity. */
        require(
            validateOrderParameters(claimer, secondHash),
            "claim: Second order has invalid parameters"
        );

        require(isClaimed(owner.target),"claim: You already claimed");

        require(
            fills[owner.maker][firstHash] == 0,
            "claim: This order already filled"
        );

        /* Prevent self-matching (possibly unnecessary, but safer). */
        require(
            firstHash != secondHash,
            "claim: Self-matching orders is prohibited"
        );
        {
            /* Calculate signatures (must be awkwardly decoded here due to stack size constraints). */
            (bytes memory firstSignature, bytes memory secondSignature) = abi
                .decode(signatures, (bytes, bytes));

            /* Check first order authorization. */
            require(
                validateOrderAuthorization(
                    firstHash,
                    owner.maker,
                    firstSignature
                ),
                "claim: First order failed authorization"
            );

            /* Check second order authorization. */
            require(
                validateOrderAuthorization(
                    secondHash,
                    claimer.maker,
                    secondSignature
                ),
                "claim: Second order failed authorization"
            );
        }
        
        IERC20(owner.token).transferFrom(
            owner.maker,
            owner.target,
            owner.amount
        );

        fills[owner.maker][firstHash] = owner.amount;
        claimed[owner.target] = owner.amount;

        emit Claimed(claimer.maker, owner.amount);
    }
}
