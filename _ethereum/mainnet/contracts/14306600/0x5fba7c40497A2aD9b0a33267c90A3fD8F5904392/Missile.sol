// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
// import "./console.sol";

contract Missile is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    string private baseURI;
    uint256 public MAXSUPPLY = 10_000;
    uint256 public cost = 0.1 ether;
    bool public paused = false;

    constructor (
        string memory _name,
        string memory _symbol,
        string memory _URI
    ) ERC721(_name, _symbol) {
        baseURI = _URI;
    }

    function mint(uint256 _mintAmount) public payable {
        uint256 _supply = totalSupply();
        require(!paused, "Missile: Minting is temporary close");
        require(_mintAmount > 0, "Missile: qty should gte 0");
        require(_supply.add(_mintAmount) <= MAXSUPPLY, "Missile: Achieve max supply");
        require(msg.value >= cost.mul(_mintAmount), "Missile: Insufficient balance");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_msgSender(), _supply + i);
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

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function flipPause() public onlyOwner {
        paused = !paused;
    }

    function withdraw() public onlyOwner {
        uint totalBalance = address(this).balance;

        uint share = totalBalance.div(2);

        (bool sendDevteam, ) = payable(0x733332b63c0Fe8668f5Eba3A905BB7c9274614E6).call{ value: share }("");
        require(sendDevteam, "Missile: Fail to withdraw Devteam");

        (bool sendOperator, ) = payable(0x0eA82aa70Ba54531B705029a52A2fBEe8601eB82).call{ value: totalBalance.sub(share) }("");
        require(sendOperator, "Missile: Fail to withdraw Operator");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
