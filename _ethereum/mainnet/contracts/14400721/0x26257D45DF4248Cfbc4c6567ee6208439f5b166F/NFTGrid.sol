// SPDX-License-Identifier:  CC-BY-NC-4.0
// email "licensing [at] pyxelchain.com" for licensing information
// Pyxelchain Technologies v1.0.0 (NFTGrid.sol)

pragma solidity =0.8.7;


import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
// import "./console.sol";

/**
 * @title Billion Pyxel Project
 * @author Nik Cimino @ncimino
 *
 * @dev the 1 billion pixels are arranged in a 32768 x 32768 = 1,073,741,824 pixel matrix
 * to address all 1 billion pixels we break them into 256 pixel tiles which are 16 pixels x 16 pixels
 * this infers a grid based addressing sytem of dimensions: 32768 / 16 = 2048 x 2048 = 4,194,304 tiles
 *
 * @custom:websites https://billionpyxelproject.com https://billionpixelproject.net
 *   
 * @notice to _significantly_ reduce gas we require that purchases are some increment of the layers defined above
 *
 * @notice this cotnract does not make use of ERC721Enumerable as the tokenIDs are not sequential
 */

/*
 * this contract is not concerned with the individual pixels, but with the tiles that can be addressed and sold
 * each tile is represented as an NFT, but each NFT can be different dimensions in layer 1 they are 1 tile each, but in layer 4 they are 16 tiles each
 *   layer 1:    1 x    1 =         1 tile / index
 *   layer 2:    2 x    2 =         4 tiles / index
 *   layer 3:    4 x    4 =        16 tiles / index
 *   layer 4:    8 x    8 =        64 tiles / index
 *   layer 5:   16 x   16 =       256 tiles / index
 *   layer 6:   32 x   32 =     1,024 tiles / index
 *   layer 7:   64 x   64 =     4,096 tiles / index
 *   layer 8:  128 x  128 =    16,384 tiles / index
 *   layer 9:  256 x  256 =    65,536 tiles / index
 *  layer 10:  512 x  512 =   262,144 tiles / index
 *  layer 11: 1024 x 1024 = 1,048,576 tiles / index
 *  layer 12: 2048 x 2048 = 4,194,304 tiles / index
 * 
 * quad alignment:
 *
 *      layer 11    layer 12
 *      ____N___   ________
 *     /   /   /  /       /
 *   W/---+---/E /       /
 *   /___/___/  /_______/
 *       S
 */

contract NFTGrid is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    //// TYPES & STRUCTS

    /**
     * @dev symetric: should be kept up-to-date with JS implementation
     * @notice layers enum interger value is used as 2 ^ Layer e.g. 2 ^ (x4=2) = 5, 2 ^ (x16=4) = 16
     *  there are a total of 12 sizes (0-11)
     * @dev these enums are uint256 / correct?
     */
    enum Size {
        X1,
        X2,
        X4,
        X8,
        X16,
        X32,
        X64,
        X128,
        X256,
        X512,
        X1024,
        X2048
    } // 2048 = 2^11 = 1 << 11

    /**
     * @notice we model our grid system in the same what that the front-end displays are modeled, this is with 0,0 in the top left corner
     * x increases as we move to the right, but y increases as we move done
     * @dev max x and y is 2048 = 2 ^ 11 which can fit in a uint16, and since we need 4 values using 64 bits packs them all tight
     * @dev we model this so that we have logical coherency between our internal logic and the display systems of this logic
     * @dev x & y are the center of the quad
     */
    struct Rectangle {
        uint16 x;
        uint16 y;
        uint16 w;
        uint16 h;
    }

    /**
     * @notice a quad cannot be owned after it has been divided
     * @dev the quads are the tokenIds which are an encoding of x,y,w,h
     */
    struct QuadTree {
        uint64 northeast;   // quads max index is 2 ^ 64 = 18,446,744,073,709,551,616
        uint64 northwest;   // however, this allows us to pack all 4 into a 256 bit slot
        uint64 southeast;
        uint64 southwest;
        Rectangle boundary; // 16 * 4 = 64 bits
        address owner;      // address are 20 bytes = 160 bits
        bool divided;       // bools are 1 byte = 8 bits  ... should also pack into a 256 bit slot, right? so 2 total?
        uint24 ownedCount;  // need 22 bits to represent full 2048x2048 count - total number of grid tiles owned under this quad (recursively)
    }

    //// EVENTS

    event ETHPriceChanged (
        uint256 oldPrice, uint256 newPrice
    );

    event TokensUpdated (
        address[] tokenAddresses, uint256[] tokenPrices
    );

    event BuyCreditWithETH (
        address indexed buyer, address indexed receiver, uint256 amountETH, uint256 amountPixels
    );

    event BuyCreditWithToken (
        address indexed buyer, address indexed token, address indexed receiver, uint256 amountToken, uint256 amountPixels
    );

    event TransferCredit (
        address indexed sender, address indexed receiver, uint256 amount
    );

    //// MODIFIERS

    modifier placementNotLocked() {
        require(!placementLocked, "NFTG: placement locked");
        _;
    }

    modifier reserveNotLocked() {
        require(!reserveLocked, "NFTG: reserve locked");
        _;
    }

    //// MEMBERS

    uint16 constant public GRID_W = 2048;
    uint16 constant public GRID_H = 2048;
    uint256 constant public PIXELS_PER_TILE = 256;

    bool public placementLocked;
    bool public reserveLocked;
    bool public permanentlyAllowCustomURIs;
    bool public allowCustomURIs = true;
    uint64 immutable public rootTokenId;
    uint256 public pricePerPixelInETH = 0.00004 ether;
    address[] public tokenAddresses; // e.g. USDC can be passed in @ $0.10/pixel = $25.60 per tile
    address[] public receivedAddresses;
    mapping (uint64 => QuadTree) public qtrees;
    mapping (address => uint256) public pricePerPixelInTokens;
    mapping (address => bool) public addressExists;
    mapping (address => uint256) public pixelCredits;
    mapping (address => uint256) public ownedPixels;
    mapping (uint256 => string) public tokenURIs;
    string public defaultURI;
    uint256 public totalPixelsOwned;

    //// CONTRACT

    constructor(address[] memory _tokenAddresses, uint256[] memory _tokenPrices) ERC721("Billion Pixel Project", "BPP") {
        updateTokens(_tokenAddresses, _tokenPrices);
        uint64 qtreeTokenId = _createQTNode(address(0x0), GRID_W/2-1, GRID_H/2-1, GRID_W, GRID_H);
        rootTokenId = qtreeTokenId;
        _subdivideQTNode(qtreeTokenId);
    }

    function getTokens() external view returns(address[] memory addresses, uint256[] memory prices) {
        addresses = new address[](tokenAddresses.length);
        prices = new uint256[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address current = tokenAddresses[i];
            addresses[i] = current;
            prices[i] = pricePerPixelInTokens[current];
        }
    }

    /**
     * @notice let each token have an independent URI as these will be owned and controlled by their owner
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory uri) {
        require(_exists(_tokenId), "NFTG: non-existant token");
        if (!allowCustomURIs) {
            uri = _getDefaultURI(_tokenId);
        } else {
            uri = tokenURIs[_tokenId];
            if (bytes(uri).length == 0) {
                uri = _getDefaultURI(_tokenId);
            }
        }
    }

    function _getDefaultURI(uint256 _tokenId) private view returns(string memory uri) {
        uri = bytes(defaultURI).length > 0 ? string(abi.encodePacked(defaultURI, _tokenId.toString())) : "";
    }

    function setDefaultURI(string memory uri) external onlyOwner {
        defaultURI = uri;
    }

    function setTokenURI(uint256 _tokenId, string calldata _tokenUri) external virtual {
        require(_exists(_tokenId), "NFTG: non-existant token");
        require(allowCustomURIs, "NFTG: custom URIs disabled");
        QuadTree storage qtree = qtrees[uint64(_tokenId)];
        require(qtree.owner == msg.sender, "NFTG: only owner can set URI");
        tokenURIs[_tokenId] = _tokenUri;
    }

    function updateTokens(address[] memory _tokenAddresses, uint256[] memory _tokenPrices) public onlyOwner {
        require(_tokenAddresses.length == _tokenPrices.length, "NFTG: array length mismatch");
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            pricePerPixelInTokens[tokenAddresses[i]] = 0;
        }
        tokenAddresses = _tokenAddresses; // set new below this line - clear old above
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            require(_tokenAddresses[i] != address(0), "NFTG: token address 0");
            require(_tokenPrices[i] != 0, "NFTG: token price 0");
            pricePerPixelInTokens[_tokenAddresses[i]] = _tokenPrices[i];
        }
        emit TokensUpdated(_tokenAddresses, _tokenPrices);
    }

    /**
     * @notice controls ability of placement
     */
    function togglePlacementLock() external onlyOwner {
        placementLocked = !placementLocked;
    }

    /**
     * @notice controls ability of users to reserve pixels
     */
    function toggleReserveLock() external onlyOwner {
        reserveLocked = !reserveLocked;
    }

    /**
     * @notice controls ability of users to set their own URI
     */
    function toggleCustomURIs() external onlyOwner {
        require(!permanentlyAllowCustomURIs, "NFTG: permanently enabled");
        allowCustomURIs = !allowCustomURIs;
    }

    /**
     * @notice controls ability of users to set their own URI
     */
    function permanentlyEnableCustomURIs() external onlyOwner {
        permanentlyAllowCustomURIs = true;
        allowCustomURIs = true;
    }

    function setETHPrice(uint256 _pricePerPixel) external onlyOwner {
        emit ETHPriceChanged(pricePerPixelInETH, _pricePerPixel);
        pricePerPixelInETH = _pricePerPixel;
    }

    function getPixelCredits(uint256 _start, uint256 _count) external view returns(address[] memory addresses, uint256[] memory balances) {
        require(_count > 0, "NFTG: count is 0");
        require(_start < receivedAddresses.length, "NFTG: start too high");
        uint256 stop = _start + _count;
        stop = (stop > receivedAddresses.length) ? receivedAddresses.length : stop;
        uint256 actualCount = stop - _start;
        addresses = new address[](actualCount);
        balances = new uint256[](actualCount);
        for (uint256 i = _start; i < stop; i++) {
            address current = receivedAddresses[i];
            addresses[i - _start] = current;
            balances[i - _start] = pixelCredits[current];
        }
    }

    function transferCredits(address _receiver, uint256 _amount) external reserveNotLocked {
        require(pixelCredits[msg.sender] >= _amount, "NFTG: not enough credit");
        require(_receiver != address(0), "NFTG: address 0");
        emit TransferCredit(msg.sender, _receiver, _amount);
        pixelCredits[msg.sender] -= _amount;
        pixelCredits[_receiver] += _amount;
    }

    /**
     * @notice purchases are blocked if a child block is owned by current buyer
     * @param _tokenId the tokenId of the quad to buy using Tokens
     */
    function buyWithToken(address _tokenAddress, uint64 _tokenId) external nonReentrant placementNotLocked {
        _buyWithToken(_tokenAddress, _tokenId);
    }

    /**
     * @param _tokenIds the tokenIds of the quads to buy using Tokens
    */
    function multiBuyWithToken(address _tokenAddress, uint64[] calldata _tokenIds) external nonReentrant placementNotLocked {
        for(uint i = 0; i < _tokenIds.length; i++) {
            _buyWithToken(_tokenAddress, _tokenIds[i]);
        }
    }

    function _buyWithToken(address _tokenAddress, uint64 _tokenId) private {
        uint256 pricePerPixel = pricePerPixelInTokens[_tokenAddress];
        require(pricePerPixel != 0, "NFTG: token not supported");
        Rectangle memory range = getRangeFromTokenId(_tokenId);
        uint256 price = _price(pricePerPixel, range);
        _buyCreditWithToken(_tokenAddress, msg.sender, price);
        _placeQTNode(_tokenId);
    }

    /**
     * @notice purchases are blocked if a child block is owned by current buyer
     * @param _tokenId the tokenId of the quad to buy using ETH
     */
    function buyWithETH(uint64 _tokenId) external payable nonReentrant placementNotLocked {
        _buyCreditWithETH(msg.sender);
        _placeQTNode(_tokenId);
    }

    /**
     * @param _tokenIds the tokenIds of the quads to buy using ETH
    */
    function multiBuyWithETH(uint64[] calldata _tokenIds) external payable nonReentrant placementNotLocked {
        _buyCreditWithETH(msg.sender);
        for(uint i = 0; i < _tokenIds.length; i++) {
            _placeQTNode(_tokenIds[i]);
        }
    }

    function _placeQTNode(uint64 _tokenId) private {
        Rectangle memory range = getRangeFromTokenId(_tokenId);
        uint256 pixelsToPlace = uint256(range.w) * uint256(range.h) * PIXELS_PER_TILE;
        uint256 pixelBalance = pixelCredits[msg.sender];
        require(pixelsToPlace <= pixelBalance, "NFTG: not enough credit");
        pixelCredits[msg.sender] -= pixelsToPlace;
        _mintQTNode(_tokenId);
    }

    /**
     * @notice the amount of {msg.value} is what will be used to convert into pixel credits
     * @param _receiveAddress is the address receiving the pixel credits
     */
    // slither-disable-next-line reentrancy-events
    function buyCreditWithETH(address _receiveAddress) external payable nonReentrant reserveNotLocked {
        _buyCreditWithETH(_receiveAddress);
    }

    function _buyCreditWithETH(address _receiveAddress) private {
        uint256 credit = msg.value / pricePerPixelInETH;
        require(credit > 0, "NFTG: not enough ETH sent");
        emit BuyCreditWithETH(msg.sender, _receiveAddress, msg.value, credit);
        pixelCredits[_receiveAddress] += credit;
        ownedPixels[_receiveAddress] += credit;
        totalPixelsOwned += credit;
        if (!addressExists[_receiveAddress]) {
            receivedAddresses.push(_receiveAddress); 
            addressExists[_receiveAddress] = true;
        }
        Address.sendValue(payable(owner()), msg.value);
    }

    /**
     * @param _tokenAddress is the address of the token being used to purchase the pixels
     * @param _receiveAddress is the address receiving the pixel credits
     * @param _amount is the amount in tokens - if using a stable like USDC, then this represent dollar value in wei
     */
    function buyCreditWithToken(address _tokenAddress, address _receiveAddress, uint256 _amount) external nonReentrant reserveNotLocked {
        _buyCreditWithToken(_tokenAddress, _receiveAddress, _amount);
    }

    function _buyCreditWithToken(address _tokenAddress, address _receiveAddress, uint256 _amount) private {
        uint256 pricePerPixel = pricePerPixelInTokens[_tokenAddress];
        require(pricePerPixel != 0, "NFTG: token not supported");
        uint256 credit = _amount / pricePerPixel;
        require(credit > 0, "NFTG: not enough tokens sent");
        emit BuyCreditWithToken(msg.sender, _tokenAddress, _receiveAddress, _amount, credit);
        pixelCredits[_receiveAddress] += credit;
        ownedPixels[_receiveAddress] += credit;
        totalPixelsOwned += credit;
        if (!addressExists[_receiveAddress]) {
            receivedAddresses.push(_receiveAddress); 
            addressExists[_receiveAddress] = true;
        }
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, owner(), _amount);
    }

    /**
     * @notice allows already purchased pixels to be allocated to specific token IDs
     * @dev will fail if pixel balance is insufficient
     * @param _tokenIds the tokenIds of the quads to place
     */
    function placePixels(uint64[] calldata _tokenIds) external nonReentrant placementNotLocked {
        for(uint i = 0; i < _tokenIds.length; i++) {
            _placeQTNode(_tokenIds[i]);
        }
    }

    /**
     * @dev only the leafs can be purchased
     * @dev quads are only divided if someone has owns a child (via subdivde or buyWith*)
     */
    function _mintQTNode(uint64 _tokenId) private {
        QuadTree storage qtree = qtrees[uint64(_tokenId)];
        require(!qtree.divided, "NFTG: cannot buy if divided");
        require(qtree.owner == address(0x0), "NFTG: already owned");
        
        revertIfParentOwned(_tokenId);
        _revertIfChildOwned(qtree); // needed if burning
        Rectangle memory range = getRangeFromTokenId(_tokenId);
        uint24 increaseCount = uint24(range.w) * uint24(range.h);
        _divideAndCount(getParentTokenId(_tokenId), increaseCount);
        
        qtree.owner = msg.sender;
        qtree.ownedCount = increaseCount;

        _safeMint(msg.sender, _tokenId);
    }

    function _price(uint256 _pricePerPixel, Rectangle memory _rect) private pure returns(uint256 price) {
        price = _pricePerPixel * PIXELS_PER_TILE * uint256(_rect.w) * uint256(_rect.h);
    }
    
    /**
     * @notice override the ERC720 function so that we can update user credits
     * @dev this logic only executes if pixels are being transferred from one user to another
     * @dev this contract doesn't support burning of these NFTs so we don't need to subtract on burn (_to == 0)
     * @dev this contract increases the owned count on reserve not on minting (_from == 0) we ignores those as they are already added
     */
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override {
        if ((_from != address(0)) && (_to != address(0))) {
            Rectangle memory range = getRangeFromTokenId(uint64(_tokenId));
            uint256 credit = uint256(range.w) * uint256(range.h) * PIXELS_PER_TILE;
            ownedPixels[_from] -= credit;
            ownedPixels[_to] += credit;
        }
    }

    /**
     * @notice calculates the price of multiple quads in ETH
     * @param _tokenIds the tokenIds of the quads to get the ETH prices of
     */
    // function getMultiETHPrice(uint64[] calldata _tokenIds) external view returns(uint price) {
    //     for(uint i = 0; i < _tokenIds.length; i++) {
    //         price += getETHPrice(_tokenIds[i]);
    //     }
    // }

    /**
     * @notice calculates the price of a quad in ETH
     * @param _tokenId the tokenId of the quad to get the ETH price of
     */
    function getETHPrice(uint64 _tokenId) external view returns(uint price) {
        Rectangle memory range = getRangeFromTokenId(_tokenId);
        price = _price(pricePerPixelInETH, range);
    }

    /**
     * @notice calculates the price of multiple quads in tokens
     * @param _tokenIds the tokenIds of the quads to get the token prices of
     */
    // function getMultiTokenPrice(uint64[] calldata _tokenIds) external view returns(uint price) {
    //     for(uint i = 0; i < _tokenIds.length; i++) {
    //         price += getTokenPrice(_tokenIds[i]);
    //     }
    // }

    /**
     * @notice calculates the price of a quad in Tokens
     * @param _tokenId the tokenId of the quad to get the Token price of
     */
    function getTokenPrice(address _tokenAddress, uint64 _tokenId) external view returns(uint price) {
        uint256 pricePerPixel = pricePerPixelInTokens[_tokenAddress];
        require(pricePerPixel != 0, "NFTG: token not supported");
        Rectangle memory range = getRangeFromTokenId(_tokenId);
        price = _price(pricePerPixel, range);
    }

    /**
     * @notice this function subdivides the quad 
     * @dev don't need to check the qtree of X2048 was divided in ctor
     */
    function _divideAndCount(uint64 _tokenId, uint24 _increaseBy) private {
        QuadTree storage qtree = qtrees[_tokenId];
        if (_tokenId != rootTokenId) {
            uint64 parentTokenId = getParentTokenId(_tokenId);
            _divideAndCount(parentTokenId, _increaseBy);
        }
        if (!qtree.divided) {
            _subdivideQTNode(_tokenId);
        }
        qtree.ownedCount += _increaseBy;
    }

    /**
     * useful for checking if any child is owned
     */
    function revertIfChildOwned(uint64 _tokenId) external view {
        QuadTree memory qtree = qtrees[_tokenId];
        _revertIfChildOwned(qtree);
    }

    function _revertIfChildOwned(QuadTree memory _qtree) private pure {
        require(_qtree.ownedCount == 0, "NFTG: child owned");
    }

    /**
     * useful for checking if any parent is owned
     */
    function revertIfParentOwned(uint64 _tokenId) public view {
        uint64 parentTokenId = _tokenId;
        while (parentTokenId != rootTokenId) { // NOTE: don't need to check the parent of X2048
            parentTokenId = getParentTokenId(parentTokenId);
            QuadTree memory parent = qtrees[parentTokenId];
            require(parent.owner == address(0x0), "NFTG: parent owned");
        }
    }

    /**
     * @dev symetric: should be kept up-to-date with JS implementation
     * @notice calculates a parent tile tokenId from a child - it is known that the parents w/h will be 2x the child,
     * and from that we can determine the quad using it's x/y
     * @param _tokenId the tokenId of the quad to get the parent range of
     */
    function getParentRange(uint64 _tokenId) public pure returns(Rectangle memory parent) {
        // parent is child until assignment (to save gas)...
        parent = getRangeFromTokenId(_tokenId);
        uint16 width = 2 * parent.w;
        uint16 height = 2 * parent.h;
        uint16 tileIndexX = calculateIndex(parent.x, parent.w);
        uint16 tileIndexY = calculateIndex(parent.y, parent.h);
        // slither-disable-next-line divide-before-multiply
        parent.x = tileIndexX / 2 * width + width / 2 - 1; // note: division here truncates and this is intended when going to indexes
        // slither-disable-next-line divide-before-multiply
        parent.y = tileIndexY / 2 * height + height / 2 - 1;
        parent.w = width;
        parent.h = height;
        validate(parent);
    }

    /**
     * index layout:
     *    layer 11    layer 12
     *      _0___1__   ____0___
     *   0 /   /   /  /       /
     *    /---+---/ 0/       /
     * 1 /___/___/  /_______/
     * x=127+256,y=127 w=256   x=0,y=0 w=1  special case for dimension of 1 since we move up and left
     * x=w/2-1+index*w         x=index*w
     * index*w=x-w/2+1
     * index=(x-w/2+1)/w
     */

    /**
     * @dev this function does not check values - it is presumed that the values have already passed 'validate'
     * @param _value is x or y
     * @param _dimension is w or h (respectively)
     * @return index is the index starting at 0 and going to w/GRID_W - 1 or h/GRID_H - 1
     *      the indexes of the tiles are the tokenId of the column or row of that tile (based on dimension)
     */

    function calculateIndex(uint16 _value, uint16 _dimension) public pure returns(uint16 index) {
        index = (_dimension == 1) ? (_value / _dimension) : ((_value + 1 - _dimension/2) / _dimension);
    }

    /**
     * @dev symetric: should be kept up-to-date with JS implementation
     * @notice calculates a parent tile tokenId from a child
     * @param _tokenId the tokenId of the quad to get the parent range of
     */
    function getParentTokenId(uint64 _tokenId) public pure returns(uint64 parentTokenId) {
        parentTokenId = _getTokenIdFromRangeNoCheck(getParentRange(_tokenId));
    }

    /**
     * @notice splits a tile into a quarter (a.k.a. quad)
     * @dev there are ne, nw, se, sw quads on the QuadTrees
     * @notice the quads are stored as tokenIds here not actual other QuadTrees
     */
    function subdivide(uint256 _tokenId) external placementNotLocked { 
        QuadTree memory qtree = qtrees[uint64(_tokenId)];
        require(!qtree.divided, "NFTG: already divided");
        require(qtree.owner == msg.sender, "NFTG: only owner can subdivide");
        _subdivideQTNode(uint64(_tokenId));
    }

    /**
     * @notice quad coordinates are at the center of the quad - this make dividing coords relative...
     * for root: x=1023, y=1023, w=2048, h=2048
     *  wChild = wParent/2 = 1024
     *  currently: xParent + wChild/2 = xParent + wParent/4 > 1023 + 512 = 1535
     * @dev special care was taken when writing this function so that this function does not transfer any ownership!
     */
    function _subdivideQTNode(uint64 _tokenId) private { 
        QuadTree storage qtree = qtrees[_tokenId];
        uint16 x = qtree.boundary.x;
        uint16 y = qtree.boundary.y;
        uint16 w = qtree.boundary.w;
        uint16 h = qtree.boundary.h;
        require(w > 1 && h > 1, "NFTG: cannot divide"); // cannot divide w or h=1 and 0 is not expected
        if (qtree.owner != address(0x0)) {
            _burn(uint256(_tokenId));
        }
        // special case for w|h=2
        // X2:0,0:x,y = 1,0 & 0,0 & 1,1 & 0,1
        // X2:1,0:x,y = 2,0 & 2,0 & 2,2 & 0,2
        // X2:1,1:x,y = 2,1 & 1,1 & 2,2 & 1,2
        // X2:2,2:x,y = 4,3 & 3,3 & 4,4 & 3,4
        if ((w == 2) || (h==2)) {
            qtree.northeast = _createQTNode(qtree.owner, x + 1, y - 0, w/2, h/2);
            qtree.northwest = _createQTNode(qtree.owner, x - 0, y - 0, w/2, h/2);
            qtree.southeast = _createQTNode(qtree.owner, x + 1, y + 1, w/2, h/2);
            qtree.southwest = _createQTNode(qtree.owner, x - 0, y + 1, w/2, h/2);
        } else {
            qtree.northeast = _createQTNode(qtree.owner, x + w/4, y - h/4, w/2, h/2);
            qtree.northwest = _createQTNode(qtree.owner, x - w/4, y - h/4, w/2, h/2);
            qtree.southeast = _createQTNode(qtree.owner, x + w/4, y + h/4, w/2, h/2);
            qtree.southwest = _createQTNode(qtree.owner, x - w/4, y + h/4, w/2, h/2);
        }
        qtree.divided = true;
        qtree.owner = address(0x0);
    }

    /**
     * @notice creates a QuadTree 
     * @return tokenId the tokenId of the quad
     */
    function _createQTNode(address _owner, uint16 _x, uint16 _y, uint16 _w, uint16 _h) private returns(uint64 tokenId) {
        Rectangle memory boundary = Rectangle(_x, _y, _w, _h);
        // console.log("_x", _x, "_y", _y);
        // console.log("_w", _w, "_h", _h);
        tokenId = getTokenIdFromRange(boundary);
        QuadTree storage qtree = qtrees[tokenId];
        qtree.boundary = boundary;
        qtree.owner = _owner;
        if (_owner != address(0)) {
            _safeMint(_owner, tokenId);
        }
    }

    /**
     * @dev symetric: should be kept up-to-date with JS implementation
     * entokenIdd tokenId: 0x<X:2 bytes>_<Y:2 bytes>_<W:2 bytes>_wers of 2 are 0x1 = 1, 0x10 = 2, 0x100 = 4, etc.
     *    4: 0x100 & (0x100 - 1) = 0x100 & 0x011 = 0x000
     * negative tests:
     *    7: 0x111 & (0x111 - 1) = 0x111 & 0x110 = 0x110
     *    5: 0x101 & (0x101 - 1) = 0x101 & 0x100 = 0x100
     * @notice for the x & y validation, these values are always in the middle of the first tile (0.5 * w, 0.5 * h) and are then at increments of w & h
     * therefor we can use the modulo operator and check that the remainder is precisely the offset:
     * @notice we offset x & y left one and up one so that for X1 the w=1/h=1 has x=0/y=0 and just as well for X2 w=2/h=2 has x=0,y=0
     *    the x & y values range from 0:w-1 and 0:h-1
     *    special care should be taken around w=1 and w=2 as the first tile for both is at x=0 and y=0 and
     *      for w=1 max x&y=2047 for w=2 max x&y=2046
     *<H:2 bytes> = 8 bytes = 64 bits (4 hex represent 2 bytes)
     * to get x we right shift by 6 bytes: 0x0000_0000_0000_<X:2 bytes>
     * to get y we right shift by 4 bytes & 0xFFFF: 0x0000_0000_<X:2 bytes>_<Y:2 bytes> & 0xFFFF = 0x0000_0000_0000_<Y:2 bytes>
     */
    function getRangeFromTokenId(uint64 _tokenId) public pure returns(Rectangle memory range) {
        uint16 mask = 0xFFFF;
        range.x = uint16((_tokenId >> 6 * 8) & mask);
        range.y = uint16((_tokenId >> 4 * 8) & mask);
        range.w = uint16((_tokenId >> 2 * 8) & mask);
        range.h = uint16(_tokenId & mask);
        validate(range);
    }

    /**
     * @dev symetric: should be kept up-to-date with JS implementation
     * entokenIdd tokenId: 0x<X:2 bytes><Y:2 bytes><W:2 bytes><H:2 bytes> = 8 bytes = 64 bits
     */
    function getTokenIdFromRange(Rectangle memory _range) public pure returns(uint64 tokenId) {
        validate(_range);
        tokenId = _getTokenIdFromRangeNoCheck(_range);
    }

    function _getTokenIdFromRangeNoCheck(Rectangle memory _range) private pure returns(uint64 tokenId) {
        tokenId = (uint64(_range.x) << 6 * 8) + (uint64(_range.y) << 4 * 8) + (uint64(_range.w) << 2 * 8) + uint64(_range.h);
    }

    /**
     * @dev symetric: should be kept up-to-date with JS implementation
     * @notice the w and h must be a power of 2 and instead of comparing to all of the values in the enum, we just check it using:
     *    N & (N - 1)  this works because all powers of 2 are 0x1 = 1, 0x10 = 2, 0x100 = 4, etc.
     *    4: 0x100 & (0x100 - 1) = 0x100 & 0x011 = 0x000
     * negative tests:
     *    7: 0x111 & (0x111 - 1) = 0x111 & 0x110 = 0x110
     *    5: 0x101 & (0x101 - 1) = 0x101 & 0x100 = 0x100
     * @notice for the x & y validation, these values are always in the middle of the first tile (0.5 * w, 0.5 * h) and are then at increments of w & h
     * there for we can use the modulo operator and check that the remainder is precisely the offset:
     * @notice we offset x & y left one and up one so that for X1 the w=1/h=1 has x=0/y=0 and just as well for X2 w=2/h=2 has x=0,y=0
     *    the x & y values range from 0:w-1 and 0:h-1
     *    special care should be taken around w=1 and w=2 as the first tile for both is at x=0 and y=0 and
     *      for w=1 max x&y=2047 for w=2 max x&y=2046
     */
    function validate(Rectangle memory _range) public pure {
        require((_range.x <= GRID_W - 1), "NFTG: x is out-of-bounds");
        require((_range.y <= GRID_H - 1), "NFTG: y is out-of-bounds");
        require((_range.w > 0), "NFTG: w must be greater than 0");
        require((_range.h > 0), "NFTG: h must be greater than 0");
        require((_range.w <= GRID_W), "NFTG: w is too large");
        require((_range.h <= GRID_H), "NFTG: h is too large");
        require((_range.w & (_range.w - 1) == 0), "NFTG: w is not a power of 2"); 
        require((_range.h & (_range.h - 1) == 0), "NFTG: h is not a power of 2");
        uint16 xMidOffset = _range.w / 2; // for w=1 xmid=0, w=2 xmid=1, w=4 xmid=2, etc.
        uint16 yMidOffset = _range.h / 2;
        // for w=1 and x=2047: (2047+1)%1=0, w=2 and x=1023: (1023+1)%2=0, w=4 and x=255: (255+1)%4=0
        require(((_range.x + 1) % _range.w) == xMidOffset, "NFTG: x is not a multiple of w");
        require(((_range.y + 1) % _range.h) == yMidOffset, "NFTG: y is not a multiple of h");
    }

    //// BOILERPLATE
    
    // receive eth with no calldata
    // see: https://blog.soliditylang.org/2020/03/26/fallback-receive-split/
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    // receive eth with no function match
    fallback() external payable {}

    function withdraw() external onlyOwner {
        address payable owner = payable(owner());
        owner.transfer(address(this).balance);
    }

    function withdrawToken(address _token, uint _amount) external onlyOwner {
        IERC20(_token).safeTransfer(owner(), _amount);
    }
}


