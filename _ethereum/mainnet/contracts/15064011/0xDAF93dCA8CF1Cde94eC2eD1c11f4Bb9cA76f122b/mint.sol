// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Prayer is ERC721A, Ownable, ReentrancyGuard {

    uint256 public maxSupply = 3999;

    uint8 public paused = 1;

    string public baseURI = 'https://static-resource.buddhanft.xyz/metadata/';
    uint256 public freeMintQuantity = 1;
    uint256 public mintLimit = 2;
    uint256 public cost = 500000000000000; // 0.0005
    mapping(address => bool) public whitelistMap;

    mapping(address => uint256[]) public mintTokenIdsMap;

    constructor(uint8 paused_) ERC721A('Prayer', 'Prayer') {
        paused = paused_;
    }

    function updateMaxSupply(uint8 maxSupply_) public onlyOwner {
        maxSupply = maxSupply_;
    }

    function updatePaused(uint8 paused_) public onlyOwner {
        paused = paused_;
    }

    function updateBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function updateFreeMintQuantity(uint256 freeMintQuantity_) public onlyOwner {
        freeMintQuantity = freeMintQuantity_;
    }

    function updateMintLimit(uint256 mintLimit_) public onlyOwner {
        mintLimit = mintLimit_;
    }

    function updateCost(uint256 cost_) public onlyOwner {
        cost = cost_;
    }

    function updateWhitelistMap(address[] memory addAddrs, address[] memory delAddrs) public onlyOwner {
        for (uint i; i < addAddrs.length; i++) {
            whitelistMap[addAddrs[i]] = true;
        }

        for (uint i; i < delAddrs.length; i++) {
            whitelistMap[delAddrs[i]] = false;
        }
    }

    function getCost(address msgSender) public view returns (uint256) {
        if (whitelistMap[msgSender]) {
            return 0;
        }
        return cost;
    }

    function calculateCost(address msgSender, uint256 quantity) public view returns (uint256) {
        if (freeMintQuantity > mintTokenIdsMap[msgSender].length) {
            uint256 remainFreeMintQuantity = freeMintQuantity - mintTokenIdsMap[msgSender].length;
            if (remainFreeMintQuantity >= quantity) {
                return 0;
            } else {
                return (quantity - remainFreeMintQuantity) * getCost(msgSender);
            }
        } else {
            return quantity * getCost(msgSender);
        }
    }

    function checkPaused() public view {
        require(paused != 1, 'The contract is paused!');
    }

    function getTokenIds(address msgSender) public view returns (uint256[] memory _tokenIds) {
        _tokenIds = mintTokenIdsMap[msgSender];
    }

    function mint(uint256 quantity) external payable {
        address msgSender = _msgSender();

        checkPaused();
        require(quantity > 0, 'Invalid quantity!');
        require(tx.origin == msgSender, 'Only EOA');
        require(msg.value >= calculateCost(msgSender, quantity), 'Insufficient funds!');
        require(mintTokenIdsMap[msgSender].length + quantity <= mintLimit, 'Max mints per wallet met');

        _doMint(msgSender, quantity);
        for (uint i; i < quantity; i++) {
            mintTokenIdsMap[msgSender].push(totalSupply() - quantity + i);
        }
    }

    function airdrop(address[] memory mintAddresses, uint256[] memory mintCounts) public onlyOwner {
        for (uint i; i < mintAddresses.length; i++) {
            _doMint(mintAddresses[i], mintCounts[i]);
        }
    }

    function _doMint(address to, uint256 quantity) private {
        require(totalSupply() + quantity <= maxSupply, 'Max supply exceeded!');
        require(to != address(0), 'Cannot have a non-address as reserve.');
        _safeMint(to, quantity);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os,) = payable(owner()).call{value : address(this).balance}('');
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
