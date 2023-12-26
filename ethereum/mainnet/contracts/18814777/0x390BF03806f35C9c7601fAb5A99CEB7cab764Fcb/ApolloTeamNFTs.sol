//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

contract ApolloTeamNFTs is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    // The max number of NFTs in the collection
    uint public constant MAX_SUPPLY = 389;
    uint public constant MAX_PER_MINT = 10;
    uint256 public lastSupply = MAX_SUPPLY;
    // The mint price for the collection
    uint public constant PRICE = 0.1 ether;
    // The max number of mints per wallet
    uint256[389] public remainingIds;

    address public devWallet;
    string public baseTokenURI;

    constructor(
        address _devWallet
    ) ERC721("ApolloTeamNFTs", "ADEVS") Ownable() {
        setBaseURI("https://eastedgestudios.github.io/ApolloNFTs/metadata/");
        devWallet = _devWallet;
        transferOwnership(devWallet);
        for (uint256 i; i < 33; i++) {
            _regularMint(devWallet);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string.concat(
                    string.concat(baseURI, Strings.toString(tokenId)),
                    ".json"
                )
                : "";
    }

    function mint(address _to, uint256 _mintAmount) public payable {
        require(lastSupply >= _mintAmount, "Mint exceeds the max supply");
        require(_mintAmount > 0, "You have to mint at least one");
        require(_mintAmount <= MAX_PER_MINT, "You can only mint 10 at a time");
        require(msg.value >= PRICE * _mintAmount, "Cost Doesnt Match");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _randomMint(_to);
        }
    }

    // Random mint
    function _randomMint(address _target) internal returns (uint256) {
        // Get Random id to mint
        uint256 _index = _getRandom() % lastSupply;
        uint256 _realIndex = getValue(_index) + 1;
        // Reduce supply
        lastSupply--;
        // Replace used id by last
        remainingIds[_index] = getValue(lastSupply);
        // Mint
        _safeMint(_target, _realIndex);
        return _realIndex;
    }

    // Mint for reserved spots
    function _regularMint(address _target) internal returns (uint256) {
        // Get Actual id to mint
        uint256 _index = totalSupply();
        uint256 _realIndex = getValue(_index) + 1;
        // Reduce supply
        lastSupply--;
        // Replace used id by last
        remainingIds[_index] = getValue(lastSupply);
        // Mint
        _safeMint(_target, _realIndex);
        return _realIndex;
    }

    // Get value from a remaining id node
    function getValue(uint256 _index) internal view returns (uint256) {
        if (remainingIds[_index] != 0) return remainingIds[_index];
        else return _index;
    }

    // Create a random id for minting
    function _getRandom() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        lastSupply
                    )
                )
            );
    }

    // Withdraw the ether in the contract
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        bool success = payable(owner()).send(balance);
        require(success, "Transfer failed");
    }
}
