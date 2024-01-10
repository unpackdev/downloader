// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract NFTCollection is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    struct Sale {
        uint256 round;
        uint256 maxSupply;
        uint256 minted;
        uint256 price;
        uint256 maxMintable;
        uint256 startTime;
        uint256 endTime;
        bool isPresale;
        bool isFinite;
    }

    string private baseURI;
    string private collectionPlaceholderURI;
    bool private collectionRevealed;

    address public devAddress;
    uint256 public maxSupply;
    Sale[] public sales;
    uint256 private maxReserveTokensSupply;
    uint256 private reserveTokensMinted;

    // sale round => address => isWhitelisted
    mapping(uint256 => mapping(address => bool)) public whiteLists;

    // sale round => address => nftsMinted
    mapping(uint256 => mapping(address => uint256)) public saleUserInfos;
    address[] public beneficiaries;
    mapping(address => uint256) public beneficiaryAllocations;

    modifier maxSupplyCheck(uint256 amount) {
        require(totalSupply() < maxSupply, "All NFTs have been minted.");
        require(amount > 0, "You must mint at least one token.");
        require(
            totalSupply() + amount <= maxSupply,
            "The amount of tokens you are trying to mint exceeds maxSupply."
        );
        _;
    }

    modifier maxReserveSupplyCheck(uint256 amount) {
        require(totalSupply() < maxSupply, "All NFTs have been minted.");
        require(
            reserveTokensMinted < maxReserveTokensSupply,
            "All reserve tokens have been minted"
        );
        require(amount > 0, "You must mint at least one token.");
        require(
            reserveTokensMinted + amount <= maxReserveTokensSupply,
            "The amount of reserve tokens you are trying to mint exceeds the maxReserveTokensSupply."
        );
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == devAddress || msg.sender == owner(),
            "Not authorized"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _maxReserveTokensSupply,
        Sale[] memory _sales,
        string memory _baseURI,
        string memory _collectionPlaceholderURI,
        address _devAddress
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        maxReserveTokensSupply = _maxReserveTokensSupply;
        collectionPlaceholderURI = _collectionPlaceholderURI;
        devAddress = _devAddress;
        baseURI = _baseURI;
        for (uint256 i = 0; i < _sales.length; i++) {
            _createSale(_sales[i]);
        }
    }

    function getSaleData(uint256 round)
        external
        view
        returns (Sale memory sale)
    {
        return sales[round];
    }

    function setDevAddress(address _devAddress) external onlyAuthorized {
        devAddress = _devAddress;
    }

    function setCollectionPlaceholderURI(string memory _uri)
        external
        onlyAuthorized
    {
        collectionPlaceholderURI = _uri;
    }

    function setBaseURI(string memory _uri) external onlyAuthorized {
        baseURI = _uri;
    }

    function revealCollection() external onlyAuthorized {
        collectionRevealed = true;
    }

    function hideCollection() external onlyAuthorized {
        collectionRevealed = false;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyAuthorized {
        require(
            _maxSupply >= totalSupply(),
            "maxSupply cannot be less than current totalSupply"
        );
        maxSupply = _maxSupply;
    }

    function setMaxReserveTokensSupply(uint256 _maxSupply)
        external
        onlyAuthorized
    {
        maxReserveTokensSupply = _maxSupply;
    }

    function whitelistAddresses(address[] memory _addresses, uint256 _saleRound)
        external
        onlyAuthorized
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whiteLists[_saleRound][_addresses[i]] = true;
        }
    }

    function removeFromWhitelist(
        address[] memory _addresses,
        uint256 _saleRound
    ) external onlyAuthorized {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whiteLists[_saleRound][_addresses[i]] = false;
        }
    }

    function configureSale(
        uint256 _round,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _maxMintable,
        uint256 _startTime,
        uint256 _endTime,
        bool _isPresale,
        bool _isFinite
    ) external onlyAuthorized {
        require(_round < sales.length, "Sales round does not exist");
        Sale storage sale = sales[_round];
        bool saleStarted = block.timestamp >= sale.startTime;
        if (!saleStarted) {
            require(
                _startTime >= block.timestamp,
                "Sale should be in the future"
            );
            sale.startTime = _startTime;
        }
        sale.endTime = _endTime;
        sale.maxSupply = _maxSupply;
        sale.price = _price;
        sale.maxMintable = _maxMintable;
        sale.isPresale = _isPresale;
        sale.isFinite = _isFinite;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mintReserveTokens(uint256 amount)
        external
        onlyOwner
        maxSupplyCheck(amount)
        maxReserveSupplyCheck(amount)
    {
        for (uint256 i = 0; i < amount; i++) {
            uint256 newItemId = totalSupply().add(1);
            reserveTokensMinted += 1;
            _safeMint(msg.sender, newItemId);
        }
    }

    function mint(uint256 round, uint256 amount)
        external
        payable
        nonReentrant
        maxSupplyCheck(amount)
        callerIsUser
    {
        Sale storage sale = sales[round];
        uint256 userMinted = saleUserInfos[round][msg.sender];
        require(block.timestamp >= sale.startTime, "Sale has not started yet");
        require(
            sale.minted.add(amount) <= sale.maxSupply,
            "Sale max supply is reached"
        );
        require(
            msg.value == sale.price.mul(amount),
            "Payment amount is lower than nft price"
        );
        require(
            userMinted.add(amount) <= sale.maxMintable,
            "You cannot mint this amount"
        );
        if (sale.isPresale) {
            require(
                whiteLists[round][msg.sender],
                "Address not whitelisted for this sale"
            );
        }
        if (sale.isFinite) {
            require(block.timestamp <= sale.endTime, "Sale has ended");
        }

        for (uint256 i = 0; i < amount; i++) {
            uint256 newItemId = totalSupply().add(1);
            _safeMint(msg.sender, newItemId);
            saleUserInfos[round][msg.sender] += 1;
            sale.minted += 1;
        }
    }

    function createSale(Sale memory sale) public onlyAuthorized {
        _createSale(sale);
    }

    function _createSale(Sale memory sale) internal {
        require(sale.price > 0, "Price should not be zero");
        require(sale.maxMintable > 0, "Mintable amount should not be zero");
        require(
            sale.startTime >= block.timestamp,
            "Sale should be in the future"
        );
        if (sale.isFinite) {
            require(sale.endTime > 0, "Sale endTime should be set");
            require(
                sale.endTime > sale.startTime,
                "Sale endTime should be greater than sale startTime"
            );
        }
        sales.push(sale);
    }

    function getTotalAllocations() public view returns (uint256) {
        uint256 investorAllocated;
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            investorAllocated += beneficiaryAllocations[beneficiaries[i]];
        }
        return investorAllocated;
    }

    function addBeneficiary(address _beneficiary, uint256 allocation)
        external
        onlyAuthorized
    {
        require(allocation > 0, "Beneficiary allocation is zero");
        require(
            beneficiaryAllocations[_beneficiary] == 0,
            "Beneficiary already added"
        );
        beneficiaryAllocations[_beneficiary] = allocation;
        beneficiaries.push(_beneficiary);
    }

    function withdraw() external onlyOwner {
        uint256 investorAllocated = getTotalAllocations();
        uint256 balance = address(this).balance;
        require(balance > investorAllocated, "Not enough balance");
        payable(msg.sender).transfer(balance.sub(investorAllocated));
    }

    function beneficiaryWithdraw(uint256 amount)
        external
        nonReentrant
        callerIsUser
    {
        uint256 allocation = beneficiaryAllocations[msg.sender];
        require(allocation > 0, "No allocation for this address");
        require(amount <= allocation, "Not enough allocation");
        uint256 balance = address(this).balance;
        require(amount <= balance, "Not enough funds to withdraw");
        payable(msg.sender).transfer(amount);
        beneficiaryAllocations[msg.sender] = beneficiaryAllocations[msg.sender]
            .sub(amount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory uri)
    {
        string memory base = _baseURI();

        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        if (!collectionRevealed) {
            if (bytes(collectionPlaceholderURI).length > 0) {
                return string(abi.encodePacked(base, collectionPlaceholderURI));
            }
        } else {
            return
                bytes(base).length > 0
                    ? string(abi.encodePacked(base, tokenId.toString()))
                    : "";
        }
    }

    function evacuateTokens(address token, address to) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to, balance);
    }

    function evacuateEther(address payable to) external onlyOwner {
        uint256 investorAllocated = getTotalAllocations();
        uint256 balance = address(this).balance;
        require(balance > investorAllocated, "Not enough funds");
        payable(to).transfer(balance.sub(investorAllocated));
    }

    receive() external payable {}
}
