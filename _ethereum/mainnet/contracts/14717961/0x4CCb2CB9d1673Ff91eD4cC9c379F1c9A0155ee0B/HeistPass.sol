// SPDX-License-Identifier: MIT LICENSE

/**
       .     '     ,      '     ,     .     '   .    
      _________        _________       _________    
   _ /_|_____|_\ _  _ /_|_____|_\ _ _ /_|_____|_\ _ 
     '. \   / .'      '. \   / .'     '. \   / .'   
       '.\ /.'          '.\ /.'         '.\ /.'     
         '.'              '.'             '.'
 
 ██████╗ ██╗ █████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██████╗  
 ██╔══██╗██║██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██╔══██╗ 
 ██║  ██║██║███████║██╔████╔██║██║   ██║██╔██╗ ██║██║  ██║ 
 ██║  ██║██║██╔══██║██║╚██╔╝██║██║   ██║██║╚██╗██║██║  ██║ 
 ██████╔╝██║██║  ██║██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██████╔╝ 
 ╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝  
           ██╗  ██╗███████╗██╗███████╗████████╗
           ██║  ██║██╔════╝██║██╔════╝╚══██╔══╝   <'l    
      __   ███████║█████╗  ██║███████╗   ██║       ll    
 (___()'`; ██╔══██║██╔══╝  ██║╚════██║   ██║       llama~
 /,    /`  ██║  ██║███████╗██║███████║   ██║       || || 
 \\"--\\   ╚═╝  ╚═╝╚══════╝╚═╝╚══════╝   ╚═╝       '' '' 

*/

pragma solidity ^0.8.0;
import "./MerkleProof.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC721AUpgradeable.sol";
import "./IDIAMOND.sol";

contract HeistPass is
    ERC721AUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    event PassBurned(uint256 indexed tokenId, address indexed creator);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    event Minted(uint256 indexed tokenId);
    uint256 private _communityMinted;

    // Mapping from token ID to referrer
    mapping(uint256 => address) internal _referrals;
    mapping(address => uint256) internal _referralRewards;

    uint256 public MAX_TOKENS;
    uint256 public MINT_PRICE;
    uint256 public SHARE_PRICE;
    string private baseURI;

    IDIAMOND public diamond;
    address public diamondheist;
    address public royaltyAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC721A_init("Heist Pass", "HEISTPASS");
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);

        MAX_TOKENS = 1000;
        MINT_PRICE = 500 ether;
        _communityMinted = 0;
        SHARE_PRICE = 0.01 ether;

        baseURI = "https://api.diamondheist.game/heistPass.json";

        pause();
    }

    function setContracts(
        IDIAMOND _diamond,
        address _diamondheist,
        address _royaltyAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        diamond = _diamond;
        diamondheist = _diamondheist;
        royaltyAddress = _royaltyAddress;
    }

    function minted() external view returns (uint256) {
        return _communityMinted;
    }

    function getFee(uint256 amount) external view returns (uint256) {
        return SHARE_PRICE * amount;
    }

    function getReferrer(uint256 tokenId) public view returns (address) {
        return _referrals[tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721AUpgradeable)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return string(abi.encodePacked(
            baseURI,
            "?tokenId=",
            StringsUpgradeable.toString(tokenId),
            "&referrer=",
            StringsUpgradeable.toHexString(uint256(uint160(_referrals[tokenId])))
        ));
    }

    function setBaseURI(string calldata _baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _baseURI;
    }

    function mintPass(uint256 amount, address dest, address referrer) internal {
        uint256 tokenId = uint16(_totalMinted());
        for (uint256 i = 1; i <= amount; i++) {
            _referrals[tokenId + i] = referrer;
        }
        _mint(dest, amount, "", false);
    }

    function mint(uint256 amount, address dest) external whenNotPaused nonReentrant {
        require(amount > 0 && amount <= 15, "MINT_AMOUNT_INVALID");
        require(tx.origin == _msgSender(), "ONLY_EOA");
        _communityMinted += amount;
        require(_communityMinted <= MAX_TOKENS, "MINT_ENDED");

        mintPass(amount, dest, _msgSender());
        diamond.transferFrom(_msgSender(), royaltyAddress, amount * MINT_PRICE);
    }

    function mintCommunity(address[] calldata dest, uint256[] calldata amounts, address referrer) external onlyRole(MINTER_ROLE) {
        uint256 tokenId = uint16(_totalMinted()) + 1;
        for (uint256 i = 0; i < dest.length; i++) {
            _referrals[tokenId + i] = referrer;
            _mint(dest[i], amounts[i], "", false);
        }
    }

    function burn(address to, uint256[] memory tokenIds) external payable whenNotPaused nonReentrant onlyRole(BURNER_ROLE) {
        require(balanceOf(to) >= tokenIds.length && tokenIds.length > 0, "INVALID_PASS_AMOUNT");
        require(msg.value == SHARE_PRICE * tokenIds.length, "PAYMENT_INVALID");

        for (uint16 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i], true);
            address referrer = getReferrer(tokenIds[i]);
            _referralRewards[referrer] += SHARE_PRICE;
            emit PassBurned(tokenIds[i], referrer);
        }
    }

    /** Allows referrers to receive their rewards */
    function withdrawRewards() external whenNotPaused nonReentrant {
        require(_msgSender() == tx.origin, "ONLY_EOA");

        uint256 rewards = _referralRewards[_msgSender()];
        require(rewards > 0, "NO_REWARDS");
        _referralRewards[_msgSender()] = 0;

        payable(_msgSender()).transfer(rewards);
    }

    function getRewards(address recipient) external view returns (uint256) {
        return _referralRewards[recipient];
    }

    function isApprovedForAll(address owner, address operator) public view override(ERC721AUpgradeable) returns (bool) {
        return (address(diamondheist) == operator || ERC721AUpgradeable.isApprovedForAll(owner, operator));
    }

    function setMintPrice(uint256 _mintPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MINT_PRICE = _mintPrice;
    }

    function setSharePrice(uint256 _sharePrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        SHARE_PRICE = _sharePrice;
    }

    function setMaxTokens(uint256 _maxTokens) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MAX_TOKENS = _maxTokens;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function emergencyWithdraw() external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(royaltyAddress).transfer(address(this).balance);
    }


    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, ERC721AUpgradeable) returns (bool) {
        return
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[42] private __gap;
}
