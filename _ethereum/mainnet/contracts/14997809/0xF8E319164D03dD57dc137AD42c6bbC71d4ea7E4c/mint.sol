// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract YeahTigersEth is ERC721A, Ownable, ReentrancyGuard {

    uint8 public paused = 0;

    string public baseURI;
    uint256 public mintLimit;
    uint256 public freeMintCount;

    uint256 public immutable cost;
    uint256 public immutable maxSupply;

    mapping(address => uint256[]) public mintTokenIdsMap;

    constructor(
        string memory baseURI_,
        uint256 mintLimit_,
        uint256 freeMintCount_,
        uint256 cost_,
        uint256 maxSupply_,
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) {
        cost = cost_;
        maxSupply = maxSupply_;
        mintLimit = mintLimit_;
        freeMintCount = freeMintCount_;
        baseURI = baseURI_;
    }

    function setPaused(uint8 paused_) public onlyOwner {
        paused = paused_;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setMintLimit(uint256 mintLimit_) public onlyOwner {
        mintLimit = mintLimit_;
    }

    function setFreeMintCount(uint256 freeMintCount_) public onlyOwner {
        freeMintCount = freeMintCount_;
    }

    function getCost() public view returns (uint256) {
        if (totalSupply() < freeMintCount) {
            return 0;
        }
        return cost;
    }

    function checkPaused() public view {
        require(paused != 1, 'The contract is paused!');
    }

    function getTokenIds(address msgSender) public view returns (uint256[] memory _tokenIds) {
        _tokenIds = mintTokenIdsMap[msgSender];
    }

    function mint() external payable {
        address msgSender = _msgSender();

        require(tx.origin == msgSender, 'Only EOA');
        require(msg.value >= getCost(), 'Insufficient funds!');
        require(mintTokenIdsMap[msgSender].length < mintLimit, 'Max mints per wallet met');
        checkPaused();

        _doMint(msgSender);
        mintTokenIdsMap[msgSender].push(totalSupply() - 1);
    }

    function _doMint(address to) private {
        require(totalSupply() < maxSupply, 'Max supply exceeded!');
        require(to != address(0), 'Cannot have a non-address as reserve.');
        _safeMint(to, 1);
    }

    function airdrop(address[] memory mintAddresses) public onlyOwner {
        for (uint i; i < mintAddresses.length; i++) {
            _doMint(mintAddresses[i]);
        }
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }
}
