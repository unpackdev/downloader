// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

// This lets us interface with the ERC20 Cubeverse Token
interface ICubeverseToken {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract CubeverseColor is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    constructor() ERC721("Cubeverse Color", "C3C") {}

    /** READING OPEN PALETTES */

    address public openPaletteAddress;

    function setOpenPaletteAddress(address _address) public onlyOwner {
        openPaletteAddress = _address;
    }

    function requirePaletteOwner(uint256 openPaletteId) private view {
        ERC721 openPaletteContract = ERC721(openPaletteAddress);

        require(
            openPaletteContract.ownerOf(openPaletteId) == _msgSender(),
            "Palette not owned"
        );
    }

    /** READING CUBEVERSE */

    address public cubeverseAddress;

    function setCubeverseAddress(address _address) public onlyOwner {
        cubeverseAddress = _address;
    }

    function requireCubeOwner(uint256 count) private view {
        ICubeverseToken cubeverseContract = ICubeverseToken(cubeverseAddress);

        require(
            balanceOf(_msgSender()) + count <=
                cubeverseContract.balanceOf(_msgSender()),
            "Not enough cubeverse tokens"
        );
    }

    /** ACTIVATING THE SALE **/

    bool public saleIsActive = false;

    function setSaleIsActive(bool isActive) public onlyOwner {
        saleIsActive = isActive;
    }

    /** MINTING **/

    uint256 public constant PRICE = 50000000000000000; // 0.05 ETH
    uint256 public constant MAX_OP_TOKENS = 500;
    uint256 public constant MAX_CUBE_TOKENS = 250;
    uint256 public constant MULTI_MINT_AMOUNT = 5;

    Counters.Counter private _openPaletteCounter;
    Counters.Counter private _cubeverseCounter;

    function getOpenPaletteMintCount() public view returns (uint256) {
        return _openPaletteCounter.current();
    }

    function getCubeverseMintCount() public view returns (uint256) {
        return _cubeverseCounter.current();
    }

    function requireMintPrerequisites(uint256 count) private {
        require(saleIsActive, "Sale not active");
        require(
            PRICE * count <= msg.value,
            "Insufficient payment, 0.05 ETH per item"
        );
    }

    function mintWithPalette(uint256 openPaletteId) public payable {
        require(
            _openPaletteCounter.current() < MAX_OP_TOKENS,
            "Exceeds max supply"
        );
        requireMintPrerequisites(1);
        requirePaletteOwner(openPaletteId);

        // Preconditions OK, let's mint!

        _safeMint(_msgSender(), openPaletteId);

        _openPaletteCounter.increment();
    }

    function multiMintWithPalettes(uint256[] calldata paletteIds)
        public
        payable
    {
        uint256 count = paletteIds.length;
        require(count <= MULTI_MINT_AMOUNT, "Multimint max is 5");
        require(
            _openPaletteCounter.current() + count - 1 < MAX_OP_TOKENS,
            "Exceeds max supply"
        );
        requireMintPrerequisites(count);
        for (uint256 i = 0; i < count; i++) {
            requirePaletteOwner(paletteIds[i]);
        }

        // Preconditions OK, let's mint!

        for (uint256 i = 0; i < count; i++) {
            _safeMint(_msgSender(), paletteIds[i]);

            _openPaletteCounter.increment();
        }
    }

    function mintWithCube() public payable {
        require(
            _cubeverseCounter.current() < MAX_CUBE_TOKENS,
            "Exceeds max supply"
        );
        requireMintPrerequisites(1);
        requireCubeOwner(1);

        // Preconditions OK, let's mint!

        _safeMint(_msgSender(), 9920 + _cubeverseCounter.current());

        _cubeverseCounter.increment();
    }

    function multiMintWithCubes(uint256 count) public payable {
        require(count <= MULTI_MINT_AMOUNT, "Multimint max is 5");
        require(
            _cubeverseCounter.current() + count - 1 < MAX_CUBE_TOKENS,
            "Exceeds max supply"
        );
        requireMintPrerequisites(count);
        requireCubeOwner(count);

        // Preconditions OK, let's mint!

        for (uint256 i = 0; i < count; i++) {
            _safeMint(_msgSender(), 9920 + _cubeverseCounter.current());

            _cubeverseCounter.increment();
        }
    }

    /** WITHDRAWING **/

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /** URI HANDLING **/

    string private customBaseURI;

    function setBaseURI(string memory baseURI) external onlyOwner {
        customBaseURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    /** REQUIRED OVERRIDES **/

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
