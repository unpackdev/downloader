/*
* Wake up, anon, it's time to rent some DVDs!
*/
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract BBBR is ERC721, Ownable {
    // .0399 ETH
    uint256 public rentalPrice = 39900000000000000;
    uint256 public maxRentals = 10001;
    uint256 public rentalsToReserve = 10;
    string public baseURI = "ipfs://QmXyd5jrNRGQYFYk4NezVmJu8Qh93iD4NR1sTtcAML9NXt/";

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Blockchain Blockbuster Rentals", "BBBR") {
        // Reserve some rentals for the store manager
        for(uint i=1; i <= rentalsToReserve; i++){
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function mintRental() public payable {
        require(rentalPrice <= msg.value, 'LOW_ETHER');
        require(_tokenIdCounter.current() + 1 <= maxRentals, 'MAX_REACHED');
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function totalSupply() public view returns(uint256) {
        return _tokenIdCounter.current();
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}