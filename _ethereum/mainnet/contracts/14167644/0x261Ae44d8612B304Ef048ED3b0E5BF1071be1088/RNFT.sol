//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import "./ERC721.sol";
import "./AccessControl.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./Strings.sol";
import "./IERC2981.sol";

contract RNFT is ERC721, EIP712, AccessControl {
    // Minter role id
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    // Signing information to redeep voucher
    string private constant SIGNING_DOMAIN = "RHealth-NFT-Voucher";
    string private constant SIGNATURE_VERSION = "1";
    // Base URI of the token metadata
    string private _baseURIextended = "https://nft.rejuvenan.com/api/token/";
    string private _contractUriExtended =
        "https://nft.rejuvenan.com/api/contract/rhealth-nft";
    // Address of the royalties recipient
    address private _royaltiesReceiver;
    // Percentage of each sale to pay as royalties
    uint256 public constant royaltiesPercentage = 500;
    // Pending withdrawals
    mapping(address => uint256) pendingWithdrawals;
    // Events
    event Mint(uint256 tokenId, address recipient);

    constructor()
        ERC721("RHealth NFT", "RNFT")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        _royaltiesReceiver = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
    struct NFTVoucher {
        /// @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
        uint256 tokenId;
        /// @notice The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
        uint256 minPrice;
        /// @notice The address to wich the sale amount is transfered.
        address sellerAddress;
        /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
        bytes signature;
    }

    /**
     * @dev Sets Base URI for the metadata
     * @param baseUri_ Base URI, where the token's ID could be appended at the end of it
     */
    function setBaseUri(string memory baseUri_)
        external
        onlyRole(MANAGER_ROLE)
    {
        _baseURIextended = baseUri_;
    }

    /**
     * @dev Sets Contract URI for the metadata
     * @param contractUri_ Contract URI, where the contract information can be fetched
     */
    function setContarctUri(string memory contractUri_)
        external
        onlyRole(MANAGER_ROLE)
    {
        _contractUriExtended = contractUri_;
    }

    /// @notice Getter function for _royaltiesReceiver
    /// @return the address of the royalties recipient
    function royaltiesReceiver() external view returns (address) {
        return _royaltiesReceiver;
    }

    /// @notice Changes the royalties' recipient address (in case rights are
    ///         transferred for instance)
    /// @param newRoyaltiesReceiver - address of the new royalties recipient
    function setRoyaltiesReceiver(address newRoyaltiesReceiver)
        external
        onlyRole(MANAGER_ROLE)
    {
        require(newRoyaltiesReceiver != _royaltiesReceiver); // dev: Same address
        _royaltiesReceiver = newRoyaltiesReceiver;
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 _royalties = (_salePrice * royaltiesPercentage) / 10000;
        return (_royaltiesReceiver, _royalties);
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

    /// @notice Getter function for baseTokenURI
    /// @return the base uri of this contract
    function baseTokenURI() public view returns (string memory) {
        return _baseURIextended;
    }

    /// @notice Getter function for contractURI
    /// @return the Contract URI of this contract
    function contractURI() public view returns (string memory) {
        return _contractUriExtended;
    }

    /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
    /// @param redeemer The address of the account which will receive the NFT upon success.
    /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
    function redeem(address redeemer, NFTVoucher calldata voucher)
        public
        payable
        returns (uint256)
    {
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);

        // make sure that the signer is authorized to mint NFTs
        require(
            hasRole(MINTER_ROLE, signer),
            "Signature invalid or unauthorized"
        );

        // make sure that the redeemer is paying enough to cover the buyer's cost
        require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");

        // first assign the token to the signer, to establish provenance on-chain
        _mint(signer, voucher.tokenId);

        // transfer the token to the redeemer
        _transfer(signer, redeemer, voucher.tokenId);

        // record payment to signer's withdrawal balance
        pendingWithdrawals[voucher.sellerAddress] += msg.value;
        emit Mint(voucher.tokenId, redeemer);
        return voucher.tokenId;
    }

    /// @notice Transfers all pending withdrawal balance to the caller. Reverts if the caller is not an authorized minter.
    function withdraw() public onlyRole(MINTER_ROLE) {
        // IMPORTANT: casting msg.sender to a payable address is only safe if ALL members of the minter role are payable addresses.
        address payable receiver = payable(msg.sender);

        uint256 amount = pendingWithdrawals[receiver];
        // zero account before transfer to prevent re-entrancy attack
        pendingWithdrawals[receiver] = 0;
        receiver.transfer(amount);
    }

    /// @notice Retuns the amount of Ether available to the caller to withdraw.
    function availableToWithdraw() public view returns (uint256) {
        return pendingWithdrawals[msg.sender];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721)
        returns (bool)
    {
        if (interfaceId == type(IERC2981).interfaceId) {
            return true;
        }
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hash(NFTVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFTVoucher(uint256 tokenId,uint256 minPrice,address sellerAddress)"
                        ),
                        voucher.tokenId,
                        voucher.minPrice,
                        voucher.sellerAddress
                    )
                )
            );
    }

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An NFTVoucher describing an unminted NFT.
    function _verify(NFTVoucher calldata voucher)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    /** Overrides ERC-721's _baseURI function */
    function _baseURI() internal view override returns (string memory) {
        return _baseURIextended;
    }
}
