//
//
//
/////////////////////////////////////////////////////////////////
//                                                             //
//       ██████  ███████ ███    ██ ███    ██ ██ ███████        //
//       ██   ██ ██      ████   ██ ████   ██ ██ ██             //
//       ██   ██ █████   ██ ██  ██ ██ ██  ██ ██ ███████        //
//       ██   ██ ██      ██  ██ ██ ██  ██ ██ ██      ██        //
//       ██████  ███████ ██   ████ ██   ████ ██ ███████        //
//                                                             //
// ███████  ██████ ██   ██ ███    ███ ███████ ██      ███████  //
// ██      ██      ██   ██ ████  ████ ██      ██         ███   //
// ███████ ██      ███████ ██ ████ ██ █████   ██        ███    //
//      ██ ██      ██   ██ ██  ██  ██ ██      ██       ███     //
// ███████  ██████ ██   ██ ██      ██ ███████ ███████ ███████  //
//                                                             //
/////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155PresetMinterPauser.sol";
import "./MerkleProof.sol";

contract EditionsByDennisSchmelzMinterMaxSupply is Ownable {
    address public editionsByDennisSchmelz = 0x3820e79dEb5E60F6f488fA2A62C8e190CC69BB47;

    uint256 public mintTokenId = 4;

    uint256 public mintTokenPriceHolders = 0.169 ether;
    uint256 public mintTokenPrice = 0.169 ether;

    bool public isPublicMintEnabled = true;
    bool public isWhitelistMintEnabled = true;

    uint256 public maxSupply = 69;
    uint256 public currentSupply = 0;

    bytes32 public root = 0x232450d8a4fb5d9e42138c429c6be5b0a6154662cb284556acb6c8b6f26c9545;

    constructor() {}

    function mintHolder(uint256 amount, bytes32[] calldata proof) public payable{
        require(isWhitelistMintEnabled, "Mint not enabled");
        require(currentSupply < maxSupply, "Max supply reached");
        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender))), "Invalid merkle proof");
        require(msg.value >= mintTokenPriceHolders * amount, "Not enough eth");

        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(editionsByDennisSchmelz);
        token.mint(msg.sender, mintTokenId, amount, "");
        
        currentSupply += amount;
    }

    function mint(uint256 amount) public payable {
        require(isPublicMintEnabled, "Mint not enabled");
        require(currentSupply < maxSupply, "Max supply reached");
        require(amount >= 1, "Amount must be >= 1");
        require(msg.value >= mintTokenPrice * amount, "Not enough eth");
        
        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(editionsByDennisSchmelz);
        token.mint(msg.sender, mintTokenId, amount, "");

        currentSupply += amount;
    }

    function setMaxSupply(uint256 max) public onlyOwner {
        maxSupply = max;
    }

    function setCurrentSupply(uint256 current) public onlyOwner {
        currentSupply = current;
    }

    function setIsPublicMintEnabled(bool isEnabled) public onlyOwner {
        isPublicMintEnabled = isEnabled;
    }

    function setIsWhitelistMintEnabled(bool isEnabled) public onlyOwner {
        isWhitelistMintEnabled = isEnabled;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setEditionsByDennisSchmelzAddress(address newAddress) public onlyOwner {
        editionsByDennisSchmelz = newAddress;
    }

    function setMintTokenId(uint256 tokenId) public onlyOwner {
        mintTokenId = tokenId;
    }

    function setMintTokenPrice(uint256 tokenPrice) public onlyOwner {
        mintTokenPrice = tokenPrice;
    }

    function setMintTokenPriceHolders(uint256 tokenPrice) public onlyOwner {
        mintTokenPriceHolders = tokenPrice;
    }

    function setRoot(bytes32 newroot) public onlyOwner {root = newroot;}
}