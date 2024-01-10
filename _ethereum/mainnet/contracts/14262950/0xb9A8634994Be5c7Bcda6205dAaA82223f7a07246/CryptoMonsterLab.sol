// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721EnumerableLemon.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

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
 * @title CryptoMonster Lab ERC-721 Smart Contract
 */

contract CryptoMonsterLab is ERC721EnumerableLemon, Ownable, Pausable, ReentrancyGuard {

    string public CRYPTOMONSTERLAB_PROVENANCE = "";
    string private baseURI;
    uint256 public maxTokens = 10000;
    uint256 public numTokensMinted = 0;
    uint256 public numTokensBurned = 0;

    // PUBLIC MINT
    uint256 public tokenPricePublic = 0.055 ether;
    uint256 public constant MAX_TOKENS_PURCHASE = 20;

    bool public mintIsActive = false;

    // WALLET BASED PRESALE MINT
    uint256 public tokenPricePresale = 0.045 ether;
    uint256 public maxTokensPerTransactionPresale = 5;
    bool public mintIsActivePresale = false;

    // FREE WALLET BASED MINT
    bool public freeWalletIsActive = false;
    mapping (address => uint256) public freeWalletList;

    // PRESALE MERKLE MINT
    mapping (address => bool) public presaleMerkleWalletList;
    bytes32 public presaleMerkleRoot;


    constructor() ERC721("CryptoMonster Lab", "CMLAB") {}

    // PUBLIC MINT
    /**
    *  @notice  Turn on/off mint state for Public Minting
    */
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
        require(numTokensMinted + numberOfTokens <= maxTokens, "Not enough tokens left to mint that many");
        require(tokenPricePublic * numberOfTokens <= msg.value, "You sent the incorrect amount of ETH");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = numTokensMinted;
            numTokensMinted++;
            _safeMint(msg.sender, mintIndex);
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
     * @notice useful to reset a list of addresses to be able to presale mint again. 
     */
    function initPresaleMerkleWalletList(address[] memory walletList) external onlyOwner {
	    for (uint i; i < walletList.length; i++) {
		    presaleMerkleWalletList[walletList[i]] = false;
	    }
    }

    /**
     * @notice check if address minted presale
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
            numberOfTokens <= maxTokensPerTransactionPresale, 
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
            numTokensMinted + numberOfTokens <= maxTokens, 
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

    // FREE WALLET BASED GIVEAWAY MINT 
    /**
    *  @notice  Turn on/off mint state for Free Wallet Minting
    */
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
	    require(numTokensMinted + numberOfTokens <= maxTokens, "Not enough tokens left to mint that many");
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
    *  @notice get token ids by wallet
    */
    function walletOfOwner(address owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
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
    function mintReserveTokens(uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = numTokensMinted;
            numTokensMinted++;
            _safeMint(msg.sender, mintIndex);
        }
    }

    /**
    *  @notice pause the contract - all transfers will be stopped
    */
    function setPaused(bool _setPaused) external onlyOwner {
	    return (_setPaused) ? _pause() : _unpause();
    }

   /**
    *  @notice get base URI of tokens
    */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // @title SETTER FUNCTIONS
   
    /**
    *  @notice set base URI of tokens
    */
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        CRYPTOMONSTERLAB_PROVENANCE = provenanceHash;
    }

    /**
    *  @notice Set max tokens - maxTokens
    */
    function setMaxTokens(uint256 amount) external onlyOwner {
        require(amount >= 0, "Must be greater or equal than zer0");
        maxTokens = amount;
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

    /**
     *  @notice Set max tokens per transaction for presale - maxTokensPerTransactionPresale 
     */
    function setMaxTokensPerTransactionPresale(uint256 amount) external onlyOwner {
        require(amount >= 0, "Invalid amount");
        maxTokensPerTransactionPresale = amount;
    }


    /**
    *  @notice override function to pause transfers
    */
    function _beforeTokenTransfer(
	    address from,
	    address to,
	    uint256 tokenId
    ) internal virtual override(ERC721EnumerableLemon) {
	    require(!paused(), "Pausable: paused");
	    super._beforeTokenTransfer(from, to, tokenId);
    }
}
