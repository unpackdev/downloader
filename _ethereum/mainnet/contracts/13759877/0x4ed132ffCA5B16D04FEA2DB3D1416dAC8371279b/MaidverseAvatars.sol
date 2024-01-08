// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./IERC1271.sol";
import "./IMaidverseAvatars.sol";
import "./Signature.sol";

contract MaidverseAvatars is Ownable, ERC721("Maidverse Avatars", "MA"), ERC721Enumerable, IERC2981, IMaidverseAvatars {
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    // keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;

    // keccak256("Permit(address owner,address spender,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_ALL_TYPEHASH = 0xdaab21af31ece73a508939fedd476a5ee5129a5ed4bb091f3236ffb45394df62;

    mapping(uint256 => uint256) public nonces;
    mapping(address => uint256) public noncesForAll;

    mapping(address => bool) public isMinter;
    mapping(address => bool) public isBatchMinter;

    enum MinterType {
        Minter,
        BatchMinter
    }

    uint256 internal _totalSupply;

    address public feeReceiver;
    uint256 public fee; //out of 10000

    string internal __baseURI;
    string public contractURI;

    constructor(address _feeReceiver, uint256 _fee) {
        _CACHED_CHAIN_ID = block.chainid;
        _HASHED_NAME = keccak256(bytes("Maidverse Avatars"));
        _HASHED_VERSION = keccak256(bytes("1"));
        _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, _CACHED_CHAIN_ID, address(this))
        );

        _setMinter(msg.sender, true);
        _setBatchMinter(msg.sender, true);
        _setMinter(address(0), true);

        _setRoyaltyInfo(_feeReceiver, _fee);

        __baseURI = "https://api.maidverse.org/avatars/";
        contractURI = "https://api.maidverse.org/avatars";
    }

    function totalSupply() public view override(ERC721Enumerable, IERC721Enumerable) returns (uint256) {
        return _totalSupply;
    }

    function tokenByIndex(uint256 index) public view override(ERC721Enumerable, IERC721Enumerable) returns (uint256) {
        require(index < _totalSupply, "MaidverseAvatars: Invalid index");
        return index;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        __baseURI = baseURI_;

        emit SetBaseURI(baseURI_);
    }

    function setContractURI(string calldata uri) external onlyOwner {
        contractURI = uri;

        emit SetContractURI(uri);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return keccak256(abi.encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, block.chainid, address(this)));
        }
    }

    function permit(
        address spender,
        uint256 id,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, "MaidverseAvatars: Expired deadline");
        bytes32 _DOMAIN_SEPARATOR = DOMAIN_SEPARATOR();

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, spender, id, nonces[id]++, deadline))
            )
        );

        address owner = ownerOf(id);
        require(spender != owner, "MaidverseAvatars: Invalid spender");

        if (Address.isContract(owner)) {
            require(
                IERC1271(owner).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e,
                "MaidverseAvatars: Unauthorized"
            );
        } else {
            address recoveredAddress = Signature.recover(digest, v, r, s);
            require(recoveredAddress == owner, "MaidverseAvatars: Unauthorized");
        }

        _approve(spender, id);
    }

    function permitAll(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, "MaidverseAvatars: Expired deadline");
        bytes32 _DOMAIN_SEPARATOR = DOMAIN_SEPARATOR();

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_ALL_TYPEHASH, owner, spender, noncesForAll[owner]++, deadline))
            )
        );

        if (Address.isContract(owner)) {
            require(
                IERC1271(owner).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e,
                "MaidverseAvatars: Unauthorized"
            );
        } else {
            address recoveredAddress = Signature.recover(digest, v, r, s);
            require(recoveredAddress == owner, "MaidverseAvatars: Unauthorized");
        }

        _setApprovalForAll(owner, spender, true);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    function setMinter(address target, bool _isMinter, MinterType minterType) external onlyOwner {
        if (minterType == MinterType.Minter) {
            require(isMinter[target] != _isMinter, "MaidverseAvatars: Permission not changed");
            _setMinter(target, _isMinter);
        } else {
            require(isBatchMinter[target] != _isMinter, "MaidverseAvatars: Permission not changed");
            _setBatchMinter(target, _isMinter);
        }
    }

    function _setMinter(address target, bool _isMinter) internal {
        isMinter[target] = _isMinter;
        emit SetMinter(target, _isMinter);
    }

    function _setBatchMinter(address target, bool _isBatchMinter) internal {
        isBatchMinter[target] = _isBatchMinter;
        emit SetBatchMinter(target, _isBatchMinter);
    }

    function setRoyaltyInfo(address _receiver, uint256 _fee) external onlyOwner {
        _setRoyaltyInfo(_receiver, _fee);
    }

    function _setRoyaltyInfo(address _receiver, uint256 _fee) internal {
        require(_fee < 10000, "MaidverseAvatars: Invalid Fee");
        feeReceiver = _receiver;
        fee = _fee;
        emit SetRoyaltyInfo(_receiver, _fee);
    }

    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (feeReceiver, (_salePrice * fee) / 10000);
    }
    
    function mint(address to) external returns (uint256 id) {
        require(isMinter[address(0)] || isMinter[msg.sender], "MaidverseAvatars: Forbidden");
        id = _totalSupply;
        _mint(to, id);
        _totalSupply = id + 1;
    }

    function mintBatch(uint256 amounts) external {
        require(isBatchMinter[msg.sender], "MaidverseAvatars: Forbidden");
        uint256 from = _totalSupply;
        for (uint256 i = 0; i < amounts; i++) {
            _mint(msg.sender, from + i);
        }
        _totalSupply = from + amounts;
    }

    function mintBatchMulti(uint256 amounts, address[] calldata recipients) external {
        require(isBatchMinter[msg.sender], "MaidverseAvatars: Forbidden");
        require(recipients.length == amounts, "MaidverseAvatars: Invalid parameters");
        uint256 from = _totalSupply;
        for (uint256 i = 0; i < amounts; i++) {
            _mint(recipients[i], from + i);
        }
        _totalSupply = from + amounts;
    }
}
