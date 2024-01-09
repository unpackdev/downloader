// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract Genesis is ERC721URIStorage, Ownable {
    uint256 public tokenCounter;
    bool public isMintOpen = false;
    mapping(address => bool) private whiteList;
    mapping(address => bool) private addressToIsMinted;
    uint256 public constant mintPrice = 0.095 ether;
    uint256 public constant maxSupply = 111;
    string public tokenURI =
        'https://ipfs.io/ipfs/QmVGdTTCPRW5MZVDoCT2ykdS7mHAWbMMr9GHZ1F9QWbry7?filename=genesis.json';

    constructor() ERC721('TheMintPass V1 Genesis', 'TMPG') {
        tokenCounter = 1;
    }

    function openMint(bool _isMintOpen) external onlyOwner {
        isMintOpen = _isMintOpen;
    }

    function setWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whiteList[addresses[i]] = true;
        }
    }

    function createToken() external payable {
        require(isMintOpen, 'Mint is not open.');
        require(whiteList[msg.sender], 'This address is not in the whitelist.');
        require(
            addressToIsMinted[msg.sender] == false,
            'This address has already mint the token.'
        );
        require(
            tokenCounter <= maxSupply,
            'All token have already been minted.'
        );
        require(msg.value >= mintPrice, 'Ether value send is not correct.');

        uint256 newTokenId = tokenCounter;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        tokenCounter++;
        addressToIsMinted[msg.sender] = true;
    }

    function tokenNotMinted() public onlyOwner {
        uint256 supply = maxSupply - tokenCounter;
        for (uint256 i = 0; i <= supply; i++) {
            _safeMint(msg.sender, tokenCounter);
            _setTokenURI(tokenCounter, tokenURI);
            tokenCounter++;
        }
    }

    function totalSupply() public view returns (uint256) {
        return tokenCounter - 1;
    }

    function isWhiteList(address value) public view returns (bool) {
        return whiteList[value];
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Transfer failed.');
    }
}
