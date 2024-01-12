// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./RLEtoSVG.sol";

import "./ERC721A.sol";
import "./Pausable.sol";

/*
 *                            _¡░╠╠░_
 *         __.,,,,,,,,,,,,,,,,░░░╚╙Γ
 *         _]φ╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠▒░░
 *     __.░φ▒╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▒▒░░.
 *   ,,;φφ╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠░~
 *   ▓▓▓╬╬╩╚╠╬╬╬╬╬╬╣▓▓█▓╬╬╚╠╠╬╬╬╬╬╠░_
 *   ████╬▒░▒╠╬╬╬╬╬╣▓███╬▒░░╠╬╬╬╬╬╠▒░.__
 *   ████╬▒░▒╠╬╬╬╬╬╣▓███╬▒░░╠╬╬╬╬╬╬╠╠▒▒░_
 *   ███▓╬▒░▒╠╬╬╬╬╬╣▓███╬╠▒╠╠╬╬╬╬╬╬╬╬╬▒░_
 *   ╬╬╬╬╬▒▒▒▒╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▒░_
 *   ╬╬╬╬╬╬╬╬╬╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▒░_
 *   ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬░░__        ____
 *   ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠╠▒φ░,_     _,φφφ
 *   ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠╩╩╩╩▒░░,____'⌠╚╩╩
 *   ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╩░Γ""""░░φ▒▒░░   '''
 *   ╬╬╬╬╬╬╬╬╠╩╩╩╩╩╠╠╬╬╬╬╬╬╬╠╩╚╚╚╚╚░'_ .░░░░░╚╚░└_
 *   ╬╬╬╬╬╬╬▒Γ░''''░╚╠╬╬╬╬╬╩Γ░' '' _  .░φ╠▒░░"''__
 *   ╚╚╚╚╚╚░░░_____'░░╚╚╚╚╚Γ░░.___ .░φφ░░╚Γ░'___
 *   ______________________'!░░┐__.░φ╠▒▒░_____
 *     _____________________''''.;░░Γ╚░░░░┌_   _
 *      __'''''________________''░░░░░░░""'
 *       _  __'______.___________'''''__    _
 *                 '░░φ░░_ _.░░░_
 *                _.░▒╠▒░ _ ;░▒░_
 *             __,φφ▒╠╬╠▒░░░░▒▒░_
 *             _░▒╬╬╬╬╬╬╠╠▒▒▒▒▒░_
 */

contract PixelPigeons is Ownable, Pausable, ERC721A {
    using Strings for uint256;

    struct EtcHolder {
        address holderAddress;
        uint256 numPigeons;
    }

    // We could have used a Merkle Tree here, but given the timing, we are fine with paying extra gas to use a map
    mapping(address => uint256) public holderMap;
    uint256 public immutable updateHoldersBatchMax;

    string[][] public palettes;
    bytes[] public pigeons;
    string[] public backgrounds;

    struct Seed {
        uint8 head;
        uint8 body;
        uint8 background;
    }

    mapping(uint256 => Seed) public _seeds;

    // If you hold more pigeons than this threshold, you get two PixelPigeons
    // Less than this, you get one
    uint256 public constant PIGEON_THRESHOLD = 16;

    error ExceedsUpdateHoldersBatchMax();
    error AirdroppedAllHolders();
    error AirdropQuantityZero();
    error NotInHolderSnapshot();
    error AlreadyClaimedPigeons();
    error CallerMustBeUser();
    error PalettesPigeonsMismatch(uint256 palettesLength, uint256 pigeonsLength);

    constructor(uint256 updateHoldersBatchMax_) ERC721A("PixelPigeons", "PP") {
        updateHoldersBatchMax = updateHoldersBatchMax_;

        _mintERC2309(owner(), 10);
    }

    /**
     * EVENTS
     */

    /**
     * @dev Emit on addHolders() after we add new holders.
     */
    event AddHolders(uint256 numHoldersAdded, uint256 timestamp);

    /**
     * @dev Emit on deleteHolders() after the holders map is reset;
     */
    event DeleteHolders(uint256 numHoldersDeleted, uint256 timestamp);

    /**
     * @dev Emit on addPalettes() after we add new color palettes.
     */
    event AddPalettes(uint256 numPalettesAdded, uint256 totalPalettes, uint256 timestamp);

    /**
     * @dev Emit on addPigeons() after we add new PixelPigeon RLE strings.
     */
    event AddPigeons(uint256 numPigeonsAdded, uint256 totalPigeons, uint256 timestamp);

    /**
     * @dev Emit on addBackgrounds() after we add new background colors.
     */
    event AddBackgrounds(uint256 numBackgroundsAdded, uint256 totalBackgrounds, uint256 timestamp);

    /**
     * @dev Emit on setSeeds() after we set the seeds.
     */
    event SetSeeds(uint256 startIndex, uint256 endIndex, uint256 timestamp);

    /**
     * @dev Emit on airdrop() after we mint the specified amount the receiver.
     */
    event Airdrop(address indexed to, uint256 quantity, uint256 timestamp);

    /**
     * @dev Emit on claimPigeons() after a user claims their allotted Pixel Pigeons.
     */
    event ClaimPigeons(address indexed to, uint256 quantity, uint256 timestamp);

    /**
     * OWNER FUNCTIONS
     */

    /**
     * @dev Allow pausing the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Allow unpausing the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Add holders to the holders map.
     */
    function addHolders(EtcHolder[] calldata holders_) external onlyOwner {
        if (holders_.length > updateHoldersBatchMax) revert ExceedsUpdateHoldersBatchMax();

        for (uint256 i = 0; i < holders_.length; i++) {
            holderMap[holders_[i].holderAddress] = holders_[i].numPigeons;
        }

        emit AddHolders(holders_.length, block.timestamp);
    }

    /**
     * @dev Resets a chunked portion of holders in the holders map.
     */
    function deleteHolders(EtcHolder[] calldata holders_) external onlyOwner {
        if (holders_.length > updateHoldersBatchMax) revert ExceedsUpdateHoldersBatchMax();

        for (uint256 i = 0; i < holders_.length; i++) {
            delete holderMap[holders_[i].holderAddress];
        }

        emit DeleteHolders(holders_.length, block.timestamp);
    }

    /**
     * @dev Airdrop `quantity` tokens to a given address.
     */
    function airdrop(address to, uint256 quantity) external onlyOwner {
        if (quantity == 0) revert AirdropQuantityZero();

        for (uint256 i = _nextTokenId(); i < quantity; i++) {
            _setSeed(i);
        }

        _mint(to, quantity);

        emit Airdrop(to, quantity, block.timestamp);
    }

    /**
     * @dev Add palettes to the string[][] palettes array.
     */
    function addPalettes(string[][] memory _palettes) external onlyOwner {
        for (uint256 i = 0; i < _palettes.length; i++) {
            palettes.push(_palettes[i]);
        }

        emit AddPalettes(_palettes.length, palettes.length, block.timestamp);
    }

    /**
     * @dev Add pigeonRLE strings to the bytes[] pigeons array.
     */
    function addPigeons(bytes[] calldata _pigeons) external onlyOwner {
        for (uint256 i = 0; i < _pigeons.length; i++) {
            pigeons.push(_pigeons[i]);
        }

        emit AddPigeons(_pigeons.length, pigeons.length, block.timestamp);
    }

    /**
     * @dev Add backgrounds strings to the string[] backgrounds array.
     */
    function addBackgrounds(string[] calldata _backgrounds) external onlyOwner {
        for (uint256 i = 0; i < _backgrounds.length; i++) {
            backgrounds.push(_backgrounds[i]);
        }

        emit AddBackgrounds(_backgrounds.length, backgrounds.length, block.timestamp);
    }

    /**
     * @dev Set the seeds (reveals?) the pigeons in the slice given from start to end.
     */
    function setSeeds(uint256 startIndex, uint256 endIndex) external onlyOwner {
        for (uint256 i = _startTokenId() + startIndex; i < endIndex; i++) {
            _setSeed(i);
        }

        emit SetSeeds(startIndex, endIndex, block.timestamp);
    }

    /**
     * VIEW FUNCTIONS
     */

    /**
     * @dev Returns number of PixelPigeons minted to a given address.
     */
    function numberMinted(address to) external view returns (uint256) {
        return _numberMinted(to);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    // Literally can't declare this external since we're overriding a public function.
    // Bad Slither.
    // slither-disable-next-line external-function
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return constructTokenURI(tokenId);
    }

    /**
     * @dev Builds the JSON metadata for a given token on-chain, including attributes & image.
     */
    function constructTokenURI(uint256 tokenId) public view returns (string memory) {
        // It's fine to overload ERC721.name() in this context,
        // since we are dealing with a single token.
        // slither-disable-next-line shadowing-local
        string memory name = string(abi.encodePacked("PixelPigeon ", tokenId.toString()));
        string memory description = string(
            abi.encodePacked("PixelPigeon ", tokenId.toString(), " thinks Everythings Coo")
        );

        uint256 headPaletteIndex = _seeds[tokenId].head;
        uint256 bodyPaletteIndex = _seeds[tokenId].body;
        uint256 backgroundIndex = _seeds[tokenId].background;

        // Note: The way we calculate the Pigeon RLE needs to be the same
        // as the way we calculate bodyPalette.
        //
        // So, if we were to randomize, pigeon[y] and bodyPalette[y]
        // would have to use the same random number y.
        //
        // This is due to the fact that different pigeons
        // have different RLEs, and thus palettes of different lengths,
        // and we need to ensure we use a palette of appropriate length for the RLE.

        bytes memory pigeon = pigeons[bodyPaletteIndex];
        string[] memory headPalette = palettes[headPaletteIndex];
        string[] memory bodyPalette = palettes[bodyPaletteIndex];
        string memory background = backgrounds[backgroundIndex];

        string memory image = RLEtoSVG.generateSVG(pigeon, headPalette, bodyPalette, background);

        RLEtoSVG.PigeonMetadata memory pigeonMetadata = RLEtoSVG._getPigeonMetadata(pigeon);

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                    Base64.encode((bytes.concat(
                        abi.encodePacked(
                        '{',
                            '"name":"', name,
                            '", "description":"', description,
                            '", "background_color":"', background,
                            '", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)),
                            '", "attributes": [',
                                '{"trait_type": "Head", "value": "', headPalette[pigeonMetadata.headColorIndex], '"},'),
                            abi.encodePacked(
                                '{"trait_type": "Eyes", "value": "', headPalette[pigeonMetadata.eyeColorIndex], '"},',
                                '{"trait_type": "Beak", "value": "', headPalette[pigeonMetadata.beakColorIndex], '"},',
                                '{"trait_type": "Body", "value": "', bodyPalette[pigeonMetadata.bodyColorIndex], '"},',
                                '{"trait_type": "Background", "value": "', background, '"}',
                            ']',
                        '}')
                    )))
            )
        );
    }

    /**
     * EXTERNAL FUNCTIONS
     */

    /**
     * @dev Claim function for a whitelisted user to get their allotted PixelPigeons.
     */
    function claimPigeons(address to) external whenNotPaused {
        if (tx.origin != msg.sender) revert CallerMustBeUser();
        if (holderMap[to] == 0) revert NotInHolderSnapshot();
        if (_numberMinted(to) > 0) revert AlreadyClaimedPigeons();

        uint256 quantity = 1;
        _setSeed(_nextTokenId());
        if (holderMap[to] > PIGEON_THRESHOLD) {
            quantity = 2;
            _setSeed(_nextTokenId() + 1);
        }

        _mint(to, quantity);

        emit ClaimPigeons(to, quantity, block.timestamp);
    }

    /**
     * INTERNAL FUNCTIONS
     */

    /**
     * @dev Generates a pseudorandom number. Used for generating pigeon metadata.
     */
    function _generateRandomNumber(
        uint256 tokenId,
        uint256 max,
        uint256 seed
    ) internal pure returns (uint256) {
        // We're generating SVG images here, not dealing with money.
        // slither-disable-next-line weak-prng
        return uint256(keccak256(abi.encodePacked(tokenId, seed))) % max;
    }

    /**
     * @dev Generates the pigeon metadata and stores it in the `_seeds` mapping
     */
    function _setSeed(uint256 tokenId) internal {
        // Note: palettes.length SHOULD EQUAL pigeons.length.
        //
        // This is due to the fact that different pigeons
        // have different RLEs, and thus palettes of different lengths,
        // and we need to ensure we use a palette of appropriate length for the RLE.

        uint256 palettesLength = palettes.length;
        uint256 pigeonsLength = pigeons.length;

        if (palettesLength != pigeonsLength) revert PalettesPigeonsMismatch(palettesLength, pigeonsLength);

        _seeds[tokenId].head = uint8(_generateRandomNumber(tokenId, palettesLength, block.timestamp));
        _seeds[tokenId].body = uint8(tokenId % palettesLength);
        _seeds[tokenId].background = uint8(_generateRandomNumber(tokenId, backgrounds.length, block.timestamp + 1));
    }
}
