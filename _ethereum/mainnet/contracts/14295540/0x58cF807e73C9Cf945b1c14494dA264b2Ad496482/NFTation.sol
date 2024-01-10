// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Upgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./IERC2981.sol";
import "./FixedPriceMarketPlace.sol";
import "./AuctionMarketPlace.sol";
import "./NFTationStorage.sol";

contract NFTation is Initializable, 
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    ERC721BurnableUpgradeable,
    UUPSUpgradeable,
    ERC721PausableUpgradeable,
    IERC2981,
    NFTationStorage {

    using CountersUpgradeable for CountersUpgradeable.Counter;

    // +EVENTS --------------------------------------------------
    event TokenBurnt(address owner, uint256 tokenId);
    event TokenCreated(
        address owner,
        uint256 tokenId,
        string tokenURI,
        uint256 royalty
    );
    // -EVENTS --------------------------------------------------

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    function initialize() initializer public {
        __ERC721_init("NFTation", "NFTAT");
        __ERC721URIStorage_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();
        __ERC721Pausable_init();
    }

    function initMarketPlaces(
        address _fixedPriceMarketPlaceContract,
        address _auctionMarketPlaceContract
    )
        public onlyOwner 
    {
        auctionMarketPlaceContract = AuctionMarketPlace(_auctionMarketPlaceContract);
        fixedPriceMarketPlaceContract = FixedPriceMarketPlace(_fixedPriceMarketPlaceContract);
    }

    function isMArketPlacesActiveForAccount() public view returns (bool) {
        return (isApprovedForAll(msg.sender, address(fixedPriceMarketPlaceContract)) &&
                isApprovedForAll(msg.sender, address(auctionMarketPlaceContract)));
    }

    function aprovalMarketPlacesForAccount() external {
        setApprovalForAll(address(fixedPriceMarketPlaceContract), true);
        setApprovalForAll(address(auctionMarketPlaceContract), true);
        //TODO emit event
    }

    function mint(string memory uri, uint256 royaltyPercentage) public {
        require(royaltyPercentage <= 50 , 'NFTation: invalid royalty');

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        tokenFirstSaleMapping[tokenId] = true;
        _setRoyalty(tokenId, _msgSender(), royaltyPercentage);

        //external call
        _safeMint(_msgSender(), tokenId);
        super._setTokenURI(tokenId, uri);
        
        emit TokenCreated(_msgSender(), tokenId, uri, royaltyPercentage);
    }

    function burn(uint256 _tokenId) public override {
        super.burn(_tokenId);

        emit TokenBurnt(_msgSender(), _tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
         override(ERC721Upgradeable, ERC721PausableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        _deleteRoyalty(tokenId);
        super._burn(tokenId);
    }

    function _baseURI() internal view override(ERC721Upgradeable) returns (string memory) {
        return "ipfs://";
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // Set to be internal function _setRoyalty
    function _setRoyalty(uint256 _tokenId, address _receiver, uint256 _percentage) internal {
        royalties[_tokenId] = Royalty(_receiver, _percentage);
    }

    function _deleteRoyalty(uint256 _tokenId) internal {
        delete(royalties[_tokenId]);
    }

    // Override for royaltyInfo(uint256, uint256)
    // royaltyInfo(uint256,uint256) => 0x2a55205a
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    )
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royalties[_tokenId].receiver;

        // This sets percentages by price * percentage / 100
        royaltyAmount = _salePrice * royalties[_tokenId].percentage / 100;
    }

    function getRoyaltyPercentage(uint256 _tokenId) public view returns (uint256) {
        return  royalties[_tokenId].percentage;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable)
        returns (bool)
    {
        if(interfaceId == type(IERC2981).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function checkFirstSale(uint256 _tokenId) external view returns (bool){
        return tokenFirstSaleMapping[_tokenId];
    }

    function disableFirstSale(uint256 _tokenId) external {
        require(_isApprovedOrOwner(msg.sender,_tokenId), 'NFTation: token must be approved');
        delete (tokenFirstSaleMapping[_tokenId]);
    }

    function pause() public virtual  onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}