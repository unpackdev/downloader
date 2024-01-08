pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";
import "./IERC777Recipient.sol";
import "./IERC777.sol";
import "./IERC1820Registry.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IRNG.sol";
import "./IRNGrequestor.sol";
import "./dust_redeemer.sol";

// import "./console.sol";

struct DustBuster {
    string  name;
    uint256 price;
    address vault;
    address token;
    uint256 reserved;
    address handler;
    bool    enabled;
}


contract dust_for_punkz is Ownable, dust_redeemer, IRNGrequestor,IERC777Recipient, ReentrancyGuard {

    IRNG          public rng;
    address       public DUST_TOKEN;

    uint256       public next_redeemable;
    mapping(uint256 => DustBuster)            redeemables;
    mapping(bytes32 => DustBusterPro)         waiting;
    mapping(address => bytes32[])      public userhashes;

    string constant public punksForDust = "https://www.youtube.com/watch?v=wsOHvP1XnRg";

    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    //
    // higher level than onlyAuth
    //
    event RedemptionRequest(bytes32 hash);

    constructor(IRNG _rng,address dust) {
        rng = _rng;
        DUST_TOKEN = dust;
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }

 
    function add_external_redeemer(
        string  memory name,
        uint256 price,
        address vault,
        address token,
        address handler
    ) external onlyOwner {
        redeemables[next_redeemable++] = DustBuster(name,price,vault,token,0,handler, true);
    }

    function add_721_vault(
        string  memory name,
        uint256 price,
        address vault,
        address token
    ) external onlyOwner {
        redeemables[next_redeemable++] = DustBuster(name,price,vault,token,0,address(this),true);
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

    function change_vault_price(uint vaultID, uint256 price) external onlyOwner {
        redeemables[vaultID].price = price;
    }

    function enable_vault(uint vaultID,  bool enabled) external onlyOwner {
        redeemables[vaultID].enabled = enabled;
    }


    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= (_start + 32), "Read out of bounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }
        return tempUint;
    }
 
    function tokensReceived(
        address ,
        address from,
        address ,
        uint256 amount,
        bytes calldata userData,
        bytes calldata
    ) external override nonReentrant {
        require(msg.sender == DUST_TOKEN,"Unauthorised");
        require(userData.length == 32,"Invalid user data");
        uint pos = toUint256(userData, 0);
        DustBuster memory db = redeemables[pos];
        require(db.enabled,"Vault not enabled");
        require(dust_redeemer(db.handler).balanceOf(db.token,db.vault) > db.reserved,"Insufficient tokens in vault");
        redeemables[pos].reserved++;
        require(amount>= db.price,"Insufficent Dust sent");
        bytes32 hash = rng.requestRandomNumberWithCallback( );
        waiting[hash] = DustBusterPro(db.name,db.vault,db.token,0,from, db.handler,pos,0,false);
        userhashes[from].push(hash);
        bytes memory data;
        IERC777(DUST_TOKEN).burn(amount,data);
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

    function process(uint256 rand, bytes32 requestId) external override {
        require(msg.sender == address(rng),"unauthorised");
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

    function redeemedTokenId(bytes32 hash) external view returns (uint256) {
        return waiting[hash].token_id;
    }

    function isTokenRedeemed(bytes32 hash) external view returns (bool) {
        return waiting[hash].redeemed;
    }


}