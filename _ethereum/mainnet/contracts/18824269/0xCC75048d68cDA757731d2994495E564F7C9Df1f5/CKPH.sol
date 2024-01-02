// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./ICKPH.sol";
import "./IPublicLockV13.sol";

contract CKPHHook is ICKPHHook, Ownable {
    uint16 public constant MAX_KEYS = 5555;
    uint16 public constant MAX_PINK_KEYS = 3000;
    uint16 public constant MAX_CHROME_KEYS = 2500;
    uint8 public constant MAX_BLACK_KEYS = 55;

    mapping(uint => uint8) internal tokenIdColor;

    uint16 public totalKeysMinted;
    uint16 public pinkKeysMinted;
    uint16 public chromeKeysMinted;
    uint8 public blackKeysMinted;

    string public baseURI;

    KeyURIs private keyURIs;

    address public lock;

    constructor(
        address _owner,
        address _lock,
        string memory _baseURI,
        KeyURIs memory _keyURIs
    ) Ownable(_owner) {
        lock = _lock;
        baseURI = _baseURI;
        keyURIs = _keyURIs;

        uint8 color = _getKeyColor();

        _setKeyColor(color, 1);
    }

    /* =================== Hooks =================== */
    /*
     *   @dev function called by Public Lock contract at the beginning of a key purchase.
     *   If this reverts, the purchase fails.
     */
    function keyPurchasePrice(
        address /* from */,
        address /* recipient */,
        address /* referrer */,
        bytes calldata /* data */
    ) external view returns (uint minKeyPrice) {
        return IPublicLockV13(msg.sender).keyPrice();
    }

    /*
     *   @dev function called by Public Lock contract at the end of a key purchase.
     *   Calls internal _getKeyColor function.
     *   Records key color
     */
    function onKeyPurchase(
        uint tokenId,
        address /*from*/,
        address /*recipient*/,
        address /*referrer*/,
        bytes calldata /*data*/,
        uint256 /*minKeyPrice*/,
        uint256 /*pricePaid*/
    ) external {
        _onlyLockContract();

        uint8 color = _getKeyColor();

        _setKeyColor(color, tokenId);
    }

    /*
     *   @dev function called by Public Lock contract at the beginning of a key grant.
     *   Used when a key is granted from credit card purchases or by the Lock owner.
     */
    function onKeyGranted(
        uint tokenId,
        address, // from,
        address, //recipient,
        address, // keyManager,
        uint // expiration
    ) external {
        _onlyLockContract();

        uint8 color = _getKeyColor();

        _setKeyColor(color, tokenId);
    }

    /*
     *   @dev called when tokenURI is called on the Public Lock contract.
     *   Shows correct token URI based on key color.
     */
    function tokenURI(
        address, // the address of the lock
        address, // the msg.sender issuing the call
        address, // the owner of the key
        uint256 tokenId, // the id (tokenId) of the key (if applicable)
        uint // the key expiration timestamp
    ) external view returns (string memory keyUri) {
        uint keyColor = tokenIdColor[tokenId];

        if (keyColor == 1)
            keyUri = string(abi.encodePacked(baseURI, keyURIs.pinkURI));

        if (keyColor == 2)
            keyUri = string(abi.encodePacked(baseURI, keyURIs.chromeURI));

        if (keyColor == 3)
            keyUri = string(abi.encodePacked(baseURI, keyURIs.blackURI));
    }

    /* =================== Internals =================== */
    /*
     *   @dev logic to pick a key color.
     *   Calls internal _draw function.
     */
    function _getKeyColor() internal view returns (uint8 color) {
        uint256 draw = _draw();

        if (draw <= MAX_BLACK_KEYS && blackKeysMinted < MAX_BLACK_KEYS)
            return color = 3;

        if (draw <= MAX_CHROME_KEYS && chromeKeysMinted < MAX_CHROME_KEYS)
            return color = 2;

        if (pinkKeysMinted < MAX_PINK_KEYS) return color = 1;

        if (
            pinkKeysMinted >= MAX_PINK_KEYS &&
            chromeKeysMinted < MAX_CHROME_KEYS &&
            blackKeysMinted < MAX_BLACK_KEYS
        ) {
            if (draw <= MAX_BLACK_KEYS) return color = 3;
            else return color = 2;
        }

        if (
            pinkKeysMinted < MAX_PINK_KEYS &&
            chromeKeysMinted >= MAX_CHROME_KEYS &&
            blackKeysMinted < MAX_BLACK_KEYS
        ) {
            if (draw <= MAX_BLACK_KEYS) return color = 3;
            else return color = 1;
        }

        if (
            pinkKeysMinted < MAX_PINK_KEYS &&
            chromeKeysMinted < MAX_CHROME_KEYS &&
            blackKeysMinted >= MAX_BLACK_KEYS
        ) {
            if (draw <= MAX_CHROME_KEYS) return color = 2;
            else return color = 1;
        }

        if (
            pinkKeysMinted >= MAX_PINK_KEYS &&
            chromeKeysMinted >= MAX_CHROME_KEYS &&
            blackKeysMinted < MAX_BLACK_KEYS
        ) return color = 3;

        if (
            pinkKeysMinted >= MAX_PINK_KEYS &&
            chromeKeysMinted < MAX_CHROME_KEYS &&
            blackKeysMinted >= MAX_BLACK_KEYS
        ) return color = 2;

        if (
            pinkKeysMinted < MAX_PINK_KEYS &&
            chromeKeysMinted >= MAX_CHROME_KEYS &&
            blackKeysMinted >= MAX_BLACK_KEYS
        ) return color = 1;
    }

    function _setKeyColor(uint8 color, uint tokenId) internal {
        if (color == 1) {
            tokenIdColor[tokenId] = 1;
            pinkKeysMinted++;
        } else if (color == 2) {
            tokenIdColor[tokenId] = 2;
            chromeKeysMinted++;
        } else if (color == 3) {
            tokenIdColor[tokenId] = 3;
            blackKeysMinted++;
        }
        totalKeysMinted++;
    }

    /*
     *   @dev logic to draw a "random" number.
     */
    function _draw() internal view returns (uint256 draw) {
        bytes32 blockHash = blockhash(block.number - totalKeysMinted);
        draw =
            uint256(keccak256(abi.encodePacked(block.timestamp, blockHash))) %
            MAX_KEYS;
    }

    /* =================== Utils =================== */
    function setKeyURIs(KeyURIs calldata _keyURIs) external onlyOwner {
        keyURIs = _keyURIs;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /* =================== Modifiers =================== */
    function _onlyLockContract() internal view {
        if (msg.sender != lock) revert ONLY_LOCK_CONTRACT();
    }
}
