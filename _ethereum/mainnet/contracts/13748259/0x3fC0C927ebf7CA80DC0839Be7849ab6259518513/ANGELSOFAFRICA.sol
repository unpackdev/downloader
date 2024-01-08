// SPDX-License-Identifier: None

pragma solidity 0.8.9;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract ANGELSOFAFRICA is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    using Counters for Counters.Counter;

    uint256 public constant ANGELS_TOTAL = 11111;
    uint256 public constant ANGELS_PRESALE = 4000;
    uint256 public constant ANGELS_COST = 0.08 ether;
    uint256 public constant ANGELS_PRESALE_COST = 0.04 ether;
    uint256 private constant ANGELS_MAINSALES_LIMIT = 4;
    uint256 private constant ANGELS_PRESALES_LIMIT = 8;

    string public constant baseExtension = ".json";
    string public baseTokenURI;
    string public notRevealedUri;

    bool public isSaleLive;
    bool public isPreSaleLive;
    bool public revealed = false;

    address public constant angelA = 0xF16b9B3e884F334a49A37BCD0Dd46c64528A75b0;
    address public constant angelB = 0x249e67841da9C12b4aC934D4C133c4FD88CC9F5d;
    address public constant angelC = 0x6f18bF4ce69F9F8A45D052c10bE655F8a83B0C91;
    address public constant angelD = 0xADD47e9B95e530E9ac62901F730850000d3E34A7;

    modifier whenPresaleStarted() {
        require(isPreSaleLive, "Presale is not open yet");
        _;
    }

    modifier whenPublicSaleStarted() {
        require(isSaleLive, "Public sale is not open yet");
        _;
    }

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri)
        ERC721("ANGELS OF AFRICA", "ANGELS")
    {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    /*
     * PUBLIC
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /*
     * ADMIN FUNCTIONS
     */

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function togglePresaleStarted() external onlyOwner {
        isPreSaleLive = !isPreSaleLive;
    }

    function togglePublicSaleStarted() external onlyOwner {
        isSaleLive = !isSaleLive;
    }

    /*
     * The real power
     */
    function presaleMint(uint256 _mintAmount)
        external
        payable
        whenPresaleStarted
    {
        uint256 total = totalSupply();
        require(_mintAmount > 0, "Need to mint at least 1 NFT");
        require(_mintAmount <= ANGELS_PRESALES_LIMIT, "Mint limit exceeded.");
        require(
            total + _mintAmount <= ANGELS_PRESALE,
            "Not enough Angels left."
        );

        require(msg.value >= ANGELS_PRESALE_COST * _mintAmount);
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, total + i);
        }
    }

    function reserveAngels() public onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 1; i <= 7; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mint(uint256 _mintAmount) external payable whenPublicSaleStarted {
        require(_mintAmount > 0, "Need to mint at least 1 NFT");
        uint256 total = totalSupply();
        if (msg.sender != owner()) {
            require(
                _mintAmount <= ANGELS_MAINSALES_LIMIT,
                "Mint limit exceeded."
            );
            require(msg.value >= ANGELS_COST * _mintAmount);
        }
        require(total + _mintAmount <= ANGELS_TOTAL, "Not enough Tokens left.");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, total + i);
        }
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(angelA, balance.mul(17).div(100));
        _widthdraw(angelB, balance.mul(17).div(100));
        _widthdraw(angelC, balance.mul(16).div(100));
        _widthdraw(angelD, balance.mul(50).div(100));
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}
