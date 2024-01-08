//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract RealFakeTurnips is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint currentPrice = 0.01 ether;

    uint turnipSupply = 6969;

    constructor() ERC721("RF Turnips", "RFT") {
        mintTurnips(msg.sender,10);
        mintTurnips(address(0xe317810ae5a074A29531Ca5D861A77012a108Fdd),10);
        mintTurnips(address(0x0121B90194147ce8FCAc988be1197CbC8912B5fF),10);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://www.realfaketurnips.com/metadata/";
    }

    function harvestTurnip(uint qty) external payable {
        require(msg.value >= currentPrice, "Amount of Ether sent too small");
        require(qty > 0, "Quantity must be more than 0");
        require(qty < 11, "Quantity must be less than or equal to 10");
        require((_tokenIdCounter.current() + qty) <= turnipSupply, "No turnips available");

        mintTurnips(msg.sender,qty);
    }

    function mintTurnips(address addr,uint qty) private {
        require((_tokenIdCounter.current() + qty) <= turnipSupply, "No turnips available");
        for(uint i = 0;i<qty;i++)
        {
            _tokenIdCounter.increment();
            _safeMint(addr, _tokenIdCounter.current());
        }
    }

    function getTurnipPrice() external view returns (uint) {
        return currentPrice;
    }

    function getTurnipSupply() external view returns (uint) {
        return turnipSupply;
    }

    function getCurrentId() external view returns (uint) {
        return _tokenIdCounter.current();
    }

    //Owner functions
    function getBalance() external view onlyOwner returns (uint) {
        return address(this).balance;
    }

    function withdraw() external onlyOwner {
        address _owner = owner();
        payable(_owner).transfer(address(this).balance);
    }
}
