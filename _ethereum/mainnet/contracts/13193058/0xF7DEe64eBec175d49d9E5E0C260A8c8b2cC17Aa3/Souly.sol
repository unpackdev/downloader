//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721BurnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

contract Souly is ERC721BurnableUpgradeable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    event Mint(address indexed author, uint256 indexed tokenId, bytes32 indexed tokenHash);

    uint8 private constant COMMISSION_EXPONENT = 4;

    uint256 private _tokenCurrentId;

    address payable private _platformAddress;
    uint256 private _creatorCommission;
    uint256 private _platformCommission;
    mapping (uint256 => address payable) private _tokenCreator;

    struct EIP712DomainType {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    struct TransferType {
        address from;
        address to;
        uint256 tokenId;
        uint256 amount;
        uint256 validUntil;
    }

    bytes32 private constant EIP712DomainTypeHash = keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));
    bytes32 private constant TransferTypeHash = keccak256(bytes("Transfer(address from,address to,uint256 tokenId,uint256 amount,uint256 validUntil)"));
    bytes32 private _domainSeparator;

    string private __baseURI;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyAdmin(){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Souly: Caller is not a admin");
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Souly: Caller is not a minter");
        _;
    }

    function initialize(address payable platformAddress_, uint256 platformCommission_, uint256 creatorCommission_, string memory baseURI)
    initializer public {
        _platformAddress = platformAddress_;
        _platformCommission = platformCommission_;
        _creatorCommission = creatorCommission_;
        _domainSeparator = hash(EIP712DomainType("SuspendedSoul","2",block.chainid,address(this)));
        __ERC721Burnable_init();
        __ERC721_init("Souly", "SLY");
        __AccessControl_init();
        __baseURI = baseURI;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function creatorCommission() public view returns(uint256){
        return _creatorCommission;
    }

    function setCreatorCommission(uint256 creatorCommission_) public onlyAdmin {
        _creatorCommission = creatorCommission_;
    }

    function platformCommission() public view returns(uint256){
        return _platformCommission;
    }

    function setPlatformCommission(uint256 platformCommission_) public onlyAdmin {
        _platformCommission = platformCommission_;
    }

    function platformAddress() public view returns(address payable){
        return _platformAddress;
    }

    function setPlatformAddress(address payable platformAddress_) public onlyAdmin {
        _platformAddress = platformAddress_;
    }

    function setBaseURI(string memory baseURI) public onlyAdmin {
        __baseURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function creatorOf(uint256 tokenId) external view returns (address payable) {
        require(_tokenCreator[tokenId] != address(0x0), "Souly: Creator query for nonexistent token");
        return _tokenCreator[tokenId];
    }

    function tokenCreator(uint256 tokenId) public view returns (address) {
        return _tokenCreator[tokenId];
    }

    function mint(address payable creator, address to, bytes32 tokenHash) public onlyMinter returns (uint256) {
        require(creator != address(0), "Souly: Creator can't be 0x0");
        require(tokenHash != bytes32(0), "Souly: Hash can't be 0x0");
        _tokenCurrentId = _tokenCurrentId + 1;
        _mint(creator, _tokenCurrentId);
        _transfer(creator, to, _tokenCurrentId);
        _tokenCreator[_tokenCurrentId] = creator;
        emit Mint(creator, _tokenCurrentId, tokenHash);
        return _tokenCurrentId;
    }

    function batchMint(address payable[] memory creator, address to, bytes32[] memory tokenHashes) public {
        require(creator.length == tokenHashes.length, "Souly: Invalid arguments length");
        for (uint256 index; index < tokenHashes.length; index++){
            mint(creator[index],to,tokenHashes[index]);
        }
    }

    function hash(EIP712DomainType memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                EIP712DomainTypeHash,
                keccak256(bytes(eip712Domain.name)),
                keccak256(bytes(eip712Domain.version)),
                eip712Domain.chainId,
                eip712Domain.verifyingContract
            ));
    }

    function setDomainSeparator(string memory name, string memory version) external onlyAdmin {
        _domainSeparator = hash(EIP712DomainType(name, version, block.chainid, address(this)));
    }

    function hash(TransferType memory transfer) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            TransferTypeHash,
            transfer.from,
            transfer.to,
            transfer.tokenId,
            transfer.amount,
            transfer.validUntil
        ));
    }

    function executeTransferFrom(address payable from, address to, uint256 tokenId, uint256 amount, uint256 validUntil, bytes memory signature
    ) public payable {
        require(validUntil >= block.timestamp, "Souly: Relayed transfer expired");
        require(to == _msgSender(), "Souly: Invalid executor");
        uint256 platformCommission_ = amount.mul(_platformCommission).div(10** COMMISSION_EXPONENT);
        require(msg.value == amount.add(platformCommission_), "Souly: Invalid amount");

        bytes32 msgHash = keccak256(abi.encodePacked(
            "\x19\x01",
            _domainSeparator,

            hash(TransferType(address(from),to,tokenId,amount,validUntil))
        ));
        require(msgHash.recover(signature) == from, "Souly: Invalid signature");

        _transfer(from, to, tokenId);

        uint256 creatorCommission_ = amount.mul(_creatorCommission).div(10** COMMISSION_EXPONENT);

        _platformAddress.transfer(platformCommission_);
        _tokenCreator[tokenId].transfer(creatorCommission_);
        from.transfer(amount.sub(creatorCommission_));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable,AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function totalSupply() view public returns (uint256) {
        return _tokenCurrentId;
    }

}