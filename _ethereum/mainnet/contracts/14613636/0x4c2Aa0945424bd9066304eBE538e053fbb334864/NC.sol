// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ECDSA.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  .__   __.  __  .__   __.        __       ___           ______  __    __       ___      .___  ___. .______    __    ______   .__   __.      _______. //
//  |  \ |  | |  | |  \ |  |       |  |     /   \         /      ||  |  |  |     /   \     |   \/   | |   _  \  |  |  /  __  \  |  \ |  |     /       | //
//  |   \|  | |  | |   \|  |       |  |    /  ^  \       |  ,----'|  |__|  |    /  ^  \    |  \  /  | |  |_)  | |  | |  |  |  | |   \|  |    |   (----` //
//  |  . `  | |  | |  . `  | .--.  |  |   /  /_\  \      |  |     |   __   |   /  /_\  \   |  |\/|  | |   ___/  |  | |  |  |  | |  . `  |     \   \     //
//  |  |\   | |  | |  |\   | |  `--'  |  /  _____  \     |  `----.|  |  |  |  /  _____  \  |  |  |  | |  |      |  | |  `--'  | |  |\   | .----)   |    //
//  |__| \__| |__| |__| \__|  \______/  /__/     \__\     \______||__|  |__| /__/     \__\ |__|  |__| | _|      |__|  \______/  |__| \__| |_______/     //
//                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// owned by Angel

contract NC is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public constant MAX_ELEMENTS = 5555;
    uint256 public PRICE = 0.01 ether;

    bool private PAUSE = false;

    Counters.Counter private _tokenIdTracker;

    string private baseTokenURI;

    bool public META_REVEAL = false;
    uint256 public HIDE_FROM = 1;
    uint256 public HIDE_TO = 5555;
    string private sampleTokenURI;

    address public constant depositaddress =
        0xc76EFC449da8Fc102bBc88B45884ad50F728Fb73;

    event PauseEvent(bool pause);
    event welcomeToNINJA(uint256 indexed id);
    event NewPriceEvent(uint256 price);

    constructor(string memory baseURI) ERC721("NINJA CHAMPIONS", "NC") {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen() {
        require(totalToken() <= MAX_ELEMENTS, "Soldout!");
        require(!PAUSE, "Sales not open");
        _;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setSampleURI(string memory sampleURI) public onlyOwner {
        sampleTokenURI = sampleURI;
    }

    function totalToken() public view returns (uint256) {
        return _tokenIdTracker.current();
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

        if (!META_REVEAL && tokenId >= HIDE_FROM && tokenId <= HIDE_TO)
            return sampleTokenURI;

        string memory baseURI = baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI,  "/", tokenId.toString())) : "";
    }

    function mint(uint256 _tokenAmount) public payable saleIsOpen {
        uint256 total = totalToken();
        require(_tokenAmount <= 20, "Max limit");
        require(total + _tokenAmount <= MAX_ELEMENTS, "Max limit");
        require(msg.value >= price(_tokenAmount), "Value below price");

        address wallet = _msgSender();

        for (uint8 i = 1; i <= _tokenAmount; i++) {
            _mintAnElement(wallet, total + i);
        }
    }

    function _mintAnElement(address _to, uint256 _tokenId) private {
        _tokenIdTracker.increment();
        _safeMint(_to, _tokenId);

        emit welcomeToNINJA(_tokenId);
    }

    function price(uint256 _count) public view returns (uint256) {
        return PRICE.mul(_count);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function setPause(bool _pause) public onlyOwner {
        PAUSE = _pause;
        emit PauseEvent(PAUSE);
    }

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
        emit NewPriceEvent(PRICE);
    }

    function setMetaReveal(
        bool _reveal,
        uint256 _from,
        uint256 _to
    ) public onlyOwner {
        META_REVEAL = _reveal;
        HIDE_FROM = _from;
        HIDE_TO = _to;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(depositaddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function giftMint(address[] memory _addrs, uint256[] memory _tokenAmounts)
        public
        onlyOwner
    {
        uint256 totalQuantity = 0;
        uint256 total = totalToken();
        for (uint256 i = 0; i < _addrs.length; i++) {
            totalQuantity += _tokenAmounts[i];
        }
        require(total + totalQuantity <= MAX_ELEMENTS, "Max limit");
        for (uint256 i = 0; i < _addrs.length; i++) {
            for (uint256 j = 0; j < _tokenAmounts[i]; j++) {
                total++;
                _mintAnElement(_addrs[i], total);
            }
        }
    }

    function mintUnsoldTokens(uint256[] memory _tokensId) public onlyOwner {
        require(PAUSE, "Pause is disable");

        for (uint256 i = 0; i < _tokensId.length; i++) {
            if (rawOwnerOf(_tokensId[i]) == address(0)) {
                _mintAnElement(owner(), _tokensId[i]);
            }
        }
    }
}
