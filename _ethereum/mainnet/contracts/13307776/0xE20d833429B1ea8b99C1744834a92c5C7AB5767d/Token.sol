// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
*  ______      _      _      ______ _   _ 
* |  ____/\   | |    | |    |  ____| \ | |
* | |__ /  \  | |    | |    | |__  |  \| |
* |  __/ /\ \ | |    | |    |  __| | . ` |
* | | / ____ \| |____| |____| |____| |\  |
* |_|/_/    \_\______|______|______|_| \_|
* _____  _    _ _   _ _  __ _____ 
* |  __ \| |  | | \ | | |/ // ____|
* | |__) | |  | |  \| | ' /| (___  
* |  ___/| |  | | . ` |  <  \___ \ 
* | |    | |__| | |\  | . \ ____) |
* |_|     \____/|_| \_|_|\_\_____/ 

 * Punks once ruled the world. Now, they've fallen to pixel dust!
 * Fallen Punks, or FLUNKS, is a collection of 10,000 generative 
 * art pieces reimagined pixel by pixel.
 * A puzzle to solve for the community. 
 * No website, no twitter, no discord. 
 * Each FLUNK costs 0.05 eth, 20 per transaction. 
 */

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Token is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string _baseTokenURI;
    string _contractURI='https://gateway.pinata.cloud/ipfs/QmYk8bPX4cq4coNbqeoYhubxh7Z8QK9UgzUa8C7AX2qSNy';
    uint256 private _reserved = 0;
    uint256 private _price = 0.05 ether;
    bool public _paused = false;

    // // withdraw addresses
    address t1 = 0x78804e31C0D132B4b7c4313404632150D408A080;

    constructor() ERC721("Fallen Punks", "FLUNKS") {
        // setBaseURI(baseURI);
        _safeMint(t1, 0);
    }

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(!_paused, "Sale paused");
        require(num < 21, "You can mint a maximum of 20 FLUNKS");
        require(
            supply + num < 10000 - _reserved,
            "Exceeds maximum FLUNKS supply"
        );
        require(msg.value >= _price * num, "Ether sent is not correct");

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Just in case Eth does some crazy stuff
    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setcontractURI(string memory _icontractURI) public onlyOwner {
        _contractURI = _icontractURI;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner {
        require(_amount <= _reserved, "Exceeds reserved FLUNKS supply");

        uint256 supply = totalSupply();
        for (uint256 i; i < _amount; i++) {
            _safeMint(_to, supply + i);
        }

        _reserved -= _amount;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance;
        require(payable(t1).send(_each));
    }
}
