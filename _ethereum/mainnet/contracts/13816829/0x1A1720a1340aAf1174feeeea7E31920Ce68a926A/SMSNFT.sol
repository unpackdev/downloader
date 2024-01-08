// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract SMSNFT is ERC721Enumerable, PaymentSplitter, Ownable {

    using SafeMath for uint256;
    using SafeMath for uint8;

    string private _apiURI;
    bool public mintActive;
    uint256 public mintPrice;
    Counter public counter;
    mapping(address => uint8) public army;
    
    address[] private _team = [0xd9b6897Bf82c79e6c04723B6E6B9a99a49aD47dC, 0x35D79706f925B94ffA8fc188BC34DE95A9475175, 0x56496BdfBE3F0d9e724C142A4f76c78D17bf399B, 0xE449df0665d01451527D82461078D4a2a5928B30, 0x939Fe8EF7Fa5048Ab452E385DB35B6cDd7B73Fd5];
    uint256[] private _shares = [5, 25, 25, 10, 35];

    uint256 public constant MAX_ZUES = 5000;
    uint256 public constant MAX_DANTE = 10000;

    uint8 public constant NONE = 0;
    uint8 public constant ZUES = 1;
    uint8 public constant DANTE = 2;

    struct Counter {
        uint256 dante;
        uint256 zues;
    }

    constructor() ERC721("Sharp Metal Sticks", "SMS") PaymentSplitter(_team, _shares) {
        _apiURI = "https://api.sharpmetalsticks.com/meta/";
        mintPrice = 5e16;
        counter.dante = 5000;
    }

    function withdrawAll() public onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }    

    function mintZues(uint256 amount) public payable {
        require(mintActive, "Sale not acitve!");
        if (army[msg.sender] == NONE) {
            army[msg.sender] = ZUES;
        } else {
            require(army[msg.sender] == ZUES, "You can't mint from both armys");
        }
        require(mintPrice.mul(amount) == msg.value, "Insufficient ETH");
        require(counter.zues.add(amount) <= MAX_ZUES, "Exeeds max supply");
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, ++counter.zues);
        }
    }

    function mintDante(uint256 amount) public payable {
        require(mintActive, "Sale not acitve!");
        if (army[msg.sender] == NONE) {
            army[msg.sender] = DANTE;
        } else {
            require(army[msg.sender] == DANTE, "You can't mint from both armys");
        }
        require(mintPrice.mul(amount) == msg.value, "Insufficient ETH");
        require(counter.dante.add(amount) <= MAX_DANTE, "Exeeds max supply");
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, ++counter.dante);
        }
    }

    function masterMint(uint256 amount, address to, uint8 _army) public onlyOwner {
        if (_army == DANTE) {
            require(counter.dante.add(amount) <= MAX_DANTE, "Exeeds max supply");
            for (uint256 i = 0; i < amount; i++) {
                _safeMint(to, ++counter.dante);
            }
        } else if (_army == ZUES) {
            require(counter.zues.add(amount) <= MAX_ZUES, "Exeeds max supply");
            for (uint256 i = 0; i < amount; i++) {
                _safeMint(to, ++counter.zues);
            }
        }
    }

    function setMintActive(bool _active) public onlyOwner {
        mintActive = _active;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _apiURI = _uri;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function _baseURI() internal view override returns (string memory) {
        return _apiURI;
    }
}
