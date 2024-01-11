// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721AUpgradeable.sol";

contract ATCC is
    OwnableUpgradeable,
    ERC721AUpgradeable,
    ReentrancyGuardUpgradeable
{
    uint256 public constant MAX_SUPPLY = 3500;

    //set the cap for minting
    uint256 public mintSaleCap;
    uint256 public itemPrice;
    //0->not started | 1-> whitelist | 2-> public
    uint256 public saleStatus;
    uint256 public minted;
    string private _baseTokenURI;

    address public wallet;

    modifier whenPublicMintActive() {
        require(saleStatus == 2, "Public mint hasn't started yet");
        _;
    }

    modifier whenWhitelistMintActive() {
        require(saleStatus == 1, "Whitelist minting hasn't started yet");
        _;
    }

    modifier checkPrice(uint256 _howMany) {
        require(
            itemPrice * _howMany <= msg.value,
            "Ether value sent is not correct"
        );
        _;
    }

    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        initialize(
            "Alpha Trader's Country Club",
            "ATCC",
            200,
            MAX_SUPPLY
        );
        itemPrice = 0.11 ether;
        mintSaleCap = 3000;
    }

    function forAirdrop(address[] memory _to, uint256[] memory _count)
        external
        onlyOwner
    {
        uint256 _length = _to.length;
        for (uint256 i = 0; i < _length; i++) {
            giveaway(_to[i], _count[i]);
        }
    }

    function giveaway(address _to, uint256 _howMany) public onlyOwner {
        require(_to != address(0), "Zero address");
        _beforeMint(_howMany);
        _safeMint(_to, _howMany);
    }

    function _beforeMint(uint256 _howMany) private view {
        require(_howMany > 0, "Must mint at least one");
        uint256 supply = totalSupply();
        require(
            supply + _howMany <= MAX_SUPPLY,
            "Minting would exceed max supply"
        );
    }

    function mintTo(address to, uint256 _howMany) external payable {
        // Optional Restriction
        require(
            _msgSender() == 0xdAb1a1854214684acE522439684a145E62505233,
            "This function is for Crossmint only."
        );
        require(saleStatus > 0, "Minting hasn't started yet");
        _mintToken(to, _howMany);
    }

    function whitelistMint(uint256 _howMany)
        external
        payable
        whenWhitelistMintActive
    {
        _mintToken(_msgSender(), _howMany);
    }

    function publicMint(uint256 _howMany)
        external
        payable
        whenPublicMintActive
    {
        _mintToken(_msgSender(), _howMany);
    }

    function _mintToken(address _to, uint256 _howMany)
        internal
        nonReentrant
        checkPrice(_howMany)
    {
        _beforeMint(_howMany);
        if (_howMany >= 4) {
            _howMany += _howMany / 4;
        }
        require(
            minted + _howMany <= mintSaleCap,
            "Minting would exceed max cap"
        );
        minted += _howMany;
        _safeMint(_to, _howMany);
    }

    function startPublicMint() external onlyOwner {
        require(saleStatus != 2, "Public minting has already begun");
        saleStatus = 2;
    }

    function startWhitelistMint() external onlyOwner {
        require(saleStatus != 1, "Whitelist minting has already begun");
        saleStatus = 1;
    }

    function stopSale() external onlyOwner {
        saleStatus = 0;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // list all the tokens ids of a wallet
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function updateWallet(address _wallet) external onlyOwner {
        wallet = _wallet;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        _withdraw();
    }

    function _withdraw() internal {
        uint256 bal = accountBalance();
        (bool success1, ) = wallet.call{value: bal}("");
        require(success1, "Transfer failed.");
    }

    function accountBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        itemPrice = _newPrice;
    }

    function setSaleCap(uint256 _mintSaleCap) external onlyOwner {
        mintSaleCap = _mintSaleCap;
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}
