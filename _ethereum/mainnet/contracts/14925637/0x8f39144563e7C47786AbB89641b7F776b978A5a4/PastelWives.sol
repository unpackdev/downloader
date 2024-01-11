// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract PastelWives is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public wivePrice = 0.07 ether;

    uint256 public constant MAX_PURCHASE_LIMIT = 3;

    uint256 public constant MAX_SUPPLY = 2222;

    bool public saleIsActive = false;
    bool public isFreeMint = false;
    bool public isPresale = true;

    uint256 public wiveReserve = 250;

    string private newBaseURI;

    mapping(address => uint256) private whiteList;
    mapping(address => bool) private freeMintWhiteList;

    constructor() ERC721("Pastel Wives", "PWNFT") {}

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function reserveWives(address _to, uint256 _reserveAmount)
        public
        onlyOwner
    {
        uint256 supply = _totalSupply();
        require(
            _reserveAmount > 0 && _reserveAmount <= wiveReserve,
            "Not enough reserve left for team"
        );
        for (uint256 i = 0; i < _reserveAmount; i++) {
            _tokenIdTracker.increment();
            _safeMint(_to, supply + i);
        }
        wiveReserve = wiveReserve.sub(_reserveAmount);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        newBaseURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return newBaseURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPresaleState() public onlyOwner {
        isPresale = !isPresale;
    }

    function flipFreeMintState() public onlyOwner {
        isFreeMint = !isFreeMint;
    }

    function freeMintWive() public {
        require(saleIsActive, "Sale must be active to mint wive");
        require(isFreeMint, "Free mint is not started yet");
        require(
            isFreeMintWhiteListed(msg.sender),
            "Not whitelisted free mint address"
        );
        require(
            _totalSupply().add(1) <= MAX_SUPPLY,
            "Purchase would exceed max supply of Wives"
        );

        uint256 mintIndex = _totalSupply();
        if (_totalSupply() < MAX_SUPPLY) {
            _tokenIdTracker.increment();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function mintWive(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint wive");
        if (isPresale) {
            require(isWhiteListed(msg.sender) != 0, "Not whitelisted");
            require(
                numberOfTokens <= whiteList[msg.sender],
                "Over Max Mint per Address"
            );
        } else {
            require(
                numberOfTokens <= MAX_PURCHASE_LIMIT,
                "Over Max Mint per Address"
            );
        }
        require(
            _totalSupply().add(numberOfTokens) <= MAX_SUPPLY,
            "Purchase would exceed max supply of Wives"
        );
        require(
            msg.value >= wivePrice.mul(numberOfTokens),
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _totalSupply();
            if (_totalSupply() < MAX_SUPPLY) {
                _tokenIdTracker.increment();
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function setWivePrice(uint256 newPrice) public onlyOwner {
        wivePrice = newPrice;
    }

    function setWhiteList(address _address, uint256 grade) public onlyOwner {
        whiteList[_address] = grade;
    }

    function setWhiteListMultiple(address[] memory _addresses, uint256 grade)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            setWhiteList(_addresses[i], grade);
        }
    }

    function removeWhiteList(address _address) public onlyOwner {
        whiteList[_address] = 0;
    }

    function isWhiteListed(address _address) public view returns (uint256) {
        return whiteList[_address];
    }

    function setFreeMintWhiteList(address _address) public onlyOwner {
        freeMintWhiteList[_address] = true;
    }

    function setFreeMintWhiteListMultiple(address[] memory _addresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            setFreeMintWhiteList(_addresses[i]);
        }
    }

    function removeFreeMintWhiteList(address _address) public onlyOwner {
        freeMintWhiteList[_address] = false;
    }

    function isFreeMintWhiteListed(address _address)
        public
        view
        returns (bool)
    {
        return freeMintWhiteList[_address];
    }
}
