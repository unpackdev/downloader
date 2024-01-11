// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
// import "./console.sol";

contract Starmfers is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    string private baseURI;
    string public baseExtension = "";
    string public notRevealedUri;

    uint public startWhiteListTime = 1650625200;
    uint public endWhiteListTime = 1650884400;

    uint public maxSupply = 7777;
    uint public cost = 0.0177 ether;

    address public devteam;
    address public operator;

    bool public paused = false;

    mapping(address => bool) public whiteList;

    constructor(
        string memory _initURI,
        address _devteam,
        address _operator
    ) ERC721("Starmfers", "STMRS") {
        baseURI = _initURI;
        devteam = _devteam;
        operator = _operator;

        for (uint i = 1; i <= 57; i++) {
            _safeMint(_operator, i);
        }
    }

    function totalCost(uint _mintAmount) public view returns (uint) {
        uint _totalCost = _mintAmount.mul(cost);
        // whiteList free mint 1 NFT
        if (
            block.timestamp <= endWhiteListTime &&
            whiteList[_msgSender()] &&
            balanceOf(_msgSender()) == 0
        ) {

            _totalCost = _totalCost.sub(cost);
        }

        return _totalCost;
    }

    function mint(uint _mintAmount) public payable {
        require(!paused, "STMRS: Minting is temporary close");
        require(block.timestamp >= startWhiteListTime, "STMRS: Not start sell yet");
        require(_mintAmount > 0, "STMRS: qty should gte 0");
        uint _supply = totalSupply();
        require(_supply + _mintAmount <= maxSupply, "STMRS: Achieve max supply");
        require(msg.value >= totalCost(_mintAmount), "STMRS: Insufficient balance");

        for (uint i = 1; i <= _mintAmount; i++) {
            _safeMint(_msgSender(), _supply + i);
        }
    }

    function setWhiteList(address[] calldata _whiteList) external onlyOwner {
        for (uint i = 0; i < _whiteList.length; i++) {
            whiteList[_whiteList[i]] = true;
        }
    }

    function setCost(uint _cost) public onlyOwner {
        cost = _cost;
    }

    function setWhiteListTime(uint _startTime, uint _endTime) public onlyOwner {
        startWhiteListTime = _startTime;
        endWhiteListTime = _endTime;
    }

    function setRevealedWithURI(string memory _URI, string memory _baseExtension) public onlyOwner {
        baseURI = _URI;
        baseExtension = _baseExtension;
    }

    function flipPause() public onlyOwner {
        paused = !paused;
    }

    function withdraw() public onlyOwner {
        uint total = address(this).balance;
        uint toDevteam = total.mul(15).div(100);

        // 15% to devteam
        (bool sendToDevteam, ) = payable(devteam).call{ value: toDevteam }("");
        require(sendToDevteam, "STMRS: Fail to withdraw to devteam");

        // 85% to operator
        (bool sendToOperator, ) = payable(operator).call{ value: total.sub(toDevteam) }("");
        require(sendToOperator, "STMRS: Fail to withdraw to operator");
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

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0 ? string(
            abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

}
