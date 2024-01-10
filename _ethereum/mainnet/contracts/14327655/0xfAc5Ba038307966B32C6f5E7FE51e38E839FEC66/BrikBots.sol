// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

/**
 * @title BrikBots ERC-721 Smart Contract
 */

contract BrikBots is ERC721, Ownable, Pausable, ReentrancyGuard {

    string public BRIKBOTS_PROVENANCE = "";
    string private baseURI;
    uint256 public constant MAX_TOKENS = 9999;
    uint256 public numTokensMinted = 0;
    uint256 public numTokensBurned = 0;

    // PUBLIC MINT
    uint256 public tokenPricePublic =  0.069 ether;
    uint256 public constant MAX_TOKENS_PURCHASE = 3;

    bool public mintIsActive = false;

    // WALLET BASED PRESALE MINT
    uint256 public tokenPricePresale = 0.069 ether; 
    uint256 public constant MAX_TOKENS_PURCHASE_PRESALE = 6;
    bool public mintIsActivePresale = false;
    mapping (address => bool) public presaleWalletList;

    // FREE WALLET BASED MINT
    bool public freeWalletIsActive = false;
    mapping (address => uint256) public freeWalletList;

    // PRESALE MERKLE MINT
    mapping (address => bool) public presaleMerkleWalletList;
    bytes32 public presaleMerkleRoot;

    constructor() ERC721("brikbots", "bb") {}

    // PUBLIC MINT
    function flipMintState() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    /**
    *  @notice public mint function
    */
    function mint(uint256 numberOfTokens) external payable nonReentrant{
        require(!paused(), "Pausable: paused"); // Toggle if pausing should suspend minting
        require(mintIsActive, "Mint is not active");
        require(numberOfTokens <= MAX_TOKENS_PURCHASE, "You went over max tokens per transaction");
        require(numTokensMinted + numberOfTokens <= MAX_TOKENS, "Not enough tokens left to mint that many");
        require(tokenPricePresale * numberOfTokens <= msg.value, "You sent the incorrect amount of ETH");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = numTokensMinted;
            if (numTokensMinted < MAX_TOKENS) {
                numTokensMinted++;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    //  PRESALE WALLET MERKLE MINT

    /**
    * @notice sets Merkle Root for presale
    */
    function setMerkleRoot(bytes32 _presaleMerkleRoot) public onlyOwner {
        presaleMerkleRoot = _presaleMerkleRoot;
    }

    /**
     * @notice view function to check if a merkleProof is valid before sending presale mint function
     */
    function isOnPresaleMerkle(bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, presaleMerkleRoot, leaf);
    }

    /**
     * @notice Turn on/off presale wallet mint
     */
    function flipPresaleMintState() external onlyOwner {
        mintIsActivePresale = !mintIsActivePresale;
    }

    /**
     * @notice deprecated - but useful to reset a list of addresses to be able to presale mint again. 
     */
    function initPresaleMerkleWalletList(address[] memory walletList) external onlyOwner {
	    for (uint i; i < walletList.length; i++) {
		    presaleMerkleWalletList[walletList[i]] = false;
	    }
    }

    /**
     * @notice check if address is on presale list
     */
    function checkAddressOnPresaleMerkleWalletList(address wallet) public view returns (bool) {
	    return presaleMerkleWalletList[wallet];
    }

    /**
     * @notice Presale wallet list mint 
     */
    function mintPresaleMerkle(uint256 numberOfTokens, bytes32[] calldata _merkleProof) external payable nonReentrant{
        require(mintIsActivePresale, "Presale mint is not active");
        require(
            numberOfTokens <= MAX_TOKENS_PURCHASE_PRESALE, 
            "You went over max tokens per transaction"
        );
        require(
	        msg.value >= tokenPricePresale * numberOfTokens,
            "You sent the incorrect amount of ETH"
        );
        require(
            presaleMerkleWalletList[msg.sender] == false, 
            "You are not on the presale wallet list or have already minted"
        );
        require(
            numTokensMinted + numberOfTokens <= MAX_TOKENS, 
            "Not enough tokens left to mint that many"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, presaleMerkleRoot, leaf), "Invalid Proof");       
        presaleMerkleWalletList[msg.sender] = true;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = numTokensMinted;
            numTokensMinted++;
            _safeMint(msg.sender, mintIndex);
        }
    }

    // FREE WALLET BASED GIVEAWAY MINT - Only Mint One
    function flipFreeWalletState() external onlyOwner {
	    freeWalletIsActive = !freeWalletIsActive;
    }

    /**
    *  @notice  add wallets and quanties they can mint for Free Wallet Mint
    */
    function initFreeWalletList(address[] memory walletList, uint256[] memory quantity) external onlyOwner {
        require(walletList.length == quantity.length, "length of arrays do not match");
	    for (uint256 i = 0; i < walletList.length; i++) {
		    freeWalletList[walletList[i]] = quantity[i];
	    }
    }

    /**
    *  @notice  mint free number of tokens from Free Wallet List
    */
    function mintFreeWalletList(uint256 numberOfTokens) external nonReentrant {
        require(freeWalletIsActive, "Mint is not active");
	    require(freeWalletList[msg.sender] > 0, "You are not on the free wallet list or have already minted");
	    require(numTokensMinted + 1 <= MAX_TOKENS, "Not enough tokens left to mint that many");
        require(numberOfTokens <= freeWalletList[msg.sender], "Over allowed quantity to mint.");
        freeWalletList[msg.sender] -= numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = numTokensMinted;
            numTokensMinted++;
            _safeMint(msg.sender, mintIndex);
        }
    }

    /**
    *  @notice  burn token id
    */
    function burn(uint256 tokenId) public virtual {
	    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        numTokensBurned++;
	    _burn(tokenId);
    }

    /**
    *  @notice get total supply
    */
    function totalSupply() external view returns (uint) { 
        return numTokensMinted - numTokensBurned;
    }

    // OWNER FUNCTIONS
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    /**
    *  @notice reserve mint n numbers of tokens
    */
    function mintTokens(uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = numTokensMinted;
            numTokensMinted++;
            _safeMint(msg.sender, mintIndex);
        }
    }

    /**
    *  @notice mint n tokens to a wallet
    */
    function mintTokenToWallet(address toWallet, uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = numTokensMinted;
            numTokensMinted++;
            _safeMint(toWallet, mintIndex);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // @title SETTER FUNCTIONS

    function setPaused(bool _setPaused) external onlyOwner {
	    return (_setPaused) ? _pause() : _unpause();
    }

    /** 
    *  @notice set base URI of tokens
    */
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        BRIKBOTS_PROVENANCE = provenanceHash;
    }

    /**
    *  @notice Set token price of public sale - tokenPricePublic
    */
    function setTokenPricePublic(uint256 tokenPrice) external onlyOwner {
        require(tokenPrice >= 0, "Must be greater or equal then zer0");
        tokenPricePublic = tokenPrice;
    }

    /**
    *  @notice Set token price of presale - tokenPricePresale
    */
    function setTokenPricePresale(uint256 tokenPrice) external onlyOwner {
        require(tokenPrice >= 0, "Must be greater or equal than zer0");
        tokenPricePresale = tokenPrice;
    }

    // Toggle this function if pausing should suspend transfers
    function _beforeTokenTransfer(
	    address from,
	    address to,
	    uint256 tokenId
    ) internal virtual override(ERC721) {
	    require(!paused(), "Pausable: paused");
	    super._beforeTokenTransfer(from, to, tokenId);
    }
}
