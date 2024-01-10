//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";

contract UKRMFERS is ERC721A, Ownable, Pausable {
    using SafeMath for uint256;

    event PermanentURI(string _value, uint256 indexed _id);

    uint public constant MAX_SUPPLY = 10000;
    uint public constant PRICE = 0.024 ether;
    uint public constant MAX_PER_MINT = 10;

    string public _contractBaseURI;

    constructor(string memory baseURI) ERC721A("UKR Mfers", "UKRMFERS") {
        _contractBaseURI = baseURI;
        _pause();
    }

  

    function mint(uint256 quantity) external payable whenNotPaused {
        require(quantity > 0, "Quantity cannot be zero");
        uint totalMinted = totalSupply();
        require(quantity <= MAX_PER_MINT, "Cannot mint that many at once");
        require(totalMinted.add(quantity) < MAX_SUPPLY, "Not enough NFTs left to mint");
        require(PRICE * quantity <= msg.value, "Insufficient funds sent");

        _safeMint(msg.sender, quantity);
        lockMetadata(quantity);
    }

    function lockMetadata(uint256 quantity) internal {
        for (uint256 i = quantity; i > 0; i--) {
            uint256 tid = totalSupply() - i;
            emit PermanentURI(tokenURI(tid), tid);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }



    function _baseURI() internal view override returns (string memory) {
        return _contractBaseURI;
    }
}