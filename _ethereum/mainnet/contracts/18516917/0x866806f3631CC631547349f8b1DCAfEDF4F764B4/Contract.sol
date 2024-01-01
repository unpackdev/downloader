// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IERC721.sol";
import "./ERC721AOpensea.sol";
import "./NFTToken.sol";

error ExceedsPerTXLimit();
error ExceedsPerWalletLimit();
error ExceedsSupplyLimit();
error InsufficientPayment();
error InvalidSender();
error MintingDisabled();
error WithdrawalFailed();
error ZeroAddressCheck();

contract NakaSimps is NFTToken, ERC721AOpensea {   

    string private _baseAssetURI;    
    
    uint public mintSupply = 7777;    
    uint public maxPerTX = 77;
    uint public maxPerWallet = 77;    
    uint public price = 0.003 ether;
    uint public freePerWallet = 1;
    
    bool public mintEnabled = false;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "not original sender");
        _;
    }
    constructor()
        ERC721A("NakaSimps", "NS")        
        ERC721AOpensea()
        NFTToken()
        
    {
        _setDefaultRoyalty(0xe89959AF5b1eE7DFede5d7807eFd8042579A74CF, 500);
    }  
   
    function mint(uint qty)
      external
      payable
      callerIsUser {
        uint price_ = calculatePrice(qty);

        if (_numberMinted(msg.sender) + qty > maxPerWallet + 1) revert ExceedsPerWalletLimit();
        if (_totalMinted() + qty > mintSupply + 1) revert ExceedsSupplyLimit();
        if (!mintEnabled) revert MintingDisabled();        
        
        if (qty > maxPerTX + 1) revert ExceedsPerTXLimit();

        _mint(msg.sender, qty);
        _refundOverPayment(price_);
    }

    function calculatePrice(uint qty) public view returns (uint) {
      uint numMinted = _numberMinted(msg.sender);
      uint free = numMinted < freePerWallet ? freePerWallet - numMinted : 0;
      if (qty >= free) {
        return (price) * (qty - free);
      }
      return 0;
    }

    function _refundOverPayment(uint256 amount) internal {
        if (msg.value < amount) revert InsufficientPayment();
        if (msg.value > amount) {
            payable(msg.sender).transfer(msg.value - amount);
        }
    }

    function reserveTo(uint256 quantity, address to) external onlyOwner {
        require(totalSupply() + quantity <= mintSupply,"not enough!");
        _mint(to, quantity);
    }

    function setMaxPerWalletLimit(uint256 val) external onlyOwner {
        maxPerWallet = val;
    }

    function setMaxPerTransaction(uint256 val) external onlyOwner {
        maxPerTX = val;
    }

    function setMintSupply(uint256 val) public onlyOwner {
        mintSupply = val;
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