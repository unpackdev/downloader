// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";

struct RoundConfig{
    bool isAllowlist;
    uint64 mintMax;
    uint64 mintCur;
    uint64 startTime;
    uint64 endTime;
    uint price;
}

contract Turbos is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, AccessControlUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint private _entered;
    modifier nonReentrant {
        require(_entered == 0, "reentrant");
        _entered = 1;
        _;
        _entered = 0;
    }
    CountersUpgradeable.Counter private _tokenIdCounter;
    string public _baseTokenURI;
    uint public collectionSize;
    uint public round;
    mapping (uint => RoundConfig) public roundConfigs;  //round=>configs

    address[] public allowlist;
    mapping (address => mapping (uint => uint)) public  allowAmount; ////address =>round =>amount

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
       // _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("Turbos", "TURBO");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        collectionSize = 10000;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }
   
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI; //"ipfs://meXt9vKD2vVhu4cwwWNM/"
    }

    function setBaseURI(string calldata baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseURI;
    }

    function setConfig(uint round_,bool isAllowlist_,uint64 mintMax_,uint64 mintCur,uint64 startTime_,uint64 endTime_,uint price_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        round =round_;
        roundConfigs[round_] = RoundConfig(isAllowlist_,mintMax_, mintCur, startTime_, endTime_, price_);
    }


    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to, string memory uri) public onlyRole(MINTER_ROLE) {
        require(roundConfigs[round].mintCur+1 <= roundConfigs[round].mintMax,"reached round max");
        __safeMint(to,uri);
        roundConfigs[round].mintCur +=  1;
    }

    function __safeMint(address to, string memory uri) internal {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function allowlistMint() external payable {
        require(roundConfigs[round].isAllowlist, "not allowlist round");
        uint count = allowAmount[msg.sender][round];
        require(count > 0, "not in allowlist or already mint");
        require(totalSupply() + count <= collectionSize, "reached max supply");
        require(roundConfigs[round].mintCur+count <= roundConfigs[round].mintMax,"reached round max");
        roundConfigs[round].mintCur +=  uint64(count);
        allowAmount[msg.sender][round] -= count;
        __batchMint(msg.sender,"",count);
        refundIfOver(roundConfigs[round].price*count);
    }

    function publicMint(uint count_) external payable {
        require(!roundConfigs[round].isAllowlist, "allowlist round");
        require(totalSupply() + count_ <= collectionSize, "reached max supply");
        require(roundConfigs[round].mintCur+count_ <= roundConfigs[round].mintMax,"reached round max");
        roundConfigs[round].mintCur +=  uint64(count_);
        //__safeMint(msg.sender, "");
        __batchMint(msg.sender,"",count_);
        refundIfOver(roundConfigs[round].price*count_);
    }    

    function __batchMint(address to,string memory uri,uint count) internal {
        uint256 tokenId = _tokenIdCounter.current();
        for (uint i=0;i<count;i++){
            tokenId++;
            _safeMint(to, tokenId);
            _setTokenURI(tokenId,uri);
        }
        _tokenIdCounter.set(tokenId);
        
    }

    function batchMint(address to,string memory uri,uint count) public onlyRole(MINTER_ROLE){
        require(roundConfigs[round].mintCur+count <= roundConfigs[round].mintMax,"reached round max");
        __batchMint(to,uri,count);
        roundConfigs[round].mintCur += uint64(count);
    }    


    function refundIfOver(uint256 price_) private nonReentrant{
        require(msg.value >= price_, "Need to send more ETH.");
        if (msg.value > price_) {
        payable(msg.sender).transfer(msg.value - price_);
        }
    }


  
    function setAllowlist(address[] calldata addresses, uint256[] calldata amounts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(addresses.length == amounts.length,"addresses does not match amount length");
        for(uint i=0; i<allowlist.length; i++)
            delete allowAmount[allowlist[i]][round];
        allowlist = addresses;
        for(uint i=0; i<addresses.length; i++){
            allowAmount[addresses[i]][round] = amounts[i];
        }
    }

    function addAllowlist(address[] calldata addresses, uint256[] calldata amounts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(addresses.length == amounts.length,"addresses does not match amount length");
        for(uint i=0; i<addresses.length; i++){
            allowlist.push(addresses[i]);
            allowAmount[addresses[i]][round] = amounts[i];
        }
    }

    function withdrawMoney() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
