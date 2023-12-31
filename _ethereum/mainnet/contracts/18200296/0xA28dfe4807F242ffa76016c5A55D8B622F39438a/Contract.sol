// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./MerkleProof.sol";
import "./IERC721.sol";
import "./ERC721AOpensea.sol";
import "./NFTToken.sol";

error ClaimDisabled();
error ExceedsPerTransactionLimit();
error ExceedsPerWalletLimit();
error ExceedsSupplyLimit();
error IncorrectPaymentValue();
error InvalidSender();
error MintingCurrentlyDisabled();
error WithdrawalFailed();
error ZeroAddressCheck();

contract BoringNakasCloaks is NFTToken, ERC721AOpensea {   

    string private _baseAssetURI;
    bool public claimEnabled = false;
    uint public maxMintSupply = 10000;    
    uint public maxPerTransaction = 9999;
    uint public maxPerWalletLimit = 9999;    
    uint public mintPrice = 0.002 ether;
    bool public mintEnabled = false;
    uint256 public claimCount;
    
    mapping(uint256 => bool) public claimed;

    modifier checkSupply(uint256 amount_) {
        if (_totalMinted() + amount_ > maxMintSupply) {
            revert ExceedsSupplyLimit();
        }
        _;
    }

    modifier onlyOriginalSender() {
        require(tx.origin == msg.sender, "not the original sender");
        _;
    }   

     modifier validateAmountPerTransaction(uint256 amount_) {
        if (amount_ > maxPerTransaction + 1) {
            revert ExceedsPerTransactionLimit();
        }
        _;
    }

    constructor()
        ERC721A("BoringNakas-Cloaks", "BNC")        
        ERC721AOpensea()
        NFTToken()
        
    {
        _setDefaultRoyalty(0x57220b0f5335A054014808Be12457CD049B3867E, 690);
    }

    function teamMint(uint256 quantity, address receiver) 
        external 
        onlyOwner
        checkSupply(quantity)
        {
        _mint(receiver, quantity);
    }   
    
    function verifyTokenOwner(
        address tokenContract,
        uint256 tokenId
    ) internal view returns (bool) {
        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        if (tokenOwner == address(0)) revert ZeroAddressCheck(); 
        return msg.sender == tokenOwner;
    }

    function claim(uint256[] calldata tokenIds) 
        public 
        allowedClaimer
        {
        if (!claimEnabled) revert ClaimDisabled();
        
        uint256 numTokens = tokenIds.length;
        require(claimCount + numTokens  <= 10000, "Not enough left to claim");
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 nakaId = tokenIds[i];
            require(!claimed[nakaId], "You already claimed, nerd!");
            bool nakaHolder = verifyTokenOwner(0xf30A9cd4Cd1Fd9EA3270afcecde5feCe34Bc4aCa, nakaId);
            require(nakaHolder, "You don't own this BoringNaka");
            claimed[nakaId] = true;
        }
        claimCount += numTokens;
        _mint(msg.sender, numTokens);        
    }

    function mint(uint qty)
      external
      payable      
      checkSupply(qty)
      validateAmountPerTransaction(qty)  
      allowedClaimer
      onlyOriginalSender          
      {
        if (!mintEnabled) revert MintingCurrentlyDisabled();

        uint price = mintPrice * qty;

        if (_numberMinted(msg.sender) + qty > maxPerWalletLimit + 1) revert ExceedsPerWalletLimit();
     
        _mint(msg.sender, qty);
        _refundExcessPayment(price);
    }
    
    function _refundExcessPayment(uint256 amount) internal {
        if (msg.value < amount) revert IncorrectPaymentValue();
        if (msg.value > amount) {
            payable(msg.sender).transfer(msg.value - amount);           
        }
    }

    function setMaxMintSupply(uint256 val) public onlyOwner {
        maxMintSupply = val;
    }

    function setMaxPerWalletLimit(uint256 val) external onlyOwner {
        maxPerWalletLimit = val;
    }

    function setMaxPerTransaction(uint256 val) external onlyOwner {
        maxPerTransaction = val;
    }

    function toggleMint() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function toggleClaim() external onlyOwner {
        claimEnabled = !claimEnabled;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseAssetURI = baseURI_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(NFTToken, ERC721AOpensea)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert WithdrawalFailed();
    }

    modifier allowedClaimer() {
        require(msg.sender != 0x4034adD1a1A750AA19142218A177D509b7A5448F, "Nice try, motherfucker.");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseAssetURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function getAux(address owner) public view returns (uint64) {
        return _getAux(owner);
    }

    function setAux(address owner, uint64 aux) external onlyOwner {
        _setAux(owner, aux);
    }      
}