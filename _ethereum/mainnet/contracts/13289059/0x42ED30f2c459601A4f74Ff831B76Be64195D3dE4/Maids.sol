// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./IUniswapV2Pair.sol";
import "./IERC1271.sol";
import "./IMaids.sol";
import "./Signature.sol";
import "./MasterChefModule.sol";
import "./IERC2981.sol";

contract Maids is Ownable, ERC721("MaidCoin Maids", "MAIDS"), ERC721Enumerable, MasterChefModule, IERC2981, IMaids {
    struct MaidInfo {
        uint256 originPower;
        uint256 supportedLPTokenAmount;
        uint256 sushiRewardDebt;
    }

    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    // keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH =
        0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;

    // keccak256("Permit(address owner,address spender,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_ALL_TYPEHASH =
        0xdaab21af31ece73a508939fedd476a5ee5129a5ed4bb091f3236ffb45394df62;

    uint256 public constant override MAX_MAID_COUNT = 1000;

    mapping(uint256 => uint256) public override nonces;
    mapping(address => uint256) public override noncesForAll;

    MaidInfo[] public override maids;

    uint256 private royaltyFee = 25; // out of 1000
    address private royaltyReceiver; // MaidCafe

    constructor(
        IUniswapV2Pair _lpToken,
        IERC20 _sushi,
        address _royaltyReceiver
    ) MasterChefModule(_lpToken, _sushi) {
        _CACHED_CHAIN_ID = block.chainid;
        _HASHED_NAME = keccak256(bytes("MaidCoin Maids"));
        _HASHED_VERSION = keccak256(bytes("1"));
        _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("MaidCoin Maids")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        royaltyReceiver = _royaltyReceiver;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.maidcoin.org/maids/";
    }

    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return keccak256(abi.encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, block.chainid, address(this)));
        }
    }

    function totalSupply() public view override(ERC721Enumerable, IERC721Enumerable) returns (uint256) {
        return maids.length;
    }

    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override(ERC721Enumerable, IERC721Enumerable)
        returns (uint256)
    {
        require(index < totalSupply(), "Maids: Invalid index");
        return index;
    }

    function mint(uint256 power) public onlyOwner returns (uint256 id) {
        id = maids.length;
        require(id < MAX_MAID_COUNT, "Maids: Maximum Maids");
        maids.push(MaidInfo({originPower: power, supportedLPTokenAmount: 0, sushiRewardDebt: 0}));
        _mint(msg.sender, id);
    }

    function mintBatch(uint256[] calldata powers, uint256 amounts) external onlyOwner {
        require(powers.length == amounts, "Maids: Invalid parameters");
        uint256 from = maids.length;
        for (uint256 i = 0; i < amounts; i += 1) {
            maids.push(MaidInfo({originPower: powers[i], supportedLPTokenAmount: 0, sushiRewardDebt: 0}));
            _mint(msg.sender, (i + from));
        }
    }

    function powerAndLP(uint256 id) external view override returns (uint256, uint256) {
        MaidInfo storage maid = maids[id];
        return (maid.originPower, maid.supportedLPTokenAmount);
    }

    function support(uint256 id, uint256 lpTokenAmount) public override {
        require(ownerOf(id) == msg.sender, "Maids: Forbidden");
        require(lpTokenAmount > 0, "Maids: Invalid lpTokenAmount");
        uint256 _supportedLPTokenAmount = maids[id].supportedLPTokenAmount;

        maids[id].supportedLPTokenAmount = _supportedLPTokenAmount + lpTokenAmount;
        lpToken.transferFrom(msg.sender, address(this), lpTokenAmount);

        uint256 _pid = masterChefPid;
        if (_pid > 0) {
            maids[id].sushiRewardDebt = _depositModule(
                _pid,
                lpTokenAmount,
                _supportedLPTokenAmount,
                maids[id].sushiRewardDebt
            );
        }

        emit Support(id, lpTokenAmount);
    }

    function supportWithPermit(
        uint256 id,
        uint256 lpTokenAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        lpToken.permit(msg.sender, address(this), lpTokenAmount, deadline, v, r, s);
        support(id, lpTokenAmount);
    }

    function desupport(uint256 id, uint256 lpTokenAmount) external override {
        require(ownerOf(id) == msg.sender, "Maids: Forbidden");
        require(lpTokenAmount > 0, "Maids: Invalid lpTokenAmount");
        uint256 _supportedLPTokenAmount = maids[id].supportedLPTokenAmount;

        maids[id].supportedLPTokenAmount = _supportedLPTokenAmount - lpTokenAmount;

        uint256 _pid = masterChefPid;
        if (_pid > 0) {
            maids[id].sushiRewardDebt = _withdrawModule(
                _pid,
                lpTokenAmount,
                _supportedLPTokenAmount,
                maids[id].sushiRewardDebt
            );
        }

        lpToken.transfer(msg.sender, lpTokenAmount);
        emit Desupport(id, lpTokenAmount);
    }

    function claimSushiReward(uint256 id) public override {
        require(ownerOf(id) == msg.sender, "Maids: Forbidden");
        maids[id].sushiRewardDebt = _claimSushiReward(maids[id].supportedLPTokenAmount, maids[id].sushiRewardDebt);
    }

    function pendingSushiReward(uint256 id) external view override returns (uint256) {
        return _pendingSushiReward(maids[id].supportedLPTokenAmount, maids[id].sushiRewardDebt);
    }

    function permit(
        address spender,
        uint256 id,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(block.timestamp <= deadline, "Maids: Expired deadline");
        bytes32 _DOMAIN_SEPARATOR = DOMAIN_SEPARATOR();

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, spender, id, nonces[id], deadline))
            )
        );
        nonces[id] += 1;

        address owner = ownerOf(id);
        require(spender != owner, "Maids: Invalid spender");

        if (Address.isContract(owner)) {
            require(
                IERC1271(owner).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e,
                "Maids: Unauthorized"
            );
        } else {
            address recoveredAddress = Signature.recover(digest, v, r, s);
            require(recoveredAddress == owner, "Maids: Unauthorized");
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
    ) external override {
        require(block.timestamp <= deadline, "Maids: Expired deadline");
        bytes32 _DOMAIN_SEPARATOR = DOMAIN_SEPARATOR();

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_ALL_TYPEHASH, owner, spender, noncesForAll[owner], deadline))
            )
        );
        noncesForAll[owner] += 1;

        if (Address.isContract(owner)) {
            require(
                IERC1271(owner).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e,
                "Maids: Unauthorized"
            );
        } else {
            address recoveredAddress = Signature.recover(digest, v, r, s);
            require(recoveredAddress == owner, "Maids: Unauthorized");
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

    function royaltyInfo(uint256, uint256 _salePrice) external view override returns (address, uint256) {
        return (royaltyReceiver, (_salePrice * royaltyFee) / 1000);
    }

    function setRoyaltyInfo(address _receiver, uint256 _royaltyFee) external onlyOwner {
        royaltyReceiver = _receiver;
        royaltyFee = _royaltyFee;
    }
}
