pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC1155PresetMinterPauserUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract BottoRetroactiveRewardV2 is
    ERC1155PresetMinterPauserUpgradeable,
    ERC1155SupplyUpgradeable,
    EIP712Upgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Mapping from token ID to minimum nonce accepted for MintPermits to mint this token
    mapping(uint256 => uint256) private _mintPermitMinimumNonces;

    /// The collection name
    string public constant name = "Ceci n\u0027est pas un Botto";

    /// Role to call setURI method
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");

    struct RedeemPermit {
        uint256 tokenId; // the id of the token to be minted
        uint256 nonce; //
        address currency; // using the zero address means Ether
        uint256 minimumPrice; // price in wei
        address payee; // address that receives the transfered funds
        uint256 kickoff; // block epoch timestamp in seconds when the permit is valid
        uint256 deadline; // block epoch timestamp in seconds when the permit is expired
        address recipient; // using the zero address means anyone can claim
        bytes data;
    }

    bytes32 public constant REDEEM_PERMIT_TYPEHASH =
        keccak256(
            "RedeemPermit(uint256 tokenId,uint256 nonce,address currency,uint256 minimumPrice,address payee,uint256 kickoff,uint256 deadline,address recipient,bytes data)"
        );

    function initialize(string memory uri_)
        public
        virtual
        override
        initializer
    {
        ERC1155PresetMinterPauserUpgradeable.initialize(uri_);
        ERC1155SupplyUpgradeable.__ERC1155Supply_init_unchained();
        EIP712Upgradeable.__EIP712_init("BottoNFT", "1.0.0");

        _grantRole(URI_SETTER_ROLE, _msgSender());
    }

    function setURI(string memory newuri_) external virtual {
        require(
            hasRole(URI_SETTER_ROLE, _msgSender()),
            "BottoRetroactiveReward: must have uri setter role"
        );

        _setURI(newuri_);
    }

    /**
     * @dev revoke all RedeemPermits issued for token ID `tokenId_` with nonce lower than `nonce_`
     * @param tokenId_ the token ID for which to revoke permits
     * @param nonce_ to cancel a permit for a given tokenId we suggest passing the account transaction count as `nonce_`
     */
    function revokePermitsUnderNonce(uint256 tokenId_, uint256 nonce_)
        external
        virtual
    {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "BottoRetroactiveReward: must have minter role"
        );

        _mintPermitMinimumNonces[tokenId_] = nonce_ + 1;
    }

    /**
     * @dev redeem a NFT using a valid permit
     * @param permit_ The RedeemPermit signed by user with `MINTER_ROLE`
     * @param recipient_ The address that will receive the newly minted NFT
     * @param signature_ The secp256k1 permit signature
     */
    function redeem(
        RedeemPermit calldata permit_,
        address recipient_,
        bytes memory signature_
    ) external payable virtual {
        address signer = _verify(_hash(permit_), signature_);

        // Make sure that the signer is authorized to mint NFTs and permit is valid
        require(
            hasRole(MINTER_ROLE, signer),
            "BottoRetroactiveReward: signature invalid"
        );

        // Check if permit is revoked
        require(
            permit_.nonce >= _mintPermitMinimumNonces[permit_.tokenId],
            "BottoRetroactiveReward: permit revoked"
        );

        // Check if permit is expired
        require(
            permit_.kickoff <= block.timestamp &&
                permit_.deadline >= block.timestamp,
            "BottoRetroactiveReward: permit expired"
        );

        // Check if recipient matches permit
        if (permit_.recipient != address(0)) {
            require(
                recipient_ == permit_.recipient,
                "BottoRetroactiveReward: recipient does not match permit"
            );
        }

        // Check if to pay using Ether or ERC20
        if (permit_.minimumPrice != 0) {
            if (permit_.currency == address(0)) {
                require(
                    msg.value >= permit_.minimumPrice,
                    "BottoRetroactiveReward: transaction value under minimum price"
                );

                (bool success, ) = permit_.payee.call{value: msg.value}("");
                require(success, "BottoRetroactiveReward: transfer failed.");
            } else {
                IERC20Upgradeable token = IERC20Upgradeable(permit_.currency);
                token.safeTransferFrom(
                    _msgSender(),
                    permit_.payee,
                    permit_.minimumPrice
                );
            }
        }

        // first assign the token to the signer, to establish provenance on-chain
        _mint(signer, permit_.tokenId, 1, "");
        _safeTransferFrom(signer, recipient_, permit_.tokenId, 1, "");
    }

    /**
     * @dev recover ERC20 tokens
     * @param token_ The ERC20 token contract address
     * @param amount_ The amount to recover
     * @param recipient_ The recipient of the recovered tokens
     */
    function recover(
        address token_,
        uint256 amount_,
        address payable recipient_
    ) external virtual {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "BottoRetroactiveReward: must have admin role"
        );

        require(amount_ > 0, "BottoRetroactiveReward: invalid amount");

        IERC20Upgradeable token = IERC20Upgradeable(token_);
        token.safeTransfer(recipient_, amount_);
    }

    /**
     * @dev see https://eips.ethereum.org/EIPS/eip-712#definition-of-encodedata
     */
    function _hash(RedeemPermit memory permit_)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        REDEEM_PERMIT_TYPEHASH,
                        permit_.tokenId,
                        permit_.nonce,
                        permit_.currency,
                        permit_.minimumPrice,
                        permit_.payee,
                        permit_.kickoff,
                        permit_.deadline,
                        permit_.recipient,
                        keccak256(permit_.data)
                    )
                )
            );
    }

    /**
     * @dev recover signer from `signature_`
     */
    function _verify(bytes32 digest_, bytes memory signature_)
        internal
        pure
        returns (address)
    {
        return ECDSAUpgradeable.recover(digest_, signature_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC1155PresetMinterPauserUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override(ERC1155PresetMinterPauserUpgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                // Check total cap when minting, should never exceed one.
                require(
                    totalSupply(ids[i]) <= 1,
                    "BottoRetroactiveReward: exceeding total supply cap"
                );
            }
        }
    }
}
