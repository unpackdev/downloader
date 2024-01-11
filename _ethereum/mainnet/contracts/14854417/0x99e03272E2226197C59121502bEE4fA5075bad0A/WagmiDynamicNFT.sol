// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************

  %%%%%%%%%%                                                       %%%%%%%%%   
  %%%%%%%%%%                                                       %%%%%%%%%   
  /%%%%%%%%%                       %%%%%%%%%                       %%%%%%%%%   
  /%%%%%%%%%                       %%%%%%%%%                       %%%%%%%%%   
   %%%%%%%%%                       %%%%%%%%%                       %%%%%%%%%   
   %%%%%%%%%                       %%%%%%%%%                       %%%%%%%%%   
   %%%%%%%%%                      (#########                       #########   
   %%%%%%%%%                                                                   
   .%%%%%%%%           @*    @@     @@  @@@@     @@@@@@@   @@@@   @@@@   @@
    %%%%%%%%/          /@   (@@%   @@  @%  @@   @@         @@ @   @ @@   @@
    %%%%%%%%%           @@  @  @* @@  @@%%%%@@  @@   @@@@  @@ @@ @@ @@   @@
    /%%%%%%%%            @@@    @@@  @@@    #@@ *@@@# ,@@  @@  @@@/ @@   @@
     %%%%%%%%                                                                  
     %%%%%%%%*                                                                 
      %%%%%%%%                   %%%%%%%%%%%%%                   %%%%%%%%      
      %%%%%%%%                  %%%%%%%%%%%%%%                  *%%%%%%%%      
       %%%%%%%%                 %%%%%%%%%%%%%%%                 %%%%%%%%       
       (%%%%%%%                 %%%%%%%%%%%%%%%                 %%%%%%%*       
        %%%%%%%*               %%%%%%%% %%%%%%%%               %%%%%%%%        
         %%%%%%%              /%%%%%%%   %%%%%%%               %%%%%%%         
          %%%%%%%             %%%%%%%     %%%%%%%             %%%%%%%          
           %%%%%%,           %%%%%%%       %%%%%%%           %%%%%%%           
            %%%%%%*         %%%%%%%         %%%%%%#         %%%%%%%            
             %%%%%%%       %%%%%%*           %%%%%%%       %%%%%%              
               %%%%%%%. %%%%%%%%               %%%%%%%/ /%%%%%%#               
                 %%%%%%%%%%%%                    #%%%%%%%%%%%

 *******************************************************************************/
import "./Base58.sol";
import "./ERC721ACommon.sol";
import "./ERC2981.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./AccessControlEnumerable.sol";
import "./ReentrancyGuard.sol"; 
import "./EnumerableSet.sol";
import "./ECDSA.sol";

interface WagmiFlyer is IERC721 {
    function flyerConversion(address owner, uint256 tokenId) external;
}

/** @dev ERC1155 Contract and can be lock wagmi assets */
interface WagmiAssets {
    function lockAssets(bytes32 _cid, uint256[] calldata _ids) external;
    function unlockAssets(bytes32 _cid) external;
}

/** @dev the stuct to save Avatar infomation and image */
struct WagmiItem {
    address srcAddr;
    uint256 srcId;
    bytes32 cid;
}

contract WagmiDynamicNFT is
    ERC721ACommon,
    ReentrancyGuard,
    AccessControlEnumerable,
    ERC2981
{
    using ECDSA for bytes32;

    event Wagmi(address indexed owner, uint256 indexed tokenId, bytes32 indexed cid);

    bytes constant IPFS_PREFIX = hex"1220";
    uint256 constant public MAX_TOTAL_SUPPLY = 9999;
    uint256 constant public MAX_AIRDROP_SUPPLY = 500;
    uint256 constant public FLYER_PRICE = 0.04 ether;
    uint256 constant public PRE_SALE_PRICE = 0.06 ether;
    uint256 constant public PUBLIC_SALE_PRICE = 0.09 ether;
    uint256 constant public MAX_BATCH_MINT_QUANTITY = 20;
    uint256 constant public MAX_PRESALE_MINT_QUANTITY = 5;

    uint256 public currentAirdropSupply;
    uint256 public publicSaleStartTime;
    uint256 public preSaleStartTime;
    bool public isMintable;

    /** @notice In the future there will be a marketplate for everyone to trade wagmi frames/items, and for wagmi creators to get royalty fees  */
    bool public isWagmiAssetsEnabled;
    WagmiAssets public WagmiAssetsContract;

    string defaultBaseURI;
    string wagmiBaseURI = "ipfs://";

    mapping(uint256 => WagmiItem) public wagmiMap;
    mapping(address => bool) public avatarContractBlaclkList;
    mapping(address => uint256) public preSaleMintedMap;
    
    bool public isFlyerMinable = true;
    WagmiFlyer FlyerContract;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    address Signer;

    constructor(
        string memory _name, string memory _symbol,
        string memory _defaultBaseURI
    )
        ERC721ACommon (_name, _symbol) 
    {
        defaultBaseURI = _defaultBaseURI;
        setPublicSaleTime(block.timestamp + 3 days);
        
        _setDefaultRoyalty(_msgSender(), 1000);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(OPERATOR_ROLE, _msgSender());
    }

    function isPublicSaleActive() public view returns (bool) {
        return block.timestamp >= publicSaleStartTime;
    }

    function currentPrice() public view returns (uint256) {
        return isPublicSaleActive() ? PUBLIC_SALE_PRICE : PRE_SALE_PRICE;
    }

    /**
     * @notice Mint one token if the sender has Flyer token.
     */
    function flyerMint(uint256 flyerId) nonReentrant external payable {
        require(isFlyerMinable, "flyer mint is not active");
        require(FLYER_PRICE == msg.value, "Invalid payment");
        require(FlyerContract.ownerOf(flyerId) == _msgSender(), "Invalid flyer owner");
        // @note burn flyer token.
        FlyerContract.flyerConversion(_msgSender(), flyerId);
        safeMint(_msgSender(), 1);
    }

    function preSaleMint(uint256 _quantity, bytes calldata _signature) nonReentrant external payable {
        require(!isPublicSaleActive(), "pre-sale is not active");
        preSaleMintedMap[_msgSender()] += _quantity;
        require(preSaleMintedMap[_msgSender()] <= MAX_PRESALE_MINT_QUANTITY, "Pre-sale minted quantity exceeds the limit");
        require(PRE_SALE_PRICE * _quantity == msg.value, "Invalid payment");
        requireVerifySignature(toPreSaleMintSigPayload(_quantity), _signature);

        safeMint(_msgSender(), _quantity);
    }

    function mint(address _to, uint256 _quantity) nonReentrant external payable {
        require(isPublicSaleActive(), "public-sale is not active");
        require(_quantity <= MAX_BATCH_MINT_QUANTITY, "Invalid mint quantity");
        require(PUBLIC_SALE_PRICE * _quantity == msg.value, "Invalid payment");
        safeMint(_to, _quantity);
    }

    function safeMint(address _to, uint256 _quantity) private {
        require(_quantity > 0, "Invalid mint quantity");
        require(totalSupply() + _quantity <= MAX_TOTAL_SUPPLY, "Public supply limit reached");
        _mint(_to, _quantity);
    }

    /**
     * @notice If the owner is not the owner of avatar NFT or avatar Contract is in 
     * blacklist, it cannot show the avatar.
     * If the owner do not set avartar, it would show default.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        address nftOwner = ownerOf(tokenId);
        if(wagmiMap[tokenId].srcAddr != address(0)) {
            if(!avatarContractBlaclkList[wagmiMap[tokenId].srcAddr] 
               && checkSenderIsAvatarOwner(nftOwner, wagmiMap[tokenId].srcAddr, wagmiMap[tokenId].srcId)
            ) {
                return string(abi.encodePacked(wagmiBaseURI, generateIpfsCid(wagmiMap[tokenId].cid)));
            }
        }
        return string(abi.encodePacked(defaultBaseURI, _toString(tokenId)));
        
    }

    function setWagmiAvatar(
        address _srcAddr, uint256 _srcId, uint256 _tokenId, bytes32 _cid,
        uint256[] calldata _assets,
        bytes calldata _avatarSig
    ) onlyApprovedOrOwner(_tokenId) external {
        require(checkSenderIsAvatarOwner(ownerOf(_tokenId), _srcAddr, _srcId), "Invalid avatar owner");
        require(!avatarContractBlaclkList[_srcAddr], "avatar contract is in blacklist");
        requireVerifySignature(toWagmiSigPayload(_srcAddr, _srcId, _tokenId, _cid, _assets), _avatarSig);

        if(isWagmiAssetsEnabled && _assets.length > 0) {
            WagmiAssetsContract.lockAssets(_cid, _assets);
        }
        wagmiMap[_tokenId] = WagmiItem(
            _srcAddr,
            _srcId,
            _cid
        );
        emit Wagmi(_msgSender(), _tokenId, _cid);
    }

    function resetWagmiAvatar(uint256 _tokenId) onlyApprovedOrOwner(_tokenId) external {
        _resetWagmiAvatar(_tokenId);
    }

    function _resetWagmiAvatar(uint256 _tokenId) private {
        if(wagmiMap[_tokenId].srcAddr != address(0)) {
            if(isWagmiAssetsEnabled) {
                WagmiAssetsContract.unlockAssets(wagmiMap[_tokenId].cid);
            }
            delete wagmiMap[_tokenId];
            emit Wagmi(_msgSender(), _tokenId, 0x0);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721ACommon, ERC2981, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function checkSenderIsAvatarOwner(address _nftOwner, address _srcAddr, uint256 _srcId) internal view returns (bool) {
        try IERC721(_srcAddr).ownerOf(_srcId) returns (address result) {
            return _nftOwner == result;
        } catch {
            return false;
        }
    }

    /**
     * @notice WARNING: Cannot be transfered if the avatar has been set.
     */
    function _beforeTokenTransfers(
        address _from,
        address _to,
        uint256 _startTokenId,
        uint256 _quantity
    ) internal override {
        // check if transfer is not for minting/burning
        if(_from != address(0) && _to != address(0)) {
            uint256 end = _startTokenId + _quantity;
            for(uint256 tokenId = _startTokenId; tokenId < end; tokenId++) {
                require(wagmiMap[tokenId].srcAddr == address(0), "need to reset avatar first");
            }
        }
        super._beforeTokenTransfers(_from, _to, _startTokenId, _quantity);
    }

    /**
     * @dev parse bytes32 to IPFS cid string
     */
    function generateIpfsCid(bytes32 _cid) internal pure returns (string memory) {
        return Base58.toBase58(abi.encodePacked(IPFS_PREFIX, _cid));
    }
        
    /**
     * @dev Constructs the buffer that is hashed for validation setting avatar signature
     */
    function toWagmiSigPayload(
        address _srcAddr,
        uint256 _srdId,
        uint256 _tokenId,
        bytes32 _cid,
        uint256[] calldata _assets
    )
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_srcAddr, _srdId, _tokenId, _cid, _msgSender(), _assets));
    }

    /**
     * @dev Constructs the buffer that is hashed for validation pre-sale mint signature
     */
    function toPreSaleMintSigPayload(
        uint256 _amt
    )
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_amt, _msgSender()));
    }

    function requireVerifySignature(bytes32 payload, bytes calldata signature) internal view {
        address recover = payload.toEthSignedMessageHash().recover(signature);
        require(Signer == recover, "Invalid signature");
    }

    /** ONLY CONTRACT OWNER */
    function setDefaultBaseURI(string calldata _uri) external onlyOwner {
        defaultBaseURI = _uri;
    }

    function setWagmiBaseURI(string calldata _uri) external onlyOwner {
        wagmiBaseURI = _uri;
    }

    function setPublicSaleTime(uint256 _time) public onlyOwner {
        publicSaleStartTime = _time;
    }

    function setFlyerContract(address _addr) public onlyOwner {
        FlyerContract = WagmiFlyer(_addr);
    }

    function setFlyerMinable(bool _minable) public onlyOwner {
        isFlyerMinable = _minable;
    }

    function setSigner(address _s) public onlyOwner {
        Signer = _s;
    }

    function setWagmiAssetsEnabled(bool _enabled) public onlyOwner {
        isWagmiAssetsEnabled = _enabled;
    }

    function setWagmiAssetsContract(address _addr) public onlyOwner {
        WagmiAssetsContract = WagmiAssets(_addr);
    }

    function withdraw() external onlyRole(OPERATOR_ROLE) {
        uint256 halfBalance = address(this).balance * 5 / 10;
        (bool scc1, ) = payable(0xCD4A5bF1EC44eAE42bFd10F653100f068E17c759).call{ value: halfBalance }("");
        (bool scc2, ) = payable(0x7804aFeBc4cd3c457709e016B18e0FEE17fE8F91).call{ value: halfBalance }("");
        require(scc1, "failed to withdraw 1");
        require(scc2, "failed to withdraw 2");
    }

    function airdrop(address _to, uint8 _quantity) external onlyRole(OPERATOR_ROLE) {
        currentAirdropSupply += _quantity;
        require(currentAirdropSupply <= MAX_AIRDROP_SUPPLY, "exceed airdrop limit");
        safeMint(_to, _quantity);
    }

    /**
     * @notice In order to prevent fraud
     * for example: someone deploy New Erc721 Contract which imitated other NFT Metadata
     * and set Avatar as fraud contracts, causing misunderstandings. 
     * need to to reset Avatar.
     * @dev This function is used to clear the avatar for specific token.
     */
    function clearWagmiAvatar(uint256 _tokenId) external onlyRole(OPERATOR_ROLE) {
        _resetWagmiAvatar(_tokenId);
    }

    function setAvatarBlackList(address[] calldata list, bool isBlack) external onlyRole(OPERATOR_ROLE) {
        for (uint index = 0; index < list.length; index++) {
            avatarContractBlaclkList[list[index]] = isBlack;
        }
    }
    
}
