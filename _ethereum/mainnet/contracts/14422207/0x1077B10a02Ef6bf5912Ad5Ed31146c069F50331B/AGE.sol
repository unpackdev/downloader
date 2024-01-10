// SPDX-License-Identifier: MIT
/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
+                 .               .         .            .              .       +
+      .        _                    ____              U _____ u                +
.           U  /"\  u     .       U /"___|u  .         \| ___"|/    .           .
.     .   .  \/ _ \/              \| |  _ /             |  _|"                  .
.            / ___ \    .      .   | |_| |        .     | |___     .      .     .
.           /_/   \_\   _           \____|   _          |_____|   _             .
.        .   \\    >>  (")          _)(|_   (")         <<   >>  (")    .       .
.            (__)  (__)  "          (__)__)   "         (__) (__)  "   .        .
.                             .             .      .               .            .
.         .      ##      .           ###              .       .                 .
.               ## ###             ##  ###           ##.                .       .
.               ## *  ##        ### ░░░░░ ##      ## * #                        .
.     .         .# ***  ###   ## ░░░ ### ░░ ##  ## ****#.                       .
.                ## *****  ### ░░ ## . ### ░░ ### ****.#          .             .
.                .## *** ## ░░░░░ ######### ░░░ ## ** #.                        .
.                 # ** ## ░░░ ## ░░░░░░░░░ # ░░░░ ####.                         .
.                ##  ## ░░ ##   ########## ░░░░░░░░ ##                          .
.                 ## ░░░ #                ##### ░░░░░ ##      .                 .
.               ## ░░ ##    ####################### ░░░ ##                      .
.             ## ░░ ##    ## ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ ##                    .
.             ##  ##    ## ░░░░░ #################### ░░░░░ ##                  .
.     .         ##    ## ░░░░░ ###                   ###  ##           .        .
.                  ### ░░░ ###          ##########      ##                      .
.                   ### ░░░░ ##         ### ░░░░ ###           HODLers  Win !   .
.                      ## ░░░░ ##          ## ░░░░ ###      ##  . . ~~~~~~~~ ## .
.                        ## ░░░░ ###      ## ░░░░ ##          ## .~~~~~~~~~##   .
.                          ## ░░░░ ##   ## ░░░░ ##              ##~~~~~~~##     .
.        .                 #### ░░░░ ### ░░░░ ##                  ##~~~##       .
.                      ####    #### ░░░░  ####                      #~#         .
.               ## ####            #######..   ####                 ##          .
.            ###                      .:.           ####           .########    .
.          ###                      .:+-+:.             ##       # ###   ####   .
.         #                       .:+-+█+-+:.             #     ##    ########  .
.       ###         *               .:+-+:.               ###  .**#    ######   .
.      ## #        **                 .:.           *       # ...##   #####     .
.     .# #        ..#                              .**      ######      ###     .
.    .##        .*..#                             ..*^        #        ##       .
.     #### ## ##.# :###### #### ## #### ####### ### ##:###### ##########        .
+                                                                               +
+                                                                               +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
*/
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./IGuardVault.sol";

contract AGE is ERC721, Pausable, Ownable {

    uint public constant AGE_PRICE = 0.1 ether;

    uint public constant AGE_PREPRICE = 0.088 ether;

    uint public constant INIT_GUARD_VAULT = 0.01 ether;

    uint public constant MAX_AGE_PURCHASE = 20;

    uint public constant MAX_AGES = 10000;

    string public AGE_PROVENANCE = "";

    //Address => Stage => tokenNumbers
    mapping(address => mapping(uint => uint)) public mintRecords;

    //Stage => merkle proof
    mapping(uint => bytes32) public preMintRoot;

    //pre mint stage, zero is public mint
    uint public preStage = 1;

    bool public preSaleActive = true;

    //Get startingIndex from community vote
    uint public startingIndex = 0;

    address public hostAddress;

    IGuardVault private guardVault;

    uint private _totalSupply = 0;

    // Base URI
    string private _baseURIextended;

    constructor(string memory name, string memory symbol, address host, string memory uri) ERC721(name, symbol) {
        hostAddress = host;
        _baseURIextended = uri;
    }

    /**
    * Mints Guardians
    */
    function mintAge(uint numberOfTokens) public payable whenNotPaused {
        require(numberOfTokens <= MAX_AGE_PURCHASE, "Can only mint 20 tokens at a time.");
        require(totalSupply() + numberOfTokens <= MAX_AGES, "Purchase would exceed max supply of Guardians.");
        require(AGE_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct.");
        require(!preSaleActive, "Now is pre mint.");

        uint vaultValue = msg.value / 10 / numberOfTokens;
        guardVault.forGuard{value : msg.value / 10}();

        if (vaultValue == INIT_GUARD_VAULT) {
            for (uint i = 0; i < numberOfTokens; i++) {
                _safeMint(msg.sender, _totalSupply);
                _totalSupply += 1;
            }
        } else {
            for (uint i = 0; i < numberOfTokens; i++) {
                _safeMint(msg.sender, _totalSupply);
                guardVault.initGuardianVault(_totalSupply, vaultValue);
                _totalSupply += 1;
            }
        }
    }

    function preMintAge(
        uint numberOfTokens,
        uint maxNumber,
        bytes32[] memory proof) public payable whenNotPaused {
        require(totalSupply() + numberOfTokens <= MAX_AGES, "Purchase would exceed max supply of Guardians.");
        require(preSaleActive && preStage > 0, "Pre mint is not active.");
        require(msg.value >= AGE_PREPRICE * numberOfTokens, "Ether value for vault is not enough.");

        uint mintedNum = mintRecords[_msgSender()][preStage];
        require(mintedNum + numberOfTokens <= maxNumber, "Pre mint already the max purchase.");

        bytes32 root = preMintRoot[preStage];
        bytes32 node = keccak256(abi.encodePacked(_msgSender(), maxNumber));

        require(MerkleProof.verify(proof, root, node), "You are not in pre mint list.");
        guardVault.forGuard{value : INIT_GUARD_VAULT * numberOfTokens}();
        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), _totalSupply);
            _totalSupply += 1;
        }
        mintRecords[_msgSender()][preStage] += numberOfTokens;
    }

    /**
    * Reserve Guardians for community
    */
    function reserveAge(uint numberOfTokens, address to) public onlyOwner payable {
        require(numberOfTokens <= MAX_AGE_PURCHASE, "Can only mint 20 tokens at a time.");
        require(AGE_PRICE * numberOfTokens / 10 <= msg.value, "Not enough Ether to mint.");

        guardVault.forGuard{value : msg.value}();
        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(to, _totalSupply);
            _totalSupply += 1;
        }
    }

    /**
     * Set the starting index for the AGE
     */
    function setStartingIndex(uint index) public onlyOwner {
        require(startingIndex == 0, "Starting index is already set.");
        startingIndex = index;
    }

    /*
    * Set provenance
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        AGE_PROVENANCE = provenanceHash;
    }

    function burn(uint tokenId) external {
        require(startingIndex != 0, "ETH need Guardians.");
        require(tx.origin == ownerOf(tokenId), "Only owner can burn token.");
        require(_msgSender() == address(guardVault), "Only vault can burn token.");
        _burn(tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint tokenId) internal override(ERC721) {
        require(_exists(tokenId), "Token must exists.");
        super._burn(tokenId);
    }

    function setStageProof(uint stage, bytes32 proof) public onlyOwner {
        preMintRoot[stage] = proof;
    }

    function getMintRecord(address minter, uint stage) public view returns (uint) {
        return mintRecords[minter][stage];
    }

    function setHost(address host) public onlyOwner {
        hostAddress = host;
    }

    function claim() public payable onlyOwner {
        require(hostAddress != address(0), "Host address is zero.");
        payable(hostAddress).transfer(address(this).balance);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleActive = !preSaleActive;
    }

    function setPreMintStage(uint nextStage) public onlyOwner {
        require(nextStage > preStage, "Set pre mint stage incorrect.");
        preStage = nextStage;
    }

    function setVault(address vaultAddress) public onlyOwner {
        guardVault = IGuardVault(vaultAddress);
    }

    function getVaultAddress() public view returns (address) {
        return address(guardVault);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function totalSupply() public view virtual returns (uint) {
        return _totalSupply;
    }

    receive() external payable virtual {}

    fallback() external payable virtual {}
}
