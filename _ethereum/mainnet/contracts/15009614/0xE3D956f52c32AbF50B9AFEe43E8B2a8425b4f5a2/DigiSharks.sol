// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Context.sol";

/**
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@/,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@..................,(@@@@@@@@&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,#@@@................................@@@@@@(,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,*@@..........................................@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,@@@...............................................@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,&@@...................................................@@@,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,@@.......................................................@@@,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,@@.........................................................@@,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,@@........@@............................&...................@@#,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,(@@.....@@@ @@@......................@@@ @@@..................@@@@,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,@@....(@@   @@.....@@......@@......@@@   @@...................@@@@@,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,@@.....@@  ,@@......................@@   @@@.........@@*......@@,.@@@,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,@@.....@@@@.......,@@@@@@@@@@.......@@@@@........@@@....@@...*@@...@@@,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,@@#.............@@@  @  @@  @@@&......................@@*.....@@.....@@@,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,@@............@@@@@@&       @@@..................,@..........@@@.....@@@,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,@@@...........@@@@@@&  @@@@@.................................@@.......@@,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,@@@..........................................................@@@@@@...@@,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,@@@@.........................................................@@@,,&@@@@@,,,,
,,,,,,,,,,,,,,,,,,,,,,,@@.,@@@........................................................@@@,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,*@*....@@@.......................................@@@@............@@@,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,(@@@@@@@@@@@.........................................@@@@@........@@,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@.................................................@@@@@@..@@@,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,@@.......................................................@@@@@*,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,@@@..........................................................@@@,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,@@@.............................................................@@,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,@@@...............................................................@@,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,(@@.....@@.....................................,@@..................@@,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,@@......@@......................................@@..................@@@,,,,,,,,,
,,,,,,,,,,,,,,,,,,,@@@......@.......................................@@@..................@@@,,,,,,,,
,,,,,,,,,,,,,,,,,,,@@,.....@@.......................................,@@..................,@@,,,,,,,,
,,,,,,,,,,,,,,,,,,@@@......@@........................................@@(..................@@@,,,,,,,
*/

/**
 * @title Digi Sharks ERC-721 Smart Contract
 */

contract DigiSharks is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string private baseURI;

    // PUBLIC MINT
    bool public mintIsActive = false;
    uint256 public tokenPricePublic = 0.0169 ether;
    uint256 public constant maxPerTxnPublic = 5;
    uint256 public constant maxTokens = 10000;

    // FREE MINT
    bool public mintIsActiveFree = false;
    uint256 public  maxFreeTokens = 2500;

    // FREE MERKLE MINT
    bool public mintIsActivePresale = false;
    bytes32 public merkleRoot;
    mapping(address => uint256) public claimed;

    constructor() ERC721A("Digi Sharks", "SHARK") {}

    // @title PUBLIC MINT
    function flipMintState() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    /**
    *  @notice public mint function
    */
    function mintShark(uint256 qty) external payable nonReentrant{
        require(tx.origin == msg.sender);
        require(mintIsActive, "Mint is not active");
        require(qty <= maxPerTxnPublic, "You went over max tokens per transaction");
        require(totalSupply() + qty <= maxTokens, "Not enough tokens left to mint that many");
        require(msg.value >= tokenPricePublic * qty, "You sent the incorrect amount of ETH");

        _safeMint(msg.sender, qty);
    }

    // @title FREE MINT

    /**
    * @notice Turn on/off free mint
    */
    function flipMintStateFree() external onlyOwner {
        mintIsActiveFree = !mintIsActiveFree;
    }
    /**
    *  @notice free mint function
    */
    function freeMintShark(uint256 qty) external nonReentrant{
        require(tx.origin == msg.sender);
        require(mintIsActiveFree, "Mint is not active");
        require(qty <= maxPerTxnPublic, "You went over max tokens per transaction");
        require(totalSupply() + qty <= maxFreeTokens, "Not enough tokens left to mint that many");
      
        _safeMint(msg.sender, qty);
    }

    // @title FREE CLAIM MERKLE 

    /**
     * @notice Turn on/off presale wallet mint
     */
    function flipPresaleMintState() external onlyOwner {
        mintIsActivePresale = !mintIsActivePresale;
    }

    /**
     * @notice view function to check if a merkleProof is valid before sending presale mint function
     */
    function isOnPresaleMerkle(bytes32[] calldata merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    /**
     * @notice reset a list of addresses to be able to presale mint again. 
     */
    function initPresaleMerkleWalletList(address[] memory walletList, uint256 qty) external onlyOwner {
	    for (uint i; i < walletList.length; i++) {
		    claimed[walletList[i]] = qty;
	    }
    }
   
    /**
    * @notice check if wallet claimed for all potions
    */
    function checkClaimed(address wallet) external view returns (uint256) {
        return claimed[wallet];
    }

    /**
     * @notice free claim merkle mint 
     */
    function claim(uint256 qty, uint256 maxQty, bytes32[] calldata merkleProof) external nonReentrant{
        require(tx.origin == msg.sender);
        require(mintIsActivePresale, "Presale mint is not active");       
        require(
            claimed[msg.sender] + qty <= maxQty, 
            "Claim: Not allowed to claim given amount"
        );
        require(
            totalSupply() + qty <= maxTokens, 
            "Not enough tokens left to mint that many"
        );

        bytes32 node = keccak256(abi.encodePacked(msg.sender, maxQty));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "You have a bad Merkle Proof."
        );
        
        claimed[msg.sender] += qty;

        _safeMint(msg.sender, qty);
    }

    /**
    *  @notice  burn token id
    */
    function burn(uint256 tokenId) public virtual {
        _burn(tokenId);
    }

    // OWNER FUNCTIONS
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    /**
    *  @notice reserve mint n numbers of tokens
    */
    function mintReserveTokens(uint256 qty) public onlyOwner {
        _safeMint(msg.sender, qty);
    }

    /**
    *  @notice mint n tokens to a wallet
    */
    function mintTokenToWallet(address toWallet, uint256 qty) public onlyOwner {
         _safeMint(toWallet, qty);
    }

    /**
    *  @notice get base URI of tokens
    */
   	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(baseURI, _tokenId.toString()));
	}
 
    /** 
    *  @notice set base URI of tokens
    */
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    /**
     * @notice sets Merkle Root for presale
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
    *  @notice Set token price of public sale - tokenPricePublic
    */
    function setTokenPricePublic(uint256 tokenPrice) external onlyOwner {
        require(tokenPrice >= 0, "Must be greater or equal then zer0");
        tokenPricePublic = tokenPrice;
    }

    /**
    *  @notice Set max free tokens - maxTokens
    */
    function setMaxFreeTokens(uint256 amount) external onlyOwner {
        require(amount >= 0, "Must be greater or equal than zer0");
        maxFreeTokens = amount;
    }

}
