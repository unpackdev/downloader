// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Context.sol";
import "./Counters.sol";

 //    _____ ________   _______ _____ ________  ________ _   _  _____ _____ ___________     _       ___  ______ 
 //   /  __ \| ___ \ \ / / ___ \_   _|  _  |  \/  |  _  | \ | |/  ___|_   _|  ___| ___ \   | |     / _ \ | ___ \
 //   | /  \/| |_/ /\ V /| |_/ / | | | | | | .  . | | | |  \| |\ `--.  | | | |__ | |_/ /   | |    / /_\ \| |_/ /
 //   | |    |    /  \ / |  __/  | | | | | | |\/| | | | | . ` | `--. \ | | |  __||    /    | |    |  _  || ___ \
 //   | \__/\| |\ \  | | | |     | | \ \_/ / |  | \ \_/ / |\  |/\__/ / | | | |___| |\ \    | |____| | | || |_/ /
 //    \____/\_| \_| \_/ \_|     \_/  \___/\_|  |_/\___/\_| \_/\____/  \_/ \____/\_| \_|   \_____/\_| |_/\____/ 

 //                                                            .:
 //                                                           / )
 //                                                          ( (
 //                                                           \ )
 //           o                                             ._(/_.
 //            o                                            |___%|
 //          ___              ___  ___  ___  ___             | %|
 //          | |        ._____|_|__|_|__|_|__|_|_____.       | %|
 //          | |        |__________________________|%|       | %|
 //          |o|          | | |%|  | |  | |  |~| | |        .|_%|.
 //         .' '.         | | |%|  | |  |~|  |#| | |        | ()%|
 //        /  o  \        | | :%:  :~:  : :  :#: | |     .__|___%|__.
 //       :____o__:     ._|_|_."    "    "    "._|_|_.   |      ___%|_
 //       '._____.'     |___|%|                |___|%|   |_____(____  )
 //                                                                 ( (
 //                                                                  \ '._____.-
 //                                                                   '._______.-
 //   from the mind of Santiago Uceda 2022
 //
 //   thanks to all the token holders for your support


/**
 * @title CryptoMonster Lab Cocktails ERC-721 Smart Contract
 */

contract CryptoMonsterLabCocktails is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private counter; 

    string private baseURI;
    uint256 public cocktailMintId = 0;

    // PUBLIC MINT
    bool public mintIsActive  = false;

    // PRESALE MERKLE MINT
    bool public mintIsActivePresale = false;  

    mapping(uint256 => Cocktail) public cocktails;

    struct Cocktail {
        uint256 tokenPricePublic;
        uint256 tokenPricePresale;
        uint256 maxPerTxnPublic;
        uint256 maxTokens;
        bytes32 merkleRoot;
        mapping(address => uint256) claimed;
    }

    constructor() ERC721A("CryptoMonster Lab Cocktails", "CMLC") {}

    /**
    * @notice create a new cocktail
    */
    function addCocktail(
        uint256 _tokenPricePublic,
        uint256 _tokenPricePresale,
        uint256 _maxPerTxnPublic,
        uint256 _maxTokens,
        bytes32 _merkleRoot
    ) external onlyOwner {
        require(_maxTokens > 0, "Max Tokens must be greater than 0");
        Cocktail storage p = cocktails[counter.current()];       
        p.tokenPricePublic = _tokenPricePublic;
        p.tokenPricePresale = _tokenPricePresale;
        p.maxPerTxnPublic = _maxPerTxnPublic;
        p.maxTokens = _maxTokens;
        p.merkleRoot = _merkleRoot;
        counter.increment();
    }

    /**
    * @notice edit an existing cocktail
    */
    function editCocktail(
        uint256 _cocktailId,
        uint256 _tokenPricePublic,
        uint256 _tokenPricePresale,
        uint256 _maxPerTxnPublic,
        uint256 _maxTokens,
        bytes32 _merkleRoot
    ) external onlyOwner {
        require(cocktailExists(_cocktailId), "");

        cocktails[_cocktailId].tokenPricePublic = _tokenPricePublic;
        cocktails[_cocktailId].tokenPricePresale = _tokenPricePresale;
        cocktails[_cocktailId].maxPerTxnPublic = _maxPerTxnPublic;
        cocktails[_cocktailId].maxTokens = _maxTokens;
        cocktails[_cocktailId].merkleRoot = _merkleRoot;
    }

    // @title PUBLIC MINT
    function flipMintState() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    /**
    *  @notice public mint function
    */
    function mint(uint256 qty) external payable nonReentrant{
        require(tx.origin == msg.sender);
        require(mintIsActive, "Mint is not active");
        require(qty <= cocktails[cocktailMintId].maxPerTxnPublic, "You went over max tokens per transaction");
        require(totalSupply() + qty <= cocktails[cocktailMintId].maxTokens, "Not enough tokens left to mint that many");
        require(msg.value >= cocktails[cocktailMintId].tokenPricePublic * qty, "You sent the incorrect amount of ETH");

        _safeMint(msg.sender, qty);
    }

    // @title PRESALE MERKLE MINT

    /**
     * @notice view function to check if a merkleProof is valid before sending presale mint function
     */
    function isOnPresaleMerkle(bytes32[] calldata merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(merkleProof, cocktails[cocktailMintId].merkleRoot, leaf);
    }

    /**
     * @notice Turn on/off presale wallet mint
     */
    function flipPresaleMintState() external onlyOwner {
        mintIsActivePresale = !mintIsActivePresale;
    }

    /**
     * @notice reset a list of addresses to be able to presale mint again. 
     */
    function initPresaleMerkleWalletList(address[] memory walletList, uint256 qty) external onlyOwner {
	    for (uint i; i < walletList.length; i++) {
		    cocktails[cocktailMintId].claimed[walletList[i]] = qty;
	    }
    }

    /**
     * @notice check if address minted
     */
    function checkAddressOnPresaleMerkleWalletList(address wallet) public view returns (uint256) {
	    return cocktails[cocktailMintId].claimed[wallet];
    }

    /**
     * @notice Presale wallet list mint 
     */
    function mintPresaleMerkle(uint256 qty, uint256 maxQty, bytes32[] calldata merkleProof) external payable nonReentrant{
        require(tx.origin == msg.sender);
        require(mintIsActivePresale, "Presale mint is not active");
        require(
	        msg.value >= cocktails[cocktailMintId].tokenPricePresale * qty,
            "You sent the incorrect amount of ETH"
        );
        require(
            cocktails[cocktailMintId].claimed[msg.sender] + qty <= maxQty, 
            "Claim: Not allowed to claim given amount"
        );
        require(
            totalSupply() + qty <= cocktails[cocktailMintId].maxTokens, 
            "Not enough tokens left to mint that many"
        );

        bytes32 node = keccak256(abi.encodePacked(msg.sender, maxQty));
        require(
            MerkleProof.verify(merkleProof, cocktails[cocktailMintId].merkleRoot, node),
            "You have a bad Merkle Proof."
        );
        cocktails[cocktailMintId].claimed[msg.sender] = cocktails[cocktailMintId].claimed[msg.sender] + qty;

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
    *  @notice mint a token id to a wallet
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
    * @notice indicates weither any cocktail exists with a given id, or not
    */
    function cocktailExists(uint256 id) public view returns (bool) {
        return cocktails[id].maxTokens > 0;
    }

    /**
    * @notice check if wallet claimed for all potions
    */
    function checkClaimed(address wallet) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](counter.current());

        for(uint256 i; i < counter.current(); i++) {
            result[i] = cocktails[i].claimed[wallet];
        }

        return result;
    }

    /**
    *  @notice Set max tokens for each staged mint
    */
    function setCocktailMintId(uint256 id) external onlyOwner {
        require(id >= 0, "Must be greater or equal then zer0");
        cocktailMintId = id;
    }

}
