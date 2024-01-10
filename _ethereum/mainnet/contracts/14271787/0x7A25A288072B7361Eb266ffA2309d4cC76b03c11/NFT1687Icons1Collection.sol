// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.3;

import "./ERC721.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./ProxyRegistry.sol";
import "./IRoyalties.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";
import "./ContextMixin.sol";
import "./NativeMetaTransaction.sol";

contract NFT1687Icons1Collection is
    ContextMixin,
    ERC721,
    NativeMetaTransaction,
    Ownable,
    ReentrancyGuard,
    AccessControl,
    IRoyalties
{
    using SafeMath for uint256;
    using Address for address;
    using Address for address payable;

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

    uint256 public PRICE;
    uint256 public MAX_TOTAL_MINT;

    // Fair distribution, thundering-herd mitigation and gas-wars prevention
    uint256 public MAX_MINT_PER_TRANSACTION;
    uint256 public MAX_ALLOWED_GAS_FEE;

    bool private _isPublicSaleActive;
    bool private _isPurchaseEnabled;
    string private _contractURI;
    string private _placeholderURI;
    string private _baseTokenURI;
    bool private _baseURIFrozen;
    address private _raribleRoyaltyAddress;
    address private _openSeaProxyRegistryAddress;

    uint256 private _currentTokenId = 0;

    constructor(
        string memory name,
        string memory symbol,
        uint256 price,
        uint256 maxTotalMint,
        uint256 maxMintPerTransaction,
        uint256 maxAllowedGasFee,
        string memory contractURIStr,
        string memory placeholderURI,
        address raribleRoyaltyAddress,
        address openSeaProxyRegistryAddress
    ) ERC721(name, symbol) {
        PRICE = price;
        MAX_TOTAL_MINT = maxTotalMint;
        MAX_MINT_PER_TRANSACTION = maxMintPerTransaction;
        MAX_ALLOWED_GAS_FEE = maxAllowedGasFee;

        _contractURI = contractURIStr;
        _placeholderURI = placeholderURI;
        _raribleRoyaltyAddress = raribleRoyaltyAddress;
        _openSeaProxyRegistryAddress = openSeaProxyRegistryAddress;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());

        _initializeEIP712(name);
    }

    // ADMIN

    function togglePublicSale(bool isActive) external onlyOwner {
        _isPublicSaleActive = isActive;
    }

    function togglePurchaseEnabled(bool isActive) external onlyOwner {
        _isPurchaseEnabled = isActive;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        require(!_baseURIFrozen, 'ERC721/BASE_URI_FROZEN');
        _baseTokenURI = baseURI;
    }

    function freezeBaseURI() external onlyOwner {
        _baseURIFrozen = true;
    }

    function setPlaceholderURI(string memory placeholderURI)
        external
        onlyOwner
    {
        _placeholderURI = placeholderURI;
    }

    function setContractURI(string memory uri) external onlyOwner {
        _contractURI = uri;
    }

    function setMaxAllowedGasFee(uint256 maxFeeGwei) external onlyOwner {
        MAX_ALLOWED_GAS_FEE = maxFeeGwei;
    }

    function setRaribleRoyaltyAddress(address addr) external onlyOwner {
        _raribleRoyaltyAddress = addr;
    }

    function setOpenSeaProxyRegistryAddress(address addr) external onlyOwner {
        _openSeaProxyRegistryAddress = addr;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }

    // PUBLIC

    function totalSupply() public view returns (uint256) {
        return _currentTokenId;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            bytes(_baseTokenURI).length > 0
                ? string(
                    abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId))
                )
                : _placeholderURI;
    }

    function getRaribleV2Royalties(uint256 id)
        external
        view
        override
        returns (LibPart.Part[] memory result)
    {
        result = new LibPart.Part[](1);

        result[0].account = payable(_raribleRoyaltyAddress);
        result[0].value = 10000;
        // 100% of royalty goes to defined address above.
        id;
        // avoid unused param warning
    }

    function getInfo()
        external
        view
        returns (
            uint256 price,
            uint256 totalSupplyNumber,
            uint256 senderBalance,
            uint256 maxTotalMint,
            uint256 maxMintPerTransaction,
            uint256 maxAllowedGasFee,
            bool isPublicSaleActive,
            bool isPurchaseEnabled
        )
    {
        return (
            PRICE,
            this.totalSupply(),
            msg.sender == address(0) ? 0 : this.balanceOf(msg.sender),
            MAX_TOTAL_MINT,
            MAX_MINT_PER_TRANSACTION,
            MAX_ALLOWED_GAS_FEE,
            _isPublicSaleActive,
            _isPurchaseEnabled
        );
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (_openSeaProxyRegistryAddress != address(0)) {
            // On Polygon
            if (block.chainid == 137 || block.chainid == 80001) {
                // if OpenSea's ERC721 Proxy Address is detected, auto-return true
                if (operator == address(_openSeaProxyRegistryAddress)) {
                    return true;
                }
                // On Ethereum
            } else if (
                block.chainid == 1 || block.chainid == 4 || block.chainid == 5
            ) {
                // Whitelist OpenSea proxy contract for easy trading.
                ProxyRegistry proxyRegistry = ProxyRegistry(
                    _openSeaProxyRegistryAddress
                );
                if (address(proxyRegistry.proxies(owner)) == operator) {
                    return true;
                }
            }
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * Mints a specified number of tokens to an address without requiring payment.
     * Caller must be an address with MINTER role.
     */
    function mint(address to, uint256 count) public nonReentrant {
        // Only allow minters to bypass the payment
        require(
            hasRole(MINTER_ROLE, msg.sender),
            'ERC721_COLLECTION/NOT_MINTER_ROLE'
        );

        // Make sure minting is allowed
        requireMintingConditions(count);


        for (uint256 i = 0; i < count; i++) {
            uint256 newTokenId = _getNextTokenId();
            _safeMint(to, newTokenId);
            _incrementTokenId();
        }
    }

    /**
     * Accepts required payment and mints a specified number of tokens to an address.
     * This method also checks if direct purchase is enabled.
     *
     * Supposed to be called by collectors directly (without Flair's escrow)
     */
    function purchase(uint256 count) public payable nonReentrant {
        // Caller cannot be a smart contract to avoid front-running by bots
        // Note this line rejects multi-sigs and contract-based wallets
        require(
            !msg.sender.isContract(),
            'ERC721_COLLECTION/CONTRACT_CANNOT_CALL'
        );

        // Minter must call directly not via a third-party
        // Note this line rejects multi-sigs and contract-based wallets
        require(tx.origin == msg.sender, 'ERC721_COLLECTION/DIRECT_CALL_ONLY');

        // Make sure minting is allowed
        requireMintingConditions(count);

        // Sent value matches required ETH amount
        require(_isPurchaseEnabled, 'ERC721_COLLECTION/PURCHASE_DISABLED');
        require(MAX_MINT_PER_TRANSACTION >= count,'ERC721_COLLECTION/MAX_PURCHASEAMOUNT_EXCEEDED');

        // Sent value matches required ETH amount
        require(
            PRICE * count <= msg.value,
            'ERC721_COLLECTION/INSUFFICIENT_ETH_AMOUNT'
        );

        for (uint256 i = 0; i < count; i++) {
            uint256 newTokenId = _getNextTokenId();
            _safeMint(msg.sender, newTokenId);
            _incrementTokenId();
        }
    }

    /**
     * Useful for when user wants to return tokens to get a refund,
     * or when they want to transfer lots of tokens by paying gas fee only once.
     */
    function transferFromBulk(
        address from,
        address to,
        uint256[] memory tokenIds
    ) public virtual {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            //solhint-disable-next-line max-line-length
            require(
                _isApprovedOrOwner(_msgSender(), tokenIds[i]),
                'ERC721: transfer caller is not owner nor approved'
            );
            _transfer(from, to, tokenIds[i]);
        }
    }

    // PRIVATE
    function requireMintingConditions( uint256 count) internal view {
        require(
            _isPublicSaleActive ,
            'ERC721_COLLECTION/CANNOT_MINT'
        );

        // Total minted tokens must not exceed maximum supply
        require(
            totalSupply() + count <= MAX_TOTAL_MINT,
            'ERC721_COLLECTION/EXCEEDS_MAX_SUPPLY'
        );

    }

    /**
     * Calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * Increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId++;
    }
}
