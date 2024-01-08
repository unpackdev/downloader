// SPDX-License-Identifier:MIT
pragma solidity 0.8.6;

import "./IERC20.sol";

// Lightweight token modelled after UNI-LP:
// https://github.com/Uniswap/uniswap-v2-core/blob/v1.0.1/contracts/UniswapV2ERC20.sol
// Adds:
//   - An exposed `mint()` with minting role
//   - An exposed `burn()`
//   - ERC-3009 (`transferWithAuthorization()`)
contract X is IERC20 {
    // bytes32 private constant EIP712DOMAIN_HASH =
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 private constant EIP712DOMAIN_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    // bytes32 private constant NAME_HASH = keccak256("X")
    bytes32 private constant NAME_HASH = 0x550c64a15031c3064454c19adc6243a6122c138a242eaa098da50bb114fc8d56;

    // bytes32 private constant VERSION_HASH = keccak256("1")
    bytes32 private constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    // bytes32 public constant PERMIT_TYPEHASH =
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    // bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
    // keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)");
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
        0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

    string public constant name = "X";
    string public constant symbol = "X";
    uint8 public constant decimals = 2;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    // ERC-2612, ERC-3009 state
    mapping(address => uint256) public nonces;
    mapping(address => mapping(bytes32 => bool)) public authorizationState;

    // Token X specific
    mapping(address => bool) public allowlist;
    mapping(address => bool) public invitationSpent;
    address public dropzero;

    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);
    event ChangeMinter(address indexed minter);

    constructor(address _dropzero) {
        dropzero = _dropzero;
    }

    function _validateSignedData(
        address signer,
        bytes32 encodeData,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), encodeData));
        address recoveredAddress = ecrecover(digest, v, r, s);
        // Explicitly disallow authorizations for address(0) as ecrecover returns address(0) on malformed messages
        require(recoveredAddress != address(0) && recoveredAddress == signer, "X:INVALID_SIGNATURE");
    }

    function mint(address to, uint256 value) external {
        require(msg.sender == dropzero, "MINT: ONLY_DROPZERO");
        _mint(to, value);
        allowlist[to] = true;
    }

    function renounceMinter() external {
        require(block.timestamp > 1637366400, "AFTER 1637366400 (20th of November)");
        dropzero = address(0);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _addToAllowList(address from, address to) internal {
        if (allowlist[to] == false && invitationSpent[from] == false) {
            invitationSpent[from] = true;
            allowlist[to] = true;
        }
    }

    function _burn(address from, uint256 value) internal {
        // Balance is implicitly checked with Solidity's underflow protection
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        require(to != address(this) && to != address(0), "X:RECEIVER_IS_TOKEN_OR_ZERO");
        require(allowlist[from] == true, "blockzerolabs.io/x/getInvite");
        _addToAllowList(from, to);
        require(allowlist[to] == true, "blockzerolabs.io/x/getInvite");

        // Balance is implicitly checked with Solidity's underflow protection
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }

    function getChainId() public view returns (uint256 chainId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }

    function getDomainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(EIP712DOMAIN_HASH, NAME_HASH, VERSION_HASH, getChainId(), address(this)));
    }

    function burn(uint256 value) external returns (bool) {
        _burn(msg.sender, value);
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        uint256 fromAllowance = allowance[from][msg.sender];
        if (fromAllowance != type(uint256).max) {
            // Allowance is implicitly checked with Solidity's underflow protection
            allowance[from][msg.sender] = fromAllowance - value;
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "X:AUTH_EXPIRED");

        bytes32 encodeData = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner], deadline));
        nonces[owner] = nonces[owner] + 1;
        _validateSignedData(owner, encodeData, v, r, s);

        _approve(owner, spender, value);
    }

    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp > validAfter, "X:AUTH_NOT_YET_VALID");
        require(block.timestamp < validBefore, "X:AUTH_EXPIRED");
        require(!authorizationState[from][nonce], "X:AUTH_ALREADY_USED");

        bytes32 encodeData =
            keccak256(
                abi.encode(TRANSFER_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce)
            );
        _validateSignedData(from, encodeData, v, r, s);

        authorizationState[from][nonce] = true;
        emit AuthorizationUsed(from, nonce);

        _transfer(from, to, value);
    }
}
