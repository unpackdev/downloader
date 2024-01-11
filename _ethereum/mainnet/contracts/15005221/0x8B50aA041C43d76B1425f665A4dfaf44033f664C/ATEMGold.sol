// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Address.sol";

error Paused();
error NotMintingTimeYet();
error MintZeroAmount();
error MaxMintAmount();
error SupplyExceeded();
error NotWhitelisted();
error NotEnoughValue();

contract ATEMGold is ERC721A, Ownable {
    string baseURI;
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmount = 10;
    uint256 public timeDeployed;
    uint256 public allowMintingAfter = 0;
    bool public isPaused = true;
    bool public isRevealed = true;
    string public notRevealedUri;

    bool public isPresale = false;
    mapping(address => bool) private _whitelist;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _allowMintingOn,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721A(_name, _symbol) {
        if (_allowMintingOn > block.timestamp) {
            allowMintingAfter = _allowMintingOn - block.timestamp;
        }

        cost = _cost;
        maxSupply = _maxSupply;
        timeDeployed = block.timestamp;

        setBaseURI(_initBaseURI);

        if (bytes(_initNotRevealedUri).length > 0) {
            setIsRevealed(false);
            setNotRevealedURI(_initNotRevealedUri);
        }
    }

    receive() external payable {
        uint256 mintAmount = msg.value / cost;
        __mint(mintAmount);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        __mint(_mintAmount);
    }

    function __mint(uint256 _mintAmount) internal {
        if (block.timestamp < timeDeployed + allowMintingAfter)
            revert NotMintingTimeYet();
        if (isPaused) revert Paused();
        if (_mintAmount == 0) revert MintZeroAmount();
        if (_mintAmount > maxMintAmount) revert MaxMintAmount();

        uint256 supply = totalSupply();

        if (supply + _mintAmount > maxSupply) revert SupplyExceeded();

        if (isPresale && !_whitelist[msg.sender]) revert NotWhitelisted();

        if (msg.sender != owner()) {
            if (msg.value < cost * _mintAmount) revert NotEnoughValue();
        }

        if (msg.value > 0) {
            uint256 change = msg.value - cost * _mintAmount;
            if (change > 0) Address.sendValue(payable(msg.sender), change);
        }

        _safeMint(msg.sender, _mintAmount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        // run ERC721A validation - ignore returned value
        ERC721A.tokenURI(tokenId);

        if (!isRevealed) {
            return notRevealedUri;
        }

        return _baseURI();
    }

    function getSecondsUntilMinting() public view returns (uint256) {
        if (block.timestamp < timeDeployed + allowMintingAfter) {
            return (timeDeployed + allowMintingAfter) - block.timestamp;
        } else {
            return 0;
        }
    }

    // Only Owner Functions
    function setIsRevealed(bool _state) public onlyOwner {
        isRevealed = _state;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setIsPaused(bool _state) public onlyOwner {
        isPaused = _state;
    }

    function withdraw() public onlyOwner {
        address fund = 0xd74ECbb623294d63f554a08B72800cB3CC533E78;
        address apoc = 0xf1E2d8FB4315e45B894db7A94b7447673a031678;
        address jn = 0x114aABf27Bc8e24e52cfDFC8f8939da2a140391d;
        address js = 0x0f7F8c28Bbcf4D1Dd6D09C1c8CE5c8919969CA84;
        address ac = 0xbdd143d9971079AE06b06Dc578F2587922d0da83;
        address ik = 0x83088Df71010fBcF29cDCc021B16D4f0D8297C40;

        uint256 ethBalance = address(this).balance;

        Address.sendValue(payable(jn), (ethBalance * 51) / 100); // 51%
        Address.sendValue(payable(fund), (ethBalance * 20) / 100); // 20%
        Address.sendValue(payable(apoc), (ethBalance * 13) / 100); // 13%
        Address.sendValue(payable(ac), (ethBalance * 12) / 100); // 12%
        Address.sendValue(payable(js), (ethBalance * 2) / 100); // 2%
        Address.sendValue(payable(ik), (ethBalance * 2) / 100); // 2%
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setIsPresale(bool _isPresale) external onlyOwner {
        isPresale = _isPresale;
    }

    function setWhitelist(address[] memory addresses, bool onoff)
        external
        onlyOwner
    {
        for (uint256 i; i < addresses.length; i++) {
            _whitelist[addresses[i]] = onoff;
        }
    }
}
