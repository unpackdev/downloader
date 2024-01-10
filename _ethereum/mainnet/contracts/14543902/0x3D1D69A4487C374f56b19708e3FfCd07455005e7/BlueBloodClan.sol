// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
// import "./console.sol";

contract BlueBloodClan is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    string baseURI;
    string public baseExtension = "";
    string public notRevealedUri;

    bool public paused = false;
    bool public revealed = false;

    uint public cost = 0.19 ether;
    uint public whiteListCost = 0.13 ether;
    uint public maxSupply = 3131;
    uint public whiteListStartTime = 1649505600; // 2022-04-09 20:00:00
    uint public whiteListEndTime = 1649509200; // 2022-04-09 21:00:00

    address public operator;
    address public devteam;

    mapping(address => bool) public whiteList;

    constructor(
        string memory _initURI,
        address _operator,
        address _devteam
    ) ERC721("Blue Blood Clan", "BBC") {
        operator = _operator;
        devteam = _devteam;

        setNotRevealedURI(_initURI);

        for (uint i = 1; i <= 50; i++) {
            _safeMint(operator, i);
        }
    }

    function mint(uint _mintAmount) public payable {
        require(!paused, "BBC: Minting is temporary close");
        require(block.timestamp >= whiteListStartTime, "BBC: It's not yet time");
        require(_mintAmount > 0, "BBC: qty should gte 0");
        uint _supply = totalSupply();
        require(_supply + _mintAmount <= maxSupply, "BBC: Achieve max supply");

        // Presale
        if (block.timestamp >= whiteListStartTime && block.timestamp < whiteListEndTime) {
            require(whiteList[_msgSender()], "BBC: You are not in the whiteList");
            require(msg.value >= whiteListCost * _mintAmount, "BBC: Insufficient balance");
            require((balanceOf(_msgSender()) + _mintAmount) <= 5, "BBC: Only can mint less then 5 nft");
        }
        // public sale
        else {
            require(msg.value >= cost * _mintAmount, "BBC: Insufficient balance");
        }

        for (uint i = 1; i <= _mintAmount; i++) {
            _safeMint(_msgSender(), _supply + i);
        }

    }

    function setWhiteList(address[] calldata _whiteList) external onlyOwner {
        for (uint i = 0; i < _whiteList.length; i++) {
            whiteList[_whiteList[i]] = true;
        }
    }

    function setWhiteListTime(uint _startTime, uint _endTime) public onlyOwner {
        whiteListStartTime = _startTime;
        whiteListEndTime = _endTime;
    }

    function setCost(uint _cost, uint _whiteListCost) public onlyOwner {
        cost = _cost;
        whiteListCost = _whiteListCost;
    }

    function setRevealedWithURI(bool _isOpen, string memory _URI, string memory _baseExtension) public onlyOwner {
        revealed = _isOpen;
        baseURI = _URI;
        baseExtension = _baseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function flipReveal() public onlyOwner {
        revealed = !revealed;
    }

    function flipPause() public onlyOwner {
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

    function walletOfOwner(address _owner) public view returns (uint[] memory) {
        uint ownerTokenCount = balanceOf(_owner);
        uint[] memory tokenIds = new uint[](ownerTokenCount);
        for (uint i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0 ? string(
            abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

}
