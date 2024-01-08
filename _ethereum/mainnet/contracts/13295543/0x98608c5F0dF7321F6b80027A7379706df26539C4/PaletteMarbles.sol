// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./ERC721Tradable.sol";

interface OpenPaletteInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
}

contract PaletteMarbles is ERC721Tradable {
    using Counters for Counters.Counter;
    // OpenPalette
    address private openPaletteAddress;
    mapping(uint256 => bool) private _avatarExists;
    uint256 public constant MULTI_MINT_AMOUNT = 5;
    uint256 public mintStart_timestamp = 1632661200; // Sunday, 26 Sep 2021 13:00:00.000000000 UTC +00:00
    uint256 public freeMintEnd_timestamp = 1632920400; //  Wed, 29 Sep 2021 13:00:00.000000000 UTC +00:00
    uint256 public constant PRICE = 20000000000000000; // 0.02 ETH

    constructor(address _proxyRegistryAddress, address _openPaletteAddress)
        ERC721Tradable("PaletteMarbles", "PLMB", _proxyRegistryAddress) {
        openPaletteAddress = _openPaletteAddress;
    }

    function requirePalettePrerequisites(uint256 _tokenId, address _to) private view{
        require(
            OpenPaletteInterface(openPaletteAddress).ownerOf(_tokenId) == _to,
            "Palette not owned"
        );
        require(_tokenId >= 0 && _tokenId < 10000, "Token ID invalid");
        require(!_avatarExists[_tokenId], "This marble already exists");
    }

    function requireMintPrerequisites(uint256 count) private {
        require(block.timestamp >= mintStart_timestamp, "Mint not active");

        if(block.timestamp > freeMintEnd_timestamp) {
            require(
                PRICE * count <= msg.value,
                "Insufficient payment, 0.02 ETH per item"
            );
        }

        require(_marblesCounter.current() + count - 1 < MAX_TOKENS, "Exceeds max supply");
    }

    /**
     * @dev Mint
     * @param _tokenId Token ID to mint
     * @param _to  Address to receive the token
     */
    function mint(uint256 _tokenId, address _to) external payable {
        requireMintPrerequisites(1);
        requirePalettePrerequisites(_tokenId, _to);

        _safeMint(_to, _tokenId);
        _avatarExists[_tokenId] = true;
        _marblesCounter.increment();
    }

    function multiMintWithPalettes(uint256[] calldata paletteIds, address _to) public payable {
        uint256 count = paletteIds.length;
        require(count <= MULTI_MINT_AMOUNT, "Multimint max is 5");
        requireMintPrerequisites(count);

        for (uint256 i = 0; i < count; i++) {
            requirePalettePrerequisites(paletteIds[i], _to);
        }

        for (uint256 i = 0; i < count; i++) {
            _safeMint(_to, paletteIds[i]);
            _avatarExists[paletteIds[i]] = true;
            _marblesCounter.increment();
        }
    }


    function baseTokenURI() override public pure returns (string memory) {
        return "https://ipfs.io/ipfs/QmTQFqFqi4fk9SBgW1KjWcjytDmJBd2ibEm5Us2PvgSR2H/";
    }

    function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId), ".json"));
    }

    function withdraw(address _account, uint256 _balance) private {
        payable(_account).transfer(_balance);
    }

    address public constant devAddress = 0xE69Eb4946188c5085f38e683b61b892a96c27124;
    function withdrawAll() public payable onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0);
        uint256 share = contractBalance / 2;
        withdraw(devAddress, share);
        withdraw(owner(), share);
    }

    // Open Palettes

    function palettesOf(address _owner) public view returns(uint256[] memory) {
        uint256 balance = OpenPaletteInterface(openPaletteAddress).balanceOf(_owner);
        uint256[] memory palettes = new uint256[](balance);

        for(uint256 i = 0; i < balance; i++) {
            uint256 tokenId = OpenPaletteInterface(openPaletteAddress).tokenOfOwnerByIndex(_owner, i);
            palettes[i] = tokenId;
        }

        return palettes;
    }

    function isMinted(uint256 _tokenId) public view returns (bool) {
        return _avatarExists[_tokenId];
    }

    // Tokens count
    uint256 public constant MAX_TOKENS = 2000;
    Counters.Counter private _marblesCounter;

    function getPaletteMarblesMintCount() public view returns (uint256) {
        return _marblesCounter.current();
    }
}
