// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.8;

import "./IERC2981.sol";
import "./Pausable.sol";
import "./ERC721A.sol";
import "./ICapsuleMetadata.sol";
import "./ICapsuleRenderer.sol";
import "./ISkribbles.sol";
import "./ITypeface.sol";

/// ----------------------------------------------------------------------------- 
/// --------------------------------- BASED ON ----------------------------------
/// ----------------------------------------------------------------------------- 
///                                                                          
///              000    000   0000    0000  0   0  0      00000   0000             
///             0   0  0   0  0   0  0      0   0  0      0      0               
///             0      00000  0000    000   0   0  0      0000    000              
///             0   0  0   0  0          0  0   0  0      0          0            
///              000   0   0  0      0000    000   00000  00000  0000              
///
/// ----------------------------------------------------------------------------- 
/// ------------------0xABF3e9F15a4529bf1769EAB968250c9243A8E7C1-----------------
/// ----------------------------------------------------------------------------- 
/// ------------------------------ BY THE LEGENDARY -----------------------------
/// ----------------------------------------------------------------------------- 
///
///                 0000  00000 0000  00000     00000 00000 0   0
///                 0   0 0     0   0   0       0       0   0   0
///                 0000  0000  0000    0       0000    0   00000
///                 0     0     0 0     0       0       0   0   0
///                 0     00000 0  0  00000  0  00000   0   0   0
///
/// ----------------------------------------------------------------------------- 
/// ------------------------------ I SALUTE YOU ---------------------------------
/// -----------------------------------------------------------------------------

/**
  @title Skribbles

  @notice Fork of the Capsules contracts by the amazing >>> peri.eth / @Peripheralist <<<
  
  Contract address of CapsuleToken: 0xABF3e9F15a4529bf1769EAB968250c9243A8E7C1 / Further 
  info: https://cpsls.app/#/
  
  There are several reasons I decides to fork Peri's Capsules project:

    I stumbled upon this project as part of a deep dive into svg/composable NFT's (as part 
    of the speed run ethereum by buidlguidl.eth). This project stood out in terms of orginality,
    and I wanted to study it in all of its details and increase my experience in buidling svg nft 
    projects.

    Regardless of the originality, the capsules project remained unnoticed by the degen nft community. 
    To draw more attention to this type of projects (non-pfp nfts), as well as svg nfts in general, I wanted to be able to 
    mint and distribute Capsules while dropping some of the restrictions in the original contract and 
    without paying the minting fee (mintAsOwner).
  
  To the extent there is every going to paid minting: 70% of revenues (or such lower percentage
  he can unilaterally set) will be claimable by peri.eth.

  Ξ∞

  @dev Errors and Events are defined in ISkribbles

  @author degenwizards.eth / @degenwizards
 */
contract Skribbles is
    ISkribbles,
    ERC721A,
    IERC2981,
    Ownable,
    Pausable
{

    /// Price to mint a Skribble
    uint256 public mintPrice;

    /// Address that mints for free on this contract
    address public mintMaster;

    /// capsuleTypeface address
    address public immutable capsuleTypeface;

    /// Default CapsuleRenderer address
    address public defaultRenderer;

    /// CapsuleMetadata address
    address public CapsuleMetadata;

    /// Address to receive mint and royalty fees
    address public feeReceiverOne;
    address public feeReceiverTwo;

    /// Fee amount out of 1000 for receiverOne;
    uint256 public feeTakeOne;

    /// Royalty amount out of 1000
    uint256 public royalty;

    /// Validity of a renderer address
    mapping(address => bool) internal _validRenderers;

    /// Text of a Skribble ID
    mapping(uint256 => bytes32[8]) internal _textOf;

    /// Color of a Skribble ID
    mapping(uint256 => bytes3) internal _colorOf;

    /// Font of a Skribble ID
    mapping(uint256 => Font) internal _fontOf;

    /// Renderer address of a Skribble ID
    mapping(uint256 => address) internal _rendererOf;

    /// Numer of gift mints for addresses
    mapping(address => uint256) internal _giftCount;

    /// Contract URI
    string internal _contractURI;


    /* -------------------------------------------------------------------------- */
    /*       0   0   000   0000   00000  00000  00000  00000  0000    0000        */
    /*       00 00  0   0  0   0    0    0        0    0      0   0  0            */
    /*       0 0 0  0   0  0   0    0    00000    0    00000  0000    000         */
    /*       0   0  0   0  0   0    0    0        0    0      0 0        0        */
    /*       0   0   000   0000   00000  0      00000  00000  0  0   0000         */
    /* -------------------------------------------------------------------------- */
    /* -------------------------------- MODIFIERS ------------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Require that the value sent is at least MINT_PRICE.
    modifier requireMintPrice() {
        if (msg.value < mintPrice) revert ValueBelowMintPrice();
        _;
    }

    /// @notice Require that the gift count of sender is greater than 0.
    modifier requireGift() {
        if (giftCountOf(msg.sender) == 0) revert NoGiftAvailable();
        _;
    }

    /// @notice Require that the font is valid for a given renderer.
    modifier onlyValidFontForRenderer(Font memory font, address renderer) {
        if (!isValidFontForRenderer(font, renderer))
            revert InvalidFontForRenderer(renderer);
        _;
    }

    /// @notice Require that the font is valid for a given renderer.
    modifier onlyValidRenderer(address renderer) {
        if (!isValidRenderer(renderer)) revert InvalidRenderer();
        _;
    }

    /// @notice Require that the sender owns the Skribble.
    modifier onlySkribbleOwner(uint256 SkribbleId) {
        address owner = ownerOf(SkribbleId);
        if (owner != msg.sender) revert NotSkribbleOwner(owner);
        _;
    }

    /// @notice Require that the sender is feeReceiverOne.
    modifier onlyFeeReceiverOne() {
        if (msg.sender != feeReceiverOne) revert OnlyFeeReceiverOneCanDoThis();
        _;
    }

    /// @notice Require that the sender is feeReceiverTwo.
    modifier onlyFeeReceiverTwo() {
        if (msg.sender != feeReceiverTwo) revert OnlyFeeReceiverTwoCanDoThis();
        _;
    }

    /// @notice Require that the sender is mintMaster or owner.
    modifier onlyMintMaster() {
        if (msg.sender != owner() && msg.sender != mintMaster) revert OnlyMintMasterCanDoThis();
        _;
    }

    /// @notice Require that the address param in not address(0)
    modifier notZeroAddress(address inputAddress) {
        if(inputAddress == address(0)) revert InputAddressCanNotBeAddressZero();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*  000    000   0   0   0000  00000  0000   0   0   000   00000  000   0000  */
    /* 0   0  0   0  00  0  0        0    0   0  0   0  0   0    0   0   0  0   0 */
    /* 0      0   0  0 0 0   000     0    0000   0   0  0        0   0   0  0000  */
    /* 0   0  0   0  0  00      0    0    0  0   0   0  0   0    0   0   0  0  0  */
    /*  000    000   0   0  0000     0    0   0   000    000     0    000   0   0 */
    /* -------------------------------------------------------------------------- */
    /* ------------------------------- CONSTRUCTOR ------------------------------ */
    /* -------------------------------------------------------------------------- */


    constructor(
        address _capsuleTypeface,
        address _defaultRenderer,
        address _CapsuleMetadata,
        address _feeReceiver1,
        address _feeReceiver2,
        uint256 _feeTakeOne,
        uint256 _royalty
    ) ERC721A("Skribbles", "b_b") {
        capsuleTypeface = _capsuleTypeface;
        _setDefaultRenderer(_defaultRenderer);
        _setMetadata(_CapsuleMetadata);
        _setFeeReceiverOne(_feeReceiver1);
        _setFeeReceiverTwo(_feeReceiver2);
        _setRoyalty(_royalty);
        _pause();
        _setMintingPrice(1e16); // 0.01 ETH
        _setFeeTakeOne(_feeTakeOne);

    }

    /* -------------------------------------------------------------------------- */
    /*           00000  0   0  00000  00000  0000   0   0   000   0               */
    /*           0       0 0     0    0      0   0  00  0  0   0  0               */
    /*           0000     0      0    0000   0000   0 0 0  00000  0               */
    /*           0       0 0     0    0      0  0   0  00  0   0  0               */
    /*           00000  0   0    0    00000  0   0  0   0  0   0  00000           */
    /* -------------------------------------------------------------------------- */
    /* --------------------------- EXTERNAL FUNCTIONS --------------------------- */
    /* -------------------------------------------------------------------------- */


    /// @notice Mints a Skribble to sender, saving gas by not setting text.
    /// @param color Color of Skribble.
    /// @param font Font of Skribble.
    /// @return skribbleId ID of minted Skribble.
    function mint(
        bytes3 color,
        Font calldata font,
        bytes32[8] calldata text
    )
        external
        payable
        whenNotPaused
        requireMintPrice
        returns (uint256 skribbleId)
    {
        skribbleId = _mintSkribble(msg.sender, color, font, text);
    }

    /// @notice Mints a Skribble to sender, saving gas by not setting text.
    /// @param color Color of Skribble.
    /// @param font Font of Skribble.
    /// @return skribbleId ID of minted Skribble.
    function mintGift(
        bytes3 color,
        Font calldata font,
        bytes32[8] calldata text
    )
        external
        whenNotPaused
        requireGift
        returns (uint256 skribbleId)
    {
        _giftCount[msg.sender]--;
        skribbleId = _mintSkribble(msg.sender, color, font, text);
        emit MintGift(msg.sender);
    }

    /// @notice Return token URI for Skribble, using the CapsuleMetadata contract.
    /// @param SkribbleId ID of Skribble token.
    /// @return metadata Metadata string for Skribble.
    function tokenURI(uint256 SkribbleId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(SkribbleId), "ERC721A: URI query for nonexistent token");
        return
            ICapsuleMetadata(CapsuleMetadata).metadataOf(
                skribbleOf(SkribbleId),
                svgOf(SkribbleId)
            );
    }

    /// @notice Return contractURI.
    /// @return contractURI contractURI
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Return SVG image from the Skribble's renderer.
    /// @param SkribbleId ID of Skribble token.
    /// @return svg Encoded SVG image of Skribble.
    function svgOf(uint256 SkribbleId) public view returns (string memory) {
        return
            ICapsuleRenderer(rendererOf(SkribbleId)).svgOf(skribbleOf(SkribbleId));
    }

    /// @notice Returns all data for Skribble.
    /// @param SkribbleId ID of Skribble.
    /// @return Capsule struct.
    function skribbleOf(uint256 SkribbleId) public view returns (Capsule memory) {
        bytes3 color = _colorOf[SkribbleId];

        return
            Capsule({
                id: SkribbleId,
                font: _fontOf[SkribbleId],
                text: _textOf[SkribbleId],
                color: color,
                isPure: false
            });
    }

    /// @notice Returns the gift count of an address.
    /// @param a Address to check gift count of.
    /// @return count Gift count for address.
    function giftCountOf(address a) public view returns (uint256) {
        return _giftCount[a];
    }

    /// @notice Returns the color of a Skribble.
    /// @param SkribbleId ID of Skribble.
    /// @return color Color of Skribble.
    function colorOf(uint256 SkribbleId) public view returns (bytes3) {
        return _colorOf[SkribbleId];
    }

    /// @notice Returns the text of a Skribble.
    /// @param SkribbleId ID of Skribble.
    /// @return text Text of Skribble.
    function textOf(uint256 SkribbleId) public view returns (bytes32[8] memory) {
        return _textOf[SkribbleId];
    }

    /// @notice Returns the font of a Skribble.
    /// @param SkribbleId ID of Skribble.
    /// @return font Font of Skribble.
    function fontOf(uint256 SkribbleId) public view returns (Font memory) {
        return _fontOf[SkribbleId];
    }

    /// @notice Returns renderer of a Skribble. If the Skribble has no renderer set, the default renderer is used.
    /// @param SkribbleId ID of Skribble.
    /// @return renderer Address of renderer.
    function rendererOf(uint256 SkribbleId) public view returns (address) {
        if (_rendererOf[SkribbleId] != address(0)) return _rendererOf[SkribbleId];
        return defaultRenderer;
    }

    /// @notice Check if font is valid for a Renderer contract.
    /// @param renderer Renderer contract address.
    /// @param font Font to check validity of.
    /// @return true True if font is valid.
    function isValidFontForRenderer(Font memory font, address renderer)
        public
        view
        returns (bool)
    {
        return ICapsuleRenderer(renderer).isValidFont(font);
    }

    /// @notice Check if address is a valid CapsuleRenderer contract.
    /// @param renderer Renderer address to check.
    /// @return true True if renderer is valid.
    function isValidRenderer(address renderer) public view returns (bool) {
        return _validRenderers[renderer];
    }

    /// @notice Check if color is valid.
    /// @dev A color is valid if all 3 bytes are divisible by 5 AND at least one byte == 255.
    /// @param color Color to check validity of.
    /// @return true True if color is valid.
    function isValidColor(bytes3 color) public pure returns (bool) {
        // At least one byte must equal 0xff (255)
        if (color[0] < 0xff && color[1] < 0xff && color[2] < 0xff) {
            return false;
        }
        // All bytes must be divisible by 5
        unchecked {
            for (uint256 i; i < 3; i++) {
                if (uint8(color[i]) % 5 != 0) return false;
            }
        }
        return true;
    }

    /// @notice Check if Skribble text is valid.
    /// @dev Checks validity using Skribble's renderer contract.
    /// @param SkribbleId ID of Skribble.
    /// @return true True if Skribble text is valid.
    function isValidSkribbleText(uint256 SkribbleId)
        external
        view
        returns (bool)
    {
        return
            ICapsuleRenderer(rendererOf(SkribbleId)).isValidText(
                textOf(SkribbleId)
            );
    }

    /// @notice Withdraws balance of this contract to the feeReceiver address.
    function withdraw() external /*nonReentrant*/ {
        uint256 calcUnit = address(this).balance / 1000;
        uint256 feeAmountOne = calcUnit * feeTakeOne;
        uint256 feeTakeTwo = 1000 - feeTakeOne;
        uint256 feeAmountTwo = calcUnit * feeTakeTwo;
        payable(feeReceiverTwo).transfer(calcUnit * feeTakeTwo);
        payable(feeReceiverOne).transfer(feeAmountOne);
        emit Withdraw(feeReceiverOne, feeAmountOne, feeReceiverTwo, feeAmountTwo);
    }

    /// @notice EIP2981 royalty standard
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (salePrice * royalty) / 1000);
    }

    /// @notice EIP2981 standard Interface return. Adds to ERC721A Interface returns.
    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev Allows contract to receive ETH
    receive() external payable {}

    /* -------------------------------------------------------------------------- */
    /*                      000   0   0  0   0  00000  0000                       */
    /*                     0   0  0   0  00  0  0      0   0                      */
    /*                     0   0  0   0  0 0 0  0000   0000                       */
    /*                     0   0  0 0 0  0  00  0      0  0                       */
    /*                      000    0 0   0   0  00000  0   0                      */
    /* -------------------------------------------------------------------------- */
    /* ------------------------ Skribble OWNER FUNCTIONS ------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Allows Skribble owner to set the Skribble text and font.
    /// @param SkribbleId ID of Skribble.
    /// @param text New text for Skribble.
    /// @param font New font for Skribble.
    function setTextAndFont(
        uint256 SkribbleId,
        bytes32[8] calldata text,
        Font calldata font
    ) external {
        _setText(SkribbleId, text);
        _setFont(SkribbleId, font);
    }

    /// @notice Allows Skribble owner to set the Skribble text and font.
    /// @param SkribbleId ID of Skribble.
    /// @param text New text for Skribble.
    /// @param color New color for Skribble.
    function setTextAndColor(
        uint256 SkribbleId,
        bytes32[8] calldata text,
        bytes3 color
    ) external {
         _setText(SkribbleId, text);
         _setColor(SkribbleId, color);
    }

    /// @notice Allows Skribble owner to set the Skribble text.
    /// @param SkribbleId ID of Skribble.
    /// @param text New text for Skribble.
    function setText(uint256 SkribbleId, bytes32[8] calldata text) external {
        _setText(SkribbleId, text);
    }

    /// @notice Allows Skribble owner to set the Skribble font.
    /// @param SkribbleId ID of Skribble.
    /// @param font New font for Skribble.
    function setFont(uint256 SkribbleId, Font calldata font) external {
        _setFont(SkribbleId, font);
    }

    /// @notice Allows Skribble owner to set the Skribble color.
    /// @param SkribbleId ID of Skribble.
    /// @param color New font for Skribble.
    function setColor(uint256 SkribbleId, bytes3 color) external {
        _setColor(SkribbleId, color);    
    }

    /// @notice Allows Skribble owner to set its renderer contract. If renderer is the zero address, the Skribble will use the default renderer.
    /// @dev Does not check validity of the current Skribble text or font with the new renderer.
    /// @param SkribbleId ID of Skribble.
    /// @param renderer Address of new renderer.
    function setRendererOf(uint256 SkribbleId, address renderer)
        external
        onlySkribbleOwner(SkribbleId)
        onlyValidRenderer(renderer)
    {
        _rendererOf[SkribbleId] = renderer;
        emit SetSkribbleRenderer(SkribbleId, renderer);
    }

    /// @notice Burns a Skribble.
    /// @param SkribbleId ID of Skribble to burn.
    function burn(uint256 SkribbleId) external onlySkribbleOwner(SkribbleId) {
        _burn(SkribbleId);
    }

    /* -------------------------------------------------------------------------- */
    /*                      000   0000   0   0  00000  0   0                      */
    /*                     0   0  0   0  00 00    0    00  0                      */
    /*                     00000  0   0  0 0 0    0    0 0 0                      */
    /*                     0   0  0   0  0   0    0    0  00                      */
    /*                     0   0  0000   0   0  00000  0   0                      */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------- ADMIN FUNCTIONS ----------------------------- */
    /* -------------------------------------------------------------------------- */


    /// @notice Owner sets Mint Master
    /// @param _mintMaster address to be set as mintMaster (minting for free)
    function setMintMaster(address _mintMaster) external onlyOwner{
        mintMaster = _mintMaster;
        emit SetMintMaster(_mintMaster);
    }

    /// @notice Owner Mints a Skribble (fee-less)
    /// @param to Recipient of Skribble.
    /// @param color Color of Skribble.
    /// @param font Font of Skribble.
    /// @return SkribbleId ID of minted Skribble.
    function mintAsOwner(
        address to,
        bytes3 color,
        Font calldata font,
        bytes32[8] calldata text
    )
        external
        onlyMintMaster
        returns (uint256)
    {
        return _mintSkribble(to, color, font, text);
    }

    /// @notice Allows the owner of this contract to set the gift count of multiple addresses.
    /// @param addresses Addresses to set gift count for.
    /// @param counts Counts to set for addresses.
    function setGiftCounts(
        address[] calldata addresses,
        uint256[] calldata counts
    ) external onlyOwner {
        if (addresses.length != counts.length) {
            revert("Number of addresses must equal number of gift counts.");
        }
        for (uint256 i; i < addresses.length; i++) {
            address a = addresses[i];
            uint256 count = counts[i];
            _giftCount[a] = count;
            emit SetGiftCount(a, count);
        }
    }

    /// @notice Allows the owner of this contract to update the default renderer contract.
    /// @param renderer Address of new default renderer contract.
    function setDefaultRenderer(address renderer) external onlyOwner {
        _setDefaultRenderer(renderer);
    }

    /// @notice Allows the owner of this contract to add a valid renderer contract.
    /// @param renderer Address of renderer contract.
    function addValidRenderer(address renderer) external onlyOwner {
        _addValidRenderer(renderer);
    }

    /// @notice Allows the owner of this contract to update the metadata contract.
    /// @param _CapsuleMetadata Address of new default metadata contract.
    function setCapsuleMetadata(address _CapsuleMetadata) external onlyOwner {
        _setMetadata(_CapsuleMetadata);
    }

    /// @notice Allows the owner of this contract to update the contractURI.
    /// @param __contractURI New contractURI.
    function setContractURI(string calldata __contractURI) external onlyOwner {
        _setContractURI(__contractURI);
    }

    /// @notice Allows feeReceiverOne to update itself.
    /// @param newFeeReceiver Address of new feeReceiver.
    function setFeeReceiverOne(address newFeeReceiver) external onlyFeeReceiverOne notZeroAddress(newFeeReceiver) {
        _setFeeReceiverOne(newFeeReceiver);
    }

    /// @notice Allows feeReceiverTwo to update itself.
    /// @param newFeeReceiver Address of new feeReceiver.
    function setFeeReceiverTwo(address newFeeReceiver) external onlyFeeReceiverTwo notZeroAddress(newFeeReceiver) {
        _setFeeReceiverTwo(newFeeReceiver);
    }

    /// @notice Allows  feeReceiverOne to lower its take.
    /// @param _feeTakeOne new, lower feeTake uint/1000.
    function setFeeTakeOne(uint _feeTakeOne) external onlyFeeReceiverOne {
        if(feeTakeOne < _feeTakeOne) revert CanOnlySetLowerFeeTakes(feeTakeOne, _feeTakeOne);
        _setFeeTakeOne(_feeTakeOne);
    }

    /// @notice Allows the owner of this contract to update the royalty amount.
    /// @param royaltyAmount New royalty amount.
    function setRoyalty(uint256 royaltyAmount) external onlyOwner {
        _setRoyalty(royaltyAmount);
    }

    /// @notice Allows the owner of this contract to update the minting price.
    /// @param _mint_price to be set.
    function setMintingPrice(uint256 _mint_price) external onlyOwner {
        _setMintingPrice(_mint_price);
    }

    /// @notice Allows the contract owner to pause the contract.
    /// @dev Can only be called by the owner when the contract is unpaused.
    function pause() external override onlyOwner {
        _pause();
    }

    /// @notice Allows the contract owner to unpause the contract.
    /// @dev Can only be called by the owner when the contract is paused.
    function unpause() external override onlyOwner {
        _unpause();
    }

    /* -------------------------------------------------------------------------- */
    /*           00000  0   0  00000  00000  0000   0   0   000   0               */
    /*             0    00  0    0    0      0   0  00  0  0   0  0               */
    /*             0    0 0 0    0    0000   0000   0 0 0  00000  0               */
    /*             0    0  00    0    0      0  0   0  00  0   0  0               */
    /*           00000  0   0    0    00000  0   0  0   0  0   0  00000           */
    /* -------------------------------------------------------------------------- */
    /* --------------------------- INTERNAL FUNCTIONS --------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice ERC721A override to start tokenId at 1 instead of 0.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Mints a Skribble.
    /// @param to Address to receive Skribble.
    /// @param color Color of Skribble.
    /// @param font Font of Skribble.
    /// @return SkribbleId ID of minted Skribble.
    function _mintSkribble(
        address to,
        bytes3 color,
        Font calldata font,
        bytes32[8] memory text
    )
        internal
        onlyValidFontForRenderer(font, defaultRenderer)
        returns (uint256 SkribbleId)
    {
        _mint(to, 1, new bytes(0), false);
        SkribbleId = _currentIndex - 1;
        _colorOf[SkribbleId] = color;
        _fontOf[SkribbleId] = font;
        _textOf[SkribbleId] = text;
        emit MintSkribble(SkribbleId, to, color, font, text);
    }

    function _setText(uint256 SkribbleId, bytes32[8] calldata text)
        internal
        onlySkribbleOwner(SkribbleId)
    {
        _textOf[SkribbleId] = text;
        emit SetSkribbleText(SkribbleId, text);
    }

    function _setFont(uint256 SkribbleId, Font calldata font)
        internal
        onlySkribbleOwner(SkribbleId)
        onlyValidFontForRenderer(font, rendererOf(SkribbleId))
    {
        _fontOf[SkribbleId] = font;
        emit SetSkribbleFont(SkribbleId, font);
    }

      function _setColor(uint256 SkribbleId, bytes3 color)
        internal
        onlySkribbleOwner(SkribbleId)
    {
        _colorOf[SkribbleId] = color;
        emit SetSkribbleColor(SkribbleId, color);
    }


    function _addValidRenderer(address renderer) internal {
        _validRenderers[renderer] = true;
        emit AddValidRenderer(renderer);
    }

    /// @notice Check if all lines of text are empty.
    /// @param text Text to check.
    /// @return true if text is empty.
    function _isEmptyText(bytes32[8] memory text) internal pure returns (bool) {
        for (uint256 i; i < 8; i++) {
            if (!_isEmptyLine(text[i])) return false;
        }
        return true;
    }

    /// @notice Check if line is empty.
    /// @dev Returns true if every byte of text is 0x00.
    /// @param line line to check.
    /// @return true if line is empty.
    function _isEmptyLine(bytes32 line) internal pure returns (bool) {
        bytes2[16] memory _line = _bytes32ToBytes2Array(line);
        for (uint256 i; i < 16; i++) {
            if (_line[i] != 0) return false;
        }
        return true;
    }

    /// @notice Format bytes32 type as array of bytes2
    /// @param b bytes32 value to convert to array
    /// @return a Array of bytes2
    function _bytes32ToBytes2Array(bytes32 b)
        internal
        pure
        returns (bytes2[16] memory a)
    {
        for (uint256 i; i < 16; i++) {
            a[i] = bytes2(abi.encodePacked(b[i * 2], b[i * 2 + 1]));
        }
    }

    function _setDefaultRenderer(address renderer) internal {
        _addValidRenderer(renderer);
        defaultRenderer = renderer;
        emit SetDefaultRenderer(renderer);
    }

    function _setRoyalty(uint256 royaltyAmount) internal {
        require(royaltyAmount <= 1000, "Amount too high");
        royalty = royaltyAmount;
        emit SetRoyalty(royaltyAmount);
    }

    function _setContractURI(string calldata __contractURI) internal {
        _contractURI = __contractURI;
        emit SetContractURI(__contractURI);
    }

    function _setFeeReceiverOne(address newFeeReceiver) internal {
        feeReceiverOne = newFeeReceiver;
        emit SetFeeReceiverOne(newFeeReceiver);
    }

    function _setFeeReceiverTwo(address newFeeReceiver) internal {
        feeReceiverTwo = newFeeReceiver;
        emit SetFeeReceiverTwo(newFeeReceiver);
    }

    function _setFeeTakeOne(uint _feeTakeOne) internal {
        require(_feeTakeOne <= 1000, "Amount too high");
        feeTakeOne = _feeTakeOne;
        emit SetFeeTakeOne(_feeTakeOne);
    }

    function _setMintingPrice(uint _mintPrice) internal {
        mintPrice = _mintPrice;
        emit SetMintingPrice(_mintPrice);
    }

    function _setMetadata(address _CapsuleMetadata) internal {
        CapsuleMetadata = _CapsuleMetadata;
        emit SetMetadata(_CapsuleMetadata);
    }
}