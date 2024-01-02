// SPDX-License-Identifier: -- DG ---

pragma solidity ^0.8.9;

contract ERC20 {

    string private _name;
    string private _symbol;
    uint8 private  _decimals;

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint) public nonces;

    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    address internal constant ZERO_ADDY = address(0x0);
    uint256 internal constant UINT256_MAX = type(uint256).max;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    constructor(
        string memory _entryname,
        string memory _entrysymbol
    ) {
        _name = _entryname;
        _symbol = _entrysymbol;
        _decimals = 18;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name())),
                keccak256(bytes('1')),
                block.chainid,
                address(this)
            )
        );
    }

    function name()
        public
        view
        returns (string memory)
    {
        return _name;
    }

    function symbol()
        public
        view
        returns (string memory)
    {
        return _symbol;
    }

    function decimals()
        public
        view
        returns (uint8)
    {
        return _decimals;
    }

    function totallSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(
        address _account
    )
        public
        view
        returns (uint256)
    {
        return _balances[_account];
    }

    function _mint(
        address _to,
        uint256 _value
    )
        internal
    {
        _totalSupply =
        _totalSupply + _value;

        unchecked {
            _balances[_to] =
            _balances[_to] + _value;
        }

        emit Transfer(
            ZERO_ADDY,
            _to,
            _value
        );
    }

    function _burn(
        address _from,
        uint256 _value
    )
        internal
    {
        unchecked {
            _totalSupply =
            _totalSupply - _value;
        }

        _balances[_from] =
        _balances[_from] - _value;

        emit Transfer(
            _from,
            ZERO_ADDY,
            _value
        );
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _value
    )
        private
    {
        _allowances[_owner][_spender] = _value;

        emit Approval(
            _owner,
            _spender,
            _value
        );
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    )
        private
    {
        _balances[_from] =
        _balances[_from] - _value;

        unchecked {
            _balances[_to] =
            _balances[_to] + _value;
        }

        emit Transfer(
            _from,
            _to,
            _value
        );
    }

    function approve(
        address _spender,
        uint256 _value
    )
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            _value
        );

        return true;
    }

    function transfer(
        address _to,
        uint256 _value
    )
        external
        returns (bool)
    {
        _transfer(
            msg.sender,
            _to,
            _value
        );

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (bool)
    {
        if (_allowances[_from][msg.sender] != UINT256_MAX) {
            _allowances[_from][msg.sender] -= _value;
        }

        _transfer(
            _from,
            _to,
            _value
        );

        return true;
    }

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {
        require(
            _deadline >= block.timestamp,
            "Token: PERMIT_CALL_EXPIRED"
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        _owner,
                        _spender,
                        _value,
                        nonces[_owner]++,
                        _deadline
                    )
                )
            )
        );

        if (uint256(_s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ERC20: INVALID_SIGNATURE");
        }

        address recoveredAddress = ecrecover(
            digest,
            _v,
            _r,
            _s
        );

        require(
            recoveredAddress != ZERO_ADDY &&
            recoveredAddress == _owner,
            "ERC20: INVALID_SIGNATURE"
        );

        _approve(
            _owner,
            _spender,
            _value
        );
    }
}
