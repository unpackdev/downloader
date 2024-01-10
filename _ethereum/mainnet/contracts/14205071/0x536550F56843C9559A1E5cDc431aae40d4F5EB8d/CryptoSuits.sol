
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeMath.sol";

contract CryptoSuits is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public baseUri;
    bool private onchain;
    ERC721 metadata;

    // Sales
    bool public startSale;
    uint256 public price = .03 ether;
    uint public constant maxPurchase = 20;
    uint public constant maxSupply = 10000;
    uint private constant maxTeamMint = 100;

    // Team
    address private sara = 0x00796e910Bd0228ddF4cd79e3f353871a61C351C;
    address private greg = 0x3FF9f20B191C78Cae66103926E4536049AC4b944;
    address private steve = 0xBa48044540aB8cDAEe47a338844100a0aE756a8d;

    constructor() ERC721("CryptoSuits", "CRYPTOSUIT") {
        mintTeam(10, sara);
        mintTeam(10, greg);
        mintTeam(10, steve);
    }

    function totalSupply() public view returns(uint256) {
        return _tokenIds.current();
    }

    function exists(uint256 tokenId) public view returns(bool) {
        return _exists(tokenId);
    }

    function mint(uint numberOfTokens) public payable nonReentrant {
        require(startSale);
        require(numberOfTokens <= maxPurchase);
        require(_tokenIds.current().add(numberOfTokens) <= maxSupply);
        require(price.mul(numberOfTokens) <= msg.value);

        for(uint i = 0; i < numberOfTokens; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
        }
    }

    function mintTeam(uint256 numberOfTokens, address receiver) public onlyOwner {
        require(_tokenIds.current().add(numberOfTokens) <= maxSupply);
        require(_tokenIds.current().add(numberOfTokens) <= maxTeamMint);
        for(uint i = 0; i < numberOfTokens; i++) {
            _tokenIds.increment();
            _safeMint(receiver, _tokenIds.current());
        }
    }

    function getByOwner(address owner) view public returns(uint256[] memory result) {
        result = new uint256[](balanceOf(owner));
        uint256 resultIndex = 0;
        for (uint256 t = 1; t <= _tokenIds.current(); t++) {
            if (_exists(t) && ownerOf(t) == owner) {
                result[resultIndex] = t;
                resultIndex++;
            }
        }
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function setSaleStart(bool _startSale) public onlyOwner {
        startSale = _startSale;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setMetadata(address _metadata) public onlyOwner {
        metadata = ERC721(_metadata);
    }

    function setOnchain(bool _onchain) public onlyOwner {
        onchain = _onchain;
    }

    function withdraw() public payable onlyOwner {
        uint256 _each = address(this).balance / 3;
        require(payable(sara).send(_each));
        require(payable(greg).send(_each));
        require(payable(steve).send(_each));
    }

    function forwardERC20s(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    /*
    *   Overrides
    */
    function tokenURI(uint256 tokenId) override public view returns (string memory output) {
        require(_exists(tokenId));
        if(!onchain) {
            output = string(abi.encodePacked(baseUri, toString(tokenId)));
        } else {
            output = metadata.tokenURI(tokenId);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }


    function toString(uint256 value) public pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    receive () external payable virtual {}
}
