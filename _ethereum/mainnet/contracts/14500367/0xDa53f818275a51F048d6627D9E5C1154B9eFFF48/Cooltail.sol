// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
// import "./console.sol";

contract Cooltail is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    string baseURI;
    string public baseExtension = "";
    string public notRevealedUri;

    uint256 public maxSupply = 157;
    uint256 public cost = 1.2 ether;
    uint256 public whiteListCost = 0.9 ether;

    mapping(address => bool) public whiteList;

    bool public paused = false;
    bool public revealed = false;

    bool public isDutchAuction = false;
    uint256 public auctionStartTime;
    uint256 public auctionTimeStep;
    uint256 public auctionStepNumber;
    uint256 public auctionPriceStep;
    uint256 public auctionStartPrice;
    uint256 public auctionEndPrice;

    uint256 public whiteListStartTime = 1648990800; // 2022-04-03 21:00:00
    uint256 public whiteListEndTime = 1648994400; // 2022-04-03 22:00:00

    address public devteam;
    address public operator;

    constructor (
        string memory _initNotRevealedUri,
        address _operator,
        address _devteam
    ) ERC721("Cooltail NFT", "CTL") {
        devteam = _devteam;
        operator = _operator;

        setNotRevealedURI(_initNotRevealedUri);

        for (uint256 i = 1; i <= 2; i++) {
            _safeMint(_operator, i);
        }
    }

    function setWhiteList(address[] calldata _whiteList) external onlyOwner {
        for (uint i = 0; i < _whiteList.length; i++) {
          whiteList[_whiteList[i]] = true;
        }
    }

    function mint(uint256 _mintAmount) public payable {
        require(!paused, "CTL: Minting is temporary close");
        require(_mintAmount > 0, "CTL: qty should gte 0");
        uint256 _supply = totalSupply();
        require(_supply + _mintAmount <= maxSupply, "CTL: Achieve max supply");

        if (isDutchAuction) {
            _dutchAuction(_mintAmount);
        } else {
            _publicOffering(_mintAmount);
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_msgSender(), _supply + i);
        }
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

    function setDutchAuction(
        uint256 _auctionStartTime,
        uint256 _auctionTimeStep,
        uint256 _auctionStepNumber,
        uint256 _auctionPriceStep,
        uint256 _auctionStartPrice,
        uint256 _auctionEndPrice
    ) public onlyDevTeam {
        isDutchAuction = true;
        auctionStartTime = _auctionStartTime;
        auctionTimeStep = _auctionTimeStep;
        auctionStepNumber = _auctionStepNumber;
        auctionPriceStep = _auctionPriceStep;
        auctionStartPrice = _auctionStartPrice;
        auctionEndPrice = _auctionEndPrice;
    }

    function setRevealedWithURI(bool _isOpen, string memory _URI, string memory _baseExtension) public onlyOwner {
        revealed = _isOpen;
        baseURI = _URI;
        baseExtension = _baseExtension;
    }

    function flipAuction() public onlyDevTeam {
        isDutchAuction = !isDutchAuction;
    }

    function flipReveal() public onlyOwner {
        revealed = !revealed;
    }

    function flipPause() public onlyDevTeam {
        paused = !paused;
    }

    function withdraw() public onlyOwner {
        uint total = address(this).balance;
        uint toDevteam = total.mul(15).div(100);

        // 15% to devteam
        (bool sendToDevteam, ) = payable(devteam).call{ value: toDevteam }("");
        require(sendToDevteam, "BBC: Fail to withdraw to devteam");

        // 85% to operator
        (bool sendToOperator, ) = payable(operator).call{ value: total.sub(toDevteam) }("");
        require(sendToOperator, "BBC: Fail to withdraw to operator");
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
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

    function _dutchAuction(uint256 _mintAmount) internal {
        require(block.timestamp >= auctionStartTime, 'CTL: Auction not start');
        require((_mintAmount * getAuctionPrice()) <= msg.value, 'CTL: Not enough ether sent');
    }

    function _publicOffering(uint256 _mintAmount) internal {
        require(block.timestamp >= whiteListStartTime, "CTL: Not start sell yet");
        if (block.timestamp >= whiteListStartTime && block.timestamp <= whiteListEndTime) {
            // Presale
            require(msg.value >= whiteListCost * _mintAmount, "CTL: Insufficient balance");
            require(whiteList[_msgSender()], "CTL: You are not in the whiteList");
        } else {
            // public sale
            require(msg.value >= cost * _mintAmount, "CTL: Insufficient balance");
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    modifier onlyDevTeam() {
        require(devteam == _msgSender(), "CTL: caller is not the devTeam");
        _;
    }

}
