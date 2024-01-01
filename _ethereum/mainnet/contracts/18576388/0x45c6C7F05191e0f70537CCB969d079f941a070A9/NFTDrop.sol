// SPDX-License-Identifier: MIT
/***
 *              _____                _____                    _____                    _____            _____                    _____          
 *             /\    \              /\    \                  /\    \                  /\    \          /\    \                  /\    \         
 *            /::\    \            /::\    \                /::\    \                /::\____\        /::\    \                /::\    \        
 *           /::::\    \           \:::\    \              /::::\    \              /:::/    /       /::::\    \               \:::\    \       
 *          /::::::\    \           \:::\    \            /::::::\    \            /:::/    /       /::::::\    \               \:::\    \      
 *         /:::/\:::\    \           \:::\    \          /:::/\:::\    \          /:::/    /       /:::/\:::\    \               \:::\    \     
 *        /:::/__\:::\    \           \:::\    \        /:::/__\:::\    \        /:::/    /       /:::/__\:::\    \               \:::\    \    
 *        \:::\   \:::\    \          /::::\    \      /::::\   \:::\    \      /:::/    /        \:::\   \:::\    \              /::::\    \   
 *      ___\:::\   \:::\    \        /::::::\    \    /::::::\   \:::\    \    /:::/    /       ___\:::\   \:::\    \    ____    /::::::\    \  
 *     /\   \:::\   \:::\    \      /:::/\:::\    \  /:::/\:::\   \:::\    \  /:::/    /       /\   \:::\   \:::\    \  /\   \  /:::/\:::\    \ 
 *    /::\   \:::\   \:::\____\    /:::/  \:::\____\/:::/__\:::\   \:::\____\/:::/____/       /::\   \:::\   \:::\____\/::\   \/:::/  \:::\____\
 *    \:::\   \:::\   \::/    /   /:::/    \::/    /\:::\   \:::\   \::/    /\:::\    \       \:::\   \:::\   \::/    /\:::\  /:::/    \::/    /
 *     \:::\   \:::\   \/____/   /:::/    / \/____/  \:::\   \:::\   \/____/  \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/    / \/____/ 
 *      \:::\   \:::\    \      /:::/    /            \:::\   \:::\    \       \:::\    \       \:::\   \:::\    \       \::::::/    /          
 *       \:::\   \:::\____\    /:::/    /              \:::\   \:::\____\       \:::\    \       \:::\   \:::\____\       \::::/____/           
 *        \:::\  /:::/    /    \::/    /                \:::\   \::/    /        \:::\    \       \:::\  /:::/    /        \:::\    \           
 *         \:::\/:::/    /      \/____/                  \:::\   \/____/          \:::\    \       \:::\/:::/    /          \:::\    \          
 *          \::::::/    /                                 \:::\    \               \:::\    \       \::::::/    /            \:::\    \         
 *           \::::/    /                                   \:::\____\               \:::\____\       \::::/    /              \:::\____\        
 *            \::/    /                                     \::/    /                \::/    /        \::/    /                \::/    /        
 *             \/____/                                       \/____/                  \/____/          \/____/                  \/____/         
 *                                                                                                                                              
 */

pragma solidity ^0.8.9;

import "./ERC1155Upgradeable.sol";
import "./ERC1155ReceiverUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./IRoleManager.sol";
import "./INFTBase.sol";

contract NFTDrop is Initializable, UUPSUpgradeable, ERC1155HolderUpgradeable, ContextUpgradeable {

    using SafeMathUpgradeable for uint256;

    IRoleManager public roleManager;
    INFTBase public nftBase;

    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // NFTDrop info
    struct NFTDropInfo {
        uint256 amount;
        uint256 dropAmount;
        uint256 remain;
        uint256 start;
        uint256 end;
        bool allow;
    }

    mapping (uint256 => NFTDropInfo) public nftDrops;  //nft id => NFTDropInfo
    mapping (uint256 => address[]) public usedAddr;  //nft id => address
    mapping (uint256 => mapping (address => bool)) public allowList;  //nft id => address

    //event
    event AddedAllowList(uint256 indexed nftId, address user);
    event RemovedAllowlist(uint256 indexed nftId, address user);
    event AddedAllowListBatch(uint256 indexed nftId, address[] user);
    event RemovedAllowlistBatch(uint256 indexed nftId, address[] user);

    event Add(uint256 indexed nftId, uint256 amount, uint256 dropAmount, uint256 start, uint256 end, bool allow);
    event Set(uint256 indexed nftId, uint256 dropAmount, uint256 start, uint256 end, bool allow);
    event GetNft(uint256 indexed nftId, uint256 dropAmount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IRoleManager _roleManager, INFTBase _nftBase) initializer public {
        __UUPSUpgradeable_init();

        roleManager = IRoleManager(_roleManager);
        nftBase = INFTBase(_nftBase);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155ReceiverUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(ADMIN_ROLE)
        override
    {}

    modifier onlyRole(bytes32 role) {
        require(roleManager.hasRole(role, _msgSender()),"NFTDrop/has_no_role");
        _;
    }

    function addAllowList(uint256 nftId, address user) public onlyRole(ADMIN_ROLE) {
        require(!allowList[nftId][user], "NFTDrop/already_on_allowList");
        allowList[nftId][user] = true;
        
        emit AddedAllowList(nftId, user);
    }

    function removeAllowList(uint256 nftId, address user) public onlyRole(ADMIN_ROLE) {
        require(allowList[nftId][user], "NFTDrop/not_on_allowList");
        allowList[nftId][user] = false;

        emit RemovedAllowlist(nftId, user);
    }

    function addAllowListBatch(uint256 nftId, address[] memory users) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < users.length; i++) {
            allowList[nftId][users[i]] = true;
        }
        emit AddedAllowListBatch(nftId, users);
    }

    function removeAllowListBatch(uint256 nftId, address[] memory users) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < users.length; i++) {
            allowList[nftId][users[i]] = false;
        }
        emit RemovedAllowlistBatch(nftId, users);
    }


    /**
     * @dev Add NFT Drop
     */ 
    function add(uint256 _nftId, uint256 _amount, uint256 _dropAmount, uint256 _start, uint256 _end, bool _allow) public onlyRole(ADMIN_ROLE) {
        require(nftBase.balanceOf(_msgSender(), _nftId) >= _amount,"NFTDrop/insufficient_amount");
        require(_amount > 0, "NFTDrop/nft_zero");
        require(_end > _start, "NFTDrop/time_err");

        nftBase.safeTransferFrom(_msgSender(), address(this), _nftId, _amount, "");

        nftDrops[_nftId].amount = _amount;
        nftDrops[_nftId].dropAmount = _dropAmount;
        nftDrops[_nftId].remain = _amount;
        nftDrops[_nftId].start = _start;
        nftDrops[_nftId].end = _end;
        nftDrops[_nftId].allow = _allow;

        emit Add(_nftId, _amount, _dropAmount, _start, _end, _allow);
    }

    /**
     * @dev Set NFT Drop
     */ 
    function set(uint256 _nftId, uint256 _dropAmount, uint256 _start, uint256 _end, bool _allow) public onlyRole(ADMIN_ROLE) {
        require(nftDrops[_nftId].amount > 0, "NFTDrop/nft_zero");
        require(_end > _start, "NFTDrop/time_err");
        
        nftDrops[_nftId].dropAmount = _dropAmount;
        nftDrops[_nftId].start = _start;
        nftDrops[_nftId].end = _end;
        nftDrops[_nftId].allow = _allow;

        emit Set(_nftId, _dropAmount, _start, _end, _allow);
    }

    
    /**
     * @dev Get NFT
     */ 
    function getNft(uint256 _nftId) public {
        require(nftDrops[_nftId].remain >= nftDrops[_nftId].dropAmount,"NFTDrop/sold_out");
        require(nftDrops[_nftId].start <= block.timestamp ,"NFTDrop/not_yet_start");
        require(nftDrops[_nftId].end >= block.timestamp ,"NFTDrop/finished");

        //check allow list
        if (nftDrops[_nftId].allow){
            if (!allowList[_nftId][_msgSender()])
                revert("NFTDrop/not_allowed");
        }

        //check used addr
        uint256 length = usedAddr[_nftId].length;
        for (uint256 i = 0; i < length; ++i) {
            if (usedAddr[_nftId][i] == _msgSender()){
                revert("NFTDrop/already_airdrop");
            }
        }
        usedAddr[_nftId].push(_msgSender());
        
        nftBase.safeTransferFrom(address(this), _msgSender(), _nftId, nftDrops[_nftId].dropAmount, "");
        nftDrops[_nftId].remain = nftDrops[_nftId].remain.sub(nftDrops[_nftId].dropAmount);

        emit GetNft(_nftId, nftDrops[_nftId].dropAmount);
    }

    /**
     * @dev Withdraw
     */ 
    function withdraw(uint256 _nftId) public onlyRole(ADMIN_ROLE) {
        require(nftDrops[_nftId].remain > 0, "NFTDrop/nft_zero");

        nftBase.safeTransferFrom(address(this), _msgSender(), _nftId, nftDrops[_nftId].remain, "");
        nftDrops[_nftId].remain = 0;
    }
}