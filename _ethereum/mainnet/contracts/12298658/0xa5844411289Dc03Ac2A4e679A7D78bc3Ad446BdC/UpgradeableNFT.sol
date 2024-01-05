// contracts/ERC721PresetMinterPauserAutoIdUpgradeableCustomized.sol
// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./Initializable.sol";
// import "./ClonesUpgradeable.sol";
import "./StringsUpgradeable.sol";
/**
 * !!! Notice ERC721PresetMinterPauserAutoIdUpgradeableCustomized is a fork of ERC721PresetMinterPauserAutoIdUpgradeable
 *  its been adapted to support the ERC721URIStorageUpgradeable
 *  folowing IERC721Metadata-tokenURI metadata will be stored in IPFS
 *
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract UpgradeableNFT is Initializable, ContextUpgradeable, AccessControlEnumerableUpgradeable, ERC721EnumerableUpgradeable, ERC721BurnableUpgradeable, ERC721PausableUpgradeable, ERC721URIStorageUpgradeable {

    function initialize(string memory name, string memory symbol, string memory baseTokenURI) public virtual initializer {
        __ERC721PresetMinterPauserAutoId_init(name, symbol, baseTokenURI);
    }
    using CountersUpgradeable for CountersUpgradeable.Counter;

  // using SafeMathUpgradeable for uint256;
  // using StringsUpgradeable for string;
  
  enum  TokenState { Pending, ForSale, Sold, Transferred, Beta, Signer, Gov, Team, Founder, Obitel, Roads, Solomonic, Partreon, Process, NeedKYC, NeedSign, NeedDocument, Deprecated, Bonus, OnLoanDeal }

  enum  Category {FOCUS, ALLURE, INSPIRATION, EXCITEMENT, ELEMENTS, GEMINI, SINGULAR, REF_FOCUS, REF_ALLURE, REF_INSPIRATION, REF_EXCITEMENT, REF_ELEMENTS, REF_GEMINI, REF_SINGULAR, EARN, FOUNDER_ROLE, FEE_ROLE, OR_SOLOMONIC, OR_PARTREON, OR_PRIMATECH, OBITEL, ROADS, OR_FEE, OR_NFT, FUN, OR_RELAY}

  // struct Price {
  //   uint256 tokenId;
  //   uint256 price;
  //   string metaId;
  //   TokenState state;
  //   string Category;
  //   // TokenCategory state;
  // }

  // mapping(uint256 => Price) public items;

  // uint256 public id;

  // address payable feeAddress;



    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");

    bytes32 public constant OBITEL_ROLE = keccak256("OBITEL_ROLE");

    bytes32 public constant ROADS_ROLE = keccak256("ROADS_ROLE");

    bytes32 public constant LEGAL_ROLE = keccak256("LEGAL_ROLE");

    bytes32 public constant RSIVAKOV_ROLE = keccak256("RSIVAKOV_ROLE");

    bytes32 public constant ZHANNA_ROLE = keccak256("ZHANNA_ROLE");

    bytes32 public constant DANA_ROLE = keccak256("DANA_ROLE");

    bytes32 public constant ARTSH_ROLE = keccak256("ARTSH_ROLE");

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    bytes32 public constant AUDIT_ROLE = keccak256("AUDIT_ROLE");

    bytes32 public constant SOLOMONIC_ROLE = keccak256("SOLOMONIC_ROLE");

    bytes32 public constant PARTREON_ROLE = keccak256("PARTREON_ROLE");

    bytes32 public constant PRIMATECH_ROLE = keccak256("PRIMATECH_ROLE");

    bytes32 public constant NFT_ROLE = keccak256("NFT_ROLE");

    bytes32 public constant FEE_ROLE = keccak256("FEE_ROLE");

    bytes32 public constant GOLD_ROLE = keccak256("GOLD_ROLE");

    bytes32 public constant BLINK_BEACON_ROLE = keccak256("BLINK_BEACON_ROLE");

    bytes32 public constant BLINK_ORACLE_ROLE = keccak256("BLINK_ORACLE_ROLE");


    CountersUpgradeable.Counter private _tokenIdTracker;

    string private _baseTokenURI;
    string private _contractURI;



//   event ErrorOut(string error, uint256 tokenId);
//   event BatchTransfered(string metaId, address[] recipients, uint256[] ids);
//   event Minted(uint256 id, string metaId);
//   event BatchBurned(string metaId, uint256[] ids);
//   event BatchForSale(uint256[] ids, string metaId);
//   event Bought(uint256 tokenId, string metaId, uint256 value);
//   event Destroy();




    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be set with in IPFS persisted metadata ipfsHash value.
     * See {ERC721-tokenURI}.
     */
    function __ERC721PresetMinterPauserAutoId_init(string memory name, string memory symbol, string memory baseTokenURI) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC721_init_unchained(name, symbol);
        __ERC721Enumerable_init_unchained();
        __ERC721Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC721Pausable_init_unchained();
        __ERC721PresetMinterPauserAutoId_init_unchained(baseTokenURI);
    }

    function __ERC721PresetMinterPauserAutoId_init_unchained(string memory baseTokenURI) internal initializer {
        _baseTokenURI = baseTokenURI;
        _contractURI = baseTokenURI;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(FOUNDER_ROLE, _msgSender());
        _setupRole(OBITEL_ROLE, _msgSender());
        _setupRole(ROADS_ROLE, _msgSender());
        _setupRole(LEGAL_ROLE, _msgSender());
        _setupRole(RSIVAKOV_ROLE, _msgSender());
        _setupRole(ZHANNA_ROLE, _msgSender());
        _setupRole(DANA_ROLE, _msgSender());
        _setupRole(ARTSH_ROLE, _msgSender());
        _setupRole(SIGNER_ROLE, _msgSender());
        _setupRole(AUDIT_ROLE, _msgSender());
        _setupRole(SOLOMONIC_ROLE, _msgSender());
        _setupRole(PARTREON_ROLE, _msgSender());
        _setupRole(PRIMATECH_ROLE, _msgSender());
        _setupRole(NFT_ROLE, _msgSender());
        _setupRole(FEE_ROLE, _msgSender());
        _setupRole(BLINK_BEACON_ROLE, _msgSender());
        _setupRole(BLINK_ORACLE_ROLE, _msgSender());
    }


    // function contractURI() public view returns (string memory) {
    //     return "https://metadata-url.com/my-metadata";
    // }

    /**
    * @dev returns _baseTokenURI value of 'ipfs://' .
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI();
    }
    /**
    * @dev returns _baseTokenURI value of 'ipfs://' .
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * an IpfsHash is passed as the IERC721Metadata-tokenURI, metadata is persisted in IPFS before minting
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, string memory hash) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");

        uint256 newItemId = _tokenIdTracker.current();
        
        _mint(to, newItemId);
        ERC721URIStorageUpgradeable._setTokenURI(newItemId, hash);
        _tokenIdTracker.increment();
    }

    function _burn(uint256 tokenId) internal override(ERC721URIStorageUpgradeable, ERC721Upgradeable) {
        ERC721Upgradeable._burn(tokenId);
        ERC721URIStorageUpgradeable._burn(tokenId);
    }

    /**
    * @dev See {IERC721Metadata-tokenURI}.
    */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (string memory) {
        // return Strings.strConcat(
        //     _baseTokenURI(),
        //     Strings.uint2str(tokenId)
        // );
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    
    /**
     * @dev Add Token URI On IPFS by TokenId
     */
    function _setTokenURI(uint256 tokenId, string memory hash) internal virtual override {
        ERC721URIStorageUpgradeable._setTokenURI(tokenId, hash);
    }


    function setBaseTokenURI(string memory baseTokenURI) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "setBaseTokenURI: must have ADMIN role to change this");
        _baseTokenURI = baseTokenURI;
    }



    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Add Token URI On IPFS by TokenId
     */
    function _setContractURI(string memory hash) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "setBaseTokenURI: must have ADMIN role to change this");
        _contractURI = hash;
    }






    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
//TODO: Нужно Вынести в библиотеки
  //   function batchTransfer(address giver, address[] memory recipients, uint256[] memory values) public virtual {
  //   require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "batchTransfer: must have ADMIN role to change this");

  //   for (uint256 i = 0; i < values.length; i++) {
  //     transferFrom(giver, recipients[i], values[i]);
  //    items[values[i]].state = TokenState.Transferred;
  //   }
  //   emit BatchTransfered(items[values[0]].metaId, recipients, values);
  // }

  // function batchMint(address to, uint256 amountToMint, string memory metaId, uint256 setPrice, bool isForSale, string enum   ) public virtual {
  //   require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");
  //   require(amountToMint <= 112, "Over 112");

  //   for (uint256 i = 0; i < amountToMint; i++) {
  //     id = id.add(1);
  //     items[id].price = setPrice;
  //     items[id].metaId = metaId;
  //     if(isForSale == true){
  //       items[id].state = TokenState.ForSale;
        
  //     } else {
  //       items[id].state = TokenState.Pending;
  //     }
  //     _mint(to, id);
  //     emit Minted(id, metaId);
  //   }
   
  // }

  // function batchBurn(uint256[] memory tokenIds) public  {
  //   require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");
  //   for (uint256 i = 0; i < tokenIds.length; i++) {
  //     _burn(tokenIds[i]);
  //   }
  //   emit BatchBurned(items[tokenIds[0]].metaId, tokenIds);
  // }




    uint256[48] private __gap;
}