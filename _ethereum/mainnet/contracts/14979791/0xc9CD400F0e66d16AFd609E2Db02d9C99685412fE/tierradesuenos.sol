// SPDX-License-Identifier: MIT
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
/*
The official genesis photography project by Gabriela Gabrielaa


        ,----,                                                                                                                                                                     
      ,/   .`|                                                                                                                                                                     
    ,`   .'  :                                                           ,---,                ,--,             .--.--.                                                             
  ;    ;     / ,--,                                                    .'  .' `\            ,--.'|            /  /    '.                                                           
.'___,/    ,',--.'|               __  ,-.  __  ,-.                   ,---.'     \           |  | :           |  :  /`. /          ,--,                ,---,    ,---.               
|    :     | |  |,              ,' ,'/ /|,' ,'/ /|                   |   |  .`\  |          :  : '           ;  |  |--`         ,'_ /|            ,-+-. /  |  '   ,'\   .--.--.    
;    |.';  ; `--'_       ,---.  '  | |' |'  | |' | ,--.--.           :   : |  '  |   ,---.  |  ' |           |  :  ;_      .--. |  | :    ,---.  ,--.'|'   | /   /   | /  /    '   
`----'  |  | ,' ,'|     /     \ |  |   ,'|  |   ,'/       \          |   ' '  ;  :  /     \ '  | |            \  \    `. ,'_ /| :  . |   /     \|   |  ,"' |.   ; ,. :|  :  /`./   
    '   :  ; '  | |    /    /  |'  :  /  '  :  / .--.  .-. |         '   | ;  .  | /    /  ||  | :             `----.   \|  ' | |  . .  /    /  |   | /  | |'   | |: :|  :  ;_     
    |   |  ' |  | :   .    ' / ||  | '   |  | '   \__\/: . .         |   | :  |  '.    ' / |'  : |__           __ \  \  ||  | ' |  | | .    ' / |   | |  | |'   | .; : \  \    `.  
    '   :  | '  : |__ '   ;   /|;  : |   ;  : |   ," .--.; |         '   : | /  ; '   ;   /||  | '.'|         /  /`--'  /:  | : ;  ; | '   ;   /|   | |  |/ |   :    |  `----.   \ 
    ;   |.'  |  | '.'|'   |  / ||  , ;   |  , ;  /  /  ,.  |         |   | '` ,/  '   |  / |;  :    ;        '--'.     / '  :  `--'   \'   |  / |   | |--'   \   \  /  /  /`--'  / 
    '---'    ;  :    ;|   :    | ---'     ---'  ;  :   .'   \        ;   :  .'    |   :    ||  ,   /           `--'---'  :  ,      .-./|   :    |   |/        `----'  '--'.     /  
             |  ,   /  \   \  /                 |  ,     .-./        |   ,.'       \   \  /  ---`-'                       `--`----'     \   \  /'---'                   `--'---'   
              ---`-'    `----'                   `--`---'            '---'          `----'                                               `----'                                    
                                                                                                                                                                                   



*/
pragma solidity ^0.8.4;

import "./ERC721URIStorage.sol";
import "./IERC2981.sol";

import "./Ownable.sol";

import "./AccessControl.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract TierraDeSuenos is ERC721URIStorage, IERC2981, Ownable, AccessControl {
    using Strings for uint256;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    string private baseURI;
    
    // OpenSea Proxy Variables
    address private openSeaProxyRegistryAddress;
    bool private isOpenSeaProxyActive = true;
    address private ownerAddress = 0x746514Ce362560C24b7d01827a32436a49C9cD41;
    address private managerAddress = 0xa7E458A1b32070387e7548063E1F5e7f3982E6D1;
    address private crossmintAddress = 0xdAb1a1854214684acE522439684a145E62505233;
    // 13 chapters 1/1's
    // 13 Airdropped full videos
    uint256 public constant maxChapters = 13;

    uint256 public constant SALE_PRICE = 1 ether;
    bool public isPublicSaleActive;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier publicSaleActive() {
        require(
            isPublicSaleActive,
            "Public sale is not open"
        );
        _;
    }

    // Only mint chapters 1
    modifier canMintChapter(uint256 tokenId) {
        require(
            !(_exists(tokenId)),
            "NFT has already been minted."
        );
        _;
    }

    modifier isCorrectPayment(uint256 price) {
        require(
            price == msg.value || msg.sender == ownerAddress,
            "Incorrect ETH value sent"
        );
        _;
    }
    
    // https://etherscan.io/address/0x5180db8f5c931aae63c74266b211f580155ecac8#code
    constructor(
        address _openSeaProxyRegistryAddress
    ) ERC721("TierraDeSuenos", "TIERRA") {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MANAGER_ROLE, msg.sender);
        grantRole(MANAGER_ROLE, managerAddress);
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============
    function mint(uint256 tokenId)
        external
        payable
        publicSaleActive
        canMintChapter(tokenId)
        isCorrectPayment(SALE_PRICE)
    {
        payable(address(ownerAddress)).transfer(msg.value);

        _safeMint(msg.sender,tokenId);
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function claimAirdrops()
        external
        onlyOwner
    {
        for (uint256 i = 0; i < maxChapters; i++) {
            _safeMint(ownerAddress, i + maxChapters);
        }

    }

    // ============ MANAGER-ONLY ADMIN FUNCTIONS ============

    function setBaseURI(string memory _baseURI) public onlyRole(MANAGER_ROLE) {
        baseURI = _baseURI;
    }

    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyRole(MANAGER_ROLE)
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    // ============ FUNCTION OVERRIDES ============

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

        /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return string(bytes.concat(bytes(baseURI), "/", bytes(tokenId.toString()), ".json"));
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
     // Check out royalty registry as alternative
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(ownerAddress), SafeMath.div(SafeMath.mul(salePrice, 10), 100));
    }
}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}