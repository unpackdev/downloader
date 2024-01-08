// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract EtherGhostsNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _givedAmountTracker;

    string private _baseTokenURI;
    uint256 public saleStartTimestamp = 1633122000;

    mapping(address => bool) private whiteListAdresses;

    event Bought(address walletAddress, uint256 tokenId);

    constructor() ERC721("Ether  Ghosts", "GHOSTS") {
        _baseTokenURI = "ipfs://QmS612yMoGTt1FpTWWNaCd8kTHm1afwFK25tGW4rGnFeqk/";
        whiteListAdresses[0x5042FEE4CE5C6aEd241A79d9309E1FB640EE3E19] = true;
        whiteListAdresses[0xA239c13c054E498B9bE633262574862676d73f7f] = true;
        whiteListAdresses[0xC532689a88a5dBc7D5bdF4886C9A340466D3E125] = true;
        whiteListAdresses[0xB33dAB527dAc8AbAEC0c9F2Cd7Fe27FdB047612a] = true;
        whiteListAdresses[0x8AFA2c45FD9614A818b7Cb242eA361B1EA073f29] = true;
    }

    function contractURI() external pure returns (string memory) {
        return "https://www.etherghosts.art/api/contract_metadata";
    }

    function buy(uint256 amount) external payable {
        require(
            block.timestamp >= saleStartTimestamp,
            "Sale has not started yet"
        );
        require(amount <= 10000 - _tokenIdTracker.current(), "Not enough left");
        require(
            msg.value >= amount * 50000000000000000,
            "Invalid ether amount sent "
        );
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = mint(msg.sender);
            emit Bought(msg.sender, tokenId);
        }
        payable(owner()).transfer(msg.value);
    }

    function buy(address receiver, uint256 amount) external payable {
        require(whiteListAdresses[msg.sender], "must be whitelisted");
        require(amount <= 10000 - _tokenIdTracker.current(), "Not enough left");

        for (uint256 i = 0; i < amount; i++) {
            mint(receiver);
        }
        payable(msg.sender).transfer(msg.value);
    }

    function sessionId() public view returns (uint256) {
        return 10000 - _tokenIdTracker.current();
    }

    function mint(address to) internal returns (uint256) {
        _tokenIdTracker.increment();
        _mint(to, _tokenIdTracker.current());
        return _tokenIdTracker.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}
