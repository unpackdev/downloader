//"SPDX-License-Identifier: GPL-3.0

/*******************************************
              _                       _
             | |                     | |
  _ __   ___ | |_   _ ___   __ _ _ __| |_
 | '_ \ / _ \| | | | / __| / _` | '__| __|
 | |_) | (_) | | |_| \__ \| (_| | |  | |_
 | .__/ \___/|_|\__, |___(_)__,_|_|   \__|
 | |             __/ |
 |_|            |___/

 a homage to math, geometry and cryptography.

********************************************/
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./SSTORE2.sol";
import "./Base64.sol";
import "./PolyRenderer.sol";


contract Polys is ERC721, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;
    using Base64 for bytes;

    // Token structs and types
    // -------------------------------------------
    enum TokenType {Original, Offspring, Circle}

    struct Parents {
        uint16 polyIdA;
        uint16 polyIdB;
    }

    struct TokenMetadata {
        string name;
        address creator;
        uint8 remainingChildren;
        bool wasCircled;
        TokenType tokenType;
    }

    struct Counters {
        uint8 originals;
        uint16 offspring;
    }

    // Events
    // -------------------------------------------
    event AuctionStarted(uint256 startTime);
    event BreedingStarted();
    event CirclingStarted();

    // Constants
    // -------------------------------------------
    // all eth in this wallet will be used for charity actions
    address private constant _charityWallet = 0xE00327f0f5f5F55d01C2FC6a87ddA1B8E292Ac79;

    uint8 private constant _MAX_NUM_ORIGINALS = 100;
    uint8 private constant _MAX_NUM_OFFSPRING = 16;
    uint8 private constant _MAX_PER_EARLY_ACCESS_ADDRESS = 4;
    uint8 private constant _MAX_CIRCLES_PER_WALLET = 5;

    uint private constant _START_PRICE = 16 ether;
    uint private constant _RESERVE_PRICE = 0.25 ether;
    uint private constant _AUCTION_DURATION = 1 days;
    uint private constant _HALVING_PERIOD = 4 hours; // price halves every halving period


    // State variables
    // -------------------------------------------

    // We always return the on-chain image, but currently some platforms can't render on-chain images
    // so we will also provide an off-chain version. Once the majority of the platforms upgrade and start rendering
    // on-chain images, we will stop providing the off-chain version.
    bool private _alsoShowOffChainVersion;

    // We might want to add the animation we used on the website to the NFT itself sometime in the future.
    bool private _alsoShowAnimationUrl;

    uint public auctionStartTime;
    bool public isBreedingSeason;
    bool public isCirclingSeason;
    mapping(address => uint) public availableBalance;

    Counters private _counters;
    mapping(address => uint) private _circlesMinted;

    address private _openSeaProxyRegistryAddress;
    bool private _isOpenSeaProxyActive = true;
    string private _baseUrl = "https://polys.art/poly/";

    // Original Variables
    // -------------------------------------------
    // @dev only originals have data
    mapping(uint256 => TokenMetadata) public tokenMetadata;
    mapping(uint256 => address) private _tokenDataPointers;
    mapping(address => string) private _creatorsName;

    // Offspring Variables
    // -------------------------------------------
    mapping(uint256 => Parents) private _tokenIdToParents;
    mapping(bytes32 => bool) private _tokenPairs;
    mapping(address => uint8) private _mintedOnPreSale;

    constructor(address openSeaProxyRegistryAddress) ERC721("Polys", "POLY") {
        _openSeaProxyRegistryAddress = openSeaProxyRegistryAddress;
    }

    // Creation Functions
    // -------------------------------------------
    function mint(bytes calldata polyData, string calldata name, uint256 tokenId,
        address creator, bytes calldata signature) nonReentrant payable external {
        require(tokenId <= _MAX_NUM_ORIGINALS && tokenId > 0, "1");
        require(verify(abi.encodePacked(polyData, name, tokenId, creator), signature), "2");
        require(polyData.length > 19 && polyData.length < 366, "3");
        require(polyData.length % 5 == 0, "4");
        require(bytes(name).length > 0 && bytes(name).length < 11, "5");
        require(auctionStartTime != 0, "13");

        if (msg.sender != creator) {
            require(msg.value >= price(), "6");
            uint256 tenPercent = msg.value / 10;
            availableBalance[owner()] += tenPercent;
            availableBalance[creator] += (msg.value-tenPercent);
        } else if (msg.sender != owner()) {
            // artists can mint their own pieces for 10%, and the founder can mint his pieces for free
            // so in practise each artist sets the minimum price of their NFTs,
            // if price goes lower than their minimum, they will mint them themselves.
            require(msg.value >= (price() / 10), "6");
            availableBalance[owner()] += msg.value;
        }

        TokenMetadata memory metadata;
        metadata.name = name;
        metadata.remainingChildren = _MAX_NUM_OFFSPRING;
        metadata.creator = creator;
        metadata.tokenType = TokenType.Original;

        // SSTORE2 significantly reduces the gas costs. Kudos to hypnobrando for showing me this solution.
        _tokenDataPointers[tokenId] = SSTORE2.write(polyData);
        tokenMetadata[tokenId] = metadata;
        _counters.originals += 1;

        _mint(msg.sender, tokenId);
    }

    // State changing functions
    // -------------------------------------------
    function startAuction() external onlyOwner {
        require(auctionStartTime == 0); // can't start the auction twice.
        auctionStartTime = block.timestamp;
        emit AuctionStarted(auctionStartTime);
    }

    function alsoShowOffChainVersion(bool state) external onlyOwner {
        _alsoShowOffChainVersion = state;
    }

    function alsoShowAnimationUrl(bool state) external onlyOwner {
        _alsoShowAnimationUrl = state;
    }

    function setBaseUrl(string calldata baseUrl) external onlyOwner {
        _baseUrl = baseUrl;
    }

    function startBreedingSeason() public onlyOwner {
        isBreedingSeason = true;
        emit BreedingStarted();
    }

    function startCirclingSeason() public onlyOwner {
        isCirclingSeason = true;
        emit CirclingStarted();
    }

    function signPieces(string calldata name) public {
        require(bytes(name).length < 16);
        _creatorsName[msg.sender] = name;
    }

    // Disable gas-less listings to OpenSea. Kudos to Crypto Coven!
    function setIsOpenSeaProxyActive(bool isOpenSeaProxyActive) external onlyOwner {
        _isOpenSeaProxyActive = isOpenSeaProxyActive;
    }

    // Circling and Mixing
    // -------------------------------------------
    function mintCircle(uint256 polyId) external nonReentrant payable {
        require(isCirclingSeason, "7");
        require(tokenIsOriginal(polyId), "8");
        require(tokenMetadata[polyId].wasCircled == false, "9");
        require(msg.value == 0.314 ether, "6");
        require(_circlesMinted[msg.sender] < _MAX_CIRCLES_PER_WALLET);
        _circlesMinted[msg.sender] += 1;

        uint256 circleTokenId = _MAX_NUM_ORIGINALS + polyId;

        tokenMetadata[polyId].wasCircled = true;

        _safeMint(msg.sender, circleTokenId);

        availableBalance[creatorOf(polyId)] += 0.2512 ether;
        availableBalance[owner()] += 0.0314 ether;
        availableBalance[_charityWallet] += 0.0314 ether;
    }

    function preSaleOffspring(uint256 polyIdA, uint256 polyIdB, bytes calldata signature) external nonReentrant payable {
        require(_mintedOnPreSale[msg.sender] < _MAX_PER_EARLY_ACCESS_ADDRESS, "10");
        require(verify(abi.encodePacked(msg.sender), signature), "2");
        _mintedOnPreSale[msg.sender] += 1;
        _mintOffspring(polyIdA, polyIdB);
    }

    function publicSaleOffspring(uint256 polyIdA, uint256 polyIdB) external nonReentrant payable {
        require(isBreedingSeason, "11");
        _mintOffspring(polyIdA, polyIdB);
    }

    // Internal
    // -------------------------------------------
    function verify(bytes memory message, bytes calldata signature) internal view returns (bool){
        return keccak256(message).toEthSignedMessageHash().recover(signature) == owner();
    }

    function description(bool isCircle) internal pure returns (string memory) {
        string memory shape = isCircle ? '"Circles' : '"Regular polygons';
        return string(abi.encodePacked(shape, ' on an infinitely scalable canvas."'));
    }

    // Shout out to blitmap for coming up with this breeding mechanic
    function _mintOffspring(uint256 polyIdA, uint256 polyIdB) internal {
        require(tokenIsOriginal(polyIdA) && tokenIsOriginal(polyIdB), "16");
        require(polyIdA != polyIdB, "17");
        require(tokenMetadata[polyIdA].remainingChildren > 0, "18");
        require(msg.value == 0.08 ether, "6");

        // a given pair can only be minted once
        bytes32 pairHash = keccak256(abi.encodePacked(polyIdA, polyIdB));
        require(_tokenPairs[pairHash] == false, "19");

        _counters.offspring += 1;
        uint256 offspringTokenId = 2 * _MAX_NUM_ORIGINALS + _counters.offspring;

        Parents memory parents;
        parents.polyIdA = uint16(polyIdA);
        parents.polyIdB = uint16(polyIdB);

        tokenMetadata[polyIdA].remainingChildren--;

        _tokenIdToParents[offspringTokenId] = parents;
        _tokenPairs[pairHash] = true;
        _safeMint(msg.sender, offspringTokenId);

        availableBalance[creatorOf(polyIdA)] += 0.056 ether;
        availableBalance[creatorOf(polyIdB)] += 0.008 ether;
        availableBalance[owner()] += 0.008 ether;
        availableBalance[_charityWallet] += 0.008 ether;
    }

    // Withdraw
    // -------------------------------------------
    function withdraw() public nonReentrant {
        uint256 withdrawAmount = availableBalance[msg.sender];
        availableBalance[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: withdrawAmount}('');
        require(success, "12");
    }

    // Getters
    // -------------------------------------------
    function numMintedOriginals() public view returns (uint) {
        return _counters.originals;
    }

    function pairIsTaken(uint256 polyIdA, uint256 polyIdB) public view returns (bool) {
        bytes32 pairHash = keccak256(abi.encodePacked(polyIdA, polyIdB));
        return _tokenPairs[pairHash];
    }

    function price() public view returns (uint256) {
        require(block.timestamp >= auctionStartTime);
        uint timeElapsed = block.timestamp - auctionStartTime; // timeElapsed since start of the auction
        if (timeElapsed > _AUCTION_DURATION)
            return _RESERVE_PRICE;
        uint period = timeElapsed/_HALVING_PERIOD;
        uint start_price = _START_PRICE >> period;  // start price for current period
        uint end_price = _START_PRICE >> (period + 1);  // end price for current period
        timeElapsed = timeElapsed % _HALVING_PERIOD; // timeElapsed since the start of the current period
        return ((_HALVING_PERIOD - timeElapsed)*start_price + timeElapsed * end_price)/_HALVING_PERIOD;
    }

    function parentOfCircle(uint circleId) public view returns (uint256){
        require(tokenIsCircle(circleId), "14");
        return circleId - _MAX_NUM_ORIGINALS;
    }

    function creatorNameOf(uint polyId) public view returns(string memory){
        return _creatorsName[creatorOf(polyId)];
    }

    function creatorOf(uint polyId) public view returns (address){
        uint tokenId;
        if (tokenIsOriginal(polyId)){
            tokenId = polyId;
        } else if (tokenIsCircle(polyId)){
            tokenId = parentOfCircle(polyId);
        } else {
            tokenId = _tokenIdToParents[polyId].polyIdA;
        }
        return tokenMetadata[tokenId].creator;
    }

    function tokenIsOriginal(uint256 polyId) public view returns (bool) {
        return _exists(polyId) && (polyId <= _MAX_NUM_ORIGINALS);
    }

    function tokenIsCircle(uint256 polyId) public view returns (bool) {
        return _exists(polyId) && polyId > _MAX_NUM_ORIGINALS && polyId <= 2*_MAX_NUM_ORIGINALS;
    }

    function parentsOfMix(uint256 mixId) public view returns (uint256, uint256) {
        require(!tokenIsOriginal(mixId) && !tokenIsCircle(mixId));
        return (_tokenIdToParents[mixId].polyIdA, _tokenIdToParents[mixId].polyIdB);
    }

    function tokenNameOf(uint polyId) public view returns (string memory) {
        require(_exists(polyId), "15");
        if (tokenIsOriginal(polyId)) {
            return tokenMetadata[polyId].name;
        }
        if (tokenIsCircle(polyId)) {
            return string(abi.encodePacked("Circled ", tokenMetadata[parentOfCircle(polyId)].name));
        }
        Parents memory parents = _tokenIdToParents[polyId];
        return string(abi.encodePacked(tokenMetadata[parents.polyIdA].name, " ",
            tokenMetadata[parents.polyIdB].name));
    }

    function tokenDataOf(uint256 polyId) public view returns (bytes memory) {
        if (tokenIsOriginal(polyId)) {
            return SSTORE2.read(_tokenDataPointers[polyId]);
        }
        if (tokenIsCircle(polyId)) {
            return SSTORE2.read(_tokenDataPointers[parentOfCircle(polyId)]);
        }
        bytes memory composition = SSTORE2.read(_tokenDataPointers[_tokenIdToParents[polyId].polyIdA]);
        bytes memory palette = SSTORE2.read(_tokenDataPointers[_tokenIdToParents[polyId].polyIdB]);

        // Is the first palette colour equal to the background color:
        bool compositionUsesNegativeTechnique = (composition[0] == composition[3]) && (composition[1] == composition[4])
                                                && (composition[2] == composition[5]);
        // Some compositions use a few polys with the colour of the background to remove foreground from the image.
        // We call this, the "negative technique", because adding polys subtracts foreground instead of adding.
        // For this technique to be correctly translated to mixings, we do two things:
        // 1) we ordered (off-chain) all the colours in the palette according to their distance to the background color
        // so that the most similar colour to the background is the first.
        // 2) if the composition uses the "negative technique", then on the palette we replace the closest colour to the
        // background with the actual background so that this technique is applied perfectly.

        for (uint8 i = 0; i < 15; ++i) {
            if (compositionUsesNegativeTechnique && i > 2 && i < 6){
                // make the first palette colour the same as the background
                composition[i] = palette[i-3];
            } else {
                composition[i] = palette[i];
            }
        }
        return composition;
    }

    function tokenURI(uint polyId) override public view returns (string memory) {
        require(_exists(polyId), "15");
        bytes memory polyData = tokenDataOf(polyId);
        bool isCircle = tokenIsCircle(polyId);
        string memory idStr = polyId.toString();
        string memory svg = PolyRenderer.svgOf(polyData, isCircle);

        bytes memory media = abi.encodePacked('data:image/svg+xml;base64,', bytes(svg).encode());
        if (_alsoShowOffChainVersion) {
            media = abi.encodePacked(',"image_data":"', media, '","image":"', _baseUrl, idStr);
        } else {
            media = abi.encodePacked(',"image":"', media);
        }
        if (_alsoShowAnimationUrl) {
            media = abi.encodePacked(',"animation_url":"', _baseUrl, "anim/", idStr, '"', media);
        }

        string memory json = abi.encodePacked('{"name":"#', idStr, " ", tokenNameOf(polyId),
            '","description":', description(isCircle), media, '","attributes":',
            PolyRenderer.attributesOf(polyData, isCircle), '}').encode();
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    // Allow gas-less listings on OpenSea.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(
            _openSeaProxyRegistryAddress
        );
        if (_isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
}

// Used to Allow gas-less listings on OpenSea
contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/*
errors:
1: Original token id should be between 1 and 100.
2: Invalid signature.
3: Poly data length should be between 20 and 365 bytes.
4: Poly data length should be a multiple of 5.
5: The poly name needs to be between 1 and 10 characters.
6: ETH value is incorrect.
7: It is not circle season.
8: Token id is not original.
9: That parent was already circled.
10: No more pre-sale mints left.
11: It is not breeding season.
12: Withdraw failed.
13: Auction has not started yet.
14: That token is not a circle.
15: Poly does not exist.
16: One or two parents are not original
17: The parents can't be the same.
18: The first parent has 0 remaining children
19: That combination was already minted.
*/