pragma solidity 0.8.11;

import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./PaymentSplitterUpgradeable.sol";
import "./IMerkle.sol";
import "./IApelist.sol";

import "./Initializable.sol";

contract ApelistController is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable, PaymentSplitterUpgradeable {    
    bool public whitelistLive;
    bool public isSaleLive;
    
    IMerkle public whitelist;
    IMerkle public claim;
    IApelist public nft;

    struct Config {
        uint256 price;
        uint256 maxSupply;
        uint256 maxWLMint;
        uint256 maxMint;
    }

    struct Limit {
        uint256 wl;
        uint256 open;
    }

    Config public config;
    
    mapping(address => bool) admins;
    mapping(address => bool) public claimed;
    mapping(address => Limit) public limit;    

    function initialize(address[] memory _recipients, uint256[] memory _shares, IMerkle _whitelist, IMerkle _claim) virtual public initializer {
        config.price = 0.18 ether;
        config.maxSupply = 2600;
        config.maxWLMint = 5;
        config.maxMint = 5;
        whitelist = _whitelist;
        claim = _claim;

        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __PaymentSplitter_init(_recipients, _shares);
    }


    function adminMint(uint256 quantity, address to) external adminOrOwner {
        _callMint(quantity, to);
    }

    function totalSupply() public view returns (uint256) {
        return nft.totalSupply(1);
    }

    function wlMint(uint256 quantity, bytes32[] memory claimProof, bytes32[] memory wlProof) external payable whenNotPaused nonReentrant {
        require(whitelistLive, "Not live");
        require(whitelist.isPermitted(msg.sender, wlProof), "Not WL'd");
        require(msg.value >= quantity * config.price, "Exceeds cost");        
        require(limit[msg.sender].wl + quantity <= config.maxWLMint, "Exceeds max");        
        limit[msg.sender].wl += quantity;

        uint256 _quantity = quantity;
        if(legibleForClaim(msg.sender, claimProof)) {
            _quantity += 1;
            claimed[msg.sender] = true;
        }
        require(totalSupply() + _quantity <= config.maxSupply, "Exceeds supply");
        require(_quantity > 0, "No Zeros");

        _callMint(_quantity, msg.sender); 
    }

    function legibleForClaim(address to, bytes32[] memory proof) public view returns (bool) {
        return claim.isPermitted(to, proof) && !claimed[to];
    }

    function mint(uint256 quantity) external payable whenNotPaused nonReentrant {        
        require(quantity > 0, "No Zeros");
        require(isSaleLive, "Not live");
        require(msg.value >= quantity * config.price, "Exceeds cost");
        require(limit[msg.sender].open + quantity <= config.maxMint, "Exceeds max");
        require(totalSupply() + quantity <= config.maxSupply, "Exceeds supply");
        limit[msg.sender].open += quantity;
        _callMint(quantity, msg.sender);        
    }

    function _callMint(uint256 quantity, address to) internal {
        nft.apeMint(to, 1, quantity);
    }

    function setSupply(uint256 _supply) external adminOrOwner {
        config.maxSupply = _supply;
    }

    function setMaxWLMint(uint256 _max) external adminOrOwner {
        config.maxMint = _max;
    }

    function setMaxMint(uint256 _max) external adminOrOwner {
        config.maxWLMint = _max;
    }

    function setMaxSupply(uint256 _supply) external adminOrOwner {
        config.maxSupply = _supply;
    }

    function setPrice(uint256 _price) external adminOrOwner {
        config.price = _price;
    }

    function toggleWhitelistLive() external adminOrOwner {
        whitelistLive = !whitelistLive;
    }

    function toggleSaleLive() external adminOrOwner {
        isSaleLive = !isSaleLive;
    }

    function setNFT(IApelist _nft) external adminOrOwner {
        nft = _nft;
    }
    
    function addAdmin(address _admin) external adminOrOwner {
        admins[_admin] = true;
    }

    function setWhitelist(IMerkle _whitelist) external adminOrOwner {
        whitelist = _whitelist;
    }

    function setClaim(IMerkle _claim) external adminOrOwner {
        claim = _claim;
    }

    function removeAdmin(address _admin) external adminOrOwner {
        delete admins[_admin];
    }

    modifier adminOrOwner() {
        require(msg.sender == owner() || admins[msg.sender], "Unauthorized");
        _;
    }
}