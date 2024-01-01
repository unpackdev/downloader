// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155URIStorage.sol";
import "./ERC2981.sol";

/* -----------------------------------------------
_________          _______  ______   ______   _______           _______ 
\__   __/|\     /|(  ___  )(  __  \ (  __  \ (  ____ \|\     /|(  ____ \
   ) (   | )   ( || (   ) || (  \  )| (  \  )| (    \/| )   ( || (    \/
   | |   | (___) || (___) || |   ) || |   ) || (__    | |   | || (_____ 
   | |   |  ___  ||  ___  || |   | || |   | ||  __)   | |   | |(_____  )
   | |   | (   ) || (   ) || |   ) || |   ) || (      | |   | |      ) |
   | |   | )   ( || )   ( || (__/  )| (__/  )| (____/\| (___) |/\____) |
   )_(   |/     \||/     \|(______/ (______/ (_______/(_______)\_______)
                                                                                                                   
 ----------------------------------------------- */

contract CostaRicaStamps is AccessControl, ReentrancyGuard,ERC1155URIStorage, ERC2981 {

    bytes32 public constant MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;
    bytes32 public constant AIRDROP_ROLE = 0x3a2f235c9daaf33349d300aadff2f15078a89df81bcfdd45ba11c8f816bddc6f;

    using Strings for uint256;
    
    error notAdmin();
    error Paused();
    error supplyAlreadySet();
    error exceedsSupply();
    error zeroSupply();
    error lenghtMismatch();
    error alreadyDefined();
    error wrongPrice();
    error invalidId();
    error freeMintClose();
    error failSafeCast();
    error notMinter();
    error notAuth();
    error airdropReached(uint256 id);
    error invalidSupply();

    uint256 public price = 0.1 ether; 
    address private _owner;
    string private _name;
    string private _symbol;
    bool public paused = false;
    bool private royaties = false;
    mapping(uint256 => uint256) private maxSupply; 
    mapping(uint256 => uint256) private maxDropSupply; 
    mapping(uint256 => uint256) private dropSupply; 
    constructor(uint256 _id, uint256 _maxSupply,uint256 _maxDropSupply, string memory _tokenURI, string memory name_, string memory symbol_) ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(AIRDROP_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        _grantRole(MINTER_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        _grantRole(AIRDROP_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        _name = name_;
        _symbol = symbol_;
        maxSupply[_id] = _maxSupply;
        maxDropSupply[_id] = _maxDropSupply;
        defineUri(_id,_tokenURI);
        _owner = msg.sender;
    }

    modifier admin() {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){ 
            revert notAdmin();
        }
        _;
    }

    modifier minter() {
        if(!hasRole(MINTER_ROLE, msg.sender)){ 
            revert notMinter();
        }
        _;
    }

    modifier airdrop() {
        if(!hasRole(AIRDROP_ROLE, msg.sender)){ 
            revert notAuth();
        }
        _;
    }

    modifier isPaused() {
        if(paused){
            revert Paused();
        }
        _;
    }

    modifier supplySet(uint256 _id) {
        if(maxSupply[_id] != 0){
            revert supplyAlreadySet();
        }
        _;
    }


    function mint(uint256 id,uint256 amount) external payable nonReentrant isPaused {
        if(msg.value != price){
            revert wrongPrice();
        }

        if(id == 0) {
            revert invalidId();
        }

        supply[id] += amount;

        uint256 max = getSupply(id);
    
        if (max > maxSupply[id] - maxDropSupply[id]) {
            revert  exceedsSupply();
        }

        _mint(msg.sender, id, amount, "");
    }

    function mintBatch(uint256[] memory id) external payable nonReentrant isPaused {
        
        uint256 length = id.length;
        uint256[] memory values = new uint256[](length);
        uint amount;

        for (uint i = 0; i < length;) {

            if(id[i] == 0) {
                revert invalidId();
            }

            supply[id[i]] += 1;

            uint256 max = getSupply(id[i]);
    
            if (max > maxSupply[id[i]] - maxDropSupply[id[i]]) {
                revert  exceedsSupply();
            }
            values[i] = 1;
            amount += 1;
            unchecked {
                ++i;
            }
        }

         if(msg.value != (price * amount)){
            revert wrongPrice();
        }

        _mintBatch(msg.sender, id, values, "");
    }

    function freeMint(uint256 id, address user) external nonReentrant isPaused minter {
        if(id == 0) {
            revert invalidId();
        }

        supply[id] += 1;
        uint256 max = getSupply(id);

        if (max > maxSupply[id] - maxDropSupply[id]) {
            revert  exceedsSupply();
        }

        _mint(user, id, 1, "");
    }

    function gifts(address user, uint256[] memory id, uint256[] memory values) external nonReentrant isPaused airdrop {
        uint256 length = id.length;

        for (uint i = 0; i < length;) {

            dropSupply[id[i]] += 1;

            uint256 max = dropSupply[id[i]];
    
            if (max > maxDropSupply[id[i]]) {
                revert  airdropReached(id[i]);
            }

            unchecked {
                ++i;
            }
        }
        _mintBatch(user, id, values, "");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function name() public view returns(string memory){
        return _name;
    }

    function symbol() public view returns(string memory){
        return _symbol;
    }

    function getMaxSupply(uint256 _id) public view returns(uint256){
        return maxSupply[_id];
    }

    function setMaxSupply(uint256 _id, uint256 _maxSupply, uint256 _maxDropSupply, string memory _tokenURI) public admin supplySet(_id) isPaused {
         if((_maxSupply -_maxDropSupply) == 0){
            revert invalidSupply();
        }
        if(_maxSupply == 0){
            revert zeroSupply();
        }
        if(_maxDropSupply != 0) {
            maxDropSupply[_id] = _maxDropSupply;
        }
        maxSupply[_id] = _maxSupply;
        defineUri(_id, _tokenURI);
    }

    function updateDropSupply(uint256 _id, uint256 _maxDropSupply) public admin isPaused {
        if(maxSupply[_id] == 0){
            revert zeroSupply();
        }

        if((maxSupply[_id] -_maxDropSupply) == 0){
            revert invalidSupply();
        }
        
        maxDropSupply[_id] = _maxDropSupply;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public admin {
        if(royaties){
            revert alreadyDefined();
        }
        super._setDefaultRoyalty(receiver,feeNumerator);
        royaties = true;
    } 

    function defineUri(uint256 _id, string memory _tokenURI) private {
        _tokenURIs[_id] = _tokenURI;
    }

    function setPaused(bool _state) public admin{ 
        paused = _state;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function setOwner(address _newOwner) public admin{ 
        _owner = _newOwner;
    }

    function updatePrice(uint256 newPrice) public admin {
        price = newPrice;
    }

}