// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";


contract CryptoAncestorNFT is ERC721A, Ownable {
    using Strings for uint256;
    ////////////////////////////////////////////
    struct TransferInfo {
        address transferedTo;
        uint256 chainType;
    }

    ///////////////////////////////////////////
    event TransferChainEvent(address owner, uint256 chain, address target, uint256 happened);

    /// @dev All constant defination
    ////////////////////////////////////////////
    uint256 public constant CRYPTO_INVENTORY = 999;
    uint256 public constant PRICE = 0.88 ether;

    /// private variable for business
    ////////////////////////////////////////////
    bool private _selling = false; 
    uint256 private _round_cap = 99;
    string private _base = "https://gateway.pinata.cloud/ipfs/QmT5zbEsB1gv9dQgXr3j5SyfRrurqNkpx5SovbLwory7U4/";
    string private _transfered_notifce_url = "https://gateway.pinata.cloud/ipfs/QmPPeedth23fHtyDh37PbRgn5JksoZoZG9hZqc7MRxV6vY/";
    address private _seller = 0x652d5F582EF096b2c5DdCD3c66aaF0bE23662951;

    
    /// @dev transfered means transfer the Ancestor NFT to another chain
    /// then on eth this NFT can't be trade anymore.
    /// tokenID=>owner address
    mapping(uint256=>TransferInfo) private _transfered;
    uint256[] private _supportedChains;

    /// functions
    ////////////////////////////////////////////////////////////////////////
    /// Override
    function _baseURI() internal view override returns (string memory) {
        return _base;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        TransferInfo memory info = _transfered[tokenId];
        if (info.transferedTo != address(0)) {
            return _transfered_notifce_url;
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /// NFT Related
    ////////////////////////////////////////////////////////////////////////
    constructor() ERC721A("Crypto Ancestor NFT ", "CAN") {
        batchMint(_seller, 99);
    }

    function validatePurchaseRequirement(uint256 amount) private {
        // basic validate
        require(_selling == true, "Selling not started");
        require(amount >= 1, "Need to buy at least one");
        require(amount <= 2, "Can buy two at mosst");
        require(msg.value >= (PRICE * amount), "Insufficient funds sent");
        isEnough(amount);
    }

    /// @dev purchase crypto currency NFT
    function purchase(uint256 amount) external payable {
        validatePurchaseRequirement(amount);
        mintTo(msg.sender, amount);
    }

    /// @dev check if we have storage for the purchase
    function isEnough(uint256 amount) private view returns (bool enough) {
        uint256 solded = totalSupply();
        uint256 afterPurchased = solded + amount;
        enough = true;
        require(afterPurchased <= _round_cap, "Round cap reached");
        require(afterPurchased <= CRYPTO_INVENTORY, "Out of stock");
    }

        /// @dev check if we have storage for the purchase
    function queryTransferStatus(uint256 tokenId) external view returns (TransferInfo memory status) {
        status = _transfered[tokenId];
    }

    /// @dev transfer
    function doTransferToOtherChain(uint256 nftID, uint256 toChain, address targetAddress) public {

        require(isChainExist(toChain), "Chain is not exist");
        require(isOwner(nftID, msg.sender), "Only owner");

        TransferInfo storage transferedInfo = _transfered[nftID];
        require(transferedInfo.chainType == 0 ,"Already transferred");

        transferedInfo.chainType = toChain;
        transferedInfo.transferedTo = targetAddress;

        emit TransferChainEvent(msg.sender, toChain, targetAddress, block.timestamp);

    }

    /// @dev external method to verify the owner of the token
    function isOwner(uint256 nftID, address owner) public view returns(bool isNFTOwner) {
        address tokenOwner = ownerOf(nftID);
        isNFTOwner = (tokenOwner == owner);
    }


    function getMinted(address addr) external view returns (uint256 minted) {
        minted = _numberMinted(addr);
    }

    /// @dev show all purchased nfts by Arrays
    /// @return tokens nftID array
    function listMyNFT(address owner) external view returns (uint256[] memory tokens) {
        uint256 owned = balanceOf(owner);
        tokens = new uint256[](owned);
        uint256 start = 0;
        for (uint i=0; i<totalSupply(); i++) {
            if (ownerOf(i) == owner) {
                tokens[start] = i;
                start ++;
            }
        }
    }

    /// @dev mint function
    function mintTo(address purchaseUser, uint256 amount) private {
        _safeMint(purchaseUser, amount);
    }

    function isChainExist(uint256 chain) public view returns(bool) {
        for (uint256 i=0; i<_supportedChains.length; i++) {
            if (_supportedChains[i] == chain) {
                return true;
            }
        }
        return false;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(_transfered[tokenId].transferedTo == address(0), "This token has been transferred to another chain");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {

        require(_transfered[tokenId].transferedTo == address(0), "This token has been transferred to another chain");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {

        require(_transfered[tokenId].transferedTo == address(0), "This token has been transferred to another chain");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    /// Admin
    //////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////
    function batchMint(address wallet, uint amount) public onlyOwner {
        isEnough(amount);
        mintTo(wallet, amount);
    }


    function restoreOwner(uint256 nftID) public onlyOwner {

        TransferInfo storage transferedInfo = _transfered[nftID];
        require(transferedInfo.chainType != 0, "Not transfered");

        transferedInfo.chainType = 0;
        transferedInfo.transferedTo = address(0);

    }

    function setSellData(bool selling_, uint256 round_cap_) external onlyOwner {
        if (selling_ != _selling) {
            _selling = selling_;
        }
        require(round_cap_ > _round_cap, "error(1)");
        require(round_cap_ <= CRYPTO_INVENTORY, "error(2)");
        _round_cap = round_cap_;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _base = uri;
    }

    function setTransferedURI(string memory transfered) external onlyOwner {
        _transfered_notifce_url = transfered;
    }


    function setAllURI(string memory uri, string memory transfered) external onlyOwner {
        _base = uri;
        _transfered_notifce_url = transfered;
    }


    function addValidChain(uint256[] memory chains) external onlyOwner {
        for (uint256 i=0; i<chains.length; i++) {
            if (!isChainExist(chains[i])) {
                _supportedChains.push(chains[i]);
            }
        }
    }

    function withdrawTo(address targetAddress) external onlyOwner {
        payable(targetAddress).transfer(address(this).balance);
    }

    function withdrawLimit(address targetAddress, uint256 amount) external onlyOwner {
        payable(targetAddress).transfer(amount);
    }

}