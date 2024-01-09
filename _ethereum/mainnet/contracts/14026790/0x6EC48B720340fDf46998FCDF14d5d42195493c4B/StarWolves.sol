// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

/**
 ______     ______   ______     ______        __     __     ______     __         __   __   ______     ______    
/\  ___\   /\__  _\ /\  __ \   /\  == \      /\ \  _ \ \   /\  __ \   /\ \       /\ \ / /  /\  ___\   /\  ___\   
\ \___  \  \/_/\ \/ \ \  __ \  \ \  __<      \ \ \/ ".\ \  \ \ \/\ \  \ \ \____  \ \ \'/   \ \  __\   \ \___  \  
 \/\_____\    \ \_\  \ \_\ \_\  \ \_\ \_\     \ \__/".~\_\  \ \_____\  \ \_____\  \ \__|    \ \_____\  \/\_____\ 
  \/_____/     \/_/   \/_/\/_/   \/_/ /_/      \/_/   \/_/   \/_____/   \/_____/   \/_/      \/_____/   \/_____/ 
**/

/**
 * @title Star Wolves ERC-721 Smart Contract
 */

contract StarWolves is ERC721, Ownable, Pausable, ReentrancyGuard {

    string public CONTRACTNAME_PROVENANCE = "";
    string private baseURI;
    uint256 public constant MAX_TOKENS = 8980;
    uint256 public constant MAX_PRESALE_TOKENS = 2000;
    uint256 public constant GENESIS_TOKENS = 100;
    uint256 public numTokensMinted = 0;
    uint256 public numTokensBurned = 0;
    uint256 public numTokensMintedPresale = 0;

    // PUBLIC MINT
    uint256 public constant TOKEN_PRICE = 0.0888 ether;
    uint256 public constant MAX_TOKENS_PURCHASE = 5;

    bool public mintIsActive = false;

    // PRESALE MINT
    uint256 public constant PRESALE_TOKEN_PRICE = 0.0888 ether;
    uint256 public constant MAX_TOKENS_PURCHASE_PRESALE = 2;
    bool public presaleIsActive = false;
    mapping (address => bool) public presaleWalletList;
    bytes32 public presaleMerkleRoot;

    // FREE  MINT
    bool public freeWalletIsActive = false;
    mapping (address => bool) public freeWalletList;


    constructor() ERC721("Star Wolves", "SW") {}

    // PUBLIC MINT
    function flipMintState() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function mint(uint256 numberOfTokens) external payable nonReentrant{
        require(!paused(), "Pausable: paused"); // Toggle if pausing should suspend minting
        require(mintIsActive, "Mint is not active");
        require(numberOfTokens <= MAX_TOKENS_PURCHASE, "You went over max tokens per transaction");
        require(numTokensMinted + numberOfTokens <= MAX_TOKENS, "Not enough tokens left to mint that many");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, "You sent the incorrect amount of ETH");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = numTokensMinted;
            if (numTokensMinted < MAX_TOKENS) {
                numTokensMinted++;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

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

    // WALLET BASED PRESALE
    function flipPresaleState() external onlyOwner {
	    presaleIsActive = !presaleIsActive;
    }

    function initPresaleWalletList(address[] memory walletList) external onlyOwner {
	    for (uint256 i = 0; i < walletList.length; i++) {
		    presaleWalletList[walletList[i]] = true;
	    }
    }

    function mintPresale(uint256 numberOfTokens, bytes32[] calldata _merkleProof) external payable nonReentrant{
	    require(!paused(), "Pausable: paused"); // Toggle if pausing should suspend minting
	    require(presaleIsActive, "Presale is not active");
	    require(!presaleWalletList[msg.sender], "You have already minted presale!");
	    require(numberOfTokens <= MAX_TOKENS_PURCHASE_PRESALE, "You went over max tokens per transaction");
	    require(numTokensMinted + numberOfTokens <= MAX_TOKENS, "Not enough tokens left to mint that many");
	    require(numTokensMintedPresale + numberOfTokens <= MAX_PRESALE_TOKENS, "Not enough tokens left to mint that many");
	    require(PRESALE_TOKEN_PRICE * numberOfTokens <= msg.value, "You sent the incorrect amount of ETH");

	    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
	    require(MerkleProof.verify(_merkleProof, presaleMerkleRoot, leaf), "Bad Merkle Proof: You are not on the presale wallet list");

	    presaleWalletList[msg.sender] = true;

	    for (uint256 i = 0; i < numberOfTokens; i++) {
		    uint256 mintIndex = numTokensMinted;
		    if (numTokensMinted < MAX_TOKENS) {
			    numTokensMinted++;
			    numTokensMintedPresale++;
			    _safeMint(msg.sender, mintIndex);
		    }
	    }
    }

    // FREE WALLET BASED GIVEAWAY MINT - Only Mint One
    function flipFreeWalletState() external onlyOwner {
	    freeWalletIsActive = !freeWalletIsActive;
    }

    function initFreeWalletList(address[] memory walletList) external onlyOwner {
	    for (uint256 i = 0; i < walletList.length; i++) {
		    freeWalletList[walletList[i]] = true;
	    }
    }

    function mintFreeWalletList() external nonReentrant {
        require(freeWalletIsActive, "Mint is not active");
	    require(freeWalletList[msg.sender] == true, "You are not on the free wallet list or have already minted");
	    require(numTokensMinted + 1 <= MAX_TOKENS, "Not enough tokens left to mint that many");

        uint256 mintIndex = numTokensMinted;
        numTokensMinted++;
	freeWalletList[msg.sender] = false;
        _safeMint(msg.sender, mintIndex);

    }

    // TOTAL SUPPLY
    function totalSupply() external view returns (uint) { 
        return numTokensMinted - numTokensBurned;
    }

    // BURN IT 
    function burn(uint256 tokenId) public virtual {
	    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
	    _burn(tokenId);
    }

    // OWNER FUNCTIONS
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function reserveMintSome(uint256 amt) external onlyOwner {
        uint256 mintIndex = numTokensMinted;
        for (uint256 i = 0; i < amt; i++) {
            numTokensMinted++;
            _safeMint(msg.sender, mintIndex + i);
        }
    }

    function setPaused(bool _setPaused) external onlyOwner {
	    return (_setPaused) ? _pause() : _unpause();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        CONTRACTNAME_PROVENANCE = provenanceHash;
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


