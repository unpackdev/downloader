pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract GalacticEmpire is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private constant _maxTokens = 11111;
    uint256 private _maxPresaleTokens = 1211;
    uint256 private constant _maxMint = 20;
    uint256 private constant _maxPresaleMint = 7;
    uint256 public constant _price = 77770000000000000; // 0.07777 ETH
    bool private _presaleActive = false;
    bool private _saleActive = false;

    string public _prefixURI;

    constructor() ERC721("GalacticEmpire", "GE") {}

    function _baseURI() internal view override returns (string memory) {
        return _prefixURI;
    }

    function setMaxPresaleTokens(uint256 quantity) public onlyOwner {
        _maxPresaleTokens = quantity;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _prefixURI = _uri;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function togglePreSale() public onlyOwner {
        _presaleActive = !_presaleActive;
    }

    function toggleSale() public onlyOwner {
        _saleActive = !_saleActive;
        _presaleActive = false;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId));

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function mintItems(uint256 amount) public payable {
        require(amount <= _maxMint);
        require(_saleActive);

        uint256 totalMinted = _tokenIds.current();
        require(totalMinted + amount <= _maxTokens);

        require(msg.value >= amount * _price);

        for (uint256 i = 0; i < amount; i++) {
            _mintItem(msg.sender);
        }
    }

    function presaleMintItems(uint256 amount) public payable {
        require(amount <= _maxPresaleMint);
        require(_presaleActive);

        uint256 totalMinted = _tokenIds.current();
        require(totalMinted + amount <= _maxPresaleTokens);

        require(msg.value >= amount * _price);

        for (uint256 i = 0; i < amount; i++) {
            _mintItem(msg.sender);
        }
    }

    function _mintItem(address to) internal returns (uint256) {
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(to, id);

        return id;
    }

    function reserve(uint256 quantity, address to) public onlyOwner {
        for(uint i = _tokenIds.current(); i < quantity; i++) {
            if (i < _maxTokens) {
                _tokenIds.increment();
                _safeMint(to, i + 1);
            }
        }
    }

    function withdraw() public payable onlyOwner {
        uint256 total = address(this).balance;
        uint256 one = total * 250;
        uint256 two = total * 150;
        uint256 three = total * 20;
        uint256 four = total * 180;
        uint256 five = total * 60;
        uint256 six = total * 60;
        uint256 seven = total * 35;
        uint256 eight = total * 25;
        uint256 nine = total * 30;
        uint256 ten = total * 50;
        uint256 eleven = total * 140;

        require(payable(0x1b81e535f48f6F66f6C6a3c0e6E6e05a749EE099).send(one / 1000));
        require(payable(0x57ef04387B2C75bcCbb03CbB0c139b55F6b226c4).send(two / 1000));
        require(payable(0xAcEA32c4b01e899551312175131b1254Fa87251b).send(three / 1000));
        require(payable(0xCaC934B4Ff871EC2D33B54b9387866Ca7Ed3D152).send(four / 1000));
        require(payable(0xa20Dc2C1025F9564fDd8925731Ac72d776Ffaf3D).send(five / 1000));
        require(payable(0xaF45179E538164e0e45Fe582bc8F47701aA41297).send(six / 1000));
        require(payable(0xfA02f156c508DF8bC2fFd1fd34Ac7Fa4A598b6b5).send(seven / 1000));
        require(payable(0xcc7c8E5a327B7410260BC1A449904C386024814B).send(eight / 1000));
        require(payable(0x387950f231F0AD9519627f9efAa4cac60abA40d9).send(nine / 1000));
        require(payable(0x2750748D43FE09dB80103b6C45245aB03681dC6c).send(ten / 1000));
        require(payable(0x85624F3810BD0D4fC05120dCaF83315973dD5633).send(eleven / 1000));
    }
}