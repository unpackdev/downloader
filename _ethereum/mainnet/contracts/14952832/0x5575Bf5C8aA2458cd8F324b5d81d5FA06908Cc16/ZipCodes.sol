//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC2981.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./FixedPointMathLib.sol";

import "./ERC721A.sol";

contract ZipCodes is Ownable, ERC721A, IERC2981, ReentrancyGuard {
    /* ========== DEPENDENCIES ========== */
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;

    /* ====== CONSTANTS ====== */

    // Owners
    address payable private immutable _owner1;
    address payable private immutable _owner2;

    address payable private immutable _dev;

    /* ====== ERRORS ====== */

    string private constant ERROR_TRANSFER_FAILED = "transfer failed";

    /* ====== VARIABLES ====== */

    uint64 public MAX_SUPPLY = 0;
    uint64 public PUBLIC_SALE_PRICE = 0.03 ether;
    uint64 public MAX_MINT_ALLOWANCE = 7;

    string public DESCRIPTION = "As is. Fully on chain. Stackable. Expandable. Conceptually and tangibly bridging web3 and irl.";

    mapping (uint32 => bool) private _zipCodes;

    bool public isPublicSaleActive = false;

    /* ====== MODIFIERS ====== */

    modifier tokenExists(uint256 tokenId_) {
        require(_exists(tokenId_), "ZIP: !exist");
        _;
    }

    /* ====== CONSTRUCTOR ====== */

    constructor(address owner1_, address owner2_, address dev_) ERC721A("Zip Codes", "ZIP") {
        _owner1 = payable(owner1_);
        _owner2 = payable(owner2_);
        _dev = payable(dev_);
    }

    receive() payable external {}

    function mint(uint32 zip_)
    external payable
    nonReentrant
    {
        require(zip_ >= 501, "ZIP: !invalid zipcode");
        require(zip_ <= 99950, "ZIP: !invalid zipcode");
        require(!_zipCodes[zip_], "ZIP: !unique zipcode");
        require(isPublicSaleActive, "ZIP: !active");
        require(totalSupply() < MAX_SUPPLY, "ZIP: quantity exceeded totalSupply()");
        require(_numberMinted(msg.sender) < MAX_MINT_ALLOWANCE, "ZIP: exceeded max mint allowance per wallet");
        require(PUBLIC_SALE_PRICE == msg.value, "ZIP: !enough eth");

        // log the zipcode has been taken
        _zipCodes[zip_] = true;

        // Mint ZIP NFT
        _safeMint(msg.sender, zip_);
    }

    function isZipcodeAvailable(uint32 zip_) external view returns (bool) {
        return !_zipCodes[zip_];
    }

    function getZipcode(uint64 tokenId_) external view tokenExists(tokenId_) returns (uint32) {
        return _ownerships[tokenId_].zip;
    }

    /* ========== FUNCTION ========== */

    function setIsPublicSaleActive(bool isPublicSaleActive_) external onlyOwner {
        isPublicSaleActive = isPublicSaleActive_;
    }

    function setMaxMintAllowance(uint64 maxMintAllowance_) external onlyOwner {
        require(maxMintAllowance_ > MAX_MINT_ALLOWANCE, "max mint allowance can not be decreased");
        MAX_MINT_ALLOWANCE = maxMintAllowance_;
    }

    function setMintPrice(uint64 mintPrice_) external onlyOwner {
        PUBLIC_SALE_PRICE = mintPrice_;
    }

    function setMaxSupply(uint64 maxSupply_) external onlyOwner {
        require(maxSupply_ > MAX_SUPPLY, "max supply can not be decreased");
        MAX_SUPPLY = maxSupply_;
    }

    function setDescription(string memory description_) external onlyOwner {
        DESCRIPTION = description_;
    }

    function withdraw() public {
        uint256 balance_ = address(this).balance;
        uint256 devSplit_ = balance_.mulDivDown(3, 100);
        uint256 remainder_ = (balance_ - devSplit_) / 2;

        bool success_;
        (success_,) = _owner1.call{value : remainder_}("");
        require(success_, ERROR_TRANSFER_FAILED);

        (success_,) = _owner2.call{value : remainder_}("");
        require(success_, ERROR_TRANSFER_FAILED);

        (success_,) = _dev.call{value : devSplit_}("");
        require(success_, ERROR_TRANSFER_FAILED);
    }

    function withdrawTokens(IERC20 token) public {
        uint256 balance_ = token.balanceOf(address(this));
        uint256 devSplit_ = balance_.mulDivDown(3, 100);
        uint256 remainder_ = (balance_ - devSplit_) / 2;

        token.safeTransfer(_owner1, remainder_);
        token.safeTransfer(_owner2, remainder_);
        token.safeTransfer(_dev, devSplit_);
    }

    // ============ FUNCTION OVERRIDES ============

    function supportsInterface(bytes4 interfaceId_) public view virtual override(ERC721A, IERC165) returns (bool) {
        return interfaceId_ == type(IERC2981).interfaceId || super.supportsInterface(interfaceId_);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId_) public view virtual override tokenExists(tokenId_) returns (string memory) {
        string memory zipCode_ = _toPaddedString(_ownerships[tokenId_].zip, 5);
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                base64(
                    abi.encodePacked(
                        '{"name":"', zipCode_,
                        '", "description": "', DESCRIPTION, '", "traits": [{"trait_type": "Zipcode", "value": "',
                        zipCode_,
                        '"}], "image":"data:image/svg+xml;base64,',
                        base64(
                            abi.encodePacked(
                                '<svg xmlns="http://www.w3.org/2000/svg" width="700" height="700"><rect x="0" y="0" width="700" height="700" fill="black"/> <text x="50%" y="388" text-anchor="middle" font-weight="bold" font-size="77px" fill="white">',
                                zipCode_,
                                '</text></svg>'
                            )
                        ),
                        '"}'
                    )
                )
            )
        );
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId_, uint256 salePrice_)
    external view override
    tokenExists(tokenId_)
    returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), salePrice_.mulDivDown(25, 1000));
    }

    /**
     * @dev Converts a `uint32` to its ASCII `string` decimal representation.
     */
    function _toPaddedString(uint32 value_, uint8 padding_) private pure returns (string memory) {
        if (value_ == 0) {
            return "0";
        }
        uint32 temp = value_;
        uint8 digits_;
        while (temp != 0) {
            digits_++;
            temp /= 10;
        }
        assert(digits_ <= padding_);
        bytes memory buffer = new bytes(padding_);
        while (value_ != 0) {
            padding_ -= 1;
            buffer[padding_] = bytes1(uint8(48 + uint32(value_ % 10)));
            value_ /= 10;
        }
        while (padding_ > 0) {
            padding_ -= 1;
            buffer[padding_] = bytes1(uint8(48));
        }
        return string(buffer);
    }

    //  Base64 by Brecht Devos - <brecht@loopring.org>
    //  Provides a function for encoding some bytes in base64
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {mstore(sub(resultPtr, 2), shl(240, 0x3d3d))}
            case 2 {mstore(sub(resultPtr, 1), shl(248, 0x3d))}
        }

        return result;
    }
}
