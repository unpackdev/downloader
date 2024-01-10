pragma solidity 0.8.10;

import "./IERC721Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IUpload.sol";

contract SnailStaking is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    IERC721Upgradeable public snails;
    IERC721Upgradeable public keys;
    IUpload public upload;

    uint256 public period;
    uint256 public rate;

    mapping(uint256 => address) snailsStaked;
    mapping(uint256 => address) keysStaked;
    mapping(address => uint256) snailsStakedCount;
    mapping(address => uint256) keysStakedCount;
    mapping(address => uint256) lastClaim;
    mapping(address => uint256) balance;

    event StakedSnail(uint256 id, address owner);
    event UnstakedSnail(uint256 id, address owner);
    event StakedKey(uint256 id, address owner);
    event UnstakedKey(uint256 id, address owner);

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init_unchained();
        __ReentrancyGuard_init();
        _pause();
        period = 1 days;
        rate = 1000;
    }

    function claim() external nonReentrant _updateReward whenNotPaused {
        uint256 owed = balance[_msgSender()];
        balance[_msgSender()] = 0;
        upload.mint(_msgSender(), owed);
    }

    function proRata(uint256 uploads, uint256 keysCount) public view returns (uint256) {
        uint256 scaled = (uploads * keysCount * 1e18) / 5;
        return uploads + (scaled / 1e18);
    }
 
    function unstake(uint256[] memory snailIds, uint256[] memory keyIds) external nonReentrant _updateReward whenNotPaused {
        uint256 snailsCount = snailIds.length;
        uint256 keysCount = keyIds.length;
        if(keysCount > 0) keysStakedCount[_msgSender()] -= keysCount;
        if(snailsCount > 0) snailsStakedCount[_msgSender()] -= snailsCount;

        for(uint256 i; i < keysCount; i ++) {
            uint256 key = keyIds[i];
            require(keysStaked[key] == msg.sender, "Must own");
            delete keysStaked[key];
            keys.safeTransferFrom(address(this), msg.sender, key);
            emit UnstakedKey(key, _msgSender());
        }

        for(uint256 i; i < snailsCount; i ++ ) {
            uint256 snail = snailIds[i];
            require(snailsStaked[snail] == msg.sender, "Must own");
            delete snailsStaked[snail];
            snails.safeTransferFrom(address(this), msg.sender, snail);

            emit UnstakedSnail(snail, _msgSender());
        }
        uint256 owed = balance[_msgSender()];
        balance[_msgSender()] = 0;
        upload.mint(_msgSender(), owed);
    }

    function stake(uint256[] memory snailIds, uint256[] memory keyIds) external nonReentrant _updateReward whenNotPaused {
        uint256 snailsIdsLength = snailIds.length;
        uint256 keyIdsLength = keyIds.length;
        require(snailsStakedCount[_msgSender()] + snailsIdsLength <= 10, "Max staked");
        require(keysStakedCount[_msgSender()] + keyIdsLength <= 5, "Max staked");

        for(uint256 i; i < snailsIdsLength; i ++) {
            uint256 snail = snailIds[i];
            snailsStaked[snail] = _msgSender();            
            snails.transferFrom(_msgSender(), address(this), snail);
            emit StakedSnail(snail, _msgSender());
        }

        snailsStakedCount[_msgSender()] += snailsIdsLength;

        for(uint256 i; i < keyIdsLength; i ++) {
            uint256 key = keyIds[i];
            keysStaked[key] = _msgSender();
            keys.transferFrom(_msgSender(), address(this), key);
            emit StakedKey(key, _msgSender());
        }

        keysStakedCount[_msgSender()] += keyIdsLength;
    }

    function getTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    modifier _updateReward() {
        uint256 owed = getOwed(_msgSender());
        balance[_msgSender()] += owed;
        lastClaim[_msgSender()] = getTimestamp();

        _;
    }

    function getStakedKeys(address _owner) public view returns (uint256) {
        return keysStakedCount[_owner];
    }

    function pause() external onlyOwner {
        _pause();
    }
        
    function unpause() external onlyOwner {
        _unpause();
    }

    function setKeys(IERC721Upgradeable _keys) external onlyOwner {
        keys = _keys;
    }

    function setSnails(IERC721Upgradeable _snails) external onlyOwner {
        snails = _snails;
    }

    function setUpload(IUpload _upload) external onlyOwner {
        upload = _upload;
    }

    function setRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }

    function setPeriod(uint256 _period) external onlyOwner {
        period = _period;
    }

    function getAccrued(address owner)  public view returns (uint256) {
        uint256 accrued = ((getTimestamp() - lastClaim[owner]) * 1e18 / period) * rate;
        return accrued;
    }

    function getOwed(address owner) public view returns (uint256) {
        uint256 _snails = snailsStakedCount[_msgSender()];
        uint256 _keys = keysStakedCount[_msgSender()];
        uint256 accrued = getAccrued(_msgSender());

        return _snails * proRata(
            accrued,
            _keys
        );
    }
    
    function getBalance(address owner) public view returns (uint256) {
        return balance[owner];
    }

    function getSnailsStaked(address owner ) public view returns (uint256) {
        return snailsStakedCount[owner];
    }

    function getKeysStaked(address owner) public view returns (uint256) {
        return keysStakedCount[owner];
    }

    function getLastClaim(address owner) public view returns (uint256) {
        return lastClaim[owner];
    }

    /**
        @dev emergency function to clear state if there are issues
     */
    function updateSnailsStakedCount(uint256 _count, address owner) external onlyOwner {
        snailsStakedCount[owner] = _count;
    }

    /**
        @dev emergency function to clear state if there are issues
     */
    function updateKeysStakedCount(uint256 _count, address owner) external onlyOwner {
        keysStakedCount[owner] = _count;
    }

    /**
        @dev emergency function to clear state if there are issues
     */
    function updateUserBalance(uint256 _count, address owner) external onlyOwner {
        balance[owner] = _count;
    }
}