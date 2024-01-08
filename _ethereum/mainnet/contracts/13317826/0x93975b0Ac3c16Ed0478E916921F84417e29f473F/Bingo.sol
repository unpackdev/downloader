// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FormaBase.sol";

contract Bingo is FormaBase {
    uint8 public boardWidth;
    uint8 public maxBoardWidth = 8;
    uint16 public tileProbability;

    uint64 public freshTokensMinted = 0;
    uint64 public mergeTokensMinted = 0;

    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(uint256 => bool[]) public tokenIdToData;
    mapping(uint256 => uint32) public tokenIdToCount;
    mapping(uint256 => bool) public tokenIdToBurned;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseURI,
        uint8 _boardWidth,
        uint16 _tileProbability,
        uint256 _pricePerToken,
        uint256 _maxTokens
    ) ERC721(_tokenName, _tokenSymbol) {
        admins[msg.sender] = true;
        formaAddress = msg.sender;
        baseURI = _baseURI;
        require(_pricePerToken >= minPricePerToken, "pricePerToken too low");
        require(_boardWidth <= maxBoardWidth, "Board width too large");
        require(
            _tileProbability >= 0 && _tileProbability <= 100,
            "Probability must between 0 and 100"
        );
        boardWidth = _boardWidth;
        tileProbability = _tileProbability;
        pricePerToken = _pricePerToken;
        maxTokens = _maxTokens;
    }

    function mint() public payable virtual override returns (uint256 _tokenId) {
        require(active, "Drop must be active");
        require(msg.value >= pricePerToken, "Ether amount is under set price");
        require(freshTokensMinted < maxTokens, "Must not exceed max tokens");

        uint256 tokenId = _mintToken(msg.sender);
        salesStarted = true;
        return tokenId;
    }

    function reserve(address _toAddress)
        public
        virtual
        override
        onlyAdmins
        returns (uint256 _tokenId)
    {
        require(freshTokensMinted < maxTokens, "Must not exceed max tokens");

        uint256 tokenId = _mintToken(_toAddress);
        return tokenId;
    }

    function _mintToken(address _toAddress) internal virtual returns (uint256 _tokenId) {
        uint256 tokenId = freshTokensMinted;
        freshTokensMinted = freshTokensMinted + 1;

        bytes32 hash = keccak256(
            abi.encodePacked(tokenId, block.number, blockhash(block.number - 1), _toAddress)
        );

        _mint(_toAddress, tokenId);
        tokenIdToHash[tokenId] = hash;

        bool[] memory generatedTokenData = _generateTokenData(hash);
        tokenIdToData[tokenId] = generatedTokenData;
        tokenIdToCount[tokenId] = 1;

        emit Mint(_toAddress, tokenId);

        if (msg.value > 0) {
            _splitFunds();
        }

        return tokenId;
    }

    function _generateTokenData(bytes32 _seedHash)
        internal
        view
        returns (bool[] memory _tokenData)
    {
        uint8 _totalTiles = boardWidth * boardWidth;

        bool[] memory _board = new bool[](_totalTiles);
        for (uint8 i = 0; i < _totalTiles; i++) {
            unchecked {
                uint16 _pseudoRandomNumber = uint16(uint8(bytes1(_seedHash << (8 * i))));
                uint16 _cutoff = (256 * uint16(tileProbability)) / 100;
                if (_pseudoRandomNumber < _cutoff) {
                    _board[i] = true;
                }
            }
        }
        return _board;
    }

    function merge(uint256 _tokenId1, uint256 _tokenId2) public returns (uint256 _tokenId) {
        require(
            ERC721.ownerOf(_tokenId1) == _msgSender(),
            "ERC721: Merging of token that is not own"
        );
        require(
            ERC721.ownerOf(_tokenId2) == _msgSender(),
            "ERC721: Merging of token that is not own"
        );
        require(active, "Drop must be active");

        bool[] memory _token1Data = tokenIdToData[_tokenId1];
        bool[] memory _token2Data = tokenIdToData[_tokenId2];

        uint256 mergedTokenId = _mintMergedToken(_token1Data, _token2Data, msg.sender);
        tokenIdToCount[mergedTokenId] = tokenIdToCount[_tokenId1] + tokenIdToCount[_tokenId2];

        _burn(_tokenId1);
        tokenIdToBurned[_tokenId1] = true;
        _burn(_tokenId2);
        tokenIdToBurned[_tokenId2] = true;

        return mergedTokenId;
    }

    function _mintMergedToken(
        bool[] memory _token1Data,
        bool[] memory _token2Data,
        address _toAddress
    ) internal returns (uint256 _tokenId) {
        uint256 tokenId = maxTokens + mergeTokensMinted;
        mergeTokensMinted = mergeTokensMinted + 1;

        bytes32 hash = keccak256(
            abi.encodePacked(tokenId, block.number, blockhash(block.number - 1), _toAddress)
        );

        _mint(_toAddress, tokenId);
        tokenIdToHash[tokenId] = hash;

        bool[] memory mergedData = _mergeTokenData(_token1Data, _token2Data);
        tokenIdToData[tokenId] = mergedData;

        emit Mint(_toAddress, tokenId);

        return tokenId;
    }

    function _mergeTokenData(bool[] memory _token1Data, bool[] memory _token2Data)
        internal
        view
        returns (bool[] memory _mergedTokenData)
    {
        bool[] memory _merged = new bool[](boardWidth * boardWidth);

        for (uint32 i = 0; i < _token1Data.length; i++) {
            _merged[i] = (_token1Data[i] || _token2Data[i]);
        }

        return _merged;
    }

    function tokenData(uint256 tokenId) public view returns (bool[] memory) {
        return tokenIdToData[tokenId];
    }
}
