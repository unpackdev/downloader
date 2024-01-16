// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./ERC721A.sol";

contract PASS is ERC721A {
    using Strings for uint256;

    address private _owner;

    bool public _isSaleActive = false;
    bool public _revealed = false;

    // Gduck basic info
    uint256 public maxSupply;
    uint256 public firstRoundPrice = 0.08 ether;
    uint256 public secondRoundPrice = 0.13 ether;

    address private teamHolder;

    string public baseURI = "";
    string public notRevealedUri;

    uint256 public roundOneStartTime;
    uint256 public roundTwoStartTime;
    uint256 public mintEndTime;

    uint256 public roundOneAmount;
    uint256 public roundTwoAmount;

    mapping(uint256 => string) private _tokenURIs;

    mapping(address => bool) private adminAddressList;

    modifier onlyOwner() {
        require(adminAddressList[msg.sender], "only owner");
        _;
    }

    constructor(
        uint256 _roundOneStartTime,
        uint256 _roundTwoStartTime,
        uint256 _mintEndTime,
        uint256 _roundOneAmount,
        uint256 _roundTwoAmount,
        address _teamHolder,
        string memory _notRevealedUri,
        address _adminAddress
    ) ERC721A("Spola PASS", "PASS") {
        require(
            _roundTwoStartTime > _roundOneStartTime,
            "round two must be bigger than round one"
        );
        require(
            _mintEndTime > _roundTwoStartTime,
            "end time must be bigger than round two"
        );

        roundOneStartTime = _roundOneStartTime;
        roundTwoStartTime = _roundTwoStartTime;
        mintEndTime = _mintEndTime;

        notRevealedUri = _notRevealedUri;

        maxSupply = _roundOneAmount + _roundTwoAmount;
        roundOneAmount = _roundOneAmount;
        roundTwoAmount = _roundTwoAmount;

        adminAddressList[_adminAddress] = true;
        teamHolder = _teamHolder;
_isSaleActive = true;
    }

    function getPrice() internal view returns (uint256) {
        uint256 _now = block.timestamp;
        if (_now < roundTwoStartTime) {
            return firstRoundPrice;
        } else {
            return secondRoundPrice;
        }
    }

    function mintFirstRound(uint256 tokenQuantity) public payable {
        require(_isSaleActive, "Not Active");
        require(tokenQuantity > 0, "Quantity must bigger than zero");
        require(totalSupply() + tokenQuantity <= roundOneAmount, "Exceed Max");
        require(block.timestamp > roundOneStartTime, "Round One not start");
        require(block.timestamp < roundTwoStartTime, "Round One was over");
        uint256 basicPrice = getPrice();
        uint256 price = tokenQuantity * basicPrice;
        require(msg.value >= price, "Not Enough ETH");
        _mint(msg.sender, tokenQuantity);
    }

    function mintSecondRound(uint256 tokenQuantity) public payable {
        require(_isSaleActive, "Not Active");
        require(tokenQuantity > 0, "Quantity must bigger than zero");
        require(totalSupply() + tokenQuantity <= maxSupply, "Exceed Max");
        require(block.timestamp > roundTwoStartTime, "Round One not over");
        require(block.timestamp < mintEndTime, "Round Two was over");
        uint256 basicPrice = getPrice();
        uint256 price = tokenQuantity * basicPrice;
        require(msg.value >= price, "Not Enough ETH");
        _mint(msg.sender, tokenQuantity);
    }

    function adminMint(uint256 tokenQuantity) external onlyOwner {
        _mint(msg.sender, tokenQuantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Not Exist");
        if (_revealed == false) {
            return notRevealedUri;
        }
        string memory _tokenURI = _tokenURIs[tokenId];
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }
        return
            string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"));
    }

    function openBox(string memory _newBaseURI) external onlyOwner {
        uint256 amount = maxSupply - totalSupply();
        if (amount > 0) {
            _mint(teamHolder, amount);
        }

        setReveal(true);
        setBaseURI(_newBaseURI);
    }

    //Setting functions

    //if something wrong ,solve it
    function setTokenURI(string memory uri, uint256 tokenId)
        external
        onlyOwner
    {
        _tokenURIs[tokenId] = uri;
    }

    function setSaleActive(bool _activeType) public onlyOwner {
        _isSaleActive = _activeType;
    }

    function setReveal(bool _revealedType) public onlyOwner {
        _revealed = _revealedType;
    }

    // time and price

    function setFirstRoundPrice(uint256 _mintPrice) public onlyOwner {
        firstRoundPrice = _mintPrice;
    }

    function setSecondRoundPrice(uint256 _mintPrice) public onlyOwner {
        secondRoundPrice = _mintPrice;
    }

    function setRoundOneStartTime(uint256 _t) external onlyOwner {
        roundOneStartTime = _t;
    }

    function setRoundTwoStartTime(uint256 _t) external onlyOwner {
        roundTwoStartTime = _t;
    }

    function setMintEndTime(uint256 _t) external onlyOwner {
        mintEndTime = _t;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(to).transfer(balance);
        }
    }

    //admin
    function setAdminInfo(address _addr, bool _bool) external onlyOwner {
        adminAddressList[_addr] = _bool;
    }

    function setTeamHolder(address _addr) external onlyOwner {
        teamHolder = _addr;
    }
}
