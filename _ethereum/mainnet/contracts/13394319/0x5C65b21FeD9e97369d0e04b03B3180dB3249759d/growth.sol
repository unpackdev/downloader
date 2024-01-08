
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Context.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./SafeMath.sol";



contract FRAMEDGROWTH is
    ERC721,
    ERC721Enumerable,
    Ownable,
    PaymentSplitter
{
    using SafeMath for uint256;
    using SafeMath for uint16;

    uint256 public MAX_SUPPLY = 314;
    uint256 public presaleAccessCount = 0;
    uint16 _maxPurchaseCount = 2;
    uint16 _maxPreSalePurchaseCount = 2;
    uint256 _mintPrice = 0.05 ether;
    string _baseURIValue;
    mapping(address => bool) _presaleAccess;
    bool public saleIsActive = false;
    bool public presaleIsActive = false;



    constructor(
        address[] memory payees,
        uint256[] memory paymentShares
    ) ERC721("FramedGrowth", "FRGR") PaymentSplitter(payees, paymentShares) {

    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory newBase) public onlyOwner {
        _baseURIValue = newBase;
    }
    
    
    // Toggles for Sale and Presale states
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function flipPreSaleState() public onlyOwner {
        presaleIsActive = !presaleIsActive;
    }


    // getters and setters for minting limits
    function maxPurchaseCount() public view returns (uint256) {
        return _maxPurchaseCount;
    }

    function setMaxPurchaseCount(uint8 count) public onlyOwner {
        _maxPurchaseCount = count;
    }


    function maxPreSalePurchaseCount() public view returns (uint256) {
        return _maxPreSalePurchaseCount;
    }

    function setMaxPreSalePurchaseCount(uint8 count) public onlyOwner {
        _maxPreSalePurchaseCount = count;
    }

    
    
    // getters and setters for mint price
    function baseMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function setBaseMintPrice(uint256 price) public onlyOwner {
        _mintPrice = price;
    }

    function mintPrice(uint256 numberOfTokens) public view returns (uint256) {
        return _mintPrice.mul(numberOfTokens);
    }

   
   
    // getters and setters for Presale access
    function canAccessPresale(address addr) public view returns (bool) {
        return _presaleAccess[addr];
    }

    function addPresaleAddresses(address[] calldata addresses) external onlyOwner{
        for (uint256 i = 0; i < addresses.length; i++) {
            _presaleAccess[addresses[i]] = true;
        }
        presaleAccessCount += addresses.length;
    }
    


    // MODIFIERS
    modifier mintCountMeetsSupply(uint256 numberOfTokens) {
        require(
            totalSupply().add(numberOfTokens) <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        _;
    }

    modifier doesNotExceedMaxPreSalePurchaseCount(uint256 numberOfTokens) {
        require(
            numberOfTokens <= _maxPreSalePurchaseCount,
            "Cannot mint more than 2 tokens at a time for presale"
        );
        _;
    }

    modifier doesNotExceedMaxPurchaseCount(uint256 numberOfTokens) {
        require(
            numberOfTokens <= _maxPurchaseCount,
            "Cannot mint more than 1 token at a time"
        );
        _;
    }

    modifier validatePurchasePrice(uint256 numberOfTokens) {
        require(
            mintPrice(numberOfTokens) == msg.value,
            "Ether value sent is not correct"
        );
        _;
    }
    
    
    // Minting Functions
    function _mintTokens(uint256 numberOfTokens, address to) internal {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, totalSupply() + 1);
        }
    }
    
    function OwnerMint(uint256 numberOfTokens)
        public
        mintCountMeetsSupply(numberOfTokens)
        onlyOwner
    {

        _mintTokens(numberOfTokens, msg.sender);
    }

    function mintPresale(uint16 numberOfTokens)
        public
        payable
        mintCountMeetsSupply(numberOfTokens)
        doesNotExceedMaxPreSalePurchaseCount(numberOfTokens)
        validatePurchasePrice(numberOfTokens)
    {
        require(presaleIsActive, "Presale has not started yet");
        require(canAccessPresale(msg.sender), "You do not have access to the presale");
        require((balanceOf(msg.sender) + numberOfTokens) <= _maxPreSalePurchaseCount, "This mint would put you above the presale limit of mints per account");

        _mintTokens(numberOfTokens, msg.sender);
    }

    function mintTokens(uint256 numberOfTokens)
        public
        payable
        mintCountMeetsSupply(numberOfTokens)
        doesNotExceedMaxPurchaseCount(numberOfTokens)
        validatePurchasePrice(numberOfTokens)
    {
        require(saleIsActive, "Sale has not started yet");
        require((balanceOf(msg.sender) + numberOfTokens) <= _maxPurchaseCount, "This mint would put you above the sale limit of mints per account");


        _mintTokens(numberOfTokens, msg.sender);
    }
    
    
    function capSupply() public onlyOwner {
        MAX_SUPPLY = totalSupply();
    }



    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}