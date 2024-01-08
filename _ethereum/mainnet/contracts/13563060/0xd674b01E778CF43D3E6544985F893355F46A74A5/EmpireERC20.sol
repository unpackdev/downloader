// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

import "./IEmpireERC20.sol";

import "./EmpireMath.sol";

contract EmpireERC20 is IEmpireERC20 {
    using EmpireMath for uint256;

    string public constant override name = "Empire LP";
    string public constant override symbol = "EMP-LP";
    uint8 public constant override decimals = 18;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 private immutable CACHED_CHAIN_ID;
    bytes32 private immutable CACHED_DOMAIN_SEPARATOR;
    bytes32 private constant EIP712_DOMAIN =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    mapping(address => uint256) public override nonces;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        CACHED_CHAIN_ID = chainId;
        CACHED_DOMAIN_SEPARATOR = _computeSeparator(chainId);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
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
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(
                value
            );
        }
        _transfer(from, to, value);
        return true;
    }

    function _computeSeparator(uint256 chainId)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN,
                    keccak256(bytes(name)),
                    keccak256(bytes("1")),
                    chainId,
                    address(this)
                )
            );
    }

    function _getDigest(bytes32 payload) internal view returns (bytes32) {
        uint256 chainId;

        assembly {
            chainId := chainid()
        }

        bytes32 domainSeparator =
            chainId != CACHED_CHAIN_ID
                ? _computeSeparator(chainId)
                : CACHED_DOMAIN_SEPARATOR;

        return
            keccak256(abi.encodePacked("\x19\x01", domainSeparator, payload));
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "Empire: EXPIRED");
        bytes32 digest =
            _getDigest(
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "Empire: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}
