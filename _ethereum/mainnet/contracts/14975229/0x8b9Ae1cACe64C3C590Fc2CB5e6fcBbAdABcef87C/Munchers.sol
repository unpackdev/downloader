// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./console.sol";

contract Munchers is ERC721A, ERC2981, Ownable, Pausable, PaymentSplitter {

    uint256 public maxPerTxn = 2;
    uint256 public maxMintsPerWallet = 2;
    uint256 public price = 0.0025 ether;
    string public contractURI;
    uint256 public maxTokensForFreeMint;
    uint256 public maxTokens;
    string public baseURI;
    bool public isRevealed;
    bool public isPaid;
    address public admin;
    uint256 public reservedTokensAmount;
    address[] public payees;
    uint256[] public shares;
    
    bool private _reservedMinted;
    bool private _saleActive;
    uint96 private _royaltyFee = 1000;

    constructor(
        string memory _contractURI,
        uint256 _maxTokens,
        uint256 _maxTokensForFreeMint,
        string memory baseURIString,
        uint256 _reservedTokensAmount,
        address _admin,
        address[] memory _payees,
        uint256[] memory _shares
    ) ERC721A('Munchers', 'MUNCHERS') PaymentSplitter(_payees, _shares) {
        admin = _admin;
        _setDefaultRoyalty(admin, _royaltyFee);
        contractURI = _contractURI;
        maxTokens = _maxTokens;
        maxTokensForFreeMint = _maxTokensForFreeMint;
        reservedTokensAmount = _reservedTokensAmount;
        baseURI = baseURIString;
        payees = _payees;
        shares = _shares;
    }

    /** ------------------------
    MINTING
    ---------------------------- */

    function mint(uint256 quantity) external whenNotPaused {
        runCommonChecks(quantity, maxTokensForFreeMint);
        require(!isPaid, 'paid sale enabled');
        _safeMint(msg.sender, quantity);
    }

    function paidMint(uint256 quantity) external payable whenNotPaused {
        runCommonChecks(quantity, maxTokens);        
        require(isPaid, 'paid sale not active');
        require(msg.value == price * quantity, 'wrong value');
        _safeMint(msg.sender, quantity);
    }

    /** @dev This can only be run once. */
    function mintReservedTokens() external onlyOwner {
        require(!_reservedMinted, 'reserved already minted');
        _safeMint(admin, reservedTokensAmount);
        _reservedMinted = true;
    }

    function runCommonChecks(uint256 quantity, uint256 _maxTokens) internal view {
        require(_saleActive, 'sale not active');
        require(quantity > 0, 'zero qty');
        require(msg.sender == tx.origin, 'not contract mintable');
        require(quantity < maxPerTxn + 1, 'exceeds max per txn');
        require(_getTotalMinted() + quantity < _maxTokens + 1, 'qty exceeds max tokens');
        uint256 mints = _numberMinted(msg.sender);
        require(mints + quantity < maxMintsPerWallet + 1, 'qty exceeds max per wallet');
        require(_getTotalMinted() < _maxTokens + 1, 'max tokens minted');
    }

    /** ------------------------
    OVERRIDES
    ---------------------------- */

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (isRevealed) {
            return super.tokenURI(tokenId);
        }

        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), '.json'));
    }

    /** -----------------------
    GETTERS
    --------------------------- */

    function getSaleActive() external view returns (bool) {
        return _saleActive && !paused();
    }

    function getFreeMintActive() external view returns (bool) {
        return _saleActive && !paused() && !isPaid;
    }

    function getPaidSaleActive() external view returns (bool) {
        return _saleActive && !paused() && isPaid;
    }

    function getTotalMinted() external view returns (uint256) {
        return _totalMinted() - reservedTokensAmount;
    }

    function _getTotalMinted() internal view returns (uint256) {
        return _totalMinted() - reservedTokensAmount;
    }

    /** ----------------------------
    SETTERS - OWNER ONLY
    -------------------------------- */

    function setReservedTokensAmount (uint256 amount) external onlyOwner {
        reservedTokensAmount = amount;
    }

    function reveal(string memory uri) external onlyOwner {
        baseURI = uri;
        isRevealed = true;
    }

    function setIsRevealed(bool revealed) external onlyOwner {
        isRevealed = revealed;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setContractURI(string calldata _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxTokensForFreeMint(uint256 amount) external onlyOwner {
        maxTokensForFreeMint = amount;
    }   
    
    function setMaxTokens(uint256 amount) external onlyOwner {
        maxTokens = amount;
    }

    function setMaxMintsPerWallet(uint256 amount) external onlyOwner {
        maxMintsPerWallet = amount;
    }
 
    function setRoyalty(address _address, uint96 royaltyFee) external onlyOwner {
        _setDefaultRoyalty(_address, royaltyFee);
    }

    function toggleSaleActive() external onlyOwner {
        _saleActive = !_saleActive;
    }

    function enableFreeMintSale() external onlyOwner {
        _saleActive = true;
        isPaid = false;
    }

    function enablePaidSale() external onlyOwner {
        _saleActive = true;
        isPaid = true;
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function releaseFunds(address account) public {
        release(payable(account));
    }
}