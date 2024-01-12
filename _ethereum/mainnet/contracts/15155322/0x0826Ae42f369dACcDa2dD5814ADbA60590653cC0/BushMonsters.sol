//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

error ContractsNotAllowed();
error PriceTooLow();
error MintLimitReached();
error AmountTooHigh();
error BatchLimitExceeded();
error MustBeNonZero();
error SupplyLimitReached();
error ContractPaused();
error NonexistentToken();

contract BushMonsters is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bool public isActive;

    uint256 public immutable maxSupply = 5000;
    uint256 public immutable batchLimit = 5;

    uint256 public maxFreeSupply = 666;
    uint256 public maxFreeMint = 2;
    uint256 public maxMint = 20;
    uint256 public price = 0.006 ether;
    uint256 public startTime = 1658008799;

    string public baseURI =
        "ipfs://bafybeicgkk7uhwkj4qsqkxsfxlyi4hopr34nn2s7253hg2zuzjzlqdgzja/";
    address public withdrawalAddress;

    mapping(address => uint256) public freeMinted;
    mapping(address => uint256) public paidMinted;

    /* ----- Constructor ----- */

    constructor(address _withdrawalAddress) ERC721A("BushMonsters", "BM") {
        withdrawalAddress = _withdrawalAddress;
    }

    /* ----- Modifiers ----- */

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert ContractsNotAllowed();
        _;
    }

    modifier supplyLimit(uint256 _quantity) {
        if (totalSupply() + _quantity > maxSupply) revert SupplyLimitReached();
        _;
    }

    /* ----- User Interaction ----- */

    function mint(uint256 quantity)
        external
        payable
        callerIsUser
        nonReentrant
        supplyLimit(quantity)
    {
        if (quantity > batchLimit) revert BatchLimitExceeded();
        if (!isActive) {
            if (block.timestamp < startTime) revert ContractPaused();
        }

        if (totalSupply() + quantity <= maxFreeSupply) {
            if (freeMinted[msg.sender] + quantity > maxFreeMint)
                revert MintLimitReached();
            freeMinted[msg.sender] += quantity;
        } else {
            if (msg.value < quantity * price) revert PriceTooLow();
            if (paidMinted[msg.sender] + quantity > maxMint)
                revert MintLimitReached();
            paidMinted[msg.sender] += quantity;
        }

        _mint(msg.sender, quantity);
    }

    /* ----- View ----- */

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert NonexistentToken();

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    /* ----- Restricted ----- */

    function airdrop(address user, uint256 quantity)
        external
        onlyOwner
        supplyLimit(quantity)
    {
        _safeMint(user, quantity);
    }

    function airdropBatch(address[] calldata users, uint256 quantity)
        external
        onlyOwner
        supplyLimit(quantity * users.length)
    {
        for (uint256 i; i < users.length; i++) {
            _safeMint(users[i], quantity);
        }
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
        emit PriceUpdated(_price);
    }

    function setMaxFreeSupply(uint256 _amount) external onlyOwner {
        if (_amount == 0) revert MustBeNonZero();
        maxFreeSupply = _amount;
        emit MaxFreeSupplyUpdated(_amount);
    }

    function setMaxMint(uint256 _amount) external onlyOwner {
        if (_amount == 0) revert MustBeNonZero();
        maxMint = _amount;
        emit MaxMintUpdated(_amount);
    }

    function setMaxFreeMint(uint256 _amount) external onlyOwner {
        if (_amount == 0) revert MustBeNonZero();
        maxFreeMint = _amount;
        emit MaxFreeMintUpdated(_amount);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseURIUpdated(_baseURI);
    }

    function toggleSale() external onlyOwner {
        isActive = !isActive;
        emit SaleToggled(isActive);
    }

    function setStartTime(uint256 timestamp) external onlyOwner {
        startTime = timestamp;
    }

    function setWithdrawalAddress(address _withdrawal) external onlyOwner {
        withdrawalAddress = _withdrawal;
        emit WithdrawalAddressUpdated(_withdrawal);
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(withdrawalAddress).call{
            value: address(this).balance
        }("");
        require(os);
        emit FundsWithdrawn(withdrawalAddress);
    }

    /* ----- Internal ----- */

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /* ----- Events ----- */

    event PriceUpdated(uint256 newPrice);
    event MaxSupplyUpdated(uint256 newSupply);
    event MaxMintUpdated(uint256 newSupply);
    event MaxFreeMintUpdated(uint256 newSupply);
    event BatchLimitUpdated(uint256 newSupply);
    event TeamChange(address user, bool state);
    event BaseURIUpdated(string uri);
    event UnrevealedURIUpdated(string uri);
    event SaleToggled(bool state);
    event WithdrawalAddressUpdated(address user);
    event FundsWithdrawn(address user);
    event MaxFreeSupplyUpdated(uint256 amount);
}
