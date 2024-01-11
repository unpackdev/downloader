//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract ProjectCube is ERC721, Ownable {
    using Counters for Counters.Counter;

    // Constants
    uint256 public constant totalSupply = 1_000;
    Counters.Counter public currentSupply;

    struct Pop {
        string color;
        uint256 expiry;
    }

    uint256 public _xsgdMintPrice;

    uint256 public _ethMintPrice;

    address public _xsgdProxyAddress;

    bytes32 private _seed;

    uint256 private _popDuration;

    string private _baseUri;

    // RED, ORANGE, YELLOW, GREEN, BLUE, INDIGO, PINK
    string[7] private _hexColors = [
        "#fc2847",
        "#ffa343",
        "#fdfc74",
        "#71bc78",
        "#0088ff",
        "#8349e6",
        "#fb7efd"
    ];

    mapping(uint256 => string) public _baseColors;

    event Popped(uint256 indexed tokenId, Pop pop);
    event Mint(uint256 indexed tokenId, address indexed to, string baseColor);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseUri,
        bytes32 seed,
        uint256 xsgdMintPrice,
        uint256 ethMintPrice,
        uint256 popDuration,
        address xsgdProxyAddress
    ) ERC721(name, symbol) {
        _baseUri = baseUri;
        _seed = seed;
        _xsgdMintPrice = xsgdMintPrice;
        _ethMintPrice = ethMintPrice;
        _popDuration = popDuration;
        _xsgdProxyAddress = xsgdProxyAddress;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function _setBaseURI(string memory baseUri) public onlyOwner {
        _baseUri = baseUri;
    }

    function _getBiasedRandomIndex() internal returns (uint256) {
        uint256 blockHashInt = uint256(blockhash(block.number));
        uint256 seedInt = uint256(_seed);
        bytes32 newSeed = keccak256(abi.encodePacked(blockHashInt + seedInt));
        _seed = newSeed;
        uint256 roll = uint256(newSeed) % 100;
        uint256 index = 0;
        if (roll > 78) {
            index = 0;
        } else if (roll > 56) {
            index = 1;
        } else if (roll > 34) {
            index = 2;
        } else if (roll > 12) {
            index = 3;
        } else if (roll > 6) {
            index = 4;
        } else if (roll > 2) {
            index = 5;
        } else {
            index = 6;
        }
        return index;
    }

    function _getRandomIndex() internal returns (uint256) {
        uint256 blockHashInt = uint256(blockhash(block.number));
        uint256 seedInt = uint256(_seed);
        bytes32 newSeed = keccak256(abi.encodePacked(blockHashInt + seedInt));
        uint256 index = uint256(newSeed) % 7;
        _seed = newSeed;
        return index;
    }

    function _getPopExpiry() internal view returns (uint256) {
        return block.number + _popDuration;
    }

    function _popToken(uint256 tokenId) internal {
        Pop memory pop = Pop(
            _hexColors[_getRandomIndex()],
            block.number + _popDuration
        );
        emit Popped(tokenId, pop);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 tokenId
    ) internal override {
        _popToken(tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {}

    function _safeMint(address to, uint256 tokenId) internal override {
        require(
            tokenId >= 1 && tokenId <= 1000,
            "ERC721Custom: Not a valid cube"
        );
        require(
            currentSupply.current() < totalSupply,
            "ERC721Custom: Fully Minted"
        );
        currentSupply.increment();
        _baseColors[tokenId] = _hexColors[_getBiasedRandomIndex()];
        emit Mint(tokenId, to, _baseColors[tokenId]);
        _safeMint(to, tokenId, "");
    }

    function withdrawEth(address payable payee, uint256 amount)
        public
        onlyOwner
    {
        payee.transfer(amount);
    }

    function withdrawXsgd(address payable payee, uint256 amount)
        public
        onlyOwner
    {
        IERC20(_xsgdProxyAddress).transfer(payee, amount);
    }

    function setPopDuration(uint256 popDuration) public onlyOwner {
        _popDuration = popDuration;
    }

    function setXsgdProxyAddress(address xsgdProxyAddress) public onlyOwner {
        _xsgdProxyAddress = xsgdProxyAddress;
    }

    function setMintPrice(uint256 xsgdMintPrice, uint256 ethMintPrice)
        public
        onlyOwner
    {
        _xsgdMintPrice = xsgdMintPrice;
        _ethMintPrice = ethMintPrice;
    }

    function mintTo(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function mintWithEth(uint256 tokenId) public payable {
        require(
            msg.value == _ethMintPrice,
            "ERC721Custom: sent ether different from ethBidAmount"
        );
        _safeMint(_msgSender(), tokenId);
    }

    function mintWithXsgd(uint256 tokenId) public {
        IERC20(_xsgdProxyAddress).transferFrom(
            _msgSender(),
            address(this),
            _xsgdMintPrice
        );
        _safeMint(_msgSender(), tokenId);
    }

    function popToken(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Custom: not owner or approver"
        );
        _popToken(tokenId);
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Custom: not owner or approver"
        );
        _burn(tokenId);
        currentSupply.decrement();
    }
}
