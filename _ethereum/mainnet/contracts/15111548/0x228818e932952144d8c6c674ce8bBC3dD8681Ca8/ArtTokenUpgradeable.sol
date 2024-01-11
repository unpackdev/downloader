// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721AUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./PaymentSplitterUpgradeable.sol";
import "./MerkleAllowListUpgradeable.sol";
import "./DenyListUpgradeable.sol";

contract ArtTokenUpgradeable is
    ERC721AUpgradeable,
    OwnableUpgradeable,
    PaymentSplitterUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    DenyListUpgradeable,
    MerkleAllowListUpgradeable
{
    uint16 public maxPerMint;
    uint16 public maxSupply;
    uint256 public royaltiesPercentage;
    address public royaltiesReceiver;
    string public openBaseURI;
    string public closedBaseURI;
    bool public isOpen;

    function initialize(string memory _name, string memory _symbol)
        public
        initializer
        initializerERC721A
    {
        isOpen = false;
        maxPerMint = 2;
        maxSupply = 10000;
        isAllowlistEnabled = true;
        royaltiesReceiver = address(this);
        royaltiesPercentage = 100;

        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __ERC721A_init(_name, _symbol);
    }

    function setSecondaryRoyalty(address _receiver, uint256 _percentage)
        public
        onlyOwner
    {
        royaltiesReceiver = _receiver;
        royaltiesPercentage = _percentage;
    }

    function setClosedBaseURI(string memory baseURI_) public onlyOwner {
        closedBaseURI = baseURI_;
    }

    function setOpenBaseURI(string memory baseURI_) public onlyOwner {
        openBaseURI = baseURI_;
    }

    function setIsOpen(bool _isOpen) public onlyOwner {
        isOpen = _isOpen;
    }

    function setMaxPerMint(uint16 _quantity) public onlyOwner {
        maxPerMint = _quantity;
    }

    function setMaxSupply(uint16 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function addPayee(address account, uint256 shares_) public onlyOwner {
        _addPayee(account, shares_);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(uint256 _quantity)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(!isAllowlistEnabled, "whitelist enabled");

        _beforeMint(_quantity, maxPerMint);
        _safeMint(msg.sender, _quantity);
        _afterMint(_quantity);
    }

    function mintWithProof(
        uint256 _quantity,
        uint256 _max,
        bytes32[] memory _proof
    ) external payable nonReentrant whenNotPaused {
        require(isAllowlistEnabled, "whitelist disabled");

        isWhitelisted(_proof, _max);

        _beforeMint(_quantity, _max);
        _safeMint(msg.sender, _quantity);
        _afterMint(_quantity);
    }

    function _beforeMint(uint256 _quantity, uint256 _max) private view {
        require(totalSupply() + _quantity <= maxSupply, "max supply exceeded");
        require(
            _quantity <= (_max - _minted[_msgSender()]),
            "max to mint exceeded"
        );

        if (isDenylistEnabled) {
            require(!_denylist[_msgSender()], "in denylist");
        }
    }

    function _afterMint(uint256 _quantity) private {
        _minted[_msgSender()] += _quantity;
    }

    /* solhint-disable no-unused-vars */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 _royalties = (_salePrice * royaltiesPercentage) / 100;
        return (royaltiesReceiver, _royalties);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = closedBaseURI;

        if (isOpen) {
            baseURI = openBaseURI;
        }

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
