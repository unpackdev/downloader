// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721Preset.sol";
import "./Counters.sol";

contract MSNFT is ERC721Preset {
    using Strings for uint256;
    using Counters for Counters.Counter;

    struct TokenMetadata {
        uint256 birthDate;
        uint256 matronId;
        uint256 sireId;
        uint256 breedCount;
        bool fertile;
    }

    mapping(uint256 => TokenMetadata) public tokenData;

    event Mint(address owner, uint256 tokenId, bool fertile, uint256 birthDate);

    event NFTTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 timestamp
    );

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721Preset(name, symbol, baseTokenURI) {}

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "MSNFT: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        tokenId.toString(),
                        "/metadata.json"
                    )
                )
                : "";
    }

    function getAllTokenIdByAddress(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(owner);
        require(balance != 0, "MSNFT: Owner has no token");
        uint256[] memory res = new uint256[](balance);

        for (uint256 i = 0; i < balance; i++) {
            res[i] = this.tokenOfOwnerByIndex(owner, i);
        }

        return res;
    }

    function getTokenBirthDate(uint256 tokenId) public view returns (uint256) {
        return tokenData[tokenId].birthDate;
    }

    function getTokenMatron(uint256 tokenId) public view returns (uint256) {
        return tokenData[tokenId].matronId;
    }

    function getTokenSire(uint256 tokenId) public view returns (uint256) {
        return tokenData[tokenId].sireId;
    }

    function getTokenBreedCount(uint256 tokenId) public view returns (uint256) {
        return tokenData[tokenId].breedCount;
    }

    function getTokenFertile(uint256 tokenId) public view returns (bool) {
        return tokenData[tokenId].fertile;
    }

    function getTokenMetadata(uint256 tokenId)
        public
        view
        returns (TokenMetadata memory)
    {
        return tokenData[tokenId];
    }

    function setBaseTokenURI(string memory baseTokenURI) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "MSNFT: Only DEFAULT_ADMIN_ROLE can modify baseTokenURI"
        );
        _baseTokenURI = baseTokenURI;
    }

    function increaseBreedCount(uint256 tokenId) public {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "MSNFT: must have minter role to increaseBreedCount"
        );
        tokenData[tokenId].breedCount += 1;
    }

    function mint(
        address to,
        uint256 _matronId,
        uint256 _sireId,
        uint256 breedCount,
        bool fertile
    ) public returns (uint256) {
        uint256 tokenId = _tokenIdTracker.current();
        require(
            _matronId < tokenId,
            "MSNFT: matronId is larger than total token amount"
        );
        require(
            _sireId < tokenId,
            "MSNFT: sireId is larger than total token amount"
        );

        mint(to);
        tokenData[tokenId] = TokenMetadata(
            block.timestamp,
            _matronId,
            _sireId,
            breedCount,
            fertile
        );

        emit Mint(to, tokenId, true, block.timestamp);
        return tokenId;
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        super._mint(to, tokenId);
        emit NFTTransfer(address(0), to, tokenId, block.timestamp);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._transfer(from, to, tokenId);
        emit NFTTransfer(from, to, tokenId, block.timestamp);
    }
}
