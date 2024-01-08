pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title InvertedInuCoterie contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract InvertedInuCoterie is ERC721, Ownable {
    using SafeMath for uint256;

    /**
     * @dev Emitted when `tokenId` token is sold from `from` to `to`.
     */
    event Sold(address indexed from, address indexed to, uint256 indexed tokenId, uint256 price);

    string public INVERTED_PROVENANCE = "";

    uint256 public constant dogPrice = 10000000000000000; // 0.01 ETH

    uint public constant MAX_DOGS = 10000;

    address public BAKC_ADDRESS;
    address public IAPE_ADDRESS;

    // Mapping from tokenId to sale price.
    mapping(uint256 => uint256) public tokenPrices;

    // Mapping from tokenId to token owner that set the sale price.
    mapping(uint256 => address) public priceSetters;

    constructor(string memory name, string memory symbol, address ogAddress, address invertedAddress) ERC721(name, symbol) {
        BAKC_ADDRESS = ogAddress;
        IAPE_ADDRESS = invertedAddress;
        _setBaseURI('ipfs://QmaV8sZ6oc9YFyADPg8U87irpniXmDAbHXup1JEGcdpUKv/');
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /*
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        INVERTED_PROVENANCE = provenanceHash;
    }

    /**
    * Mints
    */
    function mintDog(uint256[] memory tokenIds) public payable {
        require(totalSupply().add(tokenIds.length) <= MAX_DOGS, "would exceed max supply of Dogs");

        ERC721 bakc = ERC721(BAKC_ADDRESS);

        for (uint i=0; i < tokenIds.length; i++) {
            require(
              (bakc.ownerOf(tokenIds[i]) == msg.sender),
              "must own the BAKC dog rights"
            );
        }

        ERC721 invertedApeClub = ERC721(IAPE_ADDRESS);

        if (invertedApeClub.balanceOf(msg.sender) == 0) {
          require(dogPrice.mul(tokenIds.length) <= msg.value, "Ether value sent is not correct");
        }

        for (uint i=0; i < tokenIds.length; i++) {
            if (totalSupply() < MAX_DOGS) {
                _safeMint(msg.sender, tokenIds[i]);
            }
        }
    }

    /*
    * @dev Checks that the token owner or the token ID is approved for the Market
    * @param _tokenId uint256 ID of the token
    */
    modifier ownerMustHaveMarketplaceApproved(uint256 _tokenId) {
        address owner = ownerOf(_tokenId);
        address marketplace = address(this);
        require(
            isApprovedForAll(owner, marketplace) ||
            getApproved(_tokenId) == marketplace,
            "owner must have approved marketplace"
        );
        _;
    }

    /*
    * @dev Checks that the token is owned by the sender
    * @param _tokenId uint256 ID of the token
    */
    modifier senderMustBeTokenOwner(uint256 _tokenId) {
        address tokenOwner = ownerOf(_tokenId);
        require(
            tokenOwner == msg.sender,
            "sender must be the token owner"
        );
        _;
    }

    /*
    * @dev Checks that the token is owned by the same person who set the sale price.
    * @param _tokenId address of the contract storing the token.
    */
    function _priceSetterStillOwnsTheDog(uint256 _tokenId)
        internal view returns (bool)
    {
        return ownerOf(_tokenId) == priceSetters[_tokenId];
    }

    /*
    * @dev Set the token for sale
    * @param _tokenId uint256 ID of the token
    * @param _amount uint256 wei value that the item is for sale
    */
    function setWeiSalePrice(uint256 _tokenId, uint256 _amount)
        public
        ownerMustHaveMarketplaceApproved(_tokenId)
        senderMustBeTokenOwner(_tokenId)
    {
        tokenPrices[_tokenId] = _amount;
        priceSetters[_tokenId] = msg.sender;
    }

    /*
    * @dev Purchases the token if it is for sale.
    * @param _tokenId uint256 ID of the token.
    */
    function buy(uint256 _tokenId)
        public payable
        ownerMustHaveMarketplaceApproved(_tokenId)
    {
        // Check that the person who set the price still owns the ape.
        require(
            _priceSetterStillOwnsTheDog(_tokenId),
            "Current token owner must be the person to have the latest price."
        );

        // Check that token is for sale.
        uint256 tokenPrice = tokenPrices[_tokenId];
        require(tokenPrice > 0, "Tokens priced at 0 are not for sale.");

        // Check that the correct ether was sent.
        require(
            tokenPrice == msg.value,
            "Must purchase the token for the correct price"
        );

        address tokenOwner = ownerOf(_tokenId);

        // Payout all parties.
        _payout(tokenPrice, payable(tokenOwner), _tokenId);

        // Transfer token.
        _transfer(tokenOwner, msg.sender, _tokenId);

        // Wipe the token price.
        _resetTokenPrice(_tokenId);

        emit Sold(msg.sender, tokenOwner, tokenPrice, _tokenId);
    }

    /* @dev Internal function to set token price to 0 for a give contract.
    * @param _tokenId uint256 id of the token.
    */
    function _resetTokenPrice(uint256 _tokenId)
        internal
    {
        tokenPrices[_tokenId] = 0;
        priceSetters[_tokenId] = address(0);
    }

    /* @dev Internal function to retrieve the invertedApe Owner if it exists
    * @param _tokenId uint256 ID of the inverted ape token.
    */
    function iapeAddress(uint _tokenId) internal returns (address apeOwner) {
        ERC721 iape = ERC721(IAPE_ADDRESS);

        try iape.ownerOf(_tokenId) returns (address a) {
            return a;
        } catch Error(string memory) {
            return address(0);
        }
    }

    /* @dev Internal function to pay the seller and yacht ape owner.
    * @param _amount uint256 value to be split.
    * @param _seller address seller of the token.
    * @param _tokenId uint256 ID of the token.
    */
    function _payout(uint256 _amount, address payable _seller, uint256 _tokenId) 
        private
    {
        ERC721 bakc = ERC721(BAKC_ADDRESS);
        address payable bakcDogOwner = payable(bakc.ownerOf(_tokenId));
        address payable invertedApeOwner = payable(iapeAddress(_tokenId));
        uint256 invertedApePayment = 0;

        if (invertedApeOwner != address(0)) {
            invertedApePayment = _calcProportion(1, _amount); // 1%
        }

        uint256 bakcDogOwnerPayment = _calcProportion(1, _amount); // 1%
        uint256 sellerPayment = _amount - bakcDogOwnerPayment - invertedApePayment;

        if (invertedApePayment > 0) {
            invertedApeOwner.transfer(invertedApePayment);
        }
        if (bakcDogOwnerPayment > 0) {
            bakcDogOwner.transfer(bakcDogOwnerPayment);
        }
        if (sellerPayment > 0) {
            _seller.transfer(sellerPayment);
        }
    }

    /*
    * @dev Internal function calculate proportion of a fee for a given amount.
    *      _amount * fee / 100
    * @param _amount uint256 value to be split.
    */
    function _calcProportion(uint256 fee, uint256 _amount)
        internal pure returns (uint256)
    {
        return _amount.mul(fee).div(100);
    }
}