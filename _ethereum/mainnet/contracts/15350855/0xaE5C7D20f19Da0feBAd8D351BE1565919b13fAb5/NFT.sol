// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;


import "./ERC721.sol";
import "./Ownable.sol";


contract NFT is ERC721, Ownable {
    // ----- [ CONSTANTS ] ---------------------------------------------------------------------------------------------
    uint256 public constant NUMBER_OF_TOKENS = 10000;

    // ----- [ MINT ] -----------------------------------------------------------------------------------------------
    uint256 private _totalSupply = 0;
    string private _uri = "https://genesis-metadata.lsr.ai/";
    uint256[NUMBER_OF_TOKENS] private _mintingHistory;
    uint256 public price = 0.1 ether;

    // ----- [ RANDOM MINTING ] ----------------------------------------------------------------------------------------
    uint256[10] private _index = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    uint256[10] private _indexExists = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

    uint256 private _indexLength = 10;
    uint256 private _perColum = NUMBER_OF_TOKENS / _indexLength;
    uint256 private _nonce = 0;

    // ----- [ WHITE LIST ] --------------------------------------------------------------------------------------------
    mapping(uint256 => mapping(address => uint256)) private _whiteList;
    uint256 private _whiteListNumber;


    struct NewWhiteListData {
        address adr;
        uint256 price;
    }


    constructor() ERC721("Genesis NFT Love Sex Robots", "LSR") {}


    // ----- [ GETTERS ] -----------------------------------------------------------------------------------------------

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function mintingHistory(uint256 index) public view returns (uint256) {
        require(index < _totalSupply, "There is no entry in the history with this index");
        return _mintingHistory[index];
    }

    function whitelist(address adr) public view returns (uint256) {
        return _whiteList[_whiteListNumber][adr];
    }

    function priceForMe() public view returns (uint256) {
        if (_whiteList[_whiteListNumber][msg.sender] != 0) {
            return _whiteList[_whiteListNumber][msg.sender];
        } else {
            return (msg.sender == owner()) ? 0 : price;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }


    // ----- [ MINT ] --------------------------------------------------------------------------------------------------

    function mint(uint256 amount) public payable {
        require(_totalSupply + amount < NUMBER_OF_TOKENS, "Not enough tokens or all tokens minted");
        require((msg.sender == owner()) || (msg.value >= (amount * price - (price - priceForMe()))), "Insufficient funds");

        for (uint256 i = 0; (i < amount) && (_totalSupply < NUMBER_OF_TOKENS); ++i) {
            uint256 index = _getRandomIndex();
            _safeMint(msg.sender, index);
            _mintingHistory[_totalSupply] = index;
            ++_totalSupply;
        }

        if (_whiteList[_whiteListNumber][msg.sender] != 0) {
            _whiteList[_whiteListNumber][msg.sender] = 0;
        }

        _nonce = 0;
    }

    function _getRandomIndex() private returns (uint256) {
        if (_indexLength > 1) {
            _nonce++;
            for (uint256 i = 0; i < _indexLength; ++i) {
                uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp + _nonce))) % (_indexLength - i);
                uint256 temp = _indexExists[n];
                _indexExists[n] = _indexExists[i];
                _indexExists[i] = temp;
            }
        } else if (_index[_indexExists[0]] == _perColum) {
            revert("All tokens minted");
        }

        uint256 previousIndex = _index[_indexExists[0]] + (_indexExists[0] * _perColum);

        ++_index[_indexExists[0]];
        if (_index[_indexExists[0]] >= _perColum) {
            --_indexLength;
            _indexExists[0] = _indexExists[_indexLength];
        }

        return previousIndex;
    }


    // ----- [ CONTROL ] -----------------------------------------------------------------------------------------------

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function clearWhiteList() external onlyOwner {
        ++_whiteListNumber;
    }

    function changeWhiteList(address adr, uint256 newPrice) external onlyOwner {
        _whiteList[_whiteListNumber][adr] = newPrice;
    }

    function changeWhiteListBatch(NewWhiteListData[] calldata data) external onlyOwner {
        for (uint256 i = 0; i < data.length; ++i) {
            _whiteList[_whiteListNumber][data[i].adr] = data[i].price;
        }
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _uri = uri;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
