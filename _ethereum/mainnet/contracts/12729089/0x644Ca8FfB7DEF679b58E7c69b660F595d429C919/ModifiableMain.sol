// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC721Custom.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./IModifiableSecondary.sol";
import "./Address.sol";


/**
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract ModifiableMain is Ownable, ERC721Custom {
    using SafeMath for uint256;
    using Strings for uint256;
    using Address for address;

    // Public variables
    // masterpiece + 1024 NFT pieces
    uint256 public constant MAX_NFT_SUPPLY = 1+1024;
    uint256 public constant CMDFT_MODIFICATION_PRICE = 1024*(10**18);
    uint256 public constant MIN_PRICE = 10**17;
    uint256 public SALE_START_TIMESTAMP;
    uint256 public REVEAL_TIMESTAMP;
    uint256 public startingIndex;
    uint256 private _randomNum = 1; // !=0 in case of no sales
    bytes1[] public traitBytes;

    // auction
    address public highestBidder;
    uint256 public isEnded;
    uint256 public AUCTION_END_TS;
    uint256 public highestBid;
    uint256 public roaltyPerNft;
    mapping(address => uint256) public pendingReturns;
    mapping(uint256 => bool) public royaltyClaimed;
    
    // owner balance
    uint256 public ownerBalance;

    // Mapping from token ID to pixel to pixel color
    mapping (uint256 => mapping (uint8 => uint8) ) public _tokenPixelColor;

    // Mapping from token ID to whether the NFT piece was minted before reveal
    mapping (uint256 => bool) private _mintedBeforeReveal;

    // CMDFT token address (secondary contract)
    address public _cmdftAddress;

    // events
    // CMDFT
    event ColorModificaton (uint256 indexed tokenId, uint8 position, uint8 color);

    // reveal
    event Reveal ();

    // auction
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);


    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (address cmdftAddress, uint256 saleStartTS) 
        ERC721Custom(){
        _cmdftAddress = cmdftAddress;
        SALE_START_TIMESTAMP = saleStartTS;
        REVEAL_TIMESTAMP = SALE_START_TIMESTAMP.add(86400 * 14);
        AUCTION_END_TS = saleStartTS.add(86400 * 1200);

        // mint masterpiece at index 0. NFT pieces start with index 1
        _mint(address(this), 0);
    }

    /*
    Store traits
    Ordered according to original hashed sequence pertaining to the Pieces provenance
    */
    function storeMetadata(bytes1[] memory traitsHex) public onlyOwner
    {
        require(traitsHex.length == 1024, "Should be exactly of length=1024");
        require(traitBytes.length == 0, "Could only be set once");
        for (uint256 i = 0; i < traitsHex.length; i++) {
            traitBytes.push(traitsHex[i]);
        }
    }
    
    // CUSTOM METHODS

    /**
     * @dev list all nft indexes of user. Note: it's not the "real" ids of NFTs, because they don't take into account starting index.
     */
    function getOwnerNfts(address user) public view returns (uint256[] memory) {
        require(user != address(0), "ERC721: balance query for the zero address");
        uint N = balanceOf(user);
        uint256[] memory result = new uint256[](N);

        for (uint i=0; i<N; i++) {
            result[i] = tokenOfOwnerByIndex(user, i);
        }
        return result;
    }

    /**
     * @dev Returns if the NFT has been minted before reveal phase
     */
    function isMintedBeforeReveal(uint256 index) public view returns (bool) {
        return _mintedBeforeReveal[index];
    }

    /**
     * @dev Gets current Piece Price
     */
    function getNFTPrice() public view returns (uint256) {
        // -1 because NFT at index 0 - is masterpiece
        uint currentSupply = totalSupply().sub(1);
        if (currentSupply < 185) {
            return MIN_PRICE.mul(1);
        } else if (currentSupply < 357) {
            return MIN_PRICE.mul(3);
        } else if (currentSupply < 516) {
            return MIN_PRICE.mul(5);
        } else if (currentSupply < 662) {
            return MIN_PRICE.mul(10);
        } else if (currentSupply < 795) {
            return MIN_PRICE.mul(16);
        } else if (currentSupply < 915) {
            return MIN_PRICE.mul(23);
        } else if (currentSupply < 1021) {
            return MIN_PRICE.mul(30);
        } else { 
            return MIN_PRICE.mul(1000);
        }
    }

    /**
    * @dev Mints a piece
    */
    function mintPiece() public payable {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(getNFTPrice() == msg.value, "Ether value sent is not correct");

        // add to owner balance
        ownerBalance = ownerBalance.add(msg.value);

        // change random num
        _randomNum = _randomNum.add(uint256(keccak256(abi.encode(blockhash(block.number),
                                                                 block.coinbase,
                                                                 block.difficulty,
                                                                 msg.sender,
                                                                 totalSupply()
                                            ))) % (1023));

        // mint
        uint mintIndex = totalSupply();
        if (startingIndex == 0) {
            _mintedBeforeReveal[mintIndex] = true;
        }
        _safeMint(msg.sender, mintIndex);
    }

    /**
     * @dev Finalize starting index. 
     */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(totalSupply() == MAX_NFT_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP, 
                "Not good time for setting startingIndex");

        // make cheating on startingIndex as hard as possible
        startingIndex = _randomNum % (1023);

        // Prevent default index=0.
        if (startingIndex == 0) {
            startingIndex.add(124);
        }

        // event
        emit Reveal();
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    */
    function withdraw() onlyOwner public {
        uint balance = ownerBalance;
        require(ownerBalance > 0, "Nothing to withdraw");

        // save
        ownerBalance = 0;

        // send 
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed.");
    }

    // COLOR FUNCTIONALITY

    /**
     * @dev Get pixel color by position of Piece
     */
    function getPixelColor(uint256 tokenId, uint8 position) public view returns (uint8) {
        return _tokenPixelColor[tokenId][position];
    }

    /**
     * @dev list all pixel colors. For every piece returns 20 values, so you need another function to trim
     * this array based on piece length 
     */
    function getPixelsColor(uint256 tokenId) public view returns (uint8[] memory) {
        uint8 N = 20;
        uint8[] memory result = new uint8[](N);

        for (uint8 i=0; i<N; i++) {
            result[i] = _tokenPixelColor[tokenId][i];
        }
        return result;
    }
    
    /**
     * @dev add color of pixel for piece NFT. Colors starting from 1,.... If color == 0 - means it wasnt modified yet. 
     *
     * all pixels in each Token are numerized. The mapping between pixel position (solidity arg) and it's absolute coordinates is stored on IPFS
     * The postions start from 0 and end with NFT area -1
     *
     * If not revealed <-> (startingIndex == 0) -> could only add color to first 5 pixels
     * (because every NFT has at least 5 pixels)
     *              and 3 colors - because every NFT has at least 3 (not white) colors 
     */
    function modifyColor(uint256 tokenId, uint8 position, uint8 color) public {
        require(tokenId > 0, "NFT pieceId (tokenId) numerations starts with 1");
        require(_msgSender() == ownerOf(tokenId), "ERC721: caller is not the owner");
        require(getPixelColor(tokenId, position) == 0, "The color of pixel was already modified");
        require(color > 0, "Color should be > 0");
        require(block.timestamp < AUCTION_END_TS, "Cant modify color after 1200 days");

        if (startingIndex == 0){
            // if not revealed yet - simple check. Every token has at least 5 pixels and 3 colors
            require(position<5, "Can only modify color of 5 first pixels before reveal");
            require(color<=3, "Can only use 3 colors before reveal");
        } else {
            // if revelead - check token traits - whether the change is allowed
            (uint256 lengthTrait, uint256 colorTraits) = getTraitsOfTokenId(tokenId);

            // require pos 
            require(position < lengthTrait, "Cant colorize pixel outside figure");

            // require color
            require(color <= colorTraits , "Cant use this color");
        }

        // save changes
        _tokenPixelColor[tokenId][position] = color;

        // spend CMDFT tokens
        burnCMDFT(CMDFT_MODIFICATION_PRICE);
        emit ColorModificaton(tokenId, position, color);
    }

    /** 
    @dev Burns CMDFT tokens
    */
    function burnCMDFT(uint256 burnQuantity) public returns (bool) {
        return IModifiableSecondary(_cmdftAddress).burnCMDFT(burnQuantity, msg.sender);
    }
    
    // TRAITS FUNCTIONALITY

    /** 
    @dev Returns the trait bytes for the index at specified position in the ORIGINAL hashed sequence
    * index is in [0, .., 1023] - because we have 1024 pieces and  NFT 0 doesn't have any traits
    */
    function getTraitBytesAtIndex(uint256 index) public view returns (bytes1) {
        require(index < traitBytes.length, "Metadata does not exist for the specified index");
        return traitBytes[index];
    }

    /**
    @dev Returns the traits of each token - length and max colors
    * Requires startingIndex to be set (Reveal event)
    * tokenId is in [1,..,1024], because NFT 0 doesn't have any traits
    */
    function getTraitsOfTokenId(uint256 tokeinId) public view returns (uint256 length, uint256 color)
    {
        require(startingIndex > 0, "startingIndex is not set yet");
        require(tokeinId > 0, "NFT pieceId (tokenId) numerations starts with 1");
        require(tokeinId <= 1024, "Metadata does not exist for the specified index");
        // Derives the index of the image in the original sequence assigned to the Piece ID
        uint256 pieceIndex = (tokeinId-1+startingIndex) % 1024;
        (length, color) = getTraitsOfInitialSeqAtIndex(pieceIndex);
    }

    /**
    @dev Doesn't reflect the real traits of token
    * Returns the traits of piece at initial sequence at index. Index of piece and piece ID are different than tokenId. 
    * index - is in [0,...,1023]
    * To get the real traits of tokens - use getTraitsOfTokenId
    */
    function getTraitsOfInitialSeqAtIndex(uint256 index) public view returns (uint256 length, uint256 color)
    {
        require(index < traitBytes.length, "Metadata does not exist for the specified index");
        bytes1 traitBytesTmp = getTraitBytesAtIndex(index);

        length = _extractLengthTrait(traitBytesTmp);
        color = _extractColorTrait(traitBytesTmp);
    }

    /**
    @dev As minimal length is 5 and max 20 - to store in 4 bits -> add length to 5
    */
    function _extractLengthTrait(bytes1 traitBytesTmp) internal pure returns (uint256 length)
    {
        bytes1 lengthByte = traitBytesTmp[0] >> 4;
        length = uint8(lengthByte) + 5;
    }

    /**
    @dev Minimal colors is 3 and max 15
    */
    function _extractColorTrait(bytes1 traitBytesTmp) internal pure returns (uint256 color)
    {
        bytes1 colorByte = traitBytesTmp[0]& 0x0F;
        color = uint8(colorByte);
    }

    // AUCTION FUNCTONALITY
    /**
    * @dev Bid price
    * Bid on the auction with the value sent together with this transaction.
    * The value will only be refunded if the auction is not won.
    * 
    * Only allow external addresses to bid (because may fail masterpiece transfer to contract address)
    */
    function bid() public payable {
        require(isEnded == 0, "Auction already ended.");
        require(msg.value > highestBid, "Your bid should be higher than the highest one");
        require(!msg.sender.isContract(), "Only external accounts are allowed to bid");

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /**
    * @dev Withdraw bids that was overbided.
    */
    function withdrawBid() public {
        uint amount = pendingReturns[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        // save
        pendingReturns[msg.sender] = 0;

        // withdraw
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    /**
    * @dev End the auction, transfer artists royalties to the Pool and send eth to owner. Could only be called once!
    */
    function auctionEnd() public {
        require(block.timestamp >= AUCTION_END_TS, "Auction is not yet ended");
        require(isEnded == 0, "Auction was already finished");

        // end action
        isEnded = 1;

        // calculate roaylties
        uint256 amountOfBakers = totalSupply().sub(1); // because NFT 0 is masterpiece
        uint256 royaltyPoolAmount;

        // impossible case - no one purchased a nft piece
        if (amountOfBakers == 0){
            royaltyPoolAmount = 0;
            roaltyPerNft = 0;
        } else {
            // bakers roaylty is always 71.68% from highest bid, which is
            // uniformly distribted among them
            royaltyPoolAmount = highestBid.div(10000).mul(7168);
            roaltyPerNft = royaltyPoolAmount.div(amountOfBakers);
        }
        
        uint256 ownerRoaylty = highestBid.sub(royaltyPoolAmount);

        // send NFT 0 to highest bidder
        _transfer(address(this), highestBidder, 0);

        // add ownerRoyalty to owner
        ownerBalance = ownerBalance.add(ownerRoaylty);

        // events
        emit AuctionEnded(highestBidder, highestBid);
    }

    /**
    * @dev Withdraw an artist royalty
    */
    function withdrawRoyalty(uint256 tokenId) public {
        require(tokenId>0, "Can't claim for 0th NFT - it's a masterpiece");
        require(tokenId<=1024, "No such token");

        // require auction ended
        require(isEnded == 1, "Auction is not ended yet");

        // check owner of token
        require(ownerOf(tokenId) == msg.sender, "You are not an owner of this token");

        // check is claimed for the first time
        require(royaltyClaimed[tokenId] == false, "Roaylty was already claimed for this token");

        // check if roaylty is > 0
        require(roaltyPerNft > 0, "Artist royalty should be greater than 0");
        
        // save
        royaltyClaimed[tokenId] = true;
        
        // send 
        (bool success, ) = msg.sender.call{value: roaltyPerNft}("");
        require(success, "Transfer failed.");
    }
}
