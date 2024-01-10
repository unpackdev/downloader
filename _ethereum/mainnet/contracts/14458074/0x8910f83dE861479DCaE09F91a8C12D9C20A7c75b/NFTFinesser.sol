// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

/// @author @txorigin

import "./Ownable.sol";
import "./ERC721A.sol";

/* 
==========================================================================================
==========================================================================================
=====================================---:::::::::::--=====================================
===============================-:.                      .::-==============================
===========================:.                                .:-==========================
=======================-.           ...:::------:::::..          .:-======================
=====================:         ..:---------------========-:         .-====================
==================:.       .:-=--:=-:::--=-----------======---:        :==================
================:       :-=====--:===---:.::....:::--------------.       .-===============
==============-       .----====---==-:                .:===========-.      :==============
=============:      :==========--::                      .:-=========:.     .-============
===========-      :=========-==:                            :====-==----      .===========
==========:      -========--==.                               ====---====:     .==========
=========:     .========-====                                 .=--===-==-=:     .=========
========-     .----====-====                                   .=--========-     .========
========     .===--=-=--===:                                    -=---------=-     .=======
======+.     ===--+=--=====                                      ==========-=-     -======
=====+:     ----==--=======                                      :------------.     ======
======     :====-=========:                                      -=============     :=====
=====:     ====-========+=-                                      -==-==========.     =====
====+.    .==-=+=====-====- -====-:.      ..::---===--.          :=============:     =====
====+.    .==-============  -======+-   .==========+++:          .----------===-     -====
====+     :==-+=======-+==   :=====:      :========+=:            ==---------:==     -====
====+.    :==-++==-=-=+===                  ..::::.               =-=====-=----:     -====
====+.    .==+==-===+==+=..                                      .===-===-===--:     =====
=====:     =+===-=+++==:.==                                      =====:==--====.     =====
======     :-=-=++++=:.=+=+.                                   :=:====:====-===     :=====
=====+:     -=++++=:.=+++++:        .-===:                    -==:====-=--===-:     ======
======+.    .+++=:.=+++++=--        ======-                 .====:=====----==-     :======
=======-     :+:.=+++++=-==+:      .+=====+                 ::::-:-=======---     .=======
=======+:      =+++++=-==++++.      =+++++=                :-===---:-======-     .========
========+:     .++==-==++.:+-:.      :---:                 =======--:=--==-     .=========
=========+:     .=-==+++=======.                           --======-:=--::     .==========
==========+:      -+++==-======-                           ==-=====-:===.     .===========
++=========+=:     .:===+-=====-                           -=======-:-.     .-============
+++==========+-       -++--++++.                           .======::       :==============
++++++==========:      .:-=++=.                             .-===:.      .-===============
++++++++==========:.       :.                                 ..       .-=================
+++++++++==========+-.                                              .:====================
++++++++++++=========+=-.                                        .:-======================
+++++++++++++++=========+=-:..   .....   ..... ...  ..  . .. .:-==========================
++++++++++++++++===============-:..                     .::-==============================
+++++++++++++++++====================---:::::::::::---====================================
+++++++++++++++++++=======================================================================
++++++++++++++++++++++====================================================================
*/

contract NFTFinesser is Ownable, ERC721A {
    uint256 public maxSupply    = 300;
    uint256 public tokenPrice   = 1000000000000000000; // 1 Ether
    uint256 public renewalPrice = 420690000000000000;  // 0.42069 Ether
    bool    public saleIsActive = false;

    mapping(uint256 => uint256) public expiryTime;

    constructor() ERC721A("NFT Finesser", "FNSR") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller cannot be a contract");
        _;
    }

    /// reference: 0xc47e04308a2cBc59778e1dc2E182546C98CD5cbb
    /// @notice airdrop tokens to already paying users
    function airdropToMembers(
        address[] calldata _addresses,
        uint256[] calldata _expiries
    ) public onlyOwner {
        uint256 quantity = _addresses.length;
        require(
            quantity == _expiries.length,
            "Arrays length not matching."
        );
        require(
            maxSupply >= totalSupply() + quantity,
            "Airdropped tokens would exceed max supply."
        );
        for (uint256 i=0; i<quantity;) {
            _safeMint(_addresses[i], 1);
            if (_expiries[i] != 0) {
                expiryTime[_currentIndex-1] = _expiries[i];
            }
            unchecked{ i++; }
        }
    }

    function mint() external payable callerIsUser {
        require(saleIsActive, "Sale must be active.");
        require(tokenPrice <= msg.value, "Not enough Ethereum sent.");
        require(maxSupply >= totalSupply() + 1, "Max supply has been reached.");
        _safeMint(msg.sender, 1);
        expiryTime[_currentIndex-1] = block.timestamp + 30 days;
    }

    function ownerMint(address _receiver) public onlyOwner {
        _safeMint(_receiver, 1);
        expiryTime[_currentIndex-1] = block.timestamp + 30 days;
    }

    function ownerBatchMint(address[] calldata _receivers) public onlyOwner {
        uint256 quantity = _receivers.length;
        require(
            maxSupply >= totalSupply() + quantity,
            "Minted tokens would exceed max supply."
        );
        for (uint256 i=0; i<quantity;) {
            _safeMint(_receivers[i], 1);
            expiryTime[_currentIndex-1] = block.timestamp + 30 days;
            unchecked{ i++; }
        }
    }

    /// @notice extends/renews a token expiry date.
    /// @param tokenId the token id to extend/renew.
    function renewToken(uint256 tokenId) public payable {
        require(_exists(tokenId), "Token doesn't exist.");
        require(renewalPrice <= msg.value, "Not enough Ethereum sent.");
        uint256 _currentExpiryTime = expiryTime[tokenId];
        if (block.timestamp > _currentExpiryTime) {
            expiryTime[tokenId] = block.timestamp + 30 days;
        } else {
            expiryTime[tokenId] += 30 days;
        }
    }

    function ownerRenewToken(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "Token doesn't exist.");
        uint256 _currentExpiryTime = expiryTime[tokenId];
        if (block.timestamp > _currentExpiryTime) {
            expiryTime[tokenId] = block.timestamp + 30 days;
        } else {
            expiryTime[tokenId] += 30 days;
        }
    }

    function ownerBatchRenewTokens(uint256[] calldata tokenIds) public onlyOwner {
        uint256 quantity = tokenIds.length;
        require(quantity >= 2, "Invalid array length.");
        for (uint256 i=0; i<quantity;) {
            require(_exists(tokenIds[i]), "Token doesn't exist.");
            uint256 _currentExpiryTime = expiryTime[tokenIds[i]];
            if (block.timestamp > _currentExpiryTime) {
                expiryTime[tokenIds[i]] = block.timestamp + 30 days;
            } else {
                expiryTime[tokenIds[i]] += 30 days;
            }
            unchecked{ i++; }
        }
    }

    /// @notice overrides a token expiry date.
    function ownerSetTokenExpiry(uint256 tokenId, uint8 _days) public onlyOwner {
        require(_exists(tokenId), "Token doesn't exist.");
        expiryTime[tokenId] = block.timestamp + _days * 1 days;
    }

    /// @notice increments the `maxSupply` value.
    function addTokens(uint256 numTokens) external onlyOwner {
        maxSupply += numTokens;
    }
    
    /// @notice decrements the `maxSupply` value.
    function removeTokens(uint256 numTokens) external onlyOwner {
        require(
            maxSupply - numTokens >= totalSupply(), 
            "Supply cannot fall below minted tokens."
        );
        maxSupply -= numTokens;
    }

    /// @notice updates the `renewalPrice` value.
    function updateRenewalPrice(uint256 _renewalPrice) external onlyOwner {
        renewalPrice = _renewalPrice;
    }

    /// @notice updates the `tokenPrice` value.
    function updateTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }

    /// @notice flips the public sale status.
    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function authenticateUser(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Token doesn't exist.");
        require(
            expiryTime[tokenId] > block.timestamp,
            "Token has expired. Must renew to authenticate!"
        );
        return msg.sender == ownerOf(tokenId) ? true : false;
    }

    function checkTokenExpiry(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token doesn't exist.");
        return expiryTime[tokenId];
    }

    /// metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawBalance() public onlyOwner {
		(bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
	}

    /// @notice safely transfer a token from one owner to another.
    /// token must not be expired.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        if (owner() != msg.sender) {
            require(
                expiryTime[tokenId] > block.timestamp,
                "Cannot transfer an expired Token."
            );
        }
        _transfer(from, to, tokenId);
        if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /// @notice transfer a token from one owner to another.
    /// token must not be expired.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        if (owner() != msg.sender) {
            require(
                expiryTime[tokenId] > block.timestamp, 
                "Cannot transfer an expired Token."
            );
        }
        _transfer(from, to, tokenId);
    }
}