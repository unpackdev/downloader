// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./UUPSUpgradeable.sol";
import "./Initializable.sol";
// import "./AccessControl.sol";
import "./AccessControlUpgradeable.sol";
// import "./ECDSA.sol";
import "./ECDSAUpgradeable.sol";
// import "./draft-EIP712.sol";
import "./EIP712Upgradeable.sol";
// import "./Ownable2Step.sol";
import "./Ownable2StepUpgradeable.sol";
// import "./ReentrancyGuard.sol";
import "./ReentrancyGuardUpgradeable.sol";
// import "./ERC721URIStorage.sol";
import "./ERC721URIStorageUpgradeable.sol";
// import "./Ownable.sol";
// import "./Counters.sol";
import "./CountersUpgradeable.sol";
import "./console.sol";

contract LeafNFTContractUpgradeable is Initializable, ERC721URIStorageUpgradeable, Ownable2StepUpgradeable, 
        EIP712Upgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenAmount; // start from 1

    string private constant SIGNING_DOMAIN = "Leaf-Voucher";
    string private constant SIGNATURE_VERSION = "1";
    uint256 public constant UNITS = 10 ** 8;
    uint256 public constant DECIMAL = 10 ** 18;

    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

    // uint256 public fee = 250;//0.08 = 2.5%
    uint256 public fee;
    address public nftContractSigner;
    address public marketContract;
    address public sbtContract;

    mapping(bytes32 => bool) nftUsedSignatures;

    enum Action { Payment, MintToken}
    struct NFTVoucher {
        address creator;
        address recipient;
        uint256 tokenId;
        uint256 royalty;
        uint256 price;
        uint256 nonce;
        uint8 action;
        string uri;
        bytes signature;
    }

    event NFTMintEvent(
        address indexed minter,
        address indexed creator, 
        uint256 tokenId,
        uint256 price,
        string tokenUrl,
        uint256 creatorAmount
    );

    event ApproveAllEvent(
        address owner,
        address operator ,
        bool approved
    );

    event PaymentEvent(
        address indexed user,
        address indexed creator,
        uint256 tokenId,
        uint256 price,
        uint256 creatorAmount
    );

    event BurnEvent(
        uint256 tokenId,
        address indexed owner
    );

    event ApproveEvent(
        uint256 tokenId,
        address indexed to
    );

    event WithdrawEvent(
        uint256 amount,
        address indexed owner
    );

    event MarketContractEvent(
        address indexed market
    );

    event SBTContractEvent(
        address indexed sbtContract
    );

    event SignerEvent(
        address indexed signer
    );

    event FeeEvent(
        uint256 fee
    );

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), 'Caller is not a admin');
        _;
    }
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), 'Caller is not a minter');
        _;
    }

    function initialize() initializer public {
        __ERC721_init("Leaf-NFT", "Leaf");
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
        __AccessControl_init();
        __ReentrancyGuard_init();
        __Ownable2Step_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        fee = 2500000;//0.08 = 2.5%
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function payment(NFTVoucher calldata voucher) external payable nonReentrant{
        require(voucher.action == uint8(Action.Payment), "Invalid action");
        bytes32 messageHash = nftVoucherValidation(voucher,false);
        uint256 price = voucher.price * DECIMAL / UNITS;
        require(msg.value >= price, "Insufficient funds");

        //Calculate Fees
        uint256 platformFee = price * fee / DECIMAL;
        uint256 creatorAmount = price - platformFee;

        //transfer
        payable(voucher.creator).transfer(creatorAmount);        

        nftUsedSignatures[messageHash] = true;
        emit PaymentEvent(
            msg.sender,
            voucher.creator,
            voucher.tokenId,
            voucher.price,
            creatorAmount
        );
    }

    function mintToken(NFTVoucher calldata voucher) external payable  nonReentrant{
        require(voucher.action == uint8(Action.MintToken), "Invalid action");
        bytes32 messageHash = nftVoucherValidation(voucher,false);
        require(!_exists(voucher.tokenId), "tokenId already exists");
        uint256 price = voucher.price * DECIMAL / UNITS;
        require(msg.value >= price, "Insufficient funds");

        //Calculate Fees
        uint256 platformFee = price * fee / DECIMAL;
        uint256 creatorAmount = price - platformFee;

        //transfer
        payable(voucher.creator).transfer(creatorAmount);   

        //mint
        _safeMint(voucher.recipient, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);
    
        nftUsedSignatures[messageHash] = true;
        _tokenAmount.increment();
        emit NFTMintEvent(
            voucher.recipient,
            voucher.creator,
            voucher.tokenId,
            voucher.price,
            voucher.uri,
            creatorAmount
        );
    }

    function mintTokenAdmin(NFTVoucher calldata voucher) external onlyMinter nonReentrant{
        require(voucher.action == uint8(Action.MintToken), "Invalid action");
        bytes32 messageHash = nftVoucherValidation(voucher,true);
        require(!_exists(voucher.tokenId), "tokenId already exists");

        //mint
        _safeMint(voucher.recipient, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);
    
        nftUsedSignatures[messageHash] = true;
        _tokenAmount.increment();
        emit NFTMintEvent(
            voucher.recipient,
            voucher.creator,
            voucher.tokenId,
            voucher.price,
            voucher.uri,
            0   // Payment in legal tender
        );
    }

    function approve(address to, uint256 tokenId) public virtual override(ERC721Upgradeable, IERC721Upgradeable)  nonReentrant{
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );
        require(marketContract != address(0),"Marketplace address was not set");
        require(compareAddresses(to, marketContract),'Can only approve leaf marketplace'); 
        super._approve(to, tokenId);
        emit ApproveEvent(tokenId, to);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721Upgradeable, IERC721Upgradeable)  nonReentrant{
        require(compareAddresses(operator, marketContract),'Can only approve leaf marketplace'); 
        super._setApprovalForAll(_msgSender(), operator, approved);
        emit ApproveAllEvent(
            msg.sender,
            operator,
            approved
        );
    }

     function burn(uint256 _tokenId, address _address) external nonReentrant {
        require(msg.sender == sbtContract,"Invalid caller");
        require(_address != address(0),"Invalid address");
        address owner = _ownerOf(_tokenId);
        require(_address == owner,"Owner address incorrect!");
        super._burn(_tokenId);
        emit BurnEvent(
            _tokenId, 
            owner
        );
     }

    function withdraw() payable external nonReentrant onlyOwner{
        address payable to = payable(msg.sender);
        uint256 amount = address(this).balance;
        require(amount != 0, "Insufficient Error");
        to.transfer(amount);
        emit WithdrawEvent(
            amount,
            msg.sender
        );
    }

    function setMarketContract(address _address) external onlyAdmin{
        require(_address != address(0), "Invalid address");
        marketContract = _address;
        emit MarketContractEvent(marketContract);
    }

    function setSBTContract(address _address) external onlyAdmin{
        require(_address != address(0), "Invalid address");
        sbtContract = _address;
        emit SBTContractEvent(sbtContract);
    }

    function setNftSigner(address _address) external onlyAdmin{
        require(_address != address(0), "Invalid address");
        nftContractSigner = _address;
        emit SignerEvent(nftContractSigner);
    }     


    function setFee(uint256 _fee) external onlyAdmin(){
        require(_fee < 100000000,"Invalid fee");
        fee = _fee;
        emit FeeEvent(fee);
    }

    function exists(uint256 _tokenId) public view returns (bool) {
       return super._exists(_tokenId);
    }

    function nftVoucherValidation(NFTVoucher calldata voucher,bool isAdmin) internal view returns(bytes32){
        bytes32 messageHash = keccak256(abi.encodePacked(voucher.signature, msg.sender));

        require(msg.sender != address(0),'Invalid address');
        require(voucher.creator != address(0),'Invalid address');
        require(voucher.recipient != address(0),'Invalid address');
        require(!nftUsedSignatures[messageHash], "Signature already used");

        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);
        require(nftContractSigner == signer, "Signature invalid or unauthorized");

        if(!isAdmin){
            //check nftContractSigner Address
            require(compareAddresses(voucher.recipient, msg.sender),'You can not mint'); 
        }
        
        return messageHash;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControlUpgradeable,ERC721URIStorageUpgradeable) returns (bool) {
        return ERC721URIStorageUpgradeable.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
        keccak256("NFTVoucher(address creator,address recipient,uint256 tokenId,uint256 royalty,uint256 price,uint256 nonce,uint8 action,string uri)"),
        voucher.creator,
        voucher.recipient,
        voucher.tokenId,
        voucher.royalty,
        voucher.price,
        voucher.nonce,
        voucher.action,
        keccak256(bytes(voucher.uri))
        )));
    }

    function _verify(NFTVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
         return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function compareAddresses(address addr1, address addr2) internal pure returns(bool) {
        bytes20 b1 = bytes20(addr1);
        bytes20 b2 = bytes20(addr2);
        bytes memory b1hash = abi.encodePacked(ripemd160(abi.encodePacked(b1)));
        bytes memory b2hash = abi.encodePacked(ripemd160(abi.encodePacked(b2)));
        return keccak256(b1hash) == keccak256(b2hash);
    }  
}