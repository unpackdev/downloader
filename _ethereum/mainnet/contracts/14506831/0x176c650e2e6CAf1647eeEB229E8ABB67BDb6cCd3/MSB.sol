
// SPDX-License-Identifier: MIT

 //////////////////////////////////////////////////////////////////////
 //                                                                  //
 //    /////////////////// ///////////////////  /////////////////    //
 //  //   ____    ____   //      _______     //     ______      //   //
 //  //  |_   \  /   _|  //     /  ___  |    //    |_   _ \     //   //
 //  //    |   \/   |    //    |  (__ \_|    //      | |_) |    //   //
 //  //    | |\  /| |    //      /___ //     //      |  __ /    //   //
 //  //   _| |_\/_| |_   //    | \____) |    //     _| |__) |   //   //
 //  //  |_____||_____|  //    |_______/     //    |_______/    //   //
 //  //                  //                  //                 //   //
 //   /////////////////// /////////////////// //////////////////     //
 //     ==== META ====      ==== SPACE ====    ==== BABIES ====      //
 //                                                                  //
 //                  Smart Contract by: qazipolo.eth                 //
 //////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.4;
pragma abicoder v2;

import "./ERC721A.sol"; // ERC721A standard by Azuki (Chiru Labs)
import "./Ownable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

contract MSB is ERC721A, Ownable  {
    using SafeMath for uint256;
    bytes32 public merkleRoot;
    uint256 constant public MAX_SUPPLY= 10000;
    uint256 constant public WL_PRICE = 0.08 ether;
    uint256 constant public PRICE = 0.1 ether;
    uint256 constant public NAME_CHANGE_PRICE = 0.02 ether;
    uint256 public giveawayLimit = 100;
    string public baseTokenURI;
    bool public whitelistSaleIsActive;
    bool public saleIsActive;
    mapping(uint256 => string) public tokenName;    
    address public ownerWallet = 0x7DdF7e9AF7aA9325A15c3bd36749339e26f7dcb4;

    uint256 private nameLimit;
    mapping(uint256 => bool) nameInitialized;

    constructor() ERC721A("MetaSpaceBabies", "MSB") { }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipWhitelistSaleState() external onlyOwner {
        whitelistSaleIsActive = !whitelistSaleIsActive;
    }  

    function updateMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setNameLimit(uint256 limit) external onlyOwner {
        nameLimit = limit;
    }

    function whitelistMint(uint256 numberOfTokens, bytes32[] calldata merkleProof ) payable external callerIsUser {
        require(whitelistSaleIsActive, "Whitelist Sale must be active to mint");
        require(totalSupply().add(numberOfTokens) <= MAX_SUPPLY, "Total Supply has been minted");
        require(numberOfTokens > 0 && numberOfTokens <= 10, "Can only mint upto 10 NFTs in a transaction");
        require(msg.value == WL_PRICE.mul(numberOfTokens), "Ether value sent is not correct");
        require(numberMinted(msg.sender).add(numberOfTokens) <= 10,"Max 10 mints allowed per whitelisted wallet");

        // Verify the merkle proof
        require(MerkleProof.verify(merkleProof, merkleRoot,  keccak256(abi.encodePacked(msg.sender))  ), "Invalid proof");
		
		_safeMint(msg.sender, numberOfTokens);
    }

    function mint(uint256 numberOfTokens) external payable callerIsUser {
        require(saleIsActive, "Sale must be active to mint");
        require(totalSupply().add(numberOfTokens) <= MAX_SUPPLY, "Total Supply has been minted");
        require(msg.value == PRICE.mul(numberOfTokens), "Ether value sent is not correct");
        require(numberMinted(msg.sender).add(numberOfTokens) <= 10,"Max 10 mints allowed per wallet");

        _safeMint(msg.sender, numberOfTokens);
    }

    function withdrawAll() external onlyOwner {
        (bool success, ) = ownerWallet.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setName(uint256 tokenId, string memory newName) public {
        require(msg.sender == ownerOf(tokenId),"Caller is not the owner of NFT");
        require(tokenId < nameLimit,"Token Id is not eligible");
        require(!nameInitialized[tokenId],"Name has already been set once");
        require(bytes(newName).length > 0 && bytes(newName).length <= 50,"Name exceeds allowed character limit");
        tokenName[tokenId] = newName;
        nameInitialized[tokenId] = true;
    }

    function changeName(uint256 tokenId, string memory newName) public payable {
        require(msg.sender == ownerOf(tokenId),"Caller is not the owner of NFT");
        require(msg.value == NAME_CHANGE_PRICE,"Incorrect Price sent for name change");
        require(bytes(newName).length > 0 && bytes(newName).length <= 50,"Name exceeds allowed character limit");
        tokenName[tokenId] = newName;
    }

    function giveAway(uint256 numberOfTokens, address to) external onlyOwner {
        require(giveawayLimit.sub(numberOfTokens) >= 0,"Giveaways exhausted");
        _safeMint(to, numberOfTokens);
        giveawayLimit = giveawayLimit.sub(numberOfTokens);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

} 