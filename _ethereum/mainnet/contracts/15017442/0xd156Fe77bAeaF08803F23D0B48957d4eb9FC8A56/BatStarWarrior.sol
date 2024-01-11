// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC721A.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract BatStarWarrior is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeERC20 for IERC20;
    string public baseURI;
    address public tokenContract;

    // limit of minted tokens
    uint256 public constant PUBLIC_SALE_MAX_AMOUNT = 4000;
    uint256 public constant PRE_SALE_MAX_AMOUNT = 6000;
    uint256 public constant MAX_SUPPLY = 12000;

    // sale price
    uint256 public publicSalePrice = 0.02 ether;
    uint256 public preSalePrice = 0.005 ether;

    // address limit of minted tokens
    uint256 public constant PUBLIC_SALE_MAX_MINT_LIMIT = 5;
    uint256 public constant PRE_SALE_MAX_MINT_LIMIT = 3;
    mapping(address => uint256) private addressPublicSaleMinted;
    mapping(address => uint256) private addressPreSaleMinted;

    // sale time
    uint256 public publicSaleStartTime = 1656302400;
    uint256 public preSaleStartTime = 1656129600;
    uint256 public publicSaleDuration = 172800;
    uint256 public preSaleDuration = 172800;

    // sale status
    bool public publicSaleActive = false;
    bool public preSaleActive = false;
    bool public adminClaimStarted = false;

    // sold tokens
    uint256 public publicSaleAmountMinted;
    uint256 public preSaleAmountMinted;

    //pre
    bytes32 public preMerkleRoot;

    //revealed
    bool public revealed = false;
    string public notRevealedUri;

    error ExceedsPublicSaleSupply();
    error ExceedsPreSaleSupply();
    error ExceedsAllocatedForPublicSale();
    error ExceedsPublicSaleMintLimit();
    error ExceedsPreSaleMintLimit();
    error InsufficientETHSent();
    error PublicSaleInactive();
    error PreSaleInactive();
    error ExceedsMaxSupply();
    error WithdrawalFailed();
    error UnAuthorizedRequest();

    event Minted(
        address indexed sender,
        uint256 indexed amount,
        uint256 indexed mintPrice
    );
    event PublicSaleStart(
        uint256 indexed _saleDuration,
        uint256 indexed _saleStartTime
    );
    event PublicSaleStop(
        uint256 indexed _currentPrice,
        uint256 indexed _timeElapsed
    );
    event PreSaleStart(
        uint256 indexed _saleDuration,
        uint256 indexed _saleStartTime
    );
    event PreSaleStop(
        uint256 indexed _currentPrice,
        uint256 indexed _timeElapsed
    );

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier whenPublicSaleActive() {
        require(
            isPublicSaleStart() && !adminClaimStarted,
            "Public sale is not active"
        );
        _;
    }
    modifier whenPreSaleActive() {
        require(
            isPreSaleStart() && !adminClaimStarted,
            "Pre sale is not active"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initNotRevealedUri
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initNotRevealedUri);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function startPublicSale(
        uint256 _saleStartTime,
        uint256 _saleDuration,
        uint256 _salePrice
    ) external onlyOwner {
        publicSaleDuration = _saleDuration;
        publicSaleStartTime = _saleStartTime;
        publicSalePrice = _salePrice;
        publicSaleActive = true;
        emit PublicSaleStart(publicSaleDuration, publicSaleStartTime);
    }

    function stopPublicSale() external onlyOwner {
        publicSaleActive = false;
        emit PublicSaleStop(
            publicSalePrice,
            block.timestamp - publicSaleStartTime
        );
    }

    function startPreSale(
        uint256 _saleStartTime,
        uint256 _saleDuration,
        uint256 _salePrice
    ) external onlyOwner {
        preSaleDuration = _saleDuration;
        preSaleStartTime = _saleStartTime;
        preSalePrice = _salePrice;
        preSaleActive = true;
        emit PreSaleStart(preSaleDuration, preSaleStartTime);
    }

    function stopPreSale() external onlyOwner {
        preSaleActive = false;
        emit PreSaleStop(preSalePrice, block.timestamp - preSaleStartTime);
    }

    function isPublicSaleStart() public view returns (bool) {
        return
            publicSaleActive &&
            publicSaleStartTime > 0 &&
            block.timestamp >= publicSaleStartTime &&
            block.timestamp <= publicSaleStartTime + publicSaleDuration;
    }

    function isPreSaleStart() public view returns (bool) {
        return
            preSaleActive &&
            preSaleStartTime > 0 &&
            block.timestamp >= preSaleStartTime &&
            block.timestamp <= preSaleStartTime + preSaleDuration;
    }

    function publicSale(uint256 _amount)
        external
        payable
        nonReentrant
        whenPublicSaleActive
        callerIsUser
    {
        require(_amount > 0, "Must mint at least one nft");

        if (_totalMinted() + _amount > MAX_SUPPLY) revert ExceedsMaxSupply();

        if (publicSaleAmountMinted + _amount > PUBLIC_SALE_MAX_AMOUNT)
            revert ExceedsPublicSaleSupply();

        if (
            addressPublicSaleMinted[msg.sender] + _amount >
            PUBLIC_SALE_MAX_MINT_LIMIT
        ) revert ExceedsPublicSaleMintLimit();

        if (_amount * publicSalePrice > msg.value) revert InsufficientETHSent();

        publicSaleAmountMinted += _amount;
        addressPublicSaleMinted[msg.sender] += _amount;
        _mint(msg.sender, _amount);
        emit Minted(msg.sender, _amount, publicSalePrice);
    }

    function preSale(uint256 _amount, bytes32[] memory _proof)
        public
        payable
        nonReentrant
        whenPreSaleActive
        callerIsUser
    {
        require(isPreAllowlist(msg.sender, _proof), "Not a part of Allowlist");
        require(_amount > 0, "Must mint at least one nft");

        if (_totalMinted() + _amount > MAX_SUPPLY) revert ExceedsMaxSupply();

        if (preSaleAmountMinted + _amount > PRE_SALE_MAX_AMOUNT) {
            revert ExceedsPreSaleSupply();
        }

        if (
            addressPreSaleMinted[msg.sender] + _amount > PRE_SALE_MAX_MINT_LIMIT
        ) revert ExceedsPreSaleMintLimit();

        if (_amount * preSalePrice > msg.value) revert InsufficientETHSent();

        preSaleAmountMinted += _amount;
        addressPreSaleMinted[msg.sender] += _amount;
        _mint(msg.sender, _amount);
        emit Minted(msg.sender, _amount, preSalePrice);
    }

    function claimUnclaimedAndUnsoldWithAmount(
        address recipient,
        uint256 amount
    ) public onlyOwner {
        require(amount < MAX_SUPPLY && amount > 0, "Invalid amount");
        adminClaimStarted = true;
        uint256 totalMinted = _totalMinted();
        uint256 toBeMint = MAX_SUPPLY - totalMinted;
        uint256 toMint = amount < toBeMint ? amount : toBeMint;
        _mint(recipient, toMint);
        emit Minted(recipient, amount, 0);
    }

    function toggleAdminClaimStarted() external onlyOwner {
        adminClaimStarted = !adminClaimStarted;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            Address.sendValue(payable(owner()), balance);
        }
    }

    function withdrawERC20() external onlyOwner nonReentrant {
        uint256 balance = IERC20(tokenContract).balanceOf(address(this));
        if (balance > 0) {
            IERC20(tokenContract).safeTransfer(owner(), balance);
        }
    }

    function setTokenContract(address newTokenContract) external onlyOwner {
        tokenContract = newTokenContract;
    }

    function toggleSaleStatus(bool _publicSaleActive, bool _preSaleActive)
        external
        onlyOwner
    {
        publicSaleActive = _publicSaleActive;
        preSaleActive = _preSaleActive;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721AMetadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    function setPreMerkleRoot(bytes32 _root) external onlyOwner {
        preMerkleRoot = _root;
    }

    function isPreAllowlist(address _address, bytes32[] memory _proof)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _proof,
                preMerkleRoot,
                keccak256(abi.encodePacked(_address))
            );
    }

    function setPublicSalePrice(uint256 _price) external onlyOwner {
        publicSalePrice = _price;
    }

    function setPreSalePrice(uint256 _price) external onlyOwner {
        preSalePrice = _price;
    }

    function getAddressPublicSaleMinted(address _address)
        public
        view
        returns (uint256)
    {
        return addressPublicSaleMinted[_address];
    }

    function getAddressPreSaleMinted(address _address)
        public
        view
        returns (uint256)
    {
        return addressPreSaleMinted[_address];
    }

    function getRemainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - _totalMinted();
    }

    function getRemainingPublicSaleSupply() public view returns (uint256) {
        return PUBLIC_SALE_MAX_AMOUNT - publicSaleAmountMinted;
    }

    function getRemainingPreSaleSupply() public view returns (uint256) {
        return PRE_SALE_MAX_AMOUNT - preSaleAmountMinted;
    }
}
