// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IUniswapV2Pair.sol";
import "./IERC1271.sol";
import "./ILingerieGirls.sol";
import "./Signature.sol";
import "./MasterChefModule.sol";

contract LingerieGirls is
    Ownable,
    ERC721("MaidCoin Lingerie Girls", "LINGERIEGIRLS"),
    ERC721Enumerable,
    MasterChefModule,
    ILingerieGirls
{
    struct LingerieGirlInfo {
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

    mapping(uint256 => uint256) public override nonces;
    mapping(address => uint256) public override noncesForAll;

    uint256 public override lpTokenToLingerieGirlPower = 1;
    LingerieGirlInfo[] public override lingerieGirls;

    constructor(
        IUniswapV2Pair _lpToken,
        IERC20 _sushi,
        uint256[30] memory powers
    ) MasterChefModule(_lpToken, _sushi) {
        _CACHED_CHAIN_ID = block.chainid;
        _HASHED_NAME = keccak256(bytes("MaidCoin Lingerie Girls"));
        _HASHED_VERSION = keccak256(bytes("1"));
        _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("MaidCoin Lingerie Girls")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        for (uint256 i = 0; i < 30; i += 1) {
            lingerieGirls.push(
                LingerieGirlInfo({originPower: powers[i], supportedLPTokenAmount: 0, sushiRewardDebt: 0})
            );
            _mint(msg.sender, i);
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.maidcoin.org/lingeriegirls/";
    }

    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return keccak256(abi.encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, block.chainid, address(this)));
        }
    }

    function changeLPTokenToLingerieGirlPower(uint256 value) external onlyOwner {
        lpTokenToLingerieGirlPower = value;
        emit ChangeLPTokenToLingerieGirlPower(value);
    }

    function mint(uint256 power) external onlyOwner returns (uint256 id) {
        id = lingerieGirls.length;
        lingerieGirls.push(LingerieGirlInfo({originPower: power, supportedLPTokenAmount: 0, sushiRewardDebt: 0}));
        _mint(msg.sender, id);
    }

    function mintBatch(uint256[] calldata powers, uint256 amounts) external onlyOwner {
        require(powers.length == amounts, "LingerieGirls: Invalid parameters");
        uint256 from = lingerieGirls.length;
        for (uint256 i = 0; i < amounts; i += 1) {
            lingerieGirls.push(
                LingerieGirlInfo({originPower: powers[i], supportedLPTokenAmount: 0, sushiRewardDebt: 0})
            );
            _mint(msg.sender, (i + from));
        }
    }

    function powerOf(uint256 id) external view override returns (uint256) {
        LingerieGirlInfo storage lingerieGirl = lingerieGirls[id];
        return lingerieGirl.originPower + (lingerieGirl.supportedLPTokenAmount * lpTokenToLingerieGirlPower) / 1e18;
    }

    function support(uint256 id, uint256 lpTokenAmount) public override {
        require(ownerOf(id) == msg.sender, "LingerieGirls: Forbidden");
        require(lpTokenAmount > 0, "LingerieGirls: Invalid lpTokenAmount");
        uint256 _supportedLPTokenAmount = lingerieGirls[id].supportedLPTokenAmount;

        lingerieGirls[id].supportedLPTokenAmount = _supportedLPTokenAmount + lpTokenAmount;
        lpToken.transferFrom(msg.sender, address(this), lpTokenAmount);

        uint256 _pid = masterChefPid;
        if (_pid > 0) {
            lingerieGirls[id].sushiRewardDebt = _depositModule(
                _pid,
                lpTokenAmount,
                _supportedLPTokenAmount,
                lingerieGirls[id].sushiRewardDebt
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
        require(ownerOf(id) == msg.sender, "LingerieGirls: Forbidden");
        require(lpTokenAmount > 0, "LingerieGirls: Invalid lpTokenAmount");
        uint256 _supportedLPTokenAmount = lingerieGirls[id].supportedLPTokenAmount;

        lingerieGirls[id].supportedLPTokenAmount = _supportedLPTokenAmount - lpTokenAmount;

        uint256 _pid = masterChefPid;
        if (_pid > 0) {
            lingerieGirls[id].sushiRewardDebt = _withdrawModule(
                _pid,
                lpTokenAmount,
                _supportedLPTokenAmount,
                lingerieGirls[id].sushiRewardDebt
            );
        }

        lpToken.transfer(msg.sender, lpTokenAmount);
        emit Desupport(id, lpTokenAmount);
    }

    function claimSushiReward(uint256 id) public override {
        require(ownerOf(id) == msg.sender, "LingerieGirls: Forbidden");
        lingerieGirls[id].sushiRewardDebt = _claimSushiReward(
            lingerieGirls[id].supportedLPTokenAmount,
            lingerieGirls[id].sushiRewardDebt
        );
    }

    function pendingSushiReward(uint256 id) external view override returns (uint256) {
        return _pendingSushiReward(lingerieGirls[id].supportedLPTokenAmount, lingerieGirls[id].sushiRewardDebt);
    }

    function permit(
        address spender,
        uint256 id,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(block.timestamp <= deadline, "LingerieGirls: Expired deadline");
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
        require(spender != owner, "LingerieGirls: Invalid spender");

        if (Address.isContract(owner)) {
            require(
                IERC1271(owner).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e,
                "LingerieGirls: Unauthorized"
            );
        } else {
            address recoveredAddress = Signature.recover(digest, v, r, s);
            require(recoveredAddress == owner, "LingerieGirls: Unauthorized");
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
        require(block.timestamp <= deadline, "LingerieGirls: Expired deadline");
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
                "LingerieGirls: Unauthorized"
            );
        } else {
            address recoveredAddress = Signature.recover(digest, v, r, s);
            require(recoveredAddress == owner, "LingerieGirls: Unauthorized");
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
        return super.supportsInterface(interfaceId);
    }
}
