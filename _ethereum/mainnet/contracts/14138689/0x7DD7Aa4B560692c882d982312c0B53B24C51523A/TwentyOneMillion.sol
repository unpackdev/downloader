// SPDX-License-Identifier: UNKNOWN
// For licensing contact licensing@21mmpixels.com

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./IERC2981.sol";
import "./Strings.sol";
import "./BaseConversion.sol";

/**
 * @title 21MMpixels
 * 21MMpixels - The self describing token representing your piece of blockchain history.
 * 
 * Each purchased token represents 2500 pixels within the 21 million pixel image.  
 * 
 * The original 21MMpixels website is available at https://21mmpixels.com
 *
 * There are 8400 original issue 50x50 pixel tokens.  Token IDS 1-8400 represent these
 * original tiles.  The location of each tile is immutable, find out the location of any
 * tile within the 6000 pixel x 3500 pixel grid for as long as Ethereum exists with 
 * the tileDescription view function.  
 *
 * Collect and merge 4 adjacent tokens to make a single 10,000 pixel big token.  Merging
 * tokens will burn the original tiles, and issue a single big token with a token ID 
 * of the original top left token + 10000.
 *
 * If you're a real big shot, collect and merge 4 big tokens to create a 40,000 pixel
 * super token.  The four big Token IDs will be burned and a single super token with
 * a token ID of the original top left token + 20000. 
 * 
 * You can set the image for your token once token redemption begins.  To determine the 
 * cost of altering the image for your token, call the imageManipulationPrice 
 * view function.  The price is set to 1/21 * the tile price for each 2500 pixels 
 * represented by a token, not to exceed 0.02 ether per 2500 pixels.  Once the sale has 
 * concluded, anyone can activate redemption if the  contract owner has not yet 
 * activated redemption.   
 * 
 * Set the image for your tile in 61 bytes of storage space, with Solidity based 
 * support for storing and displaying IPFS CIDv1 file links and Arweave Transaction 
 * IDs.  Storing your image is simple: call the cidv1ToBytes view function with
 * your IPFS image cidV1, or call the arweaveTxIdToBytes view function with your
 * Arweave tx id to get all the data needed to store your image record.
 *
 * Set a URL for your token to link to for the price of the gas, retrievable with 
 * a view function by anyone.  
 *
 * Change the image and URL for your tile anytime redemption is active, and update 
 * the 21MM Pixel image in real time.  
 *
 * Make your record permanent by calling the lock token function, which prevents any 
 * future changes to your token and its image.  
 */

contract TwentyOneMillion is ERC721Tradable, IERC2981, BaseConversion {

    
    constructor(address _proxyRegistryAddress) ERC721Tradable("21MM Pixels", "PIXL", _proxyRegistryAddress) {
        
    }

    struct RedeemedStruct{
        uint8 redeemedAndLocked;  
        bytes1 multibase;  
        /* UTF-8 encoding of mutlibase: 
            0x62 = b - rfc4648 case-insensitive - no padding (IPFS cidV1)
            0x01 = Arweave tx id
            0x75 = Base64URL   */     
        bytes30 digest1;
        uint16 size;   // Number of bytes in digests to use
        bytes30 digest2;
    }

    bool    private _active;
    bool    private _salePaused;
    bool public redeemable;
    uint private _maxMint;            
    uint private _maxMintTotal;  
    uint private _price;
    // solhint-disable-next-line
    uint public constant royalty = 500;
    uint public constant TILE_LIMIT = 8400;
    uint private constant _MAX_REDEMPTION_PRICE = 20_000_000_000_000_000;
    string private _baseTokenURI;
    string private _contractURI;
    

    mapping (uint256 => string) private _tokenIdToUrl;
    mapping (uint256 => RedeemedStruct) private _tokenIdToRedeemed;
    
    event TokenImageSet(uint indexed tokenId, address indexed currentOwner, bytes30 digest1, bytes30 digest2, bytes1 multibase, uint16 size, bool locked);
    event TokensMerged(uint256 upperLeft, uint256 upperRight, uint256 lowerLeft, uint256 lowerRight, uint256 indexed newToken, bool merged);
    event TokenUrlSet(uint indexed tokenId, string url);

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    /**
     * Read-only function to show details about the project.
     */ 
 
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");
        return string(abi.encodePacked(_baseURI(), Strings.toString(_tokenId)));
    }

    /**
     * Read-only function to show the stored image link.
     */
    function tokenImg(uint256 tokenId) public view returns (string memory ipfsLink, bytes30 digest1, bytes30 digest2, bytes1 multibase, uint16 size){
        require(_exists(tokenId), "Token does not exist");
        RedeemedStruct storage redeemed = _tokenIdToRedeemed[tokenId];
        require(redeemed.redeemedAndLocked != 0, "No image set");
        if (redeemed.multibase == 0x62 || redeemed.multibase == 0x42){
            string memory link = byteArraysToBase32String(redeemed.digest1, redeemed.digest2, redeemed.multibase, redeemed.size);
            return (string(abi.encodePacked("ipfs://", link)), redeemed.digest1, redeemed.digest2, redeemed.multibase, redeemed.size); 
        }
        else if (redeemed.multibase == 0x75){
            string memory link = byteArraysToBase64String(redeemed.digest1, redeemed.digest2, redeemed.size);
            return(string(abi.encodePacked(link)), redeemed.digest1, redeemed.digest2, redeemed.multibase, redeemed.size); 
        }
        else if (redeemed.multibase == 0x01){
            string memory link = byteArraysToBase64String(redeemed.digest1, redeemed.digest2, redeemed.size);
            return(string(abi.encodePacked("arweave://",link)), redeemed.digest1, redeemed.digest2, redeemed.multibase, redeemed.size); 
        }
        else{
            return ("", redeemed.digest1, redeemed.digest2, redeemed.multibase, redeemed.size);
        }
    }

    /**
     * Read-only function to show any URL associated with a token (tile).
     */

     function tokenLinkUrl(uint256 tokenId) public view returns (string memory url){
         require(_exists(tokenId), "Token does not exist");
         RedeemedStruct memory redeemed = _tokenIdToRedeemed[tokenId];
         require(redeemed.redeemedAndLocked > 0, "Tile not set");
         return _tokenIdToUrl[tokenId];
     }

    /**
     * Read-only function to show if a token has been permanently locked.  Once a token is
     * locked, the image can not be modified, and the tile represented by that token can not
     * be merged or unmerged.
     */
    function tokenLocked(uint256 tokenId) public view returns (bool){
        require(_exists(tokenId), "Token does not exist");
        return (_tokenIdToRedeemed[tokenId].redeemedAndLocked == 2);
    }

    /**
     * Read-only function to determine if sale is active.  
     */
    function active() external view returns(bool) {
        return _active;
    }

    /**
     * Read-only function to retrieve the current price to mint a single 50x50 tiles.
     */
    function pricePerTile() public view returns (uint256) {
        require(_active, "Not active");
        return _price;
    }

    /**
     * Read-only function to retrieve maximum mint total.
     */
    function maxMintTotal() public view returns (uint256) {
        require(_active, "Not active");
        return _maxMintTotal;
    }

    /**
     * Read-only function to retrieve maximum mint per transaction.
     */
    function maxMintPerTransaction() public view returns (uint256) {
        require(_active, "Not active");
        return _maxMint;
    }

    /**
     * Read-only function to calculate the data to store a cidv1 base32 IPFS pointer for an image file.  
     * Provided for convenience.
     */
    function cidv1ToBytes(string memory _cidv1) public pure returns (bytes30 digest1, bytes30 digest2, bytes1 multibase, uint16 length) {
        bytes memory bytesArray =  bytes(_cidv1);
        uint8 firstByte = uint8(bytesArray[0]);
        require(firstByte == 98, "Not rfc4648");
        (digest1, digest2, multibase, length) = base32stringToBytes(_cidv1);
        return (digest1, digest2, multibase, length);
    }

    /**
     * Read-only function to calculate the data to store an Arweave tx id for an image file.  
     * Provided for convenience.
     */
    function arweaveTxIdToBytes(string memory _txid) public pure returns (bytes30 digest1, bytes30 digest2, bytes1 multibase, uint16 length) {
        (digest1, digest2, multibase, length) = base64URLstringToBytes(_txid);
        return (digest1, digest2, 0x01, length);
    }

    /**
     * Read-only function to calculate the data to store Base64URL encoded links for an image file.  
     * Provided for convenience.
     */
    function base64URLToBytes(string memory _url) public pure returns (bytes30 digest1, bytes30 digest2, bytes1 multibase, uint16 length) {
        (digest1, digest2, multibase, length) = base64URLstringToBytes(_url);
        return (digest1, digest2, 0x01, length);
    }

    /** 
     * Read-only function to show the price to merge four 50x50 or four 100x100 tiles.
     */
    function mergePrice(uint tokenId) public view returns (uint256){
        require(_exists(tokenId), "Token does not exist");
        require(tokenId > 0, "Invalid token");
        require(tokenId < 20000, "Too large to merge");
        if (tokenId > 10000){
            return _price * 4;
        }
        else{
            return _price * 2;
        }
    }

    /**
     * Read-only function to show current price to set or unset the image for a tile.
     */
    function imageManipulationPrice(uint tokenId) public view returns (uint256){
        require(_exists(tokenId), "Token does not exist");
        uint size = tokenId / 10000;
        uint price = _price;

        return ((price / 21) > _MAX_REDEMPTION_PRICE ? _MAX_REDEMPTION_PRICE : (price / 21)) * (4 ** size); 
    }

    /**
     * Read-only function to show the coordinates, dimensions, and size of a tile.  Does not check if tile exists.
     */
     function tileDescription(uint256 tokenId) public pure returns (string memory){
        (uint x, uint y, uint dimensions) = tileDescriptionArray(tokenId);
        string memory xCoord = Strings.toString(x);
        string memory yCoord = Strings.toString(y);
        string memory pixels = Strings.toString(dimensions * dimensions);
        string memory sizeS = Strings.toString(dimensions) ;
        return string(abi.encodePacked("x: ",xCoord, " y: ", yCoord, " size: ",sizeS, "x", sizeS, " pixels: ", pixels));
     }


    function tileDescriptionArray(uint256 tokenId) public pure returns (uint x, uint y, uint dimension){
        uint tempId = tokenId - 1;
        uint size = 0;
        uint column = 0;
        uint row = 0;
        if (tokenId > 10000){
            size = tempId / 10000;
            tempId = tempId - 10000 * size;
        }

        if (tempId == 0){
            // It's 0:0
        }
        else if (tempId < 2485) {       
            uint ind = 0;
            uint bigger = 0;

            while(bigger < tempId){
                ind++;
                bigger = bigger + ind; 
            }

            if (bigger == tempId){
                row = ind;
            }
            else{
                column = tempId + ind - bigger;
                row = bigger - tempId - 1;
            }
        }
        else if (tempId < 5985){
            uint ind = (tempId - 2485) / 70;
            uint bigger = 2485 + ind * 70;

            if (bigger == tempId){
                column = ind + 1;
                row = 69;
            }
            else{ 
                column = tempId - bigger + ind + 1;
                row = bigger + 69 - tempId;
            }
        }
        else if (tempId < 8400){
            uint ind = 0;
            uint bigger = 5985;

            while(bigger < tempId){
                ind++;
                bigger = bigger + (70 - ind); 
            }

            if (bigger == tempId){
                column = ind + 51;
                row = 69;
            }
            else{
                column = 120 + tempId - bigger;
                row = bigger + ind - tempId - 1;
            }
        }
        else {
            revert("Invalid tile");
        }

        x = column * 50;
        y = row * 50;
        dimension = 50 + (size * size) * 25 + size * 25;
        require((x + dimension) < 6001 && (y + dimension) < 3501, "Invalid tile");
    }

    /** 
     * Read-only function to retrieve the tiles that are adjacent to a tile 
     */
    function showAdjacentTiles(uint256 _topLeftTile) public pure returns (uint right, uint below, uint diag) {
        require(_topLeftTile < 20000, "Invalid tile");
        uint tempId = _topLeftTile;
        uint mergeType = 0;

        if (tempId > 10000){
                mergeType = 1;
                tempId = tempId - 10000;
        }

        (right, below, diag) = _adjacentTiles(tempId, mergeType);
    }

    /**
     * Read-only function to retrieve the total number of NFTs that have been minted thus far
     */
    function getTotalMinted() external view returns (uint256) {
        return totalSupply();
    }

    /**
     * Read-only function to retrieve the total number of NFTs that remain to be minted
     */
    function getTotalRemainingCount() external view returns (uint256) {
        return (TILE_LIMIT - totalSupply());
    }

// Royalty info
    function royaltyInfo (
            // solhint-disable-next-line no-unused-vars
            uint256 _tokenId,
            uint256 _salePrice
        ) external view override(IERC2981) returns (
            address receiver,
            uint256 royaltyAmount
        ) {
            // Royalty payment is 5% of the sale price
            uint256 royaltyPmt = _salePrice*royalty/10000;
            require(royaltyPmt > 0, "Royalty must be greater than 0");
            require(_exists(_tokenId), "Token does not exist");
            return (address(this), royaltyPmt);
        }

// Callable functions 
    function mint(uint64 _tiles) external payable callerIsUser {
        require(_active && !_salePaused, "Inactive");
        require(_tiles >= 1 && _tiles <= _maxMint, "Invalid quantity");
        require(_tiles + totalSupply() <= TILE_LIMIT,"Sold out");
        require(_tiles + balanceOf(msg.sender) <= _maxMintTotal, "Too many owned");
        require(msg.value == _tiles * _price, "Invalid amount sent"); 
        for (uint i = 0; i < _tiles; i++){
            _mintTo(msg.sender); 
        }
    }

    /**
     * Merges four adjactent tiles into a single larger tile.  Can be used on four 50x50 or
     * four 100x100 tiles.  Call function with the upper left tile Token ID.  Burns the four
     * merged tiles and issues a new tile.  Cost to merge tiles can be found with the mergePrice
     * view function.
    */
    function mergeTiles(uint256 _topLeftTile) external payable callerIsUser {
        require(_topLeftTile < 20000, "Too large to merge");
        require(ERC721.ownerOf(_topLeftTile) == msg.sender, "Top left token not owned");
        require(msg.value == mergePrice(_topLeftTile), "Invalid amount sent");
        uint tempId = _topLeftTile;
        uint mergeType = 0;

        if (_topLeftTile > 10000){
                mergeType = 1;
                tempId = tempId - 10000;
        }

        (uint right, uint bottom, uint diag) = _adjacentTiles(tempId, mergeType);
        
        require(ERC721.ownerOf(right) == msg.sender, "Top right token not owned");
        require(ERC721.ownerOf(bottom) == msg.sender, "Lower left token not owned");
        require(ERC721.ownerOf(diag) == msg.sender, "Lower right token not owned");

        require(_tokenIdToRedeemed[_topLeftTile].redeemedAndLocked != 2, "Top left token locked");
        require(_tokenIdToRedeemed[right].redeemedAndLocked != 2, "Top right token locked");
        require(_tokenIdToRedeemed[bottom].redeemedAndLocked != 2, "Bottom left token locked");
        require(_tokenIdToRedeemed[diag].redeemedAndLocked != 2, "Bottom right token locked");

        delete _tokenIdToRedeemed[_topLeftTile];
        delete _tokenIdToRedeemed[right];
        delete _tokenIdToRedeemed[bottom];
        delete _tokenIdToRedeemed[diag];

        delete _tokenIdToUrl[_topLeftTile];
        delete _tokenIdToUrl[right];
        delete _tokenIdToUrl[bottom];
        delete _tokenIdToUrl[diag];
        
        emit TokenImageSet(_topLeftTile, msg.sender, 0x0, 0x0, "", 0, false);
        emit TokenImageSet(right, msg.sender, 0x0, 0x0, "", 0, false);
        emit TokenImageSet(bottom, msg.sender, 0x0, 0x0, "", 0, false);
        emit TokenImageSet(diag, msg.sender, 0x0, 0x0, "", 0, false);
        emit TokenUrlSet(_topLeftTile, "");
        emit TokenUrlSet(right, "");
        emit TokenUrlSet(bottom, "");
        emit TokenUrlSet(diag, "");

        _burn(_topLeftTile);
        _burn(right);
        _burn(bottom);
        _burn(diag);

        uint bigTokenId = 10000 + _topLeftTile;
        _safeMint(msg.sender, bigTokenId);
        emit TokensMerged(_topLeftTile, right, bottom, diag, bigTokenId, true);
    }

    /**
     * Function to unmerge a 100x100 tile into four 50x50 tiles, or a 200x200 tile into four
     * 100x100 tiles.  Burns the larger tile, and mints four smaller tiles to owner.
    */
    function unmergeTiles(uint256 _tile) external callerIsUser {
        require(_tile > 10000, "Can not split single tile");
        require(ERC721.ownerOf(_tile) == msg.sender, "Token not owned");
        require(_tokenIdToRedeemed[_tile].redeemedAndLocked != 2, "Token locked");

        uint tempId = _tile - 10000;
        uint mergeType = 0;

        if (tempId > 10000){
                mergeType = 1;
                tempId = tempId - 10000;
        }

        (uint right, uint bottom, uint diag) = _adjacentTiles(tempId, mergeType);

        uint newLeft = _tile - 10000;

        delete _tokenIdToRedeemed[_tile];
        delete _tokenIdToUrl[_tile];
        //emit TokenImageUnset(_tile, msg.sender);  
        emit TokenImageSet(_tile, msg.sender, 0x0, 0x0, "", 0, false);      
        emit TokenUrlSet(_tile, "");

        _burn(_tile);
        _safeMint(msg.sender, newLeft);
        _safeMint(msg.sender, right);
        _safeMint(msg.sender, bottom);
        _safeMint(msg.sender, diag);

        emit TokensMerged(newLeft, right, bottom, diag, _tile, false);
    }

    /**
     *  Internal function to determine adjacent tiles given a top left tile.
    */
    function _adjacentTiles(uint256 _topLeftTile, uint256 _mergeType) internal pure returns (uint right,uint bottom,uint diag) {
        require(_topLeftTile < 8399, "Invalid starting tile");
        require(_topLeftTile > 0, "Invalid starting tile");
        uint tempId = _topLeftTile - 1;

        if (tempId < 2346) {       
            uint ind = 34;
            uint upper = 70;
            uint lower = 0;
            uint bigger = 595;
            
                while(!(tempId < bigger && tempId >= (bigger - ind))){
                    if (tempId >= bigger){
                        lower = ind;
                        ind = (ind + upper) / 2;
                        bigger = (ind * (ind + 1)) / 2;                 
                    }
                    else { 
                        upper = ind;
                        ind = ((ind + lower) / 2);
                        bigger = (ind * (ind + 1)) / 2;                     
                    }
                }

            if (_mergeType == 0){
                right = _topLeftTile + ind + 1;
                bottom = _topLeftTile + ind;
                diag = _topLeftTile + 2 * ind + 2;
            }
            else {
                require(_topLeftTile != 2279, "Invalid starting tile");
                
                right = _topLeftTile + ind + ind + 3;
                bottom = _topLeftTile + ind + ind + 1;
                diag = _topLeftTile + 4 * ind + 8;
                if (_topLeftTile > 2211){
                    diag = diag - (2 * ind - 133);
                }
            }
        }
        else if (tempId < 5915){
            uint testLower = (tempId - 2345) % 70;
            if (_mergeType == 0){
                require(testLower != 0, "Invalid starting tile");
                right = _topLeftTile + 70;
                bottom = _topLeftTile + 69;
                diag = _topLeftTile + 139; 
            }
            else{
                require(testLower > 2 && tempId < 5913 && tempId != 5844, "Invalid starting tile");  
                bottom = _topLeftTile + 138;
                right = _topLeftTile + 140;
                diag = _topLeftTile + 278;
                if (tempId > 5776  && tempId < 5847){
                    diag -= 1;
                }
                else if (tempId > 5846){
                    diag = diag - 3;
                }
            }
        }
        else  {   
            uint ind = 35;
            uint upper = 70;
            uint lower = 0;
            uint bigger = 7770;
            
                while(!(tempId <= bigger && tempId > (bigger - (71 - ind)))){
                    if (tempId > bigger){
                        lower = ind;
                        ind = (ind + upper) / 2;
                        bigger = 8400 - ((71 - ind) * (70 - ind)) / 2;
                    }
                    else {
                        upper = ind;
                        ind = (ind + lower) / 2;  
                        bigger = 8400 - ((71 - ind) * (70 - ind)) / 2;
                    }
                }

            require(tempId != bigger, "Invalid starting tile");

            uint256 testRight = (bigger - 1) - tempId;

            if (_mergeType == 0){         
                require(testRight != 0, "Invalid starting tile");
                right = _topLeftTile + (71 - ind);
                bottom = _topLeftTile + (70 - ind);
                diag = _topLeftTile + 138 - ((ind - 1) * 2);
            }
            else {
                require(testRight > 2, "Invalid starting tile");
                uint testBottom = tempId - (bigger - (71 - ind));
                require(testBottom > 2, "Invalid starting tile");
                right = _topLeftTile + (141 - ind * 2);
                bottom = _topLeftTile + (139 - ind * 2);
                diag = _topLeftTile + 272 - ((ind - 1) * 4);
            }
        }

        return (right + _mergeType * 10000, bottom + _mergeType * 10000, diag + _mergeType * 10000);
    }

    /**
     * Sets the image for a given token.  Requires payment of image manipulation price.  Image
     * manipulation price determinable with imageManipulationPrice view function.  Token can not
     * be locked.  To set the image using an IPFS CIDv1 in Base32 format, you can use the view 
     * function cidv1ToBytes to determine the data for the call.  
    */

    function setImage(uint256 tokenId, bytes30 _digest1, bytes30 _digest2, uint16 _length, bytes1 _multibase) external payable {
        require(redeemable, "Not yet active");
        require(msg.sender == ERC721.ownerOf(tokenId), "Not owner"); 
        require(msg.value == imageManipulationPrice(tokenId), "Invalid amount sent");
        RedeemedStruct memory redeemed = _tokenIdToRedeemed[tokenId];
        require(redeemed.redeemedAndLocked < 2, "Tile locked");
        redeemed.redeemedAndLocked = 1;
        redeemed.digest1 = _digest1;
        redeemed.digest2 = _digest2;
        redeemed.multibase = _multibase;
        redeemed.size = _length;
        _tokenIdToRedeemed[tokenId] = redeemed;
        emit TokenImageSet(tokenId, msg.sender, _digest1, _digest2, _multibase, _length, false);
    }

    /**
     * Permanently locks a token, including its image.  The token image can not be changed or unset.
     * The token can also no longer be merged or unmerged.  
    */
    function lockToken(uint256 tokenId) public {
        require(redeemable, "Not active");
        require(msg.sender == ERC721.ownerOf(tokenId), "Not owner"); 
        RedeemedStruct memory redeemed = _tokenIdToRedeemed[tokenId];
        require(redeemed.redeemedAndLocked != 2, "Already locked");
        require(redeemed.redeemedAndLocked == 1 && redeemed.digest1 != 0, "No image");
        redeemed.redeemedAndLocked = 2;
        _tokenIdToRedeemed[tokenId] = redeemed;
        emit TokenImageSet(tokenId, msg.sender, redeemed.digest1, redeemed.digest2, redeemed.multibase, redeemed.size, true);
    }

    /**
     * Removes the record of an image for a token.  Requires payment of imageManipulationPrice.
    */
    function unsetImage(uint256 tokenId) external payable {
        require(redeemable, "Not active");
        require(msg.sender == ERC721.ownerOf(tokenId), "Not owner"); 
        require(msg.value == imageManipulationPrice(tokenId), "Invalid amount sent");
        require(_tokenIdToRedeemed[tokenId].redeemedAndLocked != 2, "Tile locked");
        delete _tokenIdToRedeemed[tokenId];
        emit TokenImageSet(tokenId, msg.sender, 0x0, 0x0, "", 0, false);
    }

    /**
     *  Function for owner to set the url for a redeemed tile. 
     */
    function setTokenLinkUrl(uint256 tokenId, string memory url) external {
        require(redeemable, "Not active");
        require(msg.sender == ERC721.ownerOf(tokenId), "Not owner");
        require(_tokenIdToRedeemed[tokenId].redeemedAndLocked == 1, "Tile not redeemed or unlocked");
        _tokenIdToUrl[tokenId] = url;
        emit TokenUrlSet(tokenId, url);
    }

    /** 
     * Allows anyone to set tokens as redeemable upon sale completion for price of a token if owner
     * has not yet set as redeemable.
    */
    function initiateRedemption() external payable {
        require(totalSupply() == TILE_LIMIT, "Sale not yet complete");
        require(!redeemable, "Already redeemable");
        require(msg.value == _price, "Invalid amount");
        redeemable = true;
    }

    // Owner's functions
    function startSale(uint64 setPrice, uint8 maxMint, uint8 maxTotal) external onlyOwner {
        require(!_active, "Already active");
        _active = true;
        _price = setPrice;
        _maxMint = maxMint;
        _maxMintTotal = maxTotal;
    }

    function updateSaleParams(uint64 setPrice, uint8 maxMint, uint8 maxTotal) external onlyOwner {
        require(_active, "Not active");
        _price = setPrice;
        _maxMint = maxMint;
        _maxMintTotal = maxTotal;
    }
  
    function pauseSale(bool paused) external onlyOwner {
        _salePaused = paused;
    }

    function makeRedeemable() external onlyOwner {
        redeemable = true;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    function promoMint(uint256 _tiles, address recipient) external onlyOwner {
        require(_active == false, "Sale already active");
        require(recipient != address(0), "No recipient");
        require(_tiles >= 1 && _tiles < 101, "Invalid mint amount");
        for (uint i = 0; i < _tiles; i++){
            _mintTo(recipient); 
        }
    }
    
    function renounceOwnership() public view override onlyOwner {
        revert("Not allowed");
    }

    function withdraw(address payable recipient, uint256 amount) external onlyOwner {
        recipient.transfer(amount);
    }

}