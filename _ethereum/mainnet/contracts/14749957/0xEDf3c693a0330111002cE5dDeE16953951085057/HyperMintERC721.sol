// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC2981.sol";
import "./IERC20.sol";
import "./ERC721Burnable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

contract HyperMintERC721 is ERC721, Ownable, ERC721Burnable, ReentrancyGuard {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    string _name;
    string _symbol;

    uint256 public price;
    uint256 public supply;
    uint256 public totalSupply;
    uint256 public maxPerAddress;

    string public contractURI;
    string tokenMetadataURI;

    bool public allowBuy;
    uint256 public presaleDate;
    uint256 public publicSaleDate;
    uint256 public saleCloseDate;

    address customerAddress;
    address presaleAddress;
    address purchaseTokenAddress;
    address primaryRoyaltyReceiver;
    address secondaryRoyaltyReceiver;
    uint96 primaryRoyaltyFee;
    uint96 secondaryRoyaltyFee;

    struct TokenInfo {
        uint256 price;
        uint256 supply;
        uint256 totalSupply;
        uint256 maxPerAddress;
    }

    constructor (string memory __name, string memory __symbol, uint256 _price, uint256 _totalSupply, string memory _contractMetadataURI,
        string memory _tokenMetadataURI, bool _allowBuy, address _customerAddress, address _presaleAddress, uint256 _maxPerAddress) ERC721("", "") {
        _name = __name;
        _symbol = __symbol;
        price = _price;
        totalSupply = _totalSupply;
        allowBuy = _allowBuy;
        customerAddress = _customerAddress;
        presaleAddress = _presaleAddress;
        tokenMetadataURI = _tokenMetadataURI;
        contractURI = _contractMetadataURI;
        maxPerAddress = _maxPerAddress;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(tokenMetadataURI, tokenId.toString()));
    }

    function setPurchaseToken(address _purchaseToken) public onlyOwner {
        purchaseTokenAddress = _purchaseToken;
    }

    function getTokenInfo() public view returns (TokenInfo memory){
        return TokenInfo(
            price, supply, totalSupply, maxPerAddress
        );
    }

    function setNameAndSymbol(string memory newName, string memory newSymbol) public onlyOwner {
        _name = newName;
        _symbol = newSymbol;
    }

    function setMetadataURIs(string memory _contractURI, string memory _tokenURI) public onlyOwner {
        contractURI = _contractURI;
        tokenMetadataURI = _tokenURI;
    }

    function setDates(uint256 _presale, uint256 _publicSale, uint256 _saleClosed) public onlyOwner {
        presaleDate = _presale;
        publicSaleDate = _publicSale;
        saleCloseDate = _saleClosed;
    }

    function setTokenData(uint256 _price, uint256 _supply, uint256 _maxPerAddress) public onlyOwner {
        require(supply <= _supply, "Supply too low");

        price = _price;
        totalSupply = _supply;
        maxPerAddress = _maxPerAddress;
    }

    function setCustomerAddresses(address _customerAddress, address _presaleAddress) public onlyOwner {
        customerAddress = _customerAddress;
        presaleAddress = _presaleAddress;
    }

    function setAllowBuy(bool _allowBuy) public onlyOwner {
        allowBuy = _allowBuy;
    }


    function mintBatch(address[] memory accounts, uint256[] memory amounts) public onlyOwner
    {
        for (uint i = 0; i < accounts.length; i++) {
            require(supply + amounts[i] <= totalSupply, "Not enough supply");

            for (uint256 j = 1; j <= amounts[i]; j++) {
                _safeMint(accounts[i], supply + j);
            }

            supply += amounts[i];
        }
    }

    function _buy(uint256 amount) internal {
        if (saleCloseDate != 0) {
            require(block.timestamp < saleCloseDate, "Sale closed");
        }

        require(supply + amount <= totalSupply, "Not enough supply");

        if (maxPerAddress != 0) {
            require(balanceOf(msg.sender) + amount <= maxPerAddress, "Max per address limit");
        }

        uint256 currentSupply = supply;
        supply += amount;

        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(msg.sender, currentSupply + i);
        }

        uint256 saleAmount = price * amount;
        uint256 royaltyAmount = (saleAmount * primaryRoyaltyFee) / 10000;

        if (purchaseTokenAddress == address(0)) {
            require(msg.value >= saleAmount, "Insufficient value");
            payable(primaryRoyaltyReceiver).transfer(royaltyAmount);
            payable(customerAddress).transfer(saleAmount - royaltyAmount);
        } else {
            IERC20 token = IERC20(purchaseTokenAddress);
            token.safeTransferFrom(msg.sender, primaryRoyaltyReceiver, royaltyAmount);
            token.safeTransferFrom(msg.sender, customerAddress, saleAmount - royaltyAmount);
        }
    }

    function buy(uint256 amount) nonReentrant external payable {
        require(allowBuy, "Buy disabled");
        require(block.timestamp >= publicSaleDate, "Public sale closed");

        _buy(amount);
    }

    function buyPresale(uint256 amount, uint8 _v, bytes32 _r, bytes32 _s) nonReentrant external payable {
        require(allowBuy, "Buy disabled");
        require(block.timestamp >= presaleDate, "Presale closed");
        require(isMessageSignedByPresaleAddress(msg.sender, _v, _r, _s), "Not authorised");

        _buy(amount);
    }

    function isMessageSignedByPresaleAddress(address _address, uint8 _v, bytes32 _r, bytes32 _s) view internal returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(address(this), _address));
        return presaleAddress == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), _v, _r, _s);
    }

    function transferContractOwnership() public {
        require(msg.sender == customerAddress, "Not authorised");
        _transferOwnership(customerAddress);
    }

    function setRoyalty(address primaryReceiver, address secondaryReceiver, uint96 primaryFee, uint96 secondaryFee) public onlyOwner {
        primaryRoyaltyReceiver = primaryReceiver;
        secondaryRoyaltyReceiver = secondaryReceiver;
        primaryRoyaltyFee = primaryFee;
        secondaryRoyaltyFee = secondaryFee;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256) {
        uint256 royaltyAmount = (_salePrice * secondaryRoyaltyFee) / 10000;
        return (secondaryRoyaltyReceiver, royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }
}
