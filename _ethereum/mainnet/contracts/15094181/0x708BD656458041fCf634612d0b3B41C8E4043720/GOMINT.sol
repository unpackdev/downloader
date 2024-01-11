//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./Counters.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721.sol";

contract GOMINT is Ownable, Pausable, ERC721 {
    using Counters for Counters.Counter;

    uint256 public price;
    uint256 public maxSupply;
    string public baseTokenURI;
    Counters.Counter private tokenId;
    mapping(address => bool) public minters;

    constructor() ERC721("GOMINT", "GOMINT") {
        _pause();
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function togglePause() external onlyOwner  {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function mint() external payable whenNotPaused {
        require(msg.value >= price, "Not enough funds");
        require(balanceOf(msg.sender) == 0, "Cannot have more than one");
        require(maxSupply >= tokenId.current() + 1, "Out of supply");

        tokenId.increment();
        minters[msg.sender] = true;
        _safeMint(msg.sender, tokenId.current());
    }

    function teamMint(uint256 _amount) external onlyOwner {
        for (uint256 i; i < _amount; i++) {
            tokenId.increment();
            _safeMint(msg.sender, tokenId.current());
        }
    }

    function withdraw(address _receiver, uint256 _amount) external onlyOwner {
        payable(_receiver).transfer(_amount);
    }
}
