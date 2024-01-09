// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract AnimeApes is Ownable, ERC721A, ReentrancyGuard {
    string private _baseTokenURI;

    uint256 public immutable amountForSale;
    uint256 public immutable amountForFree;

    uint256 public constant maxPerWalletDuringFreePhase = 2;
    uint256 public constant maxPerWalletDuringPMPhase = 10;
    uint256 public constant maxPerWalletDuringWLPhase = 15;
    
    uint256 public amountForDevs;
    uint256 public amountForWl;

    bytes32 private _wlRoot;

    bool public isFreeMintActive = false;
    bool public isPublicMintActive = false;
    bool public isWLMintActive = false;
    uint256 public amountMintedDuringFree;
    uint256 public freeMintStartTime;
    uint256 public publicMintStartTime;
    uint256 public wlMintStartTime;
    uint256 public price;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 amountForDevs_,
        uint256 amountForFree_,
        uint256 amountForSale_,
        uint256 amountForWl_
    ) ERC721A("Anime Ape Fight Club", "AAFC", maxBatchSize_, collectionSize_) {
        amountForDevs = amountForDevs_;
        amountForSale = amountForSale_;
        amountForFree = amountForFree_;
        amountForWl = amountForWl_;
        isFreeMintActive = false;
        require(
            amountForDevs_ + amountForSale_  + amountForFree_ + amountForWl_<= collectionSize_,
            "larger collection size needed"
        );
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function whiteListMint(uint256 quantity, bytes32[] calldata _proof) external payable callerIsUser {
        require(isWLMintActive, "whitelist sale has not begun yet");
        require(msg.value >= (price * quantity), "Minting Price is not enough");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(quantity <= maxBatchSize,"can not mint this many at one time");
        require(numberMinted(msg.sender) + quantity <= maxPerWalletDuringWLPhase,"can not mint this many during this phase");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_proof, _wlRoot, leaf),
            "Sorry, you're not whitelisted."
        );
        _safeMint(msg.sender, quantity);
    }

    function freeMint(uint256 quantity) external payable callerIsUser {
        require(
            isFreeMintActive,
            "Free Mint has not yet begun."
        );
        require(
            quantity <= maxPerWalletDuringFreePhase,
            "can not mint more than the wallet limit in one transaction"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerWalletDuringFreePhase,
            "can not mint more during this phase"
        );
        require(quantity <= remainingFreeApes(), "All free mints have been used");
        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable callerIsUser {
        require(msg.value >= (price * quantity), "Minting Price is not enough");
        require(
            isPublicMintActive,
            "public sale has not begun yet"
        );
        require(totalSupply() + quantity <= collectionSize, "reached max total supply");
        require(
            totalSupply() - amountMintedDuringFree + quantity <= amountForSale || (wlMintStartTime != 0 && block.timestamp - wlMintStartTime >= 8*60*60),
            "reached max supply during this phase"
        );
        require(
            quantity <= maxBatchSize,
            "can not mint more than 5 in one transaction"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerWalletDuringPMPhase,
            "can not mint more during this phase"
        );
        _safeMint(msg.sender, quantity);
    }

    function canPublicMintStart()
        public
        view
        returns (bool)
    {
        return (freeMintStartTime != 0 && price != 0 && (remainingFreeApes() == 0 || block.timestamp - freeMintStartTime >= 1*60));
    }     

    function canWLMintStart()
        public
        view
        returns (bool)
    {
        return publicMintStartTime != 0 && _wlRoot != ""  && price != 0 && (totalSupply() >= amountForDevs + amountForFree + amountForSale || block.timestamp - publicMintStartTime >= 24*60*60);
    }                                                                             

    function remainingFreeApes() public view returns (uint256) {
        if(totalSupply() <= amountForDevs){
            return  amountForFree;
        }else if (totalSupply() < amountForDevs + amountForFree){
            return amountForFree + amountForDevs - totalSupply();
        }else{
            return 0;
        }
    }

    function getPrice() public view returns (uint256) {
        return uint256(price);
    }

    function setWLRoot(bytes32 root) external onlyOwner {
        _wlRoot = root;
    }

    function setAmountForDevs(uint256 amount) external onlyOwner { 
        amountForDevs = amount;                                    
    }

    function startFreePhase() external onlyOwner {
        isFreeMintActive = true;
        freeMintStartTime = block.timestamp;
    }

    function startPublicMintPhase() external onlyOwner {
        require(canPublicMintStart(),"Conditions not met to start the public mint");
        amountMintedDuringFree = totalSupply();
        isFreeMintActive = false;
        isPublicMintActive = true;
        publicMintStartTime = block.timestamp;
    }

    function startWLMintPhase() external onlyOwner {
        require(canWLMintStart(),"Conditions not met to start the White List mint");
        isPublicMintActive = false;
        isWLMintActive = true;
        wlMintStartTime = block.timestamp;
    }

    function setPrice(uint256 value) external onlyOwner {
        price = value;
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= amountForDevs,
            "too many already minted before dev mint"
        );
        require(
            quantity % maxBatchSize == 0,
            "can only mint a multiple of the maxBatchSize"
        );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

}
