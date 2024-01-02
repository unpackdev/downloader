// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

contract GrandLine is ERC721, AccessControl, ReentrancyGuard {
    /*----- Struct -----*/
    struct Tier {
        uint256 price;
        uint256 maxSupply;
        uint256 minted;
        mapping(address => uint256) mintedPerAddress;
    }

    /*----- State Variables -----*/
    uint256 public totalMinted;
    uint256 private _nextTokenId;
    address public treasuryAddress;
    string public baseURI;
    bool public isMintAvailable;

    /*----- Mapping -----*/
    mapping(string => Tier) public tiers;
    mapping(uint256 => string) public tokenIdToTier;
    mapping(address => uint256) public userMintedAmount;

    /*----- Events -----*/
    event BaseURIChanged(string baseURI);
    event TreasuryAddressChanged(address treasuryAddress);
    event MintAvailableChanged(bool isMintAvailable);
    event Minted(address indexed to, uint256 amount, string tier, uint256[] tokenIds);

    /**
     * @dev fallback function
     */
    fallback() external {
        revert();
    }

    /**
     * @dev fallback function
     */
    receive() external payable {
        revert();
    }

    constructor(address _admin, address _treasuryAddress, string memory _baseUri) ERC721("GrandLine", "GrandLine") {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        treasuryAddress = _treasuryAddress;
        baseURI = _baseUri;
        isMintAvailable = false;

        Tier storage freeTier = tiers["Free"];
        freeTier.price = 0;
        freeTier.maxSupply = 1000;

        Tier storage silverTier = tiers["Silver"];
        silverTier.price = 0.01 ether;
        silverTier.maxSupply = 3000;

        Tier storage goldTier = tiers["Gold"];
        goldTier.price = 0.02 ether;
        goldTier.maxSupply = 900;

        Tier storage spiritTier = tiers["Spirit"];
        spiritTier.price = 0.04 ether;
        spiritTier.maxSupply = 100;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(baseURI_).length > 0, "Invalid base URI");
        baseURI = baseURI_;
        emit BaseURIChanged(baseURI);
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_treasuryAddress != address(0), "Invalid treasury address");
        require(treasuryAddress != _treasuryAddress, "Same treasury address");
        treasuryAddress = _treasuryAddress;
        emit TreasuryAddressChanged(treasuryAddress);
    }

    function setMintAvailable(bool _isMintAvailable) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isMintAvailable != _isMintAvailable, "Same value");
        isMintAvailable = _isMintAvailable;
        emit MintAvailableChanged(isMintAvailable);
    }

    function mintBatch(uint256 _amount, string memory _tier) external payable nonReentrant {
        require(isMintAvailable, "Mint is not available");
        require(_amount > 0, "Invalid amount");
        require(tiers[_tier].maxSupply > 0, "Invalid tier");
        require(tiers[_tier].minted + _amount <= tiers[_tier].maxSupply, "Exceeds max supply");
        address user = _msgSender();

        // one user can only mint 1 NFT in free tier
        if (keccak256(abi.encodePacked(_tier)) == keccak256(abi.encodePacked("Free"))) {
            require(tiers[_tier].mintedPerAddress[user] == 0, "Only one free NFT per address");
        }

        require(msg.value >= tiers[_tier].price * _amount, "Not enough payment");
        require(userMintedAmount[user] + _amount <= 5, "Exceeds max mint per address");

        uint256[] memory tokenIds = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            ++_nextTokenId;
            _safeMint(user, _nextTokenId);
            tokenIdToTier[_nextTokenId] = _tier;
            tokenIds[i] = _nextTokenId;
        }

        tiers[_tier].minted += _amount;
        tiers[_tier].mintedPerAddress[user] += _amount;
        userMintedAmount[user] += _amount;
        totalMinted += _amount;

        uint256 totalPrice = tiers[_tier].price * _amount;

        if (msg.value > totalPrice) {
            Address.sendValue(payable(msg.sender), msg.value - totalPrice);
            Address.sendValue(payable(treasuryAddress), totalPrice);
        } else {
            Address.sendValue(payable(treasuryAddress), msg.value);
        }

        emit Minted(user, _amount, _tier, tokenIds);
    }

    function getUserMintedAmount(address _user, string memory _tier) external view returns (uint256) {
        return tiers[_tier].mintedPerAddress[_user];
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
