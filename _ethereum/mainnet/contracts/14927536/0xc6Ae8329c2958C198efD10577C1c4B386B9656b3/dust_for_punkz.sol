pragma solidity ^0.8.13;

import "./IERC721Enumerable.sol";
import "./IERC777Recipient.sol";
import "./IERC777.sol";
import "./IERC1820Registry.sol";

import "./IRNGV2.sol";
import "./IRNGrequestorV2.sol";
import "./dust_redeemer.sol";
import "./IRegistryConsumer.sol";

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";


// import "./console.sol";

struct DustBuster {
    string  name;
    uint256 price;
    uint256 remaining;
    address vault;
    address token;
    uint256 reserved;
    address handler;
    address destination; // Zero if for burning
    bool    enabled;
}


contract dust_for_punkz is Initializable, OwnableUpgradeable,  dust_redeemer, IRNGrequestorV2,IERC777Recipient, ReentrancyGuardUpgradeable {

    RegistryConsumer   constant public reg = RegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);

    uint256       public next_redeemable;
    mapping(uint256 => DustBuster)            redeemables;
    mapping(uint256 => DustBusterPro)         waiting;
    mapping(address => uint256[])      public userhashes;

    string constant public punksForDust = "https://www.youtube.com/watch?v=wsOHvP1XnRg";

    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    //
    // higher level than onlyAuth
    //
    event RedemptionRequest(uint256 hash);

    modifier onlyAppAdmin() {
        require(
            msg.sender == owner() ||
            reg.isAppAdmin(address(this),msg.sender),
            "AppAdmin : Unauthorised"
        );
        _;
    }

    function initialize() public initializer {
        require(rngAddress() != address(0),"Rng address not set in registry");
        require(dustAddress() != address(0),"DUST address not set in registry");
        
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        __Ownable_init();
    }

 
    function add_external_redeemer(
        string  memory name,
        uint256 price,
        uint256 remaining,
        address vault,
        address token,
        address handler,
        address destinasi
    ) external onlyAppAdmin {
        redeemables[next_redeemable++] = DustBuster(name,price,remaining, vault,token,0,handler, destinasi, true);
    }

    function add_721_vault(
        string  memory name,
        uint256 price,
        uint256 remaining,
        address vault,
        address token,
        address destinasi
    ) external onlyAppAdmin {
        require(IERC721(token).isApprovedForAll(vault,address(this)),"Token vault has not approved this contract");
        redeemables[next_redeemable++] = DustBuster(name,price, remaining,vault,token,0,address(this),destinasi,true);
    }

    function vaultName(uint256 vaultID) external view returns (string memory) {
        return redeemables[vaultID].name;
    }

    function vaultPrice(uint256 vaultID) external view returns (uint256) {
        return redeemables[vaultID].price;
    }

    function vaultAddress(uint256 vaultID) external view returns (address) {
        return redeemables[vaultID].vault;
    }

    function vaultToken(uint256 vaultID) external view returns (address) {
        return redeemables[vaultID].token;
    }

    function change_vault_price(uint vaultID, uint256 price) external onlyAppAdmin {
        redeemables[vaultID].price = price;
    }

    function enable_vault(uint vaultID,  bool enabled) external onlyAppAdmin {
        redeemables[vaultID].enabled = enabled;
    }
 
    function tokensReceived(
        address ,
        address from,
        address ,
        uint256 amount,
        bytes calldata userData,
        bytes calldata
    ) external override nonReentrant {
        require(msg.sender == dustAddress(),"Unauthorised");
        require(userData.length == 32,"Invalid user data");
        uint pos = uint256(bytes32(userData[0:32]));
        DustBuster memory db = redeemables[pos];
        require(db.enabled,"Vault not enabled");
        require(IERC721(db.token).isApprovedForAll(db.vault,address(this)),"Token vault has not approved this contract");
        require(dust_redeemer(db.handler).balanceOf(db.token,db.vault) > db.reserved,"Insufficient tokens in vault");
        require(db.remaining > 0, "Insufficient tokens available");
        redeemables[pos].reserved++;
        require(amount>= db.price,"Insufficent Dust sent");
        uint256 hash = rng().requestRandomNumberWithCallback( );
        waiting[hash] = DustBusterPro(db.name,db.vault,db.token,0,from, db.handler,pos,0,false);
        userhashes[from].push(hash);
        bytes memory data;
        redeemables[pos].remaining--;
        if (db.destination == address(0)){
            IERC777(dustAddress()).burn(amount,data);
        } else {
            IERC777(dustAddress()).send(db.destination,amount,data);
        }
        emit RedemptionRequest(hash);
    }


    // The built in function assumes that the token is an ERC721. 
    // This cannot be called directly - only from this contract as 
    function redeem(DustBusterPro memory general) external override returns (uint256) {
        require(msg.sender == address(this),"Invalid sender");
        IERC721Enumerable  token = IERC721Enumerable(general.token);
        require(token.supportsInterface(type(IERC721Enumerable).interfaceId),"Not an ERC721Enumerable");
        uint256 balance = token.balanceOf(general.vault);
        require(balance > 0,"No NFTs in vault");
        uint256 tokenPos = general.random % balance;
        uint256 tokenId = token.tokenOfOwnerByIndex(general.vault, tokenPos);
        token.safeTransferFrom(general.vault,general.recipient,tokenId);
        return tokenId;
    }

    function balanceOf(address token, address vault) external override view returns(uint256) {
        return IERC721Enumerable(token).balanceOf(vault);
    }

    function process(uint256 rand, uint256 requestId) external override {
        require(msg.sender == rngAddress(),"unauthorised");
        DustBusterPro memory dbp = waiting[requestId];
        dbp.random = rand;
        redeemables[dbp.position].reserved--;
        uint256 tokenId = dust_redeemer(dbp.handler).redeem(dbp);
        dbp.token_id = tokenId;
        dbp.redeemed = true;
        waiting[requestId] = dbp;
    }

    function numberOfHashes(address user) external view returns (uint256){
        return userhashes[user].length;
    }

    function redeemedTokenId(uint256 hash) external view returns (uint256) {
        return waiting[hash].token_id;
    }

    function isTokenRedeemed(uint256 hash) external view returns (bool) {
        return waiting[hash].redeemed;
    }

    function rngAddress() internal view returns (address) {
        return reg.getRegistryAddress("RANDOMV2");
    }

    function rng() internal view returns (IRNGV2) {
        return IRNGV2(rngAddress());
    }

    function dustAddress() internal view returns (address) {
        return reg.getRegistryAddress("DUST");
    }

}