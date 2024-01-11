// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./StringsUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./AuthorizableU.sol";
import "./ERC721AU.sol";

contract StacNFTokenU is AuthorizableU, ERC721AU, ReentrancyGuardUpgradeable {
    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////

    // metadata URI
    string private _baseTokenURI;

    // treasury address
    address public treasuryAddr;

    // sale configuration
    struct SaleConfig {
        bool saleFlag;
        uint256 salePrice;
    }

    SaleConfig public saleConfig;


    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier whenSale() {
        require(saleConfig.saleFlag, "This is not sale period");
        _;
    }    

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////
    function initialize() public virtual initializer {
        __ERC721AU_init("Suit & Tie Club", "SATC");
        __Authorizable_init();
        __ReentrancyGuard_init();

        saleConfig.saleFlag = true;
        saleConfig.salePrice = 0.1 ether;

        _baseTokenURI = "https://ipz.optimiz3.cloud/metadata/satc/";
        treasuryAddr = 0xA1139A7a1910d0FB4Ae01F9B8aE354D1E5601E07;
    }

    // Base URI ///////////////////////////////////////////////
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // sale update functions ///////////////////////////////////////////////
    function updateTreasuryAddr(address _treasuryAddr) public onlyOwner {
        treasuryAddr = _treasuryAddr;
    }

    function updateSaleFlag(bool _saleFlag) public onlyOwner {
        saleConfig.saleFlag = _saleFlag;
    }

    function updateSalePrice(uint256 _salePrice) public onlyOwner {
        saleConfig.salePrice = _salePrice;
    }    

    // sale functions ///////////////////////////////////////////////

    function adminMint(address recipient, uint256 quantity) public onlyOwner  {
        _safeMint(recipient, quantity);
    }

    function saleMint(uint256 quantity) external payable callerIsUser whenSale {
        require(isCorrectSaleQuantity(quantity), "Quantity isn't correct");
        uint256 totalCost = saleConfig.salePrice * quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(totalCost);
        sendFundToTreasury();
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function sendFundToTreasury() private {
        if (treasuryAddr != address(0)) {
            // (bool success, ) = treasuryAddr.call{value: address(this).balance}("");
            // require(success, "Transfer failed.");
            payable(treasuryAddr).transfer(address(this).balance);
        }
    }

    function isCorrectSaleQuantity(uint256 quantity) public pure returns (bool) {
        return quantity == 1 || quantity == 3 || quantity == 5;
    }
    /////////////////////////////////////////////////

    function withdrawFund() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }
}
