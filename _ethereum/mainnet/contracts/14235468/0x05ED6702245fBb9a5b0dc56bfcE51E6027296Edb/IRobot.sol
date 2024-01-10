// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
// import "./console.sol";

contract IRobot is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = "";
    string public notRevealedUri;

    uint256 public cost = 0.8 ether;
    uint256 public whiteListCost = 0.66 ether;

    mapping(address => bool) public whiteList;
    mapping(address => bool) public OGList;

    uint256 public maxSupply = 666;
    uint256 public level1Supply = 333;
    uint256 public level2Supply = 310;
    uint256 public maxOGSupply = 100;
    uint256 public maxWhiteLisSupply = 150;

    bool public paused = false;
    bool public revealed = false;

    bool public isDutchAuction = false;
    uint256 public auctionStartTime;
    uint256 public auctionTimeStep;
    uint256 public auctionStepNumber;
    uint256 public auctionPriceStep;
    uint256 public auctionStartPrice;
    uint256 public auctionEndPrice;

    uint256 public whiteListStartTime = 1645286400;
    uint256 public whiteListEndTime = 1645335059;

    address public devTeamAddress;

    constructor (
        string memory _name,
        string memory _symbol,
        string memory _initNotRevealedUri,
        address _operator,
        address _devteam
    ) ERC721(_name, _symbol) {
        devTeamAddress = _devteam;

        setNotRevealedURI(_initNotRevealedUri);

        for (uint256 i = 1; i <= 23; i++) {
            _safeMint(_operator, i);
        }

        transferOwnership(_operator);
    }

    function setWhiteList(address[] calldata _whiteList) external onlyOwner {
        for (uint i = 0; i < _whiteList.length; i++) {
          whiteList[_whiteList[i]] = true;
        }
    }

    function setOGList(address[] calldata _OGList) external onlyOwner {
        for (uint i = 0; i < _OGList.length; i++) {
          OGList[_OGList[i]] = true;
        }
    }

    function isOG(address _user) public view returns (bool) {
        return OGList[_user];
    }

    function isWhiteList(address _user) public view returns (bool) {
        return whiteList[_user];
    }

    function getAuctionPrice() public view returns (uint256) {
        if (!isDutchAuction) {
            return 0;
        }

        if (block.timestamp < auctionStartTime) {
            return auctionStartPrice;
        }

        uint256 step = (block.timestamp - auctionStartTime) / auctionTimeStep;
        if (step > auctionStepNumber) {
            step = auctionStepNumber;
        }

        return  auctionStartPrice > step * auctionPriceStep
        ? auctionStartPrice - step * auctionPriceStep
        : auctionEndPrice;
    }

    function _dutchAuction(uint256 _mintAmount, uint256 _supply) internal {
        require(block.timestamp >= auctionStartTime, 'IRobot: Auction not start');
        require((_mintAmount * getAuctionPrice()) <= msg.value, 'Not enough ether sent');

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_msgSender(), _supply + i);
        }
    }

    function _publicOffering(uint256 _mintAmount, uint256 _supply) internal {
        require(block.timestamp >= whiteListStartTime, "IRobot: Not start sell yet");
        bool _isWhiteList = isWhiteList(_msgSender());
        bool _isOG = isOG(_msgSender());

        if (block.timestamp >= whiteListStartTime && block.timestamp <= whiteListEndTime) {
            // Presale
            require(msg.value >= whiteListCost * _mintAmount, "IRobot: Insufficient balance");
            require(_isWhiteList || _isOG, "IRobot: You are not in the whiteList");

            if (_isWhiteList) {
                require(_mintAmount == 1, "IRobot: Only can mint 1 nft");
                require(_mintAmount <= maxWhiteLisSupply , "IRobot: Preserve sold out");
                require(balanceOf(_msgSender()) < 1, "IRobot: Achieve max minting");
                maxWhiteLisSupply -= _mintAmount;
            } else if (_isOG){
                require(_mintAmount <= 2, "IRobot: Only can mint 2 nft");
                require(_mintAmount <= maxOGSupply, "IRobot: Preserve sold out");
                require(balanceOf(_msgSender()) < 2, "IRobot: Achieve max minting");
                maxOGSupply -= _mintAmount;
            }
        } else {
            // public sale
            require(msg.value >= cost * _mintAmount, "IRobot: Insufficient balance");
            require(_mintAmount <= 2, "IRobot: Only can mint 2 nft");
            require(_supply + _mintAmount <= level1Supply, "IRobot: Level 1 sold out");

            if (_isOG) {
                require(balanceOf(_msgSender()) < 4, "IRobot: Achieve max minting");
            } else if (_isWhiteList) {
                require(balanceOf(_msgSender()) < 3, "IRobot: Achieve max minting");
            } else {
                require(balanceOf(_msgSender()) < 2, "IRobot: Achieve max minting");
            }
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_msgSender(), _supply + i);
        }
    }

    function mint(uint256 _mintAmount) public payable {
        uint256 _supply = totalSupply();
        require(!paused, "IRobot: Minting is temporary close");
        require(_mintAmount > 0, "IRobot: qty should gte 0");
        require(_supply + _mintAmount <= maxSupply, "IRobot: Achieve max supply");

        if (isDutchAuction) {
            _dutchAuction(_mintAmount, _supply);
        } else {
            _publicOffering(_mintAmount, _supply);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

    function setWhiteListTime(uint256 _startTime, uint256 _endTime) public onlyOwner {
        whiteListStartTime = _startTime;
        whiteListEndTime = _endTime;
    }

    function setCost(uint256 _cost, uint256 _whiteListCost) public onlyOwner {
        cost = _cost;
        whiteListCost = _whiteListCost;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setDutchAuction(
        uint256 _auctionStartTime,
        uint256 _auctionTimeStep,
        uint256 _auctionStepNumber,
        uint256 _auctionPriceStep,
        uint256 _auctionStartPrice,
        uint256 _auctionEndPrice
    ) public onlyOwner {
        auctionStartTime = _auctionStartTime;
        auctionTimeStep = _auctionTimeStep;
        auctionStepNumber = _auctionStepNumber;
        auctionPriceStep = _auctionPriceStep;
        auctionStartPrice = _auctionStartPrice;
        auctionEndPrice = _auctionEndPrice;
    }

    function setRevealedWithURI(bool _isOpen, string memory _URI) public onlyOwner {
        revealed = _isOpen;
        setBaseURI(_URI);
    }

    function flipAuction() public onlyDevTeam {
        isDutchAuction = !isDutchAuction;
    }

    function flipReveal() public onlyOwner {
        revealed = !revealed;
    }

    function flipPause() public onlyOwner {
        paused = !paused;
    }

    function withdraw() public payable onlyOwner {
        (bool send, ) = payable(owner()).call{value: address(this).balance}("");

        require(send, "IRobot: Fail to withdraw");
    }

    modifier onlyDevTeam() {
        require(devTeamAddress == _msgSender(), "IRobot: caller is not the devTeam");
        _;
    }

}
