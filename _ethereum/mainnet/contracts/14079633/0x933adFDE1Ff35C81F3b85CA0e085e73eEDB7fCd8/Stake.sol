// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";

import "./ERC721.sol";

interface ICryptoPunks {
    function transferPunk(address to, uint punkIndex) external;
}

/**
 * @dev The entrance of P2P business
 */
contract Stake is
    OwnableUpgradeable,
    ERC721HolderUpgradeable,
    PausableUpgradeable,
    AccessControlEnumerableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant ROLE_STAKE_ADMIN =
        keccak256("ROLE_STAKE_ADMIN");
    bytes32 public constant ROLE_BOT_ADMIN =
        keccak256("ROLE_BOT_ADMIN");

    event UpdateWhitelist(address indexed _address, bool _active);

    event SetWhiteNFT(address indexed _address);

    event Staked(
        address indexed from, 
        address indexed nftAddress, 
        uint256 indexed nftId
    );
    
    event Withdrawn(
        address indexed from, 
        uint256 indexed stakeId, 
        address indexed nftAddress, 
        uint256 nftId, 
        uint64 duration
    );

    event NFTReceived(
        address indexed operator,
        address indexed from,
        uint256 indexed tokenId,
        bytes data
    );

    mapping(address => bool) whitelist;
    // non-native NFT, e.g. CryptoPunks
    mapping(address => bool) whiteNFT;

    EnumerableSetUpgradeable.AddressSet internal whiteSet;
    // user stake info.
    mapping(address => StakeInfo[]) public stakeOf;

    struct StakeInfo {
        address nftAddress;
        uint256 nftId;
        uint64 start;
    }

    function initialize() public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ROLE_STAKE_ADMIN, _msgSender());
        _grantRole(ROLE_BOT_ADMIN, _msgSender());
        __Ownable_init();
        __Pausable_init();
    }

    modifier onlyStakeAdmin() {
        require(
            hasRole(ROLE_STAKE_ADMIN, _msgSender()),
            "Only the stake admin has permission to do this operation"
        );
        _;
    }

    modifier onlyBotAdmin() {
        require(
            hasRole(ROLE_BOT_ADMIN, _msgSender()),
            "Only the robot admin has permission to do this operation"
        );
        _;
    }

    modifier checkWhitelist(address _address) {
        require(whitelist[_address], "This address is not in the whitelist");
        _;
    }

    modifier checkNFTList(address _address) {
        require(whiteNFT[_address], "This address is not in the whitelist");
        _;
    }

    function setPause(bool pause) external onlyStakeAdmin {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function updateWhitelist(address _address, bool _active)
        public
        whenNotPaused
        onlyStakeAdmin
    {
        whitelist[_address] = _active;
        _active ? whiteSet.add(_address) : whiteSet.remove(_address);
        emit UpdateWhitelist(_address, _active);
    }

    function setWhitelist(address[] memory addresses) public whenNotPaused onlyStakeAdmin {
        for (uint256 index = 0; index < addresses.length; index++) {
            updateWhitelist(addresses[index], true);
        }
    }

    function setWhiteNFT(address _address) public whenNotPaused onlyStakeAdmin {
        whiteNFT[_address] = true;
        updateWhitelist(_address, true);
        emit SetWhiteNFT(_address);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721HolderUpgradeable) returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function getStakes(address user) public view returns (StakeInfo[] memory) {
        return stakeOf[user];
    }

    /**
     * @dev Staking NFT into contracts
     * @param _nftAdr the address of staked NFT
     * @param _nftId the tokenID of staked NFT
     */
    function stake(
        address _nftAdr,
        uint256 _nftId
    ) public whenNotPaused checkWhitelist(_nftAdr) {
        require(
            IERC721(_nftAdr).supportsInterface(0x80ac58cd),
            "Parameter _nftAdr is not ERC721 contract address"
        );
        IERC721(_nftAdr).safeTransferFrom(_msgSender(), address(this), _nftId);
        stakeOf[_msgSender()].push(
            StakeInfo({
                nftAddress: _nftAdr,
                nftId: _nftId,
                start: uint64(block.timestamp)
            })
        );
        
        emit Staked(_msgSender(), _nftAdr, _nftId);
    }

    function stakeList(address[] memory _nftAdrs, uint256[] memory _nftIds) external {
        require(_nftAdrs.length == _nftIds.length, "Bad parameters.");
        for (uint256 i = 0; i < _nftAdrs.length; i++) {
            stake(_nftAdrs[i], _nftIds[i]);
        }
    }

    /**
     * @dev Robot listens event PunkTransfer to record CryptoPunks stake info in contract
     * @param from the address of user who transfer CryptoPunks to the contract
     * @param _nftAdr the address of CryptoPunks
     * @param _nftId the id of CryptoPunks
     */
    function recordStake(
        address from,
        address _nftAdr,
        uint256 _nftId
    ) external whenNotPaused checkNFTList(_nftAdr) onlyBotAdmin {
        stakeOf[from].push(
            StakeInfo({
                nftAddress: _nftAdr,
                nftId: _nftId,
                start: uint64(block.timestamp)
            })
        );
        emit Staked(from, _nftAdr, _nftId);
    }

    /**
     * @dev withdraw staked NFT
     * @param _stakeId the id of user staked NFT in stake array
     */
    function withdraw(uint256 _stakeId) external whenNotPaused {
        require(_stakeId < stakeOf[_msgSender()].length, "Withdraw: Stake does not exist");
        StakeInfo memory userStake = stakeOf[_msgSender()][_stakeId];
        stakeOf[_msgSender()][_stakeId] = stakeOf[_msgSender()][stakeOf[_msgSender()].length - 1];
        stakeOf[_msgSender()].pop();
        uint64 duration = uint64(block.timestamp) - uint64(userStake.start);
        if (whiteNFT[userStake.nftAddress]) {
            ICryptoPunks(userStake.nftAddress).transferPunk(_msgSender(), userStake.nftId);
        } else {
            IERC721(userStake.nftAddress).safeTransferFrom(
                address(this),
                _msgSender(),
                userStake.nftId
            );
        }
        emit Withdrawn(_msgSender(), _stakeId, userStake.nftAddress, userStake.nftId, duration);
    }

    /**
     * @dev get NFT whitelist
     */
    function getWhiteSet() public view returns (address[] memory) {
        return whiteSet.values();
    }
}
