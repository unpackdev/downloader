// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./SSTORE2.sol";
import "./IPixelationsRenderer.sol";

/*

    ██████╗░██╗██╗░░██╗███████╗██╗░░░░░░█████╗░████████╗██╗░█████╗░███╗░░██╗░██████╗
    ██╔══██╗██║╚██╗██╔╝██╔════╝██║░░░░░██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║██╔════╝
    ██████╔╝██║░╚███╔╝░█████╗░░██║░░░░░███████║░░░██║░░░██║██║░░██║██╔██╗██║╚█████╗░
    ██╔═══╝░██║░██╔██╗░██╔══╝░░██║░░░░░██╔══██║░░░██║░░░██║██║░░██║██║╚████║░╚═══██╗
    ██║░░░░░██║██╔╝╚██╗███████╗███████╗██║░░██║░░░██║░░░██║╚█████╔╝██║░╚███║██████╔╝
    ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═════╝░


    What are Pixelations?

    Pixelations are an NFT collection of 32x32 pixelated images. There are 3,232 Pixelations,
    each 100% stored and rendered on-chain.

    For this collection, we took a unique approach. Rather than designing the art ourselves,
    we are giving the minter the ability to provide the art. This image could be anything:
    an IRL photo, a painting, or a JPEG pulled off the internet.

    How does it work?

    Upon minting, we perform a number of image processing steps in order to viably store your
    image on chain, and also reduce minting gas fees as much as possible. At a high level we
    do the following off chain:

    1. Convert the image into 32x32 pixels.

    2. Extract the 32 colors that best represent the image via k-means clustering.

    3. Compress the image via bit-packing since we now only need 5-bits to represent it's 32 colors.

    After these off chain steps, your image is roughly 700 bytes of data that we store in
    our custom ERC-721 smart contract. When sites like OpenSea attempt to fetch your
    Pixelation's metadata and image, our contract renders an SVG at run-time.

    ----------------------------------------------------------------------------

    Special shoutout to Chainrunners and Blitmap for the inspiration and help.
    We used a lot of the same techniques in order to perform efficient rendering.
*/

contract Pixelations is ERC721Enumerable, Ownable, ReentrancyGuard {
    uint256 public MAX_TOKENS = 3232;
    address public renderingContractAddress;

    mapping(address => uint256) public earlyAccessMintsAllowed;

    mapping(address => uint256) public privateSaleMintsAllowed;
    uint256 private constant PRIVATE_SALE_MINT_PRICE = 0.025 ether;

    uint256 public publicSaleStartTimestamp;
    uint256 private constant PUBLIC_SALE_MINT_PRICE = 0.05 ether;

    uint256 public numberOfMints;
    uint256 private MAX_PIXEL_DATA_LENGTH = 640;
    uint256 private MAX_COLOR_DATA_LENGTH = 96;
    uint256 private MAX_TOKEN_DATA_LENGTH = MAX_PIXEL_DATA_LENGTH + MAX_COLOR_DATA_LENGTH;
    address[] private _tokenDatas;

    bool public mintingCompleteAndValid;

    constructor() ERC721("Pixelations", "PIX") {}

    modifier whenPublicSaleActive() {
        require(isPublicSaleOpen(), "Public sale not open");
        _;
    }

    function isPublicSaleOpen() public view returns (bool) {
        return publicSaleStartTimestamp != 0 && block.timestamp >= publicSaleStartTimestamp;
    }

    function setPublicSaleStartTimestamp(uint256 timestamp) external onlyOwner {
        publicSaleStartTimestamp = timestamp;
    }

    function mintEarlyAccess(bytes memory tokenData)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        require(getRemainingEarlyAccessMints(msg.sender) > 0, "Address has no more early access mints remaining.");
        earlyAccessMintsAllowed[msg.sender]--;
        return _mintNewToken(tokenData);
    }

    function mintPrivateSale(bytes memory tokenData)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        require(getRemainingPrivateSaleMints(msg.sender) > 0, "Address has no more private sale mints remaining.");
        require(PRIVATE_SALE_MINT_PRICE == msg.value, "Incorrect amount of ether sent.");
        privateSaleMintsAllowed[msg.sender]--;
        return _mintNewToken(tokenData);
    }

    function mintPublicSale(bytes memory tokenData)
        external
        payable
        nonReentrant
        whenPublicSaleActive
        returns (uint256)
    {
        require(PUBLIC_SALE_MINT_PRICE == msg.value, "Incorrect amount of ether sent.");
        return _mintNewToken(tokenData);
    }

    // Technically any set of bytes of length 736 is a valid Pixelation.
    //
    // The first 640 bytes represent each pixel's bitmap. There are 32 colors so we
    // represent each pixel as a 5 bit index into an array of 32 colors.
    //
    // The next 96 bytes represent 32 colors. Each color is a 3 byte RGB.
    function _mintNewToken(bytes memory tokenData) internal returns (uint256) {
        require(tokenData.length == MAX_TOKEN_DATA_LENGTH, "tokenData must be 736 bytes.");
        require(numberOfMints < MAX_TOKENS, "All Pixelations have been minted.");

        _tokenDatas.push(SSTORE2.write(tokenData));

        uint256 newItemId = numberOfMints + 1;

        _safeMint(msg.sender, newItemId);
        numberOfMints++;

        return newItemId;
    }

    function getRemainingEarlyAccessMints(address addr) public view returns (uint256) {
        return earlyAccessMintsAllowed[addr];
    }

    function addToEarlyAccessList(address[] memory toEarlyAccessList, uint256 mintsAllowed) external onlyOwner {
        for (uint256 i = 0; i < toEarlyAccessList.length; i++) {
            earlyAccessMintsAllowed[toEarlyAccessList[i]] = mintsAllowed;
        }
    }

    function getRemainingPrivateSaleMints(address addr) public view returns (uint256) {
        return privateSaleMintsAllowed[addr];
    }

    function addToPrivateSaleList(address[] memory toPrivateSaleList, uint256 mintsAllowed) external onlyOwner {
        for (uint256 i = 0; i < toPrivateSaleList.length; i++) {
            privateSaleMintsAllowed[toPrivateSaleList[i]] = mintsAllowed;
        }
    }

    // Hopefully we don't have to use this. But as a safeguard for if somebody needs to change their photo
    // we have the ability to override the token data. Once all tokens are minted and verified to be valid, we can close
    // off this functionality with: setMintingCompleteAndValid()
    function overwriteExistingTokenData(
        uint256 tokenId,
        bytes memory tokenData
    ) external onlyOwner {
        require(tokenId >= 1, "Invalid tokenId.");
        require(tokenId <= numberOfMints, "Token hasn't been minted yet.");
        require(tokenData.length == MAX_TOKEN_DATA_LENGTH, "tokenData must be 736 bytes.");
        require(!mintingCompleteAndValid, "You are not allowed to overwrite existing token data anymore.");

        uint256 tokenIndex = tokenId - 1;
        _tokenDatas[tokenIndex] = SSTORE2.write(tokenData);
    }

    function setMintingCompleteAndValid() external onlyOwner {
        mintingCompleteAndValid = true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (renderingContractAddress == address(0)) {
            return '';
        }

        IPixelationsRenderer renderer = IPixelationsRenderer(renderingContractAddress);
        return renderer.tokenURI(tokenId, tokenDataForToken(tokenId));
    }

    // Handy function for only rendering the svg.
    function tokenSVG(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (renderingContractAddress == address(0)) {
            return '';
        }

        IPixelationsRenderer renderer = IPixelationsRenderer(renderingContractAddress);
        return renderer.tokenSVG(tokenDataForToken(tokenId));
    }

    function tokenDataForToken(uint256 tokenId) public view returns (bytes memory) {
        return SSTORE2.read(_tokenDatas[tokenId-1]);
    }

    function setRenderingContractAddress(address _renderingContractAddress) public onlyOwner {
        renderingContractAddress = _renderingContractAddress;
    }

    receive() external payable {}

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}
