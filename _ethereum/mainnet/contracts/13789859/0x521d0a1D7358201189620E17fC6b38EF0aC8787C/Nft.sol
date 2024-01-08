// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UUPSUpgradeable.sol";
import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

contract NFT is
    Initializable,
    UUPSUpgradeable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant TIER1_ROLE = keccak256("TIER1_ROLE");
    bytes32 public constant TIER2_ROLE = keccak256("TIER2_ROLE");
    bytes32 public constant TIER3_ROLE = keccak256("TIER3_ROLE");
    bytes32 public constant TIER4_ROLE = keccak256("TIER4_ROLE");
    
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint16;

    // Mapping user address to check if token is claimed by user.
    mapping(address => mapping(bytes32 => bool)) public claimed;
    // Mapping to track the total supply by the end of each tier
    mapping(bytes32 => uint256) public tierTotalSupply;
    // Mapping to keep track of the claimed token. It will mint new token after the current token
    mapping(bytes32 => uint256) public tierTotalClaimed;

    uint256 public constant MAX_SUPPLY = 10000;
    string _baseURIValue;

    function initialize() public initializer {
        ERC721Upgradeable.__ERC721_init("Token Metrics NFT", "TMNFT");
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        AccessControlUpgradeable.__AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        tierTotalSupply[TIER1_ROLE] = 8890;
        tierTotalSupply[TIER2_ROLE] = 9890;
        tierTotalSupply[TIER3_ROLE] = 9990;
        tierTotalSupply[TIER4_ROLE] = 10000;
        tierTotalClaimed[TIER2_ROLE] = 8890;
        tierTotalClaimed[TIER3_ROLE] = 9890;
        tierTotalClaimed[TIER4_ROLE] = 9990;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory newBase) external onlyOwner {
        _baseURIValue = newBase;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setClaimableRole(address[] memory claimableAddress, bytes32 _role)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(tierTotalSupply[_role] > 0, "Role not added");
        for (uint256 i = 0; i < claimableAddress.length; i++) {
            _setupRole(_role, claimableAddress[i]);
        }
    }

    function claimNFT(bytes32 _role) external whenNotPaused nonReentrant {
        require(hasRole(_role, msg.sender), "Caller cannot claim");
        require(tierTotalSupply[_role] > 0, "Role not added");
        require(totalSupply() < MAX_SUPPLY, "Max supply limit reached");
        require(
            tierTotalClaimed[_role] < tierTotalSupply[_role],
            "Max supply limit reached for tier"
        );
        require(!claimed[msg.sender][_role], "Token already claimed");
        claimed[msg.sender][_role] = true;
        _safeMint(_msgSender(), tierTotalClaimed[_role]);
        tierTotalClaimed[_role] = tierTotalClaimed[_role].add(1);
    }

    function _authorizeUpgrade(address) internal override {
        require(owner() == msg.sender, "Only owner can upgrade implementation");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
