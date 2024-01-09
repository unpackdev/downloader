// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "SafeMath.sol";
import "Strings.sol";
import "ERC721MadFaces.sol";
import "AbstractKeys.sol";

/*
                                        Authors: madjin.eth
                                            year: 2021

                ███╗░░░███╗░█████╗░██████╗░███████╗░█████╗░░█████╗░███████╗░██████╗
                ████╗░████║██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝
                ██╔████╔██║███████║██║░░██║█████╗░░███████║██║░░╚═╝█████╗░░╚█████╗░
                ██║╚██╔╝██║██╔══██║██║░░██║██╔══╝░░██╔══██║██║░░██╗██╔══╝░░░╚═══██╗
                ██║░╚═╝░██║██║░░██║██████╔╝██║░░░░░██║░░██║╚█████╔╝███████╗██████╔╝
                ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚══════╝╚═════╝░

*/


contract Part is ERC721MadFaces {

    using Strings for uint256;

    uint256 public constant ACCESS_KEY_ID = 42;
    uint256 public constant TOKEN_PRICE = 0.04 ether;

    uint256 public constant TOKEN_TEAM_AMOUNT = 100;
    uint256 public constant TOKEN_PRIVATE_AMOUNT = 200;
    uint256 public constant TOKEN_PUBLIC_AMOUNT = 2033;
    uint256 public constant TOKEN_PRESALE_AMOUNT = 1000;

    string public constant PROVENANCE_HASH = '19d75e909e2051e4481e0652953a47132e03564ddd9b6776e63cc780b30b3f81';

    uint256 public tokenTeamMinted = 0;
    uint256 public tokenPublicMinted = 0;
    uint256 public tokenPresaleMinted = 0;
    uint256 public tokenPrivateMinted = 0;

    uint256 public maxTokenQtyPerMint = 5;
    uint256 public startingIndexTokenId = 0;
    address public madFaceAddress = address(0);
    mapping(address => bool) public privateSaleEntries;

    bool public preSale = false;
    bool public publicSale = false;

    string private _currentBaseURI;

    address public share1Address = 0x99101107c8e55EA7C5EC7fc42363E8bD2B1C24fD;
    address public share2Address = 0x2F6EC9067B43F38fcECe1CA17DF22cbf95b99749;
    address public share3Address = 0xF3e076B27e72A7EdBd469cD106F3a29943FAC60d;
    address public share4Address = 0xFF31c66168d8a3c248193208790546DC14E09123;

    CKeys private immutable keys;

    constructor(string memory name, string memory symbol, address keysAddress) ERC721(name, symbol) {
        keys = CKeys(keysAddress);
    }

    modifier onlyMadFace() {
        require(_msgSender() == madFaceAddress, 'Only MadFace contract is granted');
        _;
    }

    function setPublicSale() public onlyOwner {
        publicSale = true;
    }

    function setPreSale() public onlyOwner {
        preSale = true;
    }

    function setMaxTokenQtyPerMint(uint256 maxTokenQtyPerMint_) external onlyOwner {
        maxTokenQtyPerMint = maxTokenQtyPerMint_;
    }

    function setMadFaceAddress(address madFaceAddress_) public onlyOwner not_locked {
        madFaceAddress = madFaceAddress_;
    }

    function setStartingIndexTokenId() public onlyOwner {
        require(startingIndexTokenId == 0, "startingIndexTokenId already set");
        startingIndexTokenId = uint256(
            keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1)))
        ) % MAX_SUPPLY;
    }

    function setToPrivateSale(address[] calldata entries) external onlyOwner {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            privateSaleEntries[entry] = true;
        }
    }

    function removeFromPrivateSale(address[] calldata entries) external onlyOwner {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            privateSaleEntries[entry] = false;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        tokenId = (startingIndexTokenId + tokenId) % MAX_SUPPLY;

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function totalTokenMinted() public view virtual returns (uint256) {
        return tokenTeamMinted + tokenPublicMinted + tokenPresaleMinted + tokenPrivateMinted;
    }

    // Call by MadFace Contract only
    function burn(uint256 tokenId, address sender) public onlyMadFace {
        require(ownerOf(tokenId) == sender, "Must own the part to burn it");
        _burn(tokenId);
    }

    // Call by MadFace Contract only
    function mint(uint256 tokenId, address sender) public onlyMadFace {
        require(totalSupply() + 1 <= MAX_SUPPLY, "Purchase would exceed max supply");
        _safeMint(sender, tokenId);
    }

    function mintPart(
        uint256 tokenQty,
        bytes32 hash,
        bytes memory signature,
        string memory nonce
    ) public validHash(hash, signature, nonce, tokenQty) payable nonReentrant {
        require(publicSale, 'Public sale has not started yet');
        require(tokenQty <= maxTokenQtyPerMint, "Exceed Max quantity per mint");
        require(TOKEN_PRICE * tokenQty <= msg.value, "Ether value sent is not correct");
        require(tokenPublicMinted + tokenQty <= TOKEN_PUBLIC_AMOUNT, "Purchase would exceed allocation for public sale");

        for (uint256 i = 0; i < tokenQty; i++) {
            _safeMint(_msgSender(), totalTokenMinted());
            tokenPublicMinted += 1;
        }
    }

    function mintPartPreSale(
        bytes32 hash,
        bytes memory signature,
        string memory nonce
    ) public validHash(hash, signature, nonce, 1) payable nonReentrant {
        require(preSale, 'Pre sale has not started yet');
        require(TOKEN_PRICE <= msg.value, "Ether value sent is not correct");
        require(tokenPresaleMinted + 1 <= TOKEN_PRESALE_AMOUNT, "Purchase would exceed allocation to mint with key");
        require(keys.balanceOf(_msgSender(), ACCESS_KEY_ID) > 0, "Must own a key to pretend mint on pre-sale");

        _safeMint(_msgSender(), totalTokenMinted());
        tokenPresaleMinted += 1;
        keys.burnKey(_msgSender(), ACCESS_KEY_ID);
    }

    function mintPartPrivateSale(uint256 tokenQty) public payable nonReentrant {
        require(privateSaleEntries[_msgSender()], "Must be on the whitelist to pretend mint on private sale");
        require(tokenQty <= maxTokenQtyPerMint, "Exceed Max quantity per mint");
        require(TOKEN_PRICE * tokenQty <= msg.value, "Ether value sent is not correct");
        require(tokenPrivateMinted + tokenQty <= TOKEN_PRIVATE_AMOUNT, "Purchase would exceed allocation for private sale");

        for (uint256 i = 0; i < tokenQty; i++) {
            _safeMint(_msgSender(), totalTokenMinted());
            tokenPrivateMinted += 1;
        }
        privateSaleEntries[_msgSender()] = false;
    }

    function mintBatchForTeam(uint256 tokenQty) public nonReentrant onlyOwner {
        require(tokenTeamMinted + tokenQty <= TOKEN_TEAM_AMOUNT, "Purchase would exceed allocation for team sale");

        for (uint256 i = 0; i < tokenQty; i++) {
            _safeMint(_msgSender(), totalTokenMinted());
            tokenTeamMinted += 1;
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 shareOwner = balance * 45 / 100;
        uint256 shareWSOMF = balance * 8 / 100;
        uint256 shareCharity = balance * 2 / 100;
        payable(share1Address).transfer(shareOwner);
        payable(share2Address).transfer(shareOwner);
        payable(share3Address).transfer(shareWSOMF);
        payable(share4Address).transfer(shareCharity);
    }
}
