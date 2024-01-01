// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./MerkleProof.sol";
import "./IERC721.sol";
import "./ERC721AOpensea.sol";
import "./NFTToken.sol";

error ExceedsPerTransactionLimit();
error ExceedsPerWalletLimit();
error ExceedsSupplyLimit();
error IncorrectPaymentValue();
error InvalidSender();
error MintingCurrentlyDisabled();
error WithdrawalFailed();
error ZeroAddressCheck();

contract FTXGoblins is NFTToken, ERC721AOpensea {   

    string private _baseAssetURI;    
    uint public maxSupply = 10000;    
    uint public maxPerTransaction = 9999;
    uint public maxPerWalletLimit = 9999;    
    uint public mintPrice = 0.00069 ether;
    bool public mintEnabled = false;

    modifier checkSupply(uint256 amount_) {
        if (_totalMinted() + amount_ > maxSupply) {
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
        ERC721A("FTXGoblins", "FG")        
        ERC721AOpensea()
        NFTToken()
        
    {
        _setDefaultRoyalty(0xE943b4EcA1e173C3B0285081b1c6F7e1635283e9, 690);
    }  
    
    function verifyTokenOwner(
        address tokenContract,
        uint256 tokenId
    ) internal view returns (bool) {
        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        if (tokenOwner == address(0)) revert ZeroAddressCheck(); 
        return msg.sender == tokenOwner;
    }

    function sbfReserve(uint256 quantity, address receiver) 
        external 
        onlyOwner
        checkSupply(quantity)
        {
        _mint(receiver, quantity);
    } 

    function mint(uint qty)
      external
      payable      
      checkSupply(qty)
      validateAmountPerTransaction(qty)      
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

    function setMaxSupply(uint256 val) public onlyOwner {
        maxSupply = val;
    }

    function setMaxPerWalletLimit(uint256 val) external onlyOwner {
        maxPerWalletLimit = val;
    }

    function setMaxPerTransaction(uint256 val) external onlyOwner {
        maxPerTransaction = val;
    }

    function toggleMintEnabled() external onlyOwner {
        mintEnabled = !mintEnabled;
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

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseAssetURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}