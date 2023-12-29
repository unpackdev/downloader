// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./IAuthorizers.sol";
import "./Structs.sol";

/**
 * @title Authorizers
 *
 * @notice Represents logic needed to use authorizers for DEX operations. Implements IAuthorizers interface
 */
contract Authorizers is IAuthorizers, Ownable {
    using ECDSA for bytes32;

    /// @notice Contains all the authorizer
	//slither-disable-next-line immutable-states
    mapping(address => Structs.Authorizer) public authorizers;

    /// @notice Amount of authorizers
    uint256 public authorizerCount = 0;

    /// @notice Contains vacated authorizers
    uint256[] private vacatedAuthorizers;

    /**
     * @notice A function, which returns a minimum of
     * required signatures to authorizer a transaction,
     * according to the number of authorizers.
     * @return uint256 The amount of required signatures
     */
    function minThreshold() public view returns (uint256) {
		require(authorizerCount >= 2, "Not enough authorizer registered");
        return (2 * authorizerCount - 1) / 3 + 1;
    }

    /**
     * @dev see {IAuthorizers-authorize}
     */
    function authorize(bytes32 message_, bytes[] calldata signatures_)
        external
        view
        override
        returns (bool)
    {
        require(authorizerCount > 0, "No authorizer has been registered yet");
        require(signatures_.length >= minThreshold(), "Amount of signatures is not enough");
        bool[] memory used = new bool[](authorizerCount);

        for (uint256 i = 0; i < signatures_.length; i++) {
            address signer = message_.toEthSignedMessageHash().recover(signatures_[i]);

            require(authorizers[signer].isAuthorizer, "Given message is not authorized");
            require(
                !used[authorizers[signer].index],
                "Given signatures contain duplicated authorizers"
            );
            used[authorizers[signer].index] = true;
        }
        return true;
    }

    /**
     * @dev see {IAuthorizers-messageHash}
     */
    function messageHash(
        address to_,
        uint256 amount_,
        bytes calldata txid_,
        uint256 nonce_
    ) external pure override returns (bytes32) {
        return prefixed(
                    keccak256(
                        abi.encodePacked(to_, amount_, txid_, nonce_)
                    )
                );
    }

    /**
     * @notice A function, which appends the ethereum signature prefix to the message hash
     * @param hash The hash of the message
     * @return bytes32 The prefixed message hash
     */
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @notice A function, which is used to add new authorizers
     * @param authorizer_ The address of the authorizer to add
     */
	//slither-disable-next-line similar-names
    function addAuthorizers(address authorizer_) external onlyOwner {
        require(address(authorizer_) != address(0), "Invalid authorizer address was given");
        require(
            !authorizers[authorizer_].isAuthorizer,
            "Authorizer with the given address already exists"
        );
        if (vacatedAuthorizers.length > 0) {
            authorizers[authorizer_] = Structs.Authorizer(
                vacatedAuthorizers[vacatedAuthorizers.length - 1],
                true
            );
            vacatedAuthorizers.pop();
            authorizerCount += 1;
        } else {
            authorizers[authorizer_] = Structs.Authorizer(authorizerCount, true);
            authorizerCount += 1;
        }
    }

    /**
     * @notice A function, which is used to remove authorizers
     * @param authorizer_ The address of the authorizer to remove
     */
	//slither-disable-next-line similar-names
    function removeAuthorizers(address authorizer_) external onlyOwner {
        require(address(authorizer_) != address(0), "Invalid authorizer address was given");
        require(
            authorizers[authorizer_].isAuthorizer,
            "Authorizer with the given address does not exist"
        );
        authorizers[authorizer_].isAuthorizer = false;
        vacatedAuthorizers.push(authorizers[authorizer_].index);
		require(authorizerCount > 0, "Amount of authorizers is incorrect");
        authorizerCount -= 1;
    }
}
