/*

                                                  .&&&&&&&&&&&%            
                                                  &&&&&&&&&&&&&            
                                                  &&&&&&&&&&&&&            
                                                  %%%&&&&&&&&&%            
                                         %%%%%%%%%%%%%%%%%%%%%%            
                   ./(((((((###          %%%%%%%%%%%%%%%%&((((             
                   ///((((((((##         #%%%%%%%%%%%%%%%                  
                   ////((((((((#         ####%%%%%%%%%%%%                  
                   /////((((((((         #######%#%%%%%%%                  
                   ///////(((((((((######################                  
                    ...........(((((((#######,,,,,,,,,,,                   
  .... ...                     *((((((((((##                               
*************                  ,/(((((((((((/                              
*************                  ,/////(((((((((((((/        .((((((((((((   
*************                        ,///(((((((((/         ((((((((((((   
*************************             ///////////(/         ((((((//////   
.************************.            /////////////       ,/////////////   
      *******************.            +/////////////////////////////////   
      *******************.                  +++///////////////////         
      *************************,            **********************         
       .,,,,,,,,,,,,,******************************************************
                      *****************************************************
                      ****************************,            ************
   *************            **********************,            ************
   *************            **********************,            ************
   ********************************************************.   ............
   *********************************************************               
   *********************************************************               
                ********************************************               
                ********************************************                    

*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./ERC2981Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./ERC1155PausableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ECDSA.sol";

/**
 * @dev {ERC1155} token, including:
 *
 *  - a voucher minter role that allows for token minting (creation) with voucher
 *  - a voucher transfer role that allows for token transfering with voucher
 *  - a pauser role that allows to stop all token transfers
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter, transfer, and pauser
 * roles, as well as the default admin role, which will let it grant minter,
 * transfer and pauser roles to other accounts.
 */
contract CoralNFT is
    Initializable,
    ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC2981Upgradeable,
    ERC1155Upgradeable,
    ERC1155PausableUpgradeable,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable
{
    function initialize(
        string calldata baseUri,
        address admin,
        address voucherMinter,
        address voucherTransferer,
        address pauser
    ) external virtual initializer {
        __CoralNFT_init(
            baseUri,
            admin,
            voucherMinter,
            voucherTransferer,
            pauser
        );
    }

    string public constant name = 'Coral';
    string public constant symbol = 'CORAL';
    string public constant version = '1';
    uint64 public constant MAXIMUM_ROYALTY_BPS = 2000;
    bytes32 public constant VOUCHER_MINTER_ROLE =
        keccak256('VOUCHER_MINTER_ROLE');
    bytes32 public constant VOUCHER_TRANSFER_ROLE =
        keccak256('VOUCHER_TRANSFER_ROLE');
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    bytes32 private constant _MINT_TYPE_HASH =
        keccak256(
            'MintAndTransferVoucher(uint256 tokenID,uint256 amount,address creator,uint256 expirationTime,uint128 royaltyBPS,string uri)'
        );
    bytes32 private constant _TRANSFER_TYPE_HASH =
        keccak256(
            'TransferVoucher(uint256 tokenID,address owner,uint256 expirationTime,uint256 amount,uint256 nonce)'
        );

    /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
    struct MintAndTransferVoucher {
        /// @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
        uint256 tokenID;
        uint256 amount;
        /// @notice The address of creator of this token - the voucher requires that it is signed by with this address.
        address creator;
        /// @notice Transfer voucher can be used until it has reach expiration timestamp.
        uint256 expirationTime;
        /// @notice The percentage of sale amount that will be belong to the royalty owner.
        uint128 royaltyBPS;
        /// @notice The metadata URI to associate with this token.
        string uri;
    }

    /// @notice Represents a permit to transfer NFT on behave of token owner. A signed transfer voucher can be used only by voucher transfer role for a limited of time.
    struct TransferVoucher {
        uint256 tokenID;
        /// @notice The address of owner of this token - the voucher requires that it is signed by with this address.
        address owner;
        /// @notice Transfer voucher can be used until it has reach expiration timestamp.
        uint256 expirationTime;
        /// @notice Limited tranfered amount that can use this voucher to transfer
        uint256 amount;
        /// @notice nonce
        uint256 nonce;
    }

    // Optional mapping for token URIs
    mapping(uint256 => string) internal _tokenURIs;

    mapping(uint256 => uint256) internal _tokenAmounts;

    mapping(uint256 => uint256) internal _transferAmounts;

    event MintVoucherGasUsage(
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 remainingGas
    );

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    function __CoralNFT_init(
        string calldata baseUri,
        address admin,
        address voucherMinter,
        address voucherTransferer,
        address pauser
    ) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC1155_init_unchained(baseUri);
        __Pausable_init_unchained();
        __ERC1155Pausable_init_unchained();
        __ERC1155PresetMinterPauser_init_unchained(
            admin,
            voucherMinter,
            voucherTransferer,
            pauser
        );
        __EIP712_init_unchained(name, version);
        __ReentrancyGuard_init_unchained();
        __ERC2981_init_unchained();
    }

    function __ERC1155PresetMinterPauser_init_unchained(
        address admin,
        address voucherMinter,
        address voucherTransferer,
        address pauser
    ) internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(VOUCHER_MINTER_ROLE, voucherMinter);
        _setupRole(VOUCHER_TRANSFER_ROLE, voucherTransferer);
        _setupRole(PAUSER_ROLE, pauser);
    }

    /// @notice Returns the chain id of the current blockchain.
    /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
    ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function _timeNow() internal view returns (uint256) {
        return block.timestamp;
    }

    function _exists(uint256 tokenID) internal view returns (bool) {
        return _tokenAmounts[tokenID] > 0;
    }

    function _setTokenURI(uint256 tokenID, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenID),
            'ERC721Metadata: URI set of nonexistent token.'
        );
        _tokenURIs[tokenID] = _tokenURI;
    }

    function tokenAmount(uint256 tokenID) public view returns (uint256) {
        return _tokenAmounts[tokenID];
    }

    function uri(uint256 tokenID)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    ERC1155Upgradeable.uri(tokenID),
                    _tokenURIs[tokenID]
                )
            );
    }

    function transferVoucher(
        address to,
        uint256 transferAmount,
        TransferVoucher calldata voucher,
        bytes calldata signature
    ) external nonReentrant {
        require(
            to != address(0),
            'Burning a token is not allowed with voucher.'
        );
        require(voucher.expirationTime > _timeNow(), 'Voucher is expired.');
        require(_exists(voucher.tokenID), 'Token ID does not exist.');
        require(
            hasRole(VOUCHER_TRANSFER_ROLE, _msgSender()),
            'Only an address with transfer role can transfer Token with Voucher.'
        );

        address signer = _verifyTransferVoucher(voucher, signature);
        require(
            signer == voucher.owner,
            'Signer is not the same as owner for this Token.'
        );

        uint256 ownAmount = balanceOf(voucher.owner, voucher.tokenID);
        require(
            ownAmount >= transferAmount,
            'Owner does not have enough token to transfer.'
        );

        uint256 voucherID = uint256(
            keccak256(
                abi.encode(
                    voucher.tokenID,
                    voucher.owner,
                    voucher.expirationTime,
                    voucher.nonce
                )
            )
        );

        uint256 currentTranferAmount = _transferAmounts[voucherID];
        require(
            voucher.amount >= currentTranferAmount + transferAmount,
            'The transfer voucher has reached the limit of transfer amount.'
        );

        _transferAmounts[voucherID] = currentTranferAmount + transferAmount;

        _safeTransferFrom(
            voucher.owner,
            to,
            voucher.tokenID,
            transferAmount,
            ''
        );
    }

    function mintAndTransferVoucher(
        address to,
        uint256 transferAmount,
        MintAndTransferVoucher calldata voucher,
        bytes calldata signature
    ) external returns (uint256) {
        require(
            voucher.amount >= transferAmount,
            'Amount of Token is lower than transfer amount.'
        );

        require(voucher.expirationTime > _timeNow(), 'Voucher is expired.');

        require(
            (voucher.tokenID & 0xffffffffffffffffffff) ==
                uint256(uint160(voucher.creator)) / 2**80,
            'Token ID is not under address space of the creator.'
        );

        require(
            hasRole(VOUCHER_MINTER_ROLE, _msgSender()),
            'Only an address with minter role can mint Token with Voucher.'
        );

        require(
            voucher.royaltyBPS <= MAXIMUM_ROYALTY_BPS,
            'Maximum basis points of royalty is 2000.'
        );

        address signer = _verifyMintVoucher(voucher, signature);
        require(
            signer == voucher.creator,
            'Signer is not the same as creator for this Token.'
        );
        require(
            !_exists(voucher.tokenID),
            'Token ID has already been created.'
        );

        _setRoyaltyInfo(
            voucher.creator,
            voucher.tokenID,
            1,
            voucher.royaltyBPS
        );
        _mint(voucher.creator, voucher.tokenID, voucher.amount, '');
        _setTokenURI(voucher.tokenID, voucher.uri);

        emit MintVoucherGasUsage(
            voucher.creator,
            to,
            voucher.tokenID,
            gasleft()
        );

        if (to != address(0) && transferAmount > 0) {
            _safeTransferFrom(
                voucher.creator,
                to,
                voucher.tokenID,
                transferAmount,
                ''
            );
        }

        return voucher.tokenID;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        _tokenAmounts[id] = amount;
        ERC1155Upgradeable._mint(account, id, amount, data);
    }

    function _verifyMintVoucher(
        MintAndTransferVoucher calldata voucher,
        bytes calldata signature
    ) internal view returns (address) {
        bytes32 digest = _hashMintAndTransferVoucher(voucher);
        return ECDSA.recover(digest, signature);
    }

    function _verifyTransferVoucher(
        TransferVoucher calldata voucher,
        bytes calldata signature
    ) internal view returns (address) {
        bytes32 digest = _hashTransferVoucher(voucher);
        return ECDSA.recover(digest, signature);
    }

    function _hashMintAndTransferVoucher(
        MintAndTransferVoucher calldata voucher
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _MINT_TYPE_HASH,
                        voucher.tokenID,
                        voucher.amount,
                        voucher.creator,
                        voucher.expirationTime,
                        voucher.royaltyBPS,
                        keccak256(bytes(voucher.uri))
                    )
                )
            );
    }

    function _hashTransferVoucher(TransferVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _TRANSFER_TYPE_HASH,
                        voucher.tokenID,
                        voucher.owner,
                        voucher.expirationTime,
                        voucher.amount,
                        voucher.nonce
                    )
                )
            );
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            'ERC1155PresetMinterPauser: must have pauser role to pause'
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            'ERC1155PresetMinterPauser: must have pauser role to unpause'
        );
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC1155Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
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
        override(ERC1155Upgradeable, ERC1155PausableUpgradeable)
    {
        ERC1155PausableUpgradeable._beforeTokenTransfer(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function revokeRole(bytes32 role, address account) public virtual override {
        require(
            role != DEFAULT_ADMIN_ROLE ||
                (role == DEFAULT_ADMIN_ROLE &&
                    AccessControlEnumerableUpgradeable.getRoleMemberCount(
                        DEFAULT_ADMIN_ROLE
                    ) >
                    1),
            'Cannot revoke the only admin role account.'
        );

        super.revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            role != DEFAULT_ADMIN_ROLE ||
                (role == DEFAULT_ADMIN_ROLE &&
                    AccessControlEnumerableUpgradeable.getRoleMemberCount(
                        DEFAULT_ADMIN_ROLE
                    ) >
                    1),
            'Cannot renounce the only admin role account.'
        );

        super.renounceRole(role, account);
    }

    uint256[50] private __gap;
}
