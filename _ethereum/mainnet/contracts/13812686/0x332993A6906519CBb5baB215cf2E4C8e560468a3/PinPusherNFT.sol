// SPDX-License-Identifier: MI
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
contract PinPusherNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    string public NotRevealedUri;

    uint256 public constant MAX_PUSHERS = 3333;
    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant MAX_PER_MINT = 6;
    uint256 public constant PRESALE_MAX_MINT = 3;
    uint256 public constant MAX_PUSHERS_MINT = 6;
    uint256 public constant RESERVED_PUSHERS = 100;
    address public constant founderAddress = 0x9C87A1065994f156f0B7b87AAa8B3c5F7BD67E02;
    address public constant devAddress = 0x67A0D600191AFa0E0F9a1305310C8872F5D28Bb9;
    address public constant dev2Address = 0x232F32A4C6559bf4b9cB3D6614C916C8B27ACf70;
    address public constant enigmaAddress = 0x917A4C1CcaEc78875cB97654f9c051979bE59fC2;
    address public constant gutsAddress = 0x85accD7543134aEaa43500248bF5d892B3Fd8357;
    address public constant missyAddress = 0x8B2C292Dd0fc2b0055a19cb887052952724AD05C;
    
    uint256 public reservedClaimed;
    uint256 public numPushersMinted;
    bool public publicSaleStarted;
    bool public revealed = false;
    bool public paused = false;
    mapping(address => bool) private whitelisted;
    mapping(address => uint256) private _totalClaimed;
    event BaseURIChanged(string baseURI);
    event PresaleMint(address minter, uint256 amountOfPushers);
    event PublicSaleMint(address minter, uint256 amountOfPushers);
    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Pin Pusher NFT Public Sale Has Not Begun");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function claimReserved(address recipient, uint256 amount) external onlyOwner {
        require(reservedClaimed != RESERVED_PUSHERS, "All reserved Pin Pushers are already claimed");
        require(reservedClaimed + amount <= RESERVED_PUSHERS, "Minting would exceed max Pin Pushers reserved");
        require(recipient != address(0), "Cannot add null address");
        require(totalSupply() < MAX_PUSHERS, "Too late. Go to secondary to buy a Pin Pusher!");
        require(totalSupply() + amount <= MAX_PUSHERS, "Max Supply reached!");
        uint256 _nextTokenId = numPushersMinted + 1;
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(recipient, _nextTokenId + i);
        }
        numPushersMinted += amount;
        reservedClaimed += amount;
    }
    function checkPresaleEligiblity(address addr) external view returns (bool) {
        return whitelisted[addr];
    }
    function amountClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "Cannot add null address");

        return _totalClaimed[owner];
    }
    function mint(uint256 amountOfPushers) external payable whenPublicSaleStarted {
        require(totalSupply() < MAX_PUSHERS, "All PinPusherNFTs have been minted");
        require(amountOfPushers <= MAX_PER_MINT, "Amount requested is higher than the amount allowed.");
        require(totalSupply() + amountOfPushers <= MAX_PUSHERS, "Minting would exceed max supply");
        require(
            _totalClaimed[msg.sender] + amountOfPushers <= MAX_PUSHERS_MINT,
            "Purchase exceeds max allowed per address"
        );
        require(amountOfPushers > 0, "Must mint at least one Pusher");
        require(PRICE * amountOfPushers == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfPushers; i++) {
            uint256 tokenId = numPushersMinted + 1;

            numPushersMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }
        emit PublicSaleMint(msg.sender, amountOfPushers);
    }
    function reveal() public onlyOwner {
        revealed = true;
    }
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return NotRevealedUri;
        }
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
    }
    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }
    function setBaseURI(string memory _initBaseURI) public onlyOwner {
        baseURI = _initBaseURI;
    }
    function setNotRevealedURI(string memory _NotRevealedURI) public onlyOwner {
        NotRevealedUri = _NotRevealedURI;
    }
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
    function whitelistUser(address[] calldata addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");
            whitelisted[addresses[i]] = true;
            _totalClaimed[addresses[i]] > 0 ? _totalClaimed[addresses[i]] : 0;
        }
    }
    function removeWhitelistUser(address[] calldata addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");
            whitelisted[addresses[i]] = false;
        }
    }
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(gutsAddress, ((balance * 15) / 100));
        _widthdraw(devAddress, ((balance * 15) / 100));
        _widthdraw(dev2Address, ((balance * 10) / 100));
        _widthdraw(enigmaAddress, ((balance * 10) / 100));
        _widthdraw(missyAddress, ((balance * 10) / 100));
        _widthdraw(founderAddress, address(this).balance);
    }
    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }
}