pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";


contract YetiTown is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 private whitelistSaleStartDate;
    string private baseURI;
    string public baseExtension = ".json";
    uint256 public preSaleCost = 0 ether;
    uint256 public publicSaleCost = 0 ether;
    uint256 public maxSupply = 5555;

    // maximum number of Minting per wallet
    uint256 public maxAmountPerWallet = 1500;
    // paused flag
    bool public paused = false;
    // hidden image url
    string public notRevealedUri;
    // State Variable for storing current TokenID
    uint256 nextTokenId = 1;
    // the last tokenId of WL sale
    uint256 public lastMagicTokenID = 0;
    uint256 public curTreasuryTokenAmount = 0;
    bool public publicSaleFlag = false;

    mapping(address => bool) public whitelist;

    event YetiMinted(uint256 indexed tokenId);
    event YetiBurned(uint256 indexed tokenId);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    modifier blockTradeIfNot24hrPassed() {
        // frens can always call whenever they want :)
        uint256 _timeSpent = (block.timestamp - whitelistSaleStartDate) / 3600;
        require(_timeSpent > 24);        
        _;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused);
        require(_mintAmount > 0, "Must at least mint 1 yeti");
        require(
            balanceOf(msg.sender) + _mintAmount <= maxAmountPerWallet,
            "Can not mint exceed 6 yetis per wallet"
        );
//        require(_mintAmount <= 3, "Amount must be less than 3 Yetis");
        require((nextTokenId + _mintAmount - 1) <= maxSupply);

        uint256 _currentCost = 100 ether;
        uint256 _timeSpent = (block.timestamp - whitelistSaleStartDate) / 3600;
        if (_timeSpent >= 24) {
            if (!publicSaleFlag) {
                nextTokenId = lastMagicTokenID + 46;
                publicSaleFlag = true;
            }
            _currentCost = publicSaleCost;
        } else {
            require(
                whitelist[msg.sender],
                "You are not in the whitelist to mint Yetis"
            );
            lastMagicTokenID += _mintAmount;
            _currentCost = preSaleCost;
        }

        if (msg.sender != owner()) {
            require(msg.value >= _currentCost * _mintAmount);
        }

        for (uint256 i = 0; i < _mintAmount; i++) {
            if (!_exists(nextTokenId)) {
                emit YetiMinted(nextTokenId);
                _safeMint(msg.sender, nextTokenId);
                nextTokenId++;
            }
        }
    }

    // public
    // Mint for tresury
    function tresuryPresaleMint(address _to, uint256 _amount) public onlyOwner {
        require(!paused);

        require(_amount > 0, "Invalid amount");
        require(
            lastMagicTokenID + _amount <= maxSupply,
            "Cannot exceed maximum number of supply."
        );
        require(
            curTreasuryTokenAmount + _amount <= 45,
            "Cannot exceed max number of Treasury Sale Amount"
        );

        for (uint256 j = 1; j <= _amount; j++) {
            if (!_exists(lastMagicTokenID + j)) {
                emit YetiMinted(lastMagicTokenID + j);
                _safeMint(_to, (lastMagicTokenID + j));
            }
        }
        lastMagicTokenID += _amount;
        curTreasuryTokenAmount += _amount;
    }

    // public

    // Mint for tresury in the case of mint doesn't sell out
    function tresuryMint(address _to, uint256 _amount) public onlyOwner {
        require(_amount > 0, "Invalid amount");
        require(
            nextTokenId + _amount - 1 <= maxSupply,
            "Cannot exceed maximum number of supply."
        );

        for (uint256 j = 1; j <= _amount; j++) {
            if (!_exists(nextTokenId)) {
                emit YetiMinted(nextTokenId);
                _safeMint(_to, nextTokenId);
                nextTokenId += 1;
            }
        }
    }

    /**
     * Burn a token - any game logic should be handled before this function.
     */
    function burn(uint256 tokenId) external onlyOwner{        
        emit YetiBurned(tokenId);
        _burn(tokenId);
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
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256 _timeSpent = (block.timestamp - whitelistSaleStartDate) / 3600;

        if (_timeSpent < 48) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override blockTradeIfNot24hrPassed{
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override blockTradeIfNot24hrPassed{
        
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override blockTradeIfNot24hrPassed{
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        
        _safeTransfer(from, to, tokenId, _data);
    }

    function addToWhitelist(address _address) public onlyOwner {
        if (!whitelist[_address]) {
            whitelist[_address] = true;
        }
    }

    function flipWhitelistApproveStatus(address _address) public onlyOwner {
        whitelist[_address] = !whitelist[_address];
    }

    function addressIsPresaleApproved(address _address)
        public
        view
        returns (bool)
    {
        return whitelist[_address];
    }

    function initPresaleWhitelist(address[] memory addr) public onlyOwner {
        for (uint256 i = 0; i < addr.length; i++) {
            whitelist[addr[i]] = true;
        }
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setWhitelistSaleStartDate() public onlyOwner {        
        whitelistSaleStartDate = block.timestamp;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function NextTokenId() public view returns (uint256) {
        return nextTokenId;
    }
}