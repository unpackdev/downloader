// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC721AUpgradeable.sol";
//import "./Strings.sol";

contract TippinTigers is Initializable, OwnableUpgradeable, ERC721AUpgradeable, ReentrancyGuardUpgradeable,UUPSUpgradeable {
    uint256 public  maxPerAddressDuringMint;
    address public admin;

    struct SaleConfig {
        uint32 publicSaleStartTime;
        uint64 mintlistPrice;
        uint64 publicPrice;
        uint32 publicSaleKey;
    }

    SaleConfig public saleConfig;

    mapping(address => uint256) public allowlist;
    
    // metadata URI
    string private _baseTokenURI;

    bool  public isOwnerMinted;

    modifier onlyOwnerAndAdmin() {
        require(
            owner() == _msgSender() || _msgSender() == admin,
            "Ownable: caller is not the owner or admin"
        );
        _;
    }


    function initialize() initializer public {
        __ERC721A_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        isOwnerMinted = false;

    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    // constructor(uint256 maxBatchSize_, uint256 collectionSize_,address _owner)
    //     ERC721AUp("TippinTigers", "TIPP", maxBatchSize_, collectionSize_)
    // {
    //     maxPerAddressDuringMint = maxBatchSize_;
    //     admin= _msgSender();
    //     transferOwnership(_owner);
    // }


    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function allowlistMint(uint256 quantity) external payable callerIsUser {
        uint256 price = uint256(saleConfig.mintlistPrice);
        require(quantity<=3,"Max allowed is 3 in presale");
        require(price != 0, "allowlist sale has not begun yet");
        require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
        require(totalSupply() + 1 <= collectionSize, "reached max supply");
        
        allowlist[msg.sender]--;
        _safeMint(msg.sender, quantity);
        refundIfOver(price);
    }

    function publicSaleMint(uint256 quantity, uint256 callerPublicSaleKey) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 publicSaleKey = uint256(config.publicSaleKey);
        uint256 publicPrice = uint256(config.publicPrice);
        uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
        require(publicSaleKey == callerPublicSaleKey, "called with incorrect public sale key");

        require(isPublicSaleOn(publicPrice, publicSaleKey, publicSaleStartTime), "public sale has not begun yet");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require (quantity<=10,"Max limit is 10");
       // require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "can not mint this many");
        _safeMint(msg.sender, quantity);
        refundIfOver(publicPrice * quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function isPublicSaleOn(
        uint256 publicPriceWei,
        uint256 publicSaleKey,
        uint256 publicSaleStartTime
    ) public view returns (bool) {
        return publicPriceWei != 0 && publicSaleKey != 0 && block.timestamp >= publicSaleStartTime;
    }

    function SetupSaleInfo(
        uint64 mintlistPriceWei,
        uint64 publicPriceWei,
        uint32 publicSaleStartTime,
        uint256 maxPerAddressDuringMint_
    ) external onlyOwnerAndAdmin {
        saleConfig = SaleConfig(publicSaleStartTime, mintlistPriceWei, publicPriceWei, saleConfig.publicSaleKey);
        maxPerAddressDuringMint = maxPerAddressDuringMint_;
    }

    function setPublicSaleKey(uint32 key) external onlyOwnerAndAdmin {
        saleConfig.publicSaleKey = key;
    }
    function setAdmin(address _admin) external onlyOwner{
        admin = _admin;
    }
    function getAdmin() external view returns (address){
        return admin;
    }

    function seedAllowlist(address[] memory addresses, uint256[] memory numSlots) external onlyOwnerAndAdmin {
        require(addresses.length == numSlots.length, "addresses does not match numSlots length");
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots[i];
        }
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwnerAndAdmin {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwnerAndAdmin nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }
    function owenrMint() external   onlyOwnerAndAdmin {
        require(!isOwnerMinted,"Owner Already Minted");
        for(uint8 i=0;i<5;i++){
          _safeMint(_msgSender(), 10);
        }
    }

    function getSalesConfig()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (saleConfig.mintlistPrice, saleConfig.publicPrice, saleConfig.publicSaleKey, saleConfig.publicSaleStartTime);
    }

     /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
     uint256[44] private __gap;

}
