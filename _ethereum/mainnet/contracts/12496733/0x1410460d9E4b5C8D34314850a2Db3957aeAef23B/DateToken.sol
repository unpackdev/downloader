// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./ProxyRegistry.sol";

contract DateToken is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Pausable,
    Ownable
{
    using ECDSA for bytes32;
    address _proxyRegistryAddress;
    address _metaDataSigner;
    string _baseTokenURI;
    string _contractURI;
    bytes32 constant _maxDaysLookup = hex"001F1C1F1E1F1E1F1F1E1F1E1F";
    uint16 constant _maxPreMintTokenId = 1231;
    uint256 public mintPrice;
    uint256 public cashBackPrice;
    uint256 _totalSupply = 366;
    uint16 _initialSold;
    uint16 public cashBackIndex;

    mapping(uint256 => string) private _tokenCustomURIs;

    constructor(
        string memory baseTokenURI,
        string memory contractUri,
        address proxyRegistryAddress
    ) ERC721("CryptoDates", "DATE") {
        _proxyRegistryAddress = proxyRegistryAddress;
        _contractURI = contractUri;
        _baseTokenURI = baseTokenURI;
        _metaDataSigner = msg.sender;
        _balances[msg.sender] = _totalSupply;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMetaDataSigner(address metaDataSigner) public onlyOwner {
        _metaDataSigner = metaDataSigner;
    }

    function setMintPrice(uint256 mintPriceInWei) public onlyOwner {
        mintPrice = mintPriceInWei;
    }

    function setCashBackPrice(uint256 cashBackPriceInWei)
        public
        payable
        onlyOwner
    {
        cashBackPrice = cashBackPriceInWei;
    }

    function mint(
        address to,
        uint256 tokenId,
        string memory tokenCustomURI
    ) public payable {
        if (owner() != msg.sender) {
            require(mintPrice > 0, "Mint off");
            require(mintPrice <= msg.value, "Ether");
        }

        require(_isValid(tokenId), "Invalid");
        _safeMint(to, tokenId);

        if (tokenId > _maxPreMintTokenId) {
            _totalSupply++;
        }

        if (bytes(tokenCustomURI).length > 0) {
            // No need to check owner or approved here
            _tokenCustomURIs[tokenId] = tokenCustomURI;
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawCashBack() public whenNotPaused {
        require(cashBackPrice > 0, "No cashback");
        require(_initialSold >= 366, "Not yet");
        uint256 tokenId = _fromIndex(cashBackIndex);
        require(ownerOf(tokenId) == msg.sender, "sender");
        uint256 amount = cashBackPrice;
        cashBackPrice = 0;
        payable(msg.sender).transfer(amount);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setURIs(
        string calldata newBaseTokenURI,
        string calldata newContractURI
    ) public onlyOwner {
        _baseTokenURI = newBaseTokenURI;
        _contractURI = newContractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(index < totalSupply(), "index");

        if (_initialSold < 366) {
            if (index < 366) {
                return _fromIndex(index);
            }

            if (_allTokens.length < 366) {
                return super.tokenByIndex(index - 366);
            }
        }

        return super.tokenByIndex(index);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool) {
        if (year % 4 == 0) {
            return (year % 100 != 0) || (year % 400 == 0);
        }
        return false;
    }

    function _fromIndex(uint256 J) private pure returns (uint256) {
        J += 1721060; // offset
        uint256 e =
            4 * (J + 1401 + (((4 * J + 274277) / 146097) * 3) / 4 - 38) + 3;
        uint256 h = 5 * ((e % 1461) / 4) + 2;
        uint256 D = (h % 153) / 5 + 1;
        uint256 M = ((h / 153 + 2) % 12) + 1;
        uint256 Y = (e / 1461) + ((12 + 2 - M) / 12) - 4716;
        return D + (M * 100) + (Y * 10000);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        if (_owners[tokenId] != address(0)) {
            return true;
        }
        // If there isn't an explicit owner, make sure it's a valid, pre-minted token
        return _isValid(tokenId) && tokenId <= _maxPreMintTokenId;
    }

    function _isValid(uint256 tokenId) internal pure returns (bool) {
        uint256 day = tokenId % 100;
        uint256 month = (tokenId % 10000) / 100;

        if (month == 0 || month > 12) {
            return false;
        }

        uint256 year = (tokenId % 100000000) / 10000;

        if (year == 0) {
            year = 2020;
        }

        uint8 maxDays = uint8(_maxDaysLookup[month]);

        if (month == 2 && _isLeapYear(year)) {
            maxDays = 29;
        }

        return day > 0 && day <= maxDays && year < 9999;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address _owner = _owners[tokenId];
        if (_owner != address(0)) {
            return _owner;
        }
        require(_exists(tokenId), "invalid");
        // All valid tokens without an explicit owner are owned by this contract's owner
        return owner();
    }

    function balanceOf(address _owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(_owner != address(0), "0 address");
        return _balances[_owner];
    }

    function setTokenURI(
        uint256 tokenId,
        string memory _tokenURI,
        bytes memory signature
    ) public whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "approved_owner");

        address signer =
            keccak256(abi.encode(tokenId, _tokenURI))
                .toEthSignedMessageHash()
                .recover(signature);

        require(signer == _metaDataSigner, "signature");

        _setTokenURI(tokenId, _tokenURI);
    }

    function setTokenCustomURI(uint256 tokenId, string memory tokenCustomURI)
        public
        whenNotPaused
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "approved_owner");
        _tokenCustomURIs[tokenId] = tokenCustomURI;
    }

    function getTokenCustomURI(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return _tokenCustomURIs[tokenId];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == owner()) {
            _initialSold++;
            cashBackIndex = uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.difficulty,
                            block.timestamp,
                            cashBackIndex,
                            tokenId,
                            from,
                            to
                        )
                    )
                ) % 366
            );
        }
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address _owner, address operator)
        public
        view
        override(ERC721)
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(_owner, operator);
    }

    receive() external payable {}
}
