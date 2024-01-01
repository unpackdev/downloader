// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC1155Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./Initializable.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./ExternalEarlyBird.sol";
import "./ISoulBoundPen.sol";



contract SoulBoundPen is ISoulBoundPen, Initializable, UUPSUpgradeable, ERC1155Upgradeable, PausableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, ExternalEarlyBird {

    address public usdt;

    mapping(uint256 => string) private uri_;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MARKET_ROLE = keccak256("MARKET_ROLE");
    uint256 public constant LOW = 1;
    uint256 public constant MIDDLE = 2;
    uint256 public constant HIGH = 3;

    mapping (address => bool) public minters;
    mapping (uint256 => uint256) public levelPrice;
    mapping (uint256 => uint256) private amountOfLevel_;

    function initialize(address usdt_) public initializer {
        __ERC1155_init("");
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        usdt = usdt_;
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(MARKET_ROLE, ADMIN_ROLE);

        uint256 decimals = 6;


        // Set the URI for each token type
        uri_[LOW] = "https://images1.socrates.xyz/metadata/low";
        uri_[MIDDLE] = "https://images1.socrates.xyz/metadata/middle";
        uri_[HIGH] = "https://images1.socrates.xyz/metadata/high";

        // Set the price for each token type
        levelPrice[LOW] = 10 * 10**decimals;
        levelPrice[MIDDLE] = 100 * 10**decimals;
        levelPrice[HIGH] = 300 * 10**decimals;
    }

    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address) internal onlyRole(ADMIN_ROLE) override {}


    function mint(uint256 id_) external override callerIsUser nonReentrant whenNotPaused onlyEarlyBird {
        require(!minters[msg.sender], "Socrates: The SBT has been minted");
        require(id_ == LOW || id_ == MIDDLE || id_ == HIGH, "Socrates: Not support level");
        require(IERC20(usdt).balanceOf(msg.sender) >= levelPrice[id_], "Socrates: Not enough usdt");

        IERC20(usdt).transferFrom(msg.sender, address(this), levelPrice[id_]);

        _mint(msg.sender, id_, 1, "");
        minters[msg.sender] = true;
        amountOfLevel_[id_] += 1;
        emit minted(msg.sender, id_);
    }


    function upgrade(uint256 next_) external override callerIsUser nonReentrant whenNotPaused onlyEarlyBird {
        require(minters[msg.sender], "Socrates: The SBT has not been minted");
        require(next_ == MIDDLE || next_ == HIGH, "Socrates: Not support level");
        uint256 id_ = getId(msg.sender);
        require(id_ != 0 && id_ < next_, "Socrates: Not support upgrade");
        uint256 price = levelPrice[next_] - levelPrice[id_];
        require(IERC20(usdt).balanceOf(msg.sender) >= price, "Socrates: Not enough usdt");


        IERC20(usdt).transferFrom(msg.sender, address(this), price);


        _mint(msg.sender, next_, 1, "");
        _burn(msg.sender, id_, 1);
        amountOfLevel_[id_] -= 1;
        amountOfLevel_[next_] += 1;
        emit upgraded(msg.sender, id_, next_);
    }

    /***********************************|
    |                View               |
    |__________________________________*/


    function getId(address account_) public view override returns(uint256) {
        if (balanceOf(account_, LOW) > 0) {
            return LOW;
        } else if (balanceOf(account_, MIDDLE) > 0) {
            return MIDDLE;
        } else if (balanceOf(account_, HIGH) > 0) {
            return HIGH;
        } else {
            return 0; // Not minted
        }
    }


    function uri(uint256 id_) public view override returns (string memory) {
        return uri_[id_];
    }


    function balanceOf(address account, uint256 id) public override view returns (uint256) {
        return super.balanceOf(account, id);
    }


    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public override view returns (uint256[] memory) {
        return super.balanceOfBatch(accounts, ids);
    }



    function totalMinted() public view returns (uint256) {
        return amountOfLevel_[LOW] + amountOfLevel_[MIDDLE] + amountOfLevel_[HIGH];
    }


    function amountOfLevel(uint256 id) public view returns (uint256) {
        return amountOfLevel_[id];
    }


    /***********************************|
    |                Maker              |
    |__________________________________*/


    function batchMint(address[] memory accounts, uint256 id_) external override onlyRole(MARKET_ROLE) nonReentrant {
        require(id_ == LOW || id_ == MIDDLE || id_ == HIGH, "Socrates: Not support level");

        for (uint256 i = 0; i < accounts.length; i++) {
            require(!minters[accounts[i]], "Socrates: The SBT has been minted");
            _mint(accounts[i], id_, 1, "");
            minters[accounts[i]] = true;
        }

        emit batchMinted(accounts, id_);

    }

    /***********************************|
    |                Admin              |
    |__________________________________*/

    function withdraw() external onlyRole(ADMIN_ROLE) nonReentrant {
        uint256 balance = IERC20(usdt).balanceOf(address(this));
        IERC20(usdt).transfer(msg.sender, balance);
    }

    function setPrice(uint256 id_, uint256 price_) external onlyRole(ADMIN_ROLE) {
        levelPrice[id_] = price_;
    }


    function setUri(uint256 id_, string memory newUri_) external onlyRole(ADMIN_ROLE) {
        uri_[id_] = newUri_;
    }



    function pause() external whenNotPaused onlyRole(ADMIN_ROLE) {
        _pause();
    }


    function unpause() external whenPaused onlyRole(ADMIN_ROLE) {
        _unpause();
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    /***********************************|
    |              Disable              |
    |__________________________________*/


    function safeBatchTransferFrom(address, address, uint256[] memory, uint256[] memory, bytes memory) public override pure {
        revert("Socrates: The SBT not support batch transfer");
    }

    function safeTransferFrom(address, address, uint256, uint256, bytes memory) public override pure {
        revert("Socrates: The SBT not support transfer");
    }

    function setApprovalForAll(address, bool) public override pure {
        revert("Socrates: The SBT not support setApprovalForAll");
    }

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "Socrates: Contracts not allowed");
        _;
    }
}