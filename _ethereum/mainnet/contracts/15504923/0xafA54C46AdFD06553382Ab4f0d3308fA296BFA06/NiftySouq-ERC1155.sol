// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./ERC1155Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Counters.sol";

struct NftData {
    string uri;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    address minter;
    uint256 firstSaleQuantity;
}

struct MintData {
    string uri;
    address minter;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 quantity;
}

struct LazyMintData {
    string uri;
    address minter;
    address buyer;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 quantity;
    uint256 soldQuantity;
}

contract NiftySouq1155V2 is ERC1155Upgradeable, AccessControlUpgradeable {
    using Counters for Counters.Counter;

    event PayoutTransfer(address indexed withdrawer, uint256 indexed amount);

    string private _baseTokenURI;
    address private _niftyMarketplace;
    address private _owner;

    uint256 public constant PERCENT_UNIT = 1e4;

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => NftData) public nftInfos;
    mapping(uint256 => uint256) private _totalSupply;

    modifier isNiftyMarketplace() {
        require(
            msg.sender == _niftyMarketplace,
            "Nifty1155: unauthorized. not niftysouq marketplace"
        );
        _;
    }

    modifier validatePayouts(
        address[] calldata receivers_,
        uint256[] calldata percentage_
    ) {
        require(
            percentage_.length == receivers_.length,
            "Nifty1155: payout receivers list length and percentage list length should be equal"
        );

        uint256 sum = 0;
        for (uint256 i = 0; i < percentage_.length; i++) {
            require(
                percentage_[i] > 0,
                "Nifty1155: zero payout percentage is invalid"
            );
            require(
                receivers_[i] != address(0),
                "Nifty1155: empty payout receivers address is invalid"
            );
            sum = sum + percentage_[i];
        }

        require(sum <= PERCENT_UNIT, "Nifty1155: payout percentage overflow");
        _;
    }

    function initialize(string memory baseURI_, address niftySouqMarketplace_)
        public
        initializer
    {
        __ERC1155_init(_baseTokenURI);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _owner = msg.sender;
        _baseTokenURI = baseURI_;
        _niftyMarketplace = niftySouqMarketplace_;
    }

    function setBaseURI(string memory baseUri_) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Nifty1155: unauthorized. not admin"
        );
        _baseTokenURI = baseUri_;
    }

    function getAll() public view returns (NftData[] memory nfts_) {
        for (uint256 i = 1; i < _tokenIdCounter.current(); i++) {
            nfts_[i] = nftInfos[i];
        }
    }

    function getNftInfo(uint256 tokenId_)
        public
        view
        returns (NftData memory nfts_)
    {
        nfts_ = nftInfos[tokenId_];
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(exists(tokenId), "Nifty1155: nft doesn't exists");
        return string(abi.encodePacked(_baseTokenURI, nftInfos[tokenId].uri));
    }

    function totalSupply(uint256 tokenId)
        public
        view
        virtual
        returns (uint256 totalSupply_)
    {
        totalSupply_ = _totalSupply[tokenId];
    }

    function exists(uint256 tokenId)
        public
        view
        virtual
        returns (bool exists_)
    {
        exists_ = totalSupply(tokenId) > 0;
    }

    function mint(MintData calldata mintData_)
        public
        validatePayouts(mintData_.investors, mintData_.revenues)
        validatePayouts(mintData_.creators, mintData_.royalties)
        isNiftyMarketplace
        returns (uint256 tokenId_)
    {
        _tokenIdCounter.increment();
        tokenId_ = _tokenIdCounter.current();

        _mint(mintData_.minter, tokenId_, mintData_.quantity, "");

        nftInfos[tokenId_] = NftData(
            mintData_.uri,
            mintData_.creators,
            mintData_.royalties,
            mintData_.investors,
            mintData_.revenues,
            msg.sender,
            0
        );
        _totalSupply[tokenId_] = mintData_.quantity;
    }

    function lazyMint(LazyMintData calldata lazyMintData_)
        public
        validatePayouts(lazyMintData_.investors, lazyMintData_.revenues)
        validatePayouts(lazyMintData_.creators, lazyMintData_.royalties)
        isNiftyMarketplace
        returns (uint256 tokenId_)
    {
        _tokenIdCounter.increment();
        tokenId_ = _tokenIdCounter.current();
        uint256 balanceQuantity = lazyMintData_.quantity -
            lazyMintData_.soldQuantity;
        _mint(lazyMintData_.minter, tokenId_, balanceQuantity, "");
        _mint(lazyMintData_.buyer, tokenId_, lazyMintData_.soldQuantity, "");

        nftInfos[tokenId_] = NftData(
            lazyMintData_.uri,
            lazyMintData_.creators,
            lazyMintData_.royalties,
            lazyMintData_.investors,
            lazyMintData_.revenues,
            lazyMintData_.minter,
            balanceQuantity
        );
        _totalSupply[tokenId_] = lazyMintData_.quantity;
    }

    function transferNft(
        address from_,
        address to_,
        uint256 tokenId_,
        uint256 quantity_
    ) public isNiftyMarketplace {
        _safeTransferFrom(from_, to_, tokenId_, quantity_, "");
        if (from_ == nftInfos[tokenId_].minter) {
            uint256 currentTotalSale = nftInfos[tokenId_].firstSaleQuantity +
                quantity_;
            if (currentTotalSale > _totalSupply[tokenId_]) {
                nftInfos[tokenId_].firstSaleQuantity = _totalSupply[tokenId_];
            }
        }
    }

    function burn(
        address account,
        uint256 id,
        uint256 quantity
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "Nifty1155: unauthorized. not owner or approved"
        );

        _burn(account, id, quantity);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC1155Upgradeable)
        returns (bool)
    {
        return
            ERC1155Upgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }
}
