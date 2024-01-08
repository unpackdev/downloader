// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

/*
                                                            
  .g8"""bgd MMM"""AMV `7MM"""YMM    .g8"""bgd `7MMF'  `7MMF'
.dP'     `M M'   AMV    MM    `7  .dP'     `M   MM      MM  
dM'       ` '   AMV     MM   d    dM'       `   MM      MM  
MM             AMV      MMmmMM    MM            MMmmmmmmMM  
MM.           AMV   ,   MM   Y  , MM.           MM      MM  
`Mb.     ,'  AMV   ,M   MM     ,M `Mb.     ,'   MM      MM  
  `"bmmmd'  AMVmmmmMM .JMMmmmmMMM   `"bmmmd'  .JMML.  .JMML.
                                                            
                                                            
`7MM"""Mq.`7MMF'   `7MF'`7MN.   `7MF'`7MMF' `YMM'  .M"""bgd 
  MM   `MM. MM       M    MMN.    M    MM   .M'   ,MI    "Y 
  MM   ,M9  MM       M    M YMb   M    MM .d"     `MMb.     
  MMmmdM9   MM       M    M  `MN. M    MMMMM.       `YMMNq. 
  MM        MM       M    M   `MM.M    MM  VMA    .     `MM 
  MM        YM.     ,M    M     YMM    MM   `MM.  Mb     dM 
.JMML.       `bmmmmd"'  .JML.    YM  .JMML.   MMb.P"Ybmmd"  
                                                            
 */

contract CzechPunks is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    string private _baseURIextended;
    string public PROVENANCE;
    string public contractURI;

    bool public isSaleActive = false;
    bool public isWhitelistSaleActive = false;

    uint8 public constant MAX_SUPPLY = 103;
    uint8 public constant MAX_PUBLIC_MINT = 3;
    uint256 public constant PRICE_PER_TOKEN = 0.103 ether;

    mapping(address => uint8) private _whitelist;

    address private constant POLIS_SK_ADDRESS = 0xC0e842bA82c16ef9E1c5890A9696fF2FA72BEc07; // Paralelná Polis SK
    address private constant POLIS_CZ_ADDRESS = 0x42105F249681ff262D6aB723bf19Bc854656E619; // Paralelní Polis CZ
    address private constant KRYPTO_VLADA_ADDRESS = 0x64e5624790084F8Fb0e0cdF3e400828F2b68eAE3; // KryptoVláďa
    address private constant GWEI_CZ_ADDRESS = 0x6c171579f8F3c3F65B30286b14C20a46a4eb55b9; // Gwei.cz

    constructor() ERC721('CzechPunks', 'CZECHPUNKS') {}

    // whitelist mint
    function setIsWhitelistSaleActive(bool isActive) external onlyOwner {
        isWhitelistSaleActive = isActive;
    }

    function setWhitelistAddresses(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint8 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = numAllowedToMint;
        }
    }

    function whitelistMintAmount(address addr) external view returns (uint8) {
        return _whitelist[addr];
    }

    function mintWhitelisted(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isWhitelistSaleActive, 'Whitelist sale is not active');
        require(numberOfTokens <= _whitelist[msg.sender], 'Exceeded max available to purchase');
        require(ts + numberOfTokens <= MAX_SUPPLY, 'Purchase would exceed max tokens');
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, 'Ether value sent is not correct');

        _whitelist[msg.sender] -= numberOfTokens;
        for (uint8 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    // override base functions
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function setContractURI(string memory contractUri_) external onlyOwner {
        contractURI = contractUri_;
    }

    // public mint
    function setIsSaleActive(bool isActive) public onlyOwner {
        isSaleActive = isActive;
    }

    function mint(uint8 numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(isSaleActive, 'Sale must be active to mint tokens');
        require(numberOfTokens <= MAX_PUBLIC_MINT, 'Exceeded max token purchase');
        require(ts + numberOfTokens <= MAX_SUPPLY, 'Purchase would exceed max tokens');
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, 'Ether value sent is not correct');

        for (uint8 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }

        if((ts + numberOfTokens) == MAX_SUPPLY) {
            _withdrawSplitter();
        }
    }

    // withdraw functions
    function withdrawAll() public onlyOwner {
        _withdrawSplitter();
    }

    function _withdrawSplitter() private {
        uint256 balance = address(this).balance;
        require(balance > 0, 'Contract balance must be > 0');

        uint256 cut = balance.mul(20).div(100);

        _widthdraw(POLIS_SK_ADDRESS, cut);
        _widthdraw(POLIS_CZ_ADDRESS, cut);
        _widthdraw(KRYPTO_VLADA_ADDRESS, cut);
        _widthdraw(GWEI_CZ_ADDRESS, cut);
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        require(address(this).balance >= _amount, 'Contract balance must be >= _amount');
        (bool success, ) = _address.call{value: _amount}('');
        require(success, 'Transfer failed.');
    }
}
