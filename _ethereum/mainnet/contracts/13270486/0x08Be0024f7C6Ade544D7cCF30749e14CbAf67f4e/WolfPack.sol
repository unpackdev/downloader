// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";

import "./IERC721EnumerableUpgradeable.sol";

import "./IERC2981Upgradeable.sol";

import "./console.sol";

contract WolfPack is
    Initializable,
    OwnableUpgradeable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter internal _tokenIds;
    // Base URI
    string private WP_PROVENANCE;

    uint256 private _totalSupply;
    uint256 private _safeMintNumber;
    uint256 private _price;
    uint256 private _preReleaseMint;
    uint256 private _maxMint;
    uint256 private _pack; // for giveaways
    bool private _isPreRelease;
    bool private saleIsActive;
    // Address of the royalties recipient
    address private _royaltiesReceiver;
    // Percentage of each sale to pay as royalties
    uint256 public _royaltiesPercentage;

    mapping(uint256 => address) private mintedBy;
    mapping(uint256 => address) private tokenHolder;

    event Mint(uint256 indexed tokenId, address indexed minter);

    /* Inits Contract */
    function initialize() public initializer {
        __ERC721_init("The Wolf Pack", "Wolf Pack");
        __ERC721Enumerable_init();
        __Ownable_init();
        setBaseURI(
            "https://ipfs.io/ipfs/bafkreifnt37vtfgo53mfrfn6oipdxzpcxp3ocoumuuuukgoijk7ei3isvi/"
        );
        _totalSupply = 5555;
        _preReleaseMint = 1500;
        _pack = 150;
        _safeMintNumber = _totalSupply - _pack;
        _price = 1000000000000000;
        _isPreRelease = true;
        saleIsActive = false;
        _royaltiesReceiver = 0x545646a11E214F63fddb05591a10478964e07F9f;
        // Percentage of each sale to pay as royalties
        _royaltiesPercentage = 7;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return WP_PROVENANCE;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        WP_PROVENANCE = baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(0x8cd80083f4A10C2b05a767B5aA21235eB3E36923).transfer(balance);
    }

    function preSaleState() public view returns (bool) {
        return _isPreRelease;
    }

    function saleState() public view returns (bool) {
        return saleIsActive;
    }

    function startSale() public onlyOwner {
        saleIsActive = true;
    }

    function toggleSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function getOwnerTokenBanance(address _owner)
        public
        view
        returns (uint256)
    {
        uint256 tokenCount = balanceOf(_owner);
        return tokenCount;
    }

    function OwnerNFTList(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function getTokenMinter(uint256 _tokenId) public view returns (address) {
        // You can get values from a nested mapping
        // even when it is not initialized
        return tokenHolder[_tokenId];
    }

    function getTokenMinters() public view returns (address[] memory result) {
        // You can get values from a nested mapping
        // even when it is not initialized
        uint256 tokenCount = _tokenIds.current();
        result = new address[](tokenCount);

        if (tokenCount == 0) {
            return new address[](0);
        } else {
            for (uint256 i = 0; i < tokenCount; i++) {
                result[i] = getTokenHolder(i);
            }
            return result;
        }
    }

    function getTokenHolder(uint256 _tokenId) public view returns (address) {
        // You can get values from a nested mapping
        // even when it is not initialized
        return tokenHolder[_tokenId];
    }

    function getTokenHolders() public view returns (address[] memory result) {
        // You can get values from a nested mapping
        // even when it is not initialized
        uint256 tokenCount = _tokenIds.current();
        result = new address[](tokenCount);

        if (tokenCount == 0) {
            return new address[](0);
        } else {
            for (uint256 i = 0; i < tokenCount; i++) {
                result[i] = getTokenHolder(i);
            }
            return result;
        }
    }

    function setTokenHolder(address _addr1, uint256 _tokenId) internal {
        tokenHolder[_tokenId] = _addr1;
    }

    function preSaleMint(uint8 _amount) public payable {
        uint256 tokenCount = _tokenIds.current();
        require(_isPreRelease, "Sale must be active to mint Wolf");
        require(
            _amount > 0 && _amount <= 3,
            "Exceeds Maximum Mints Per Transaction"
        );
        require(
            tokenCount.add(_amount) <= _preReleaseMint,
            "Purchase Would Exceed Max Supply of The Pack"
        );
        require(
            msg.value >= _price.mul(_amount),
            "Ether value sent is not correct"
        );

        require(
            getOwnerTokenBanance(msg.sender) <= 100,
            "Max Wolves Purchased"
        );

        for (uint256 i = 0; i < _amount; i++) {
            if (tokenCount < _preReleaseMint) {
                _tokenIds.increment();

                uint256 tokenId = _tokenIds.current();
                mintedBy[tokenId] = msg.sender;
                setTokenHolder(msg.sender, tokenId);
                _safeMint(msg.sender, tokenId);
                emit Mint(tokenId, msg.sender);
            }
        }
    }

    function mint(uint8 _amount) public payable {
        uint256 tokenCount = _tokenIds.current();
        require(saleIsActive, "Sale must be active to mint Wolf");
        require(
            _amount > 0 && _amount <= 20,
            "Exceeds Maximum Mints Per Transaction"
        );
        require(
            tokenCount.add(_amount) <= _safeMintNumber,
            "Purchase Would Exceed Max Supply of The Pack"
        );
        require(
            msg.value >= _price.mul(_amount),
            "Ether value sent is not correct"
        );
        require(
            getOwnerTokenBanance(msg.sender) <= 100,
            "Max Wolves Purchased"
        );

        for (uint256 i = 0; i < _amount; i++) {
            if (tokenCount < _safeMintNumber) {
                _tokenIds.increment();

                uint256 tokenId = _tokenIds.current();
                mintedBy[tokenId] = msg.sender;
                setTokenHolder(msg.sender, tokenId);
                _safeMint(msg.sender, tokenId);
                emit Mint(tokenId, msg.sender);
            }
        }
    }

    function mintFromReserve(address _to, uint256 _amount) external onlyOwner {
        uint256 tokenId = _tokenIds.current();
        require(_amount <= _pack, "pack is too small!");
        require(
            tokenId.add(_amount) <= _safeMintNumber,
            "Purchase would exceed max supply of The Pack"
        );

        for (uint256 i; i < _amount; i++) {
            _tokenIds.increment();
            _safeMint(_to, tokenId);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable) {
        setTokenHolder(to, tokenId);

        super._transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal override(ERC721Upgradeable) {
        setTokenHolder(to, tokenId);
        super._safeTransfer(from, to, tokenId, _data);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Informs callers that this contract supports ERC2981
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _nftId - the NFT asset queried for royalty information
    /// @param _salePrice - sale price of the NFT asset specified by _nftId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _value sale price
    function royaltyInfo(uint256 _nftId, uint256 _salePrice)
        external
        view
        returns (
            address receiver,
            uint256 royaltyAmount,
            uint256 tokenId
        )
    {
        uint256 _royalties = (_salePrice * _royaltiesPercentage) / 100;
        return (_royaltiesReceiver, _royalties, _nftId);
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
        onlyOwner
    {
        require(newRoyaltiesReceiver != _royaltiesReceiver); // dev: Same address
        _royaltiesReceiver = newRoyaltiesReceiver;
    }

    /// @notice Changes the royalties' percentage of contract
    /// @param newRoyalties - address of the new royalties recipient
    function setRoyalties(uint256 newRoyalties) external onlyOwner {
        require(newRoyalties != _royaltiesPercentage); // dev: Same address
        _royaltiesPercentage = newRoyalties;
    }
}
