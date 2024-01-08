// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./IERC2981.sol";

contract BlankArt is ERC721, EIP712, ERC721URIStorage, Ownable, IERC2981 {
    event Initialized(
        address controller,
        address signer,
        string baseURI,
        uint256 mintPrice,
        uint256 maxTokenSupply,
        bool active,
        bool publicMint
    );

    // An event whenever the foundation address is updated
    event FoundationAddressUpdated(address foundationAddress);

    // An event whenever the voucher signer address is updated
    event VoucherSignersUpdated(address foundationAddress, bool active);

    event BaseTokenUriUpdated(string baseTokenURI);

    event PermanentURI(string _value, uint256 indexed _id); // https://docs.opensea.io/docs/metadata-standards

    event Minted(uint256 tokenId, address member, string tokenURI);

    event BlankRoyaltySet(address recipient, uint16 bps);

    // if a token's URI has been locked or not
    mapping(uint256 => uint256) public tokenURILocked;
    // signing domain
    string private constant SIGNING_DOMAIN = "BlankNFT";
    // signature version
    string private constant SIGNATURE_VERSION = "1";
    // address which signs the voucher
    mapping(address => bool) _voucherSigners;
    // Array of _baseURIs
    string[] private _baseURIs;
    // gets incremented to placehold for tokens not minted yet
    uint256 public maxTokenSupply;
    // cost to mint during the public sale
    uint256 public mintPrice;
    // Enables/Disables voucher redemption
    bool public active;
    // Enables/Disables public minting (without a whitelisted voucher)
    bool public publicMint;
    // the address of the platform (for receiving commissions and royalties)
    address payable public foundationAddress;
    // pending withdrawals by account address
    mapping(address => uint256) pendingWithdrawals;
    // Max number of tokens a member can mint
    uint8 public memberMaxMintCount;
    // current token index
    uint256 public tokenIndex;
    // pending withdrawals by account address
    mapping(bytes32 => bool) private voucherClaimed;

    // EIP2981
    struct RoyaltyInfo {
        address recipient;
        uint24 bps;
    }
    RoyaltyInfo public blankRoyalty;

    constructor(
        address payable _foundationAddress,
        address _signer,
        uint256 _maxTokenSupply,
        string memory baseURI,
        uint16 _royaltyBPS
    ) ERC721("BlankArt", "BLANK") EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        memberMaxMintCount = 5;
        foundationAddress = _foundationAddress;
        _voucherSigners[_signer] = true;
        maxTokenSupply = _maxTokenSupply;
        require(maxTokenSupply > 0);
        tokenIndex = 1;
        mintPrice = 0;
        publicMint = false;
        _baseURIs.push("");
        // Default the initial index to 1. The lockTokenURI map will default to 0 for all unmapped tokens.
        _baseURIs.push(baseURI);
        active = true;
        emit Initialized(
            foundationAddress,
            _signer,
            baseURI,
            mintPrice,
            maxTokenSupply,
            active,
            publicMint
        );
        //Setup the initial royalty recipient and amount
        blankRoyalty = RoyaltyInfo(_foundationAddress, _royaltyBPS);
    }

    /// @notice Represents a voucher to claim any un-minted NFT (up to memberMaxMintCount), which has not yet been recorded into the blockchain. A signed voucher can be redeemed for real NFTs using the redeemVoucher function.
    struct BlankNFTVoucher {
        /// @notice address of intended redeemer
        address redeemerAddress;
        /// @notice Expiration of the voucher, expressed in seconds since the Unix epoch.
        uint256 expiration;
        /// @notice The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
        uint256 minPrice;
        /// @notice amount of tokens the voucher can claim.
        uint16 tokenCount;
        /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
        bytes signature;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function isMember(address account) external view returns (bool) {
        return (balanceOf(account) > 0);
    }

    function addBaseURI(string calldata baseURI) external onlyOwner {
        _baseURIs.push(baseURI);
        emit BaseTokenUriUpdated(baseURI);
    }

    // Overridden. Gets the TokenURI based on the locked version.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory _base = "";
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        if (tokenURILocked[tokenId] > 0) _base = _baseURIs[tokenURILocked[tokenId]];
        else _base = _baseURIs[_baseURIs.length - 1];

        return string(abi.encodePacked(_base, Strings.toString(tokenId), ".json"));
    }

    function _checkMemberMintCount(address account) internal view {
        if (balanceOf(account) >= memberMaxMintCount) {
            revert(
                string(
                    abi.encodePacked(
                        "Account ",
                        Strings.toHexString(uint160(account), 20),
                        " has reached its minting limit of ",
                        memberMaxMintCount,
                        ", so cannot mint"
                    )
                )
            );
        }
    }

    // Allows the current foundation address to update to something different
    function updateFoundationAddress(address payable newFoundationAddress) external onlyOwner {
        foundationAddress = newFoundationAddress;

        emit FoundationAddressUpdated(newFoundationAddress);
    }

    // Allows the voucher signing address
    function addVoucherSigner(address newVoucherSigner) external onlyOwner {
        _voucherSigners[newVoucherSigner] = true;

        emit VoucherSignersUpdated(newVoucherSigner, true);
    }

    // Disallows a voucher signing address
    function removeVoucherSigner(address oldVoucherSigner) external onlyOwner {
        _voucherSigners[oldVoucherSigner] = false;

        emit VoucherSignersUpdated(oldVoucherSigner, false);
    }

    // Locks a token's URI from being updated. Only callable by the token owner.
    function lockTokenURI(uint256 tokenId) external {
        // ensure that this token exists
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        // ensure that the token is owned by the caller
        require(ownerOf(tokenId) == msg.sender, "Invalid: Only the owner can lock their token");
        // lock this token's URI from being changed
        tokenURILocked[tokenId] = _baseURIs.length - 1;

        emit PermanentURI(tokenURI(tokenId), tokenId);
    }

    // Updates the mintPrice
    function updateMintPrice(uint256 price) external onlyOwner {
        // Update the mintPrice
        mintPrice = price;
    }

    // Updates the memberMaxMintCount
    function updateMaxMintCount(uint8 _maxMint) external onlyOwner {
        require(_maxMint > 0, "Max mint cannot be zero");
        memberMaxMintCount = _maxMint;
    }

    // Toggle the value of publicMint
    function togglePublicMint() external onlyOwner {
        publicMint = !publicMint;
    }

    // Pause minting
    function toggleActivation() external onlyOwner {
        active = !active;
    }

    function _mintBlank(address owner) private returns (uint256) {
        uint256 tokenId = tokenIndex;
        _checkMemberMintCount(owner);
        super._safeMint(owner, tokenId);
        tokenIndex++;
        string memory tokenUri = tokenURI(tokenId);
        emit Minted(tokenId, owner, tokenUri);
        return tokenId;
    }

    function redeemVoucher(uint256 amount, BlankNFTVoucher calldata voucher)
        public
        payable
        returns (uint256[] memory)
    {
        // make sure voucher redemption period is active
        require(active, "Voucher redemption is not currently active");
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);
        // make sure caller is the redeemer
        require(msg.sender == voucher.redeemerAddress, "Voucher is for a different wallet address");

        // make sure voucher has not expired.
        require(block.timestamp <= voucher.expiration, "Voucher has expired");

        // make sure that the signer is the designated signer
        require(_voucherSigners[signer], "Signature invalid or unauthorized");

        require(
            balanceOf(voucher.redeemerAddress) + amount <= memberMaxMintCount,
            "Amount is more than the minting limit"
        );

        require(tokenIndex + amount <= maxTokenSupply + 1, "All tokens have already been minted");

        // make sure that the redeemer is paying enough to cover the buyer's cost
        require(msg.value >= (voucher.minPrice * amount), "Insufficient funds to redeem");

        require(amount <= voucher.tokenCount, "Amount is more than the voucher allows");

        // make sure voucher has not already been claimed. If true, it HAS been claimed
        require(!voucherClaimed[_hash(voucher)], "Voucher has already been claimed");

        // assign the token directly to the redeemer
        uint256[] memory tokenIds = new uint256[](amount);
        for (uint256 num = 0; num < amount; num++) {
            uint256 tokenId = _mintBlank(voucher.redeemerAddress);
            tokenIds[num] = tokenId;
        }
        // record payment to signer's withdrawal balance
        pendingWithdrawals[foundationAddress] += msg.value;
        voucherClaimed[_hash(voucher)] = true;

        return tokenIds;
    }

    // Public mint function. Whitelisted members will utilize redeemVoucher()
    function mint(uint256 amount) public payable returns (uint256[] memory) {
        require(publicMint && active, "Public minting is not active.");
        require(
            balanceOf(msg.sender) + amount <= memberMaxMintCount,
            "Amount is more than the minting limit"
        );

        require(tokenIndex + amount <= maxTokenSupply + 1, "All tokens have already been minted");

        // make sure that the caller is paying enough to cover the mintPrice
        require(msg.value >= (mintPrice * amount), "Insufficient funds to mint");

        // assign the token directly to the redeemer
        uint256[] memory tokenIds = new uint256[](amount);
        for (uint256 num = 0; num < amount; num++) {
            uint256 tokenId = _mintBlank(msg.sender);
            tokenIds[num] = tokenId;
        }
        // record payment to foundationAddress withdrawal balance
        pendingWithdrawals[foundationAddress] += msg.value;
        return tokenIds;
    }

    /// @notice Transfers all pending withdrawal balance to the caller. Reverts if the caller is not an authorized minter.
    function withdraw() public {
        // IMPORTANT: casting msg.sender to a payable address is only safe if ALL members of the minter role are payable addresses.
        address payable receiver = payable(msg.sender);

        uint256 amount = pendingWithdrawals[receiver];
        // zero account before transfer to prevent re-entrancy attack
        pendingWithdrawals[receiver] = 0;
        receiver.transfer(amount);
    }

    /// @notice Returns the amount of Ether available to the caller to withdraw.
    function availableToWithdraw() public view returns (uint256) {
        return pendingWithdrawals[msg.sender];
    }

    /// @notice Returns a hash of the given BlankNFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hash(BlankNFTVoucher calldata voucher) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BlankNFTVoucher(address redeemerAddress,uint256 expiration,uint256 minPrice,uint16 tokenCount)"
                        ),
                        voucher.redeemerAddress,
                        voucher.expiration,
                        voucher.minPrice,
                        voucher.tokenCount
                    )
                )
            );
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

    /// @notice Verifies the signature for a given BlankNFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An BlankNFTVoucher describing an unminted NFT.
    function _verify(BlankNFTVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param - the tokenId queried for royalty information --Not Utilized, All tokens have the same royalty
    /// @param salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override(IERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        return (
            blankRoyalty.recipient,
            (salePrice * blankRoyalty.bps) / 10000
        );
    }
    
    /// @dev Update the address which receives royalties, and the fee charged
    /// @param recipient address of who should be sent the royalty payment
    /// @param bps uint256 amount of fee (1% == 100)
    function setDefaultRoyalty(address recipient, uint16 bps)
        public
        onlyOwner
    {
        blankRoyalty = RoyaltyInfo(recipient, bps);
        emit BlankRoyaltySet(recipient, bps);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
    }
}
