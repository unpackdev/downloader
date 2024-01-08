// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Strings.sol";
import "./CountersUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./IFactoryERC721.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * croc-pot
 *
 * https://crocpot.io
 *
 * ©2021 v1.0.0
 *
 * Requirements:
 *     - Users may buy a pass NFT in exchange for ETH.
 *          - NFTs are standard ERC721 and thus can be exchanged/moved/traded as desired.
 *          - During purchase of an NFT, funds are split (by default) into wallet addresses.
 *     - Pass types can be extended in the future.
 *     - Sale on external marketplaces permitted.
 */
contract CrocPot
is Initializable,
ContextUpgradeable,
OwnableUpgradeable,
ERC721EnumerableUpgradeable,
ERC721PausableUpgradeable,
ReentrancyGuardUpgradeable,
FactoryERC721 {
    function initialize(string memory name, string memory symbol, address _proxyRegistryAddress) public virtual initializer {
        __CrocPot_init(name, symbol, _proxyRegistryAddress);
    }

    using CountersUpgradeable for CountersUpgradeable.Counter;
    using Strings for uint256;
    using Strings for uint8;

    CountersUpgradeable.Counter private tokenIdTracker;

    address proxyRegistryAddress;

    /// @dev a fund to accept investments, including a destination wallet for transparency/prospectus.
    struct PassType {
        uint256 cost;
        uint256 maxTotal;
        uint256 count;
        /// @dev Used for checking nullity
        address destinationA;
        address destinationB;
    }

    /// @dev an array of Pass types which can be modified in the future.
    mapping(uint8 => PassType) public passTypes;

    /// @dev Mapping of tokenId to passTypeId
    mapping(uint256 => uint8) private passes;

    /**
     * @dev initializes the pot
     */
    function __CrocPot_init(string memory _name, string memory _symbol, address _proxyRegistryAddress) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __Ownable_init_unchained();
        __ERC721_init_unchained(_name, _symbol);
        __ERC721Enumerable_init_unchained();
        __Pausable_init_unchained();
        __ERC721Pausable_init_unchained();
        __CrocPot_init_unchained(_proxyRegistryAddress);
    }

    function __CrocPot_init_unchained(address _proxyRegistryAddress) internal initializer {
        // @dev excluding to reduce gas price till needed
        setProxyAddress(_proxyRegistryAddress);
    }

    /**
     * @dev Allows update of the pass types.
     */
    function setPassType(
        uint8 _passTypeId,
        uint256 _cost,
        uint256 _maxTotal,
        uint256 _count,
        address _destinationA,
        address _destinationB
    ) public
    onlyOwner
    {
        passTypes[_passTypeId] = PassType(_cost, _maxTotal, _count, _destinationA, _destinationB);
    }

    /**
     * @dev Update proxy registry address. Set to 0 to disable.
     */
    function setProxyAddress(
        address _proxyRegistryAddress
    ) public
    onlyOwner
    {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /**
     * @dev For compatibility with OpenSea
     */
    function mint(uint256 _passTypeId, address _toAddress)
    public
    whenNotPaused
    nonReentrant
    {
        /// Only owner or proxy can mint directly.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == _msgSender()
            || owner() == _msgSender()
        );

        /// Ensure the pass type is enabled and able to mint at least 1 pass
        require(canMint(_passTypeId), "CP: pass type cannot be minted");

        /// Mint last.
        _mintPasses(_passTypeId, 1, _toAddress);
    }

    /**
     * @dev for custom purchases, purchasing a single pass only
     */
    function buy(uint8 _passTypeId)
    public
    payable
    whenNotPaused
    nonReentrant
    {
        /// Ensure the pass type is mintable
        require(canMint(_passTypeId), "CP: pass type cannot be minted");

        /// Take payment for anything that isn't a proxy or owner transaction.
        require(passTypes[_passTypeId].cost <= msg.value, "CP: insufficient ETH provided");

        address payable _payableA = payable(passTypes[_passTypeId].destinationA);
        if (passTypes[_passTypeId].destinationB == address(0)) {
            /// Single destination wallet.
            (bool _successA,) = passTypes[_passTypeId].destinationA.call{value : msg.value}("");
            require(_successA, "CP: failed to send ETH");
        } else {
            /// Split destination wallets.
            address payable _payableB = payable(passTypes[_passTypeId].destinationB);

            uint256 halfPrice = msg.value / 2;
            (bool _successA,) = _payableA.call{value : halfPrice}("");
            require(_successA, "CP: failed to send ETH to A");

            (bool _successB,) = _payableB.call{value : halfPrice}("");
            require(_successB, "CP: failed to send ETH to B");
        }

        /// Mint last.
        _mintPasses(_passTypeId, 1, _msgSender());
    }

    /**
     * @dev For OpenSea compatibility
     */
    function canMint(uint256 _passTypeId) override public view returns (bool) {
        uint8 _id = uint8(_passTypeId);
        /// Returns true if a type can be minted for one mor pass
        return passTypes[_id].destinationA != address(0) && passTypes[_id].count < passTypes[_id].maxTotal;
    }

    /**
     * @dev Assume invested funds are received. Mint NFT, save deposit and emit event.
     */
    function _mintPasses(
        uint256 _passTypeId,
        uint256 _amount,
        address _receiver
    ) private
    {
        uint8 _id = uint8(_passTypeId);
        uint256 _tokenId;
        for (uint256 p = 0; p < _amount; p++) {
            _tokenId = tokenIdTracker.current();
            _safeMint(_receiver, _tokenId);
            passes[_tokenId] = _id;
            tokenIdTracker.increment();
        }
    }

    /**
     * @dev Airdrop passes of a type to a group of addresses in one transaction.
     */
    function airdrop(
        uint8 _passTypeId,
        uint256 _amountPerRecipient,
        address[] calldata _recipients
    ) public
    onlyOwner
    {
        for (uint256 i = 0; i < _recipients.length; i++) {
            _mintPasses(_passTypeId, _amountPerRecipient, _recipients[i]);
        }
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     */
    function pause() public virtual onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     */
    function unpause() public virtual onlyOwner {
        _unpause();
    }

    /**
     * @dev For OpenSea compatibility
     */
    function contractURI() public pure returns (string memory) {
        return "https://crocpot.io/token";
    }

    /**
     * @dev For OpenSea compatibility
     */
    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    /**
     * @dev return the count of passTypes that are active for OpenSea
     */
    function numOptions() override public view returns (uint256) {
        for (uint8 i = 0; i < type(uint8).max; i++) {
            if (passTypes[i].destinationA == address(0)) {
                return i;
            }
        }
        return 0;
    }

    /**
     * @dev For OpenSea compatibility
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * For the sake of simplicity, the tokenURI will contain the original deposit data.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override(ERC721Upgradeable)
    returns (string memory) {
        require(_exists(_tokenId), "CP: invalid token");
        uint8 _tokenTypeId = passes[_tokenId];
        return string(abi.encodePacked(
                "https://crocpot.io/token/",
                _tokenId.toString(), ".",
                _tokenTypeId.toString(), ".",
                passTypes[_tokenTypeId].cost.toString(), ".",
                passTypes[_tokenTypeId].maxTotal.toString(), ".",
                passTypes[_tokenTypeId].count.toString()
            ));
    }

    /**
     * @dev list the token URIs for an owner.
     */
    function tokenURIsByOwner(address _owner)
    public
    view
    returns (string[] memory) {
        uint256 _balance = ERC721Upgradeable.balanceOf(_owner);
        string[] memory _uris = new string[](_balance);
        if (_balance > 0) {
            for (uint256 t = 0; t < _balance; t++) {
                _uris[t] = tokenURI(ERC721EnumerableUpgradeable.tokenOfOwnerByIndex(_owner, t));
            }
        }
        return _uris;
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId)
    internal
    virtual
    override(ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    uint256[48] private __gap;
}