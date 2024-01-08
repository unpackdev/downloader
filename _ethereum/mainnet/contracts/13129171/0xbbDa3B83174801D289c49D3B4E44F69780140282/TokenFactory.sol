// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./Token.sol";
import "./IUserTokenIdRegistry.sol";

//import "./console.sol";

/**
 * @title Dirty Robot's Summer Season Sale
 * An NFT powered by Ether Cards - https://ether.cards
 */

// interface IERC {
//     function transfer(address sender, uint256 amount) external;
//     function transferFrom(address sender, address to, uint256 id) external;
// }

contract TokenFactory is FactoryERC721, Ownable{
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event ECRegistry(address);

    bool                public auctionAllocated;
    uint                public nextCardType;

    mapping(uint=>uint) public soldPerSeries;

    uint constant        number_of_packs  = 3;
    uint constant        number_of_series = 13; // 4 x 3 + 1
    uint constant        number_of_sales  = 8;
    uint constant public max_for_presale  = 800;
    uint constant public max_for_mainsale = 3000;
    uint constant        OG_ACCESS        = 0;
    uint constant        ALPHA_ACCESS     = 1;
    uint constant        FOUNDER_ACCESS   = 2;
    uint constant        MAINSALE_ACCESS  = 3;
    uint constant        AUCTION          = 12;

    uint constant        SUMMER_MONTAGE   = 8;
    
    address  immutable  _registry;

    string       public loeuf = "https://www.youtube.com/watch?v=VEQriHQpJFQ";


    address      public proxyRegistryAddress;
    address      public nftAddress;
    string       public baseURI = "https://client-metadata.ether.cards/api/dirtyrobot/collection/";
    string         _contractURI = "https://client-metadata.ether.cards/api/dirtyrobot/collection/contract";

    uint         public sold_in_presale;
    uint         public sold_in_mainsale;

    constructor(address _proxyRegistryAddress, address _nftAddress, address __registry) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;
        _registry  = __registry;
        emit ECRegistry(__registry);
        fireTransferEvents(address(0), owner());
    }

    function name() override external pure returns (string memory) {
        return "Dirty Robot\'s Summer Seasons Sale";
    }

    function symbol() override external pure returns (string memory) {
        return "SUMMER";
    }

    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    function numOptions() override public pure returns (uint256) {
        return AUCTION+1;
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < numOptions(); i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function mint(uint256 _optionId, address _toAddress) override public {

        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == _msgSender() ||
                owner() == _msgSender() 
        );
        Token token = Token(nftAddress);

        if (_optionId == AUCTION) { // 24
            require(!auctionAllocated, "Auction already closed");
            auctionAllocated = true;
            token.mintTo(_toAddress,SUMMER_MONTAGE);
            return;
        }

        uint number_in_pack = number_in_packet(_optionId);
        require(_optionId < AUCTION, "Series does not exist");
        uint256 permission = (_optionId / number_of_packs);

        

        if (permission == OG_ACCESS) { // 0-7
            //console.log("OG",number_in_pack,_toAddress);
            is_registered_OG(_toAddress);
            check_presale_available(number_in_pack);
        } else if (permission == ALPHA_ACCESS) { // 8-15
            is_registered_Alpha(_toAddress);
            check_presale_available(number_in_pack);
        } else if (permission == FOUNDER_ACCESS) { // 16-23
            is_registered_Founder(_toAddress);
            check_presale_available(number_in_pack);
        } else {
            permission = MAINSALE_ACCESS;
            require(max_for_mainsale - sold_in_mainsale >= number_in_pack,"Not enough items left");
            sold_in_mainsale += number_in_pack;
        } 
        for (uint j = 0; j < number_in_pack; j++) {
            token.mintTo(_toAddress,nextCardType);
            nextCardType = (nextCardType + 1) % number_of_sales;
        }
    }

    function check_presale_available(uint num_to_buy) internal {
        require(max_for_presale - sold_in_presale >= num_to_buy,"Not enough presale pieces left");
        sold_in_presale += num_to_buy;
    }

    function registry() internal view returns (IUserTokenIdRegistry) {
        return IUserTokenIdRegistry(_registry);
    }

    function is_registered_OG(address sender) internal view {
        uint16 _tokenId = registry().getTokenOrRevert(sender);
        require(_tokenId < 100,"Not qualified for this OG sale");
    }

    function is_registered_Alpha(address sender) internal view {
        uint16 _tokenId = registry().getTokenOrRevert(sender);
        require(_tokenId < 1000,"Not qualified for this ALPHA sale");
    }

    function is_registered_Founder(address sender) internal view {
        registry().getTokenOrRevert(sender);
    }

    function number_in_packet(uint256 _optionId) public view returns (uint256) {
        return 1 + (2 * (_optionId % number_of_packs));
    }

    function canMint(uint256 _optionId) override public view returns (bool) {
        if (_optionId >= numOptions()) {
            return false;
        }
        if (_optionId == AUCTION) return !auctionAllocated;
        uint256 permission = (_optionId / number_of_packs);
        //console.log(_optionId, max_for_mainsale ,sold_in_mainsale , number_in_packet(_optionId));

        if (permission <= FOUNDER_ACCESS) {
            return max_for_presale >= (sold_in_presale + number_in_packet(_optionId));
        }
        return max_for_mainsale >= (sold_in_mainsale + number_in_packet(_optionId));
    }

    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId)));
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory _uri) external onlyOwner {
        _contractURI = _uri;
    }


    /**
     * Hack to get things to work automatically on OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    function setBaseURI(string memory _base) external onlyOwner {
        baseURI = _base;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return false;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return owner();
    }

    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner {
        IERC(_tracker).transfer(_msgSender(), amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC(_tracker).transferFrom(address(this), _msgSender(), id);
    }

    
}
