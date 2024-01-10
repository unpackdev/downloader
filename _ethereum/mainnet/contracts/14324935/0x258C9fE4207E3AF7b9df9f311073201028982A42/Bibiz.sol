// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract Bibiz is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public constant SUPPLY_MAX = 6969;

    uint256 public TOTAL_SUPPLY = 0;

    uint256 public constant MAX_MINT_PER_TX = 5;

    uint256 public constant PRICE = 0.069 ether;

    string public baseURI;

    bool public stealthLaunchLive = false;

    event StealthLaunchLive(bool stealthLaunchLive);

    event BaseURI(string baseURI);

    constructor() ERC721("Bibiz", "BIBIz") {
        _tokenIds.increment();
    }

    modifier isStealthLaunchLive() {
        require(stealthLaunchLive, "Sale is not active.");
        _;
    }

    modifier doesNotExceedMaxMint(uint256 count) {
        require(
            count <= MAX_MINT_PER_TX,
            "Exceeds max mint limit."
        );
        _;
    }

    modifier doesNotExceedSupply(uint256 count) {
        require(
            TOTAL_SUPPLY + count <= SUPPLY_MAX,
            "Supply exhausted."
        );
        _;
    }

    modifier isPaymentSufficient(uint256 count) {
        require(msg.value >= count * PRICE, "Insufficient ETH sent.");
        _;
    }

    function mint(uint256 count)
        public
        payable
        isStealthLaunchLive
        doesNotExceedMaxMint(count)
        doesNotExceedSupply(count)
        isPaymentSufficient(count)
    {
        for (uint256 index = 0; index < count; index++) {
            uint256 id = _tokenIds.current();
            _safeMint(msg.sender, id);
            _tokenIds.increment();
            TOTAL_SUPPLY++;
        }
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;

        emit BaseURI(baseURI);
    }

    function setStealthStatus(bool active) public onlyOwner {
        stealthLaunchLive = active;

        emit StealthLaunchLive(stealthLaunchLive);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}