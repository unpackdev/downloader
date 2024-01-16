// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./IERC2981.sol";
import "./ERC721A.sol";

contract AlphaSharesLaunchPadNFT is ERC721A, IERC2981, Ownable, PaymentSplitter {

    struct InitialParameters {
        string name;
        string symbol;
        string uri;
        uint24 maxSupply;
        uint24 maxPerWallet;
        uint24 maxPerTransaction;
        uint72 preSalePrice;
        uint72 pubSalePrice;
        uint256 royaltyFee;
        uint256 denominator;
        address payable royaltyRecipient;
    }

    struct WhiteListAddress {
        uint256 maxPurchasable;
        uint256 purchased;
    }

    mapping(address => uint) public hasMinted;
    mapping(address => bool) public addressIsWhitelisted;
    mapping(address => WhiteListAddress) public whiteListedBuyer;
    uint24 public maxSupply;
    uint24 public maxPerWallet;
    uint24 public maxPerTransaction;
    uint72 public preSalePrice;
    uint72 public pubSalePrice;
    bool public preSaleIsActive = false;
    bool public saleIsActive = false;
    bool public publicSaleIsActive = false;
    bool public supplyLock = true;
    string private uri;

    uint256 royaltyFee;
    uint256 denominator;
    address payable royaltyRecipient;

    event RoyaltiesSet(
        uint256 royaltyFee,
        address payable royaltyRecipient,
        uint256 _denominator
    );

    event AddWhitelistAddress(address[] buyers, uint256 indexed maxPurchasable);
    event RemoveWhitelistAddress(address[] buyers); 

    constructor(
        address[] memory _payees,
        uint256[] memory _shares,
        address _owner,
        InitialParameters memory initialParameters
    ) ERC721A(initialParameters.name, initialParameters.symbol)
      PaymentSplitter(_payees, _shares) {
        uri = initialParameters.uri;
        maxSupply = initialParameters.maxSupply;
        maxPerWallet = initialParameters.maxPerWallet;
        maxPerTransaction = initialParameters.maxPerTransaction;
        preSalePrice = initialParameters.preSalePrice;
        pubSalePrice = initialParameters.pubSalePrice;
        
        royaltyFee = initialParameters.royaltyFee;
        denominator = initialParameters.denominator;
        royaltyRecipient = initialParameters.royaltyRecipient;
        
        transferOwnership(_owner);
    }

    function setMaxSupply(uint24 _supply) public onlyOwner {
        require(!supplyLock, "Supply is locked.");
        maxSupply = _supply;
    }

    function lockSupply() public onlyOwner {
        supplyLock = true;
    }

    function setPreSalePrice(uint72 _price) public onlyOwner {
        preSalePrice = _price;
    }

    function setPublicSalePrice(uint72 _price) public onlyOwner {
        pubSalePrice = _price;
    }

    function setMaxPerWallet(uint24 _quantity) public onlyOwner {
        maxPerWallet = _quantity;
    }

    function setMaxPerTransaction(uint24 _quantity) public onlyOwner {
        maxPerTransaction = _quantity;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        uri = _uri;
    }

    function setSaleState(bool _isActive) public onlyOwner {
        saleIsActive = _isActive;
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return uri;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    function mint(uint _quantity) public payable {
        uint _maxSupply = maxSupply;
        uint _maxPerWallet = maxPerWallet;
        uint _maxPerTransaction = maxPerTransaction;
        uint _preSalePrice = preSalePrice;
        uint _pubSalePrice = pubSalePrice;
        bool _saleIsActive = saleIsActive;
        uint _currentSupply = totalSupply();
        require(_saleIsActive, "Sale is not active.");
        require(_currentSupply <= _maxSupply, "Sold out.");
        require(_currentSupply + _quantity <= _maxSupply, "Requested quantity would exceed total supply.");
        
        if(minterIsWhitelisted(msg.sender, _quantity)) {
            require(_preSalePrice * _quantity <= msg.value, "Currency sent is incorrect.");
            require(_quantity <= _maxPerWallet, "Exceeds wallet presale limit.");
            uint mintedAmount = hasMinted[msg.sender] + _quantity;
            require(mintedAmount <= _maxPerWallet, "Exceeds per wallet presale limit.");                        
            whiteListedBuyer[msg.sender].purchased =
            whiteListedBuyer[msg.sender].purchased + _quantity;
        } else {
            require(_pubSalePrice * _quantity <= msg.value, "Currency sent is incorrect.");
            require(_quantity <= _maxPerTransaction, "Exceeds per transaction limit for public sale.");
        }
        _safeMint(msg.sender, _quantity);
    }

    function reserve(address _address, uint _quantity) public onlyOwner {
        _safeMint(_address, _quantity);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {        
        uint256 fee = (_salePrice * royaltyFee) / denominator;
        
        return (royaltyRecipient, fee);
    }

    function setRoyaltyFees(
        uint256 newRoyaltyFee,
        address payable newRoyaltyRecipient,
        uint256 newDenominator
    ) external onlyOwner {
        require(newDenominator >= 100, "Denominator must be at least 100.");
        require(
            newDenominator % 100 == 0,
            "Denominator must be a multiple of 100."
        );
        // maximum that fees can be is 20%
        require(
            newRoyaltyFee <= (newDenominator / 5),
            "Fees are too high."
        );
        royaltyFee = newRoyaltyFee;
        royaltyRecipient = newRoyaltyRecipient;
        denominator = newDenominator;

        emit RoyaltiesSet(royaltyFee, royaltyRecipient, denominator);
    }

    function addWhitelistAddress(
        address[] calldata buyers,
        uint256 maxPurchasable
    ) external onlyOwner {
        for (uint256 i = 0; i < buyers.length; i++) {
            addressIsWhitelisted[buyers[i]] = true;

            whiteListedBuyer[buyers[i]] = WhiteListAddress({
                maxPurchasable: maxPurchasable,
                purchased: 0
            });
        }

        emit AddWhitelistAddress(buyers, maxPurchasable);
    }

    function removeWhiteListAddres(
        address[] calldata buyers
    ) external onlyOwner {
        for (uint256 i = 0; i < buyers.length; i++) {
            addressIsWhitelisted[buyers[i]] = false;

            whiteListedBuyer[buyers[i]] = WhiteListAddress({
                maxPurchasable: 0,
                purchased: 0
            });
        }

        emit RemoveWhitelistAddress(buyers);
    }

    function isWhitelisted(address buyer) external view returns (bool) {
        return addressIsWhitelisted[buyer];
    }

    function getPrice(address buyer) external view returns (uint256) {
        if (addressIsWhitelisted[buyer]) {
            return preSalePrice;
        } else {
            return pubSalePrice;
        }
    }

    function minterIsWhitelisted(address buyer, uint256 amount) internal view returns(bool) {        
        // short circuit
        require(addressIsWhitelisted[buyer] == true, "Address not whitelisted");
        
        // cache in function
        WhiteListAddress memory buyerToCheck = whiteListedBuyer[buyer];
        
        require(
            buyerToCheck.maxPurchasable > 0,
            "Not able to purchase any right now."
        );
        require(
            (buyerToCheck.purchased + amount) <=
                buyerToCheck.maxPurchasable,
            "Max amount purchased."
        );
        return true;
    }
}