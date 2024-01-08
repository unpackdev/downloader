// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract DUCGenesisComicsCovers is ERC721Enumerable, Ownable {
    /**
     *  Private state
     */
    uint256 private basePrice = 20000000000000000; //0.02
    uint256 private MAX_MINTSUPPLY = 1998;
    uint256 private reserveAtATime = 25;
    uint256 private reservedCount = 0;
    uint256 private maxReserveCount = 100;
    address private associateAddress = 0xAa0D34B3Ac6420B769DDe4783bB1a95F157ddDF5;
    address private secondAssociateAddress = 0x7B5b04BEf8b529941F8a6876B71C2f32b8652A3c; // 0x2fea18841E5846f1A827DC3d986F76B6773bdf45;
    address private creatorAddress = 0x379a669CF423448fB8F0B35A22BACd18c722d8a7;
    string _baseTokenURI;

    mapping(address => uint256) private withdrawalBalances;

    /**
     * Public state
     */
    uint256 public maximumAllowedTokensPerPurchase = 25;
    bool public isActive = false;

    /**
     * Modifiers
     */

    modifier saleIsOpen() {
        require(totalSupply() <= MAX_MINTSUPPLY, "Sale has ended.");
        _;
    }

    modifier onlyAuthorized() {
        require(
            associateAddress == msg.sender || owner() == msg.sender || creatorAddress == msg.sender || secondAssociateAddress == msg.sender,
            "Only authorized assosciates can run this function"
        );
        _;
    }

    /**
     * Events
     */
    event AssetMinted(uint256 tokenId, address sender);
    event SaleActivation(bool isActive);

    /**
     * Constructor
     */
    constructor(string memory baseURI)
        ERC721("Genesis Comics Dusty Limited Covers", "DUC")
    {
        setBaseURI(baseURI);
    }

    /**
     * Public functions
     */
    function setBaseURI(string memory baseURI) public onlyAuthorized {
        _baseTokenURI = baseURI;
    }

    function setReserveAtATime(uint256 val) public onlyAuthorized {
        reserveAtATime = val;
    }

    function setMaxReserve(uint256 val) public onlyAuthorized {
        maxReserveCount = val;
    }

    function setPrice(uint256 _price) public onlyAuthorized {
        basePrice = _price;
    }

    function setActive(bool val) public onlyAuthorized {
        isActive = val;
        emit SaleActivation(val);
    }

    function reserveNft() public onlyAuthorized {
        require(reservedCount <= maxReserveCount, "Maximum reserves exceeded.");
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < reserveAtATime; i++) {
            emit AssetMinted(supply + i, msg.sender);
            _safeMint(msg.sender, supply + i);
            reservedCount++;
        }
    }

    /**
     * Payables
     */
    function preSale(uint256 tokenId, uint256 _count)
        public
        payable
        saleIsOpen
    {
        if (msg.sender != owner()) {
            require(isActive, "Sale is not active currently.");
        }
        require(
            totalSupply() < MAX_MINTSUPPLY,
            "Total supply would be exceeded if we minted this request"
        );
        require(
            tokenId < MAX_MINTSUPPLY,
            "Requested tokenId exceeds upper bound"
        );
        require(
            _count <= maximumAllowedTokensPerPurchase,
            "Exceeds maximum allowed tokens"
        );
        require(msg.value >= basePrice * _count, "Insuffient ETH amount sent.");

        for (uint256 i = 0; i < _count; i++) {
            emit AssetMinted(totalSupply(), msg.sender);
            _safeMint(msg.sender, totalSupply());
        }
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        if (msg.sender != owner()) {
            require(isActive, "Sale is not active currently.");
        }

        require(
            totalSupply() + _count <= MAX_MINTSUPPLY,
            "Total supply exceeded."
        );
        require(totalSupply() <= MAX_MINTSUPPLY, "Total supply spent.");
        require(
            _count <= maximumAllowedTokensPerPurchase,
            "Exceeds maximum allowed tokens"
        );
        require(msg.value >= basePrice * _count, "Insuffient ETH amount sent.");

        for (uint256 i = 0; i < _count; i++) {
            emit AssetMinted(totalSupply(), _to);
            _safeMint(_to, totalSupply());
        }

        distributeRewards(_count);
    }

    function selfWithdraw(uint256 amount) external onlyAuthorized {
        uint256 currentBalance = address(this).balance;
        require(currentBalance >= amount);
        require(withdrawalBalances[msg.sender] >= amount);
        payable(msg.sender).transfer(amount);
        withdrawalBalances[msg.sender] -= amount;
    }

    function withdrawAll() external onlyAuthorized {
        payable(associateAddress).transfer(withdrawalBalances[associateAddress]);
        payable(secondAssociateAddress).transfer(withdrawalBalances[secondAssociateAddress]);
        payable(creatorAddress).transfer(withdrawalBalances[creatorAddress]);
        resetRewards();
    }

    function withdrawalFallback() public onlyOwner {
        require(!isActive, "Invalid use of the OH SHIT button!");
        payable(creatorAddress).transfer(address(this).balance);
        resetRewards();
    }

    /**
     *  Private functions
     */

    function distributeRewards(uint256 _count) private {
        uint256 totalEarning = _count * basePrice;
        uint256 associateEarning = totalEarning * 1250 / 10000;
        uint256 secondAssociateEarning = totalEarning * 1250 / 10000;
        withdrawalBalances[associateAddress] = associateEarning;
        withdrawalBalances[secondAssociateAddress] = secondAssociateEarning;
        withdrawalBalances[creatorAddress] = totalEarning - associateEarning - secondAssociateEarning;
    }
    
    function resetRewards() private {
        withdrawalBalances[associateAddress] = 0;
        withdrawalBalances[secondAssociateAddress] = 0;
        withdrawalBalances[creatorAddress] = 0;
    }

    /**
     * Views
     */
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function getMaximumAllowedTokens()
        public
        view
        onlyAuthorized
        returns (uint256)
    {
        return maximumAllowedTokensPerPurchase;
    }

    function getPrice() external view returns (uint256) {
        return basePrice;
    }

    function getReserveAtATime() external view returns (uint256) {
        return reserveAtATime;
    }

    function getMaxMintSupply() external view returns (uint256) {
        return MAX_MINTSUPPLY;
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function getContractOwner() public view returns (address) {
        return owner();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function withdrawBalanceOf(address assosciate) public view returns (uint256) {
        require(assosciate != address(0), "Valid user address is required.");
        return withdrawalBalances[assosciate];
    }
}
