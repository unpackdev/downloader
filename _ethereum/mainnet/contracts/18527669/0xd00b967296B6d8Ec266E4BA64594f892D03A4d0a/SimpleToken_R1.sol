// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "./ERC20.sol";
import "./IERC20.sol";

contract SimpleToken_R1 is Context, IERC20, IERC20Mintable, IERC20Pegged, IERC20MetadataChangeable {

    // pre-defined state
    bytes32 internal _symbol; // 0
    bytes32 internal _name; // 1
    address public owner; // 2

    // internal state
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;
    uint256 internal _originChain;
    address internal _originAddress;

    function name() public view returns (string memory) {
        return bytes32ToString(_name);
    }

    function changeName(bytes32 newVal) external override onlyOwner {
        emit NameChanged(name(), bytes32ToString(newVal));
        _name = newVal;
    }

    function symbol() public view returns (string memory) {
        return bytes32ToString(_symbol);
    }

    function changeSymbol(bytes32 newVal) external override onlyOwner {
        emit SymbolChanged(symbol(), bytes32ToString(newVal));
        _symbol = newVal;
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        if (_bytes32 == 0) {
            return new string(0);
        }
        uint8 cntNonZero = 0;
        for (uint8 i = 16; i > 0; i >>= 1) {
            if (_bytes32[cntNonZero + i] != 0) cntNonZero += i;
        }
        string memory result = new string(cntNonZero + 1);
        assembly {
            mstore(add(result, 0x20), _bytes32)
        }
        return result;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount, true);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount, true);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        _increaseAllowance(_msgSender(), spender, amount, true);
        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        _decreaseAllowance(_msgSender(), spender, amount, true);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount, true);
        _decreaseAllowance(sender, _msgSender(), amount, true);
        return true;
    }

    function _increaseAllowance(address owner, address spender, uint256 amount, bool emitEvent) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] += amount;
        if (emitEvent) {
            emit Approval(owner, spender, _allowances[owner][spender]);
        }
    }

    function _decreaseAllowance(address owner, address spender, uint256 amount, bool emitEvent) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] -= amount;
        if (emitEvent) {
            emit Approval(owner, spender, _allowances[owner][spender]);
        }
    }

    function _approve(address owner, address spender, uint256 amount, bool emitEvent) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        if (emitEvent) {
            emit Approval(owner, spender, amount);
        }
    }

    function _transfer(address sender, address recipient, uint256 amount, bool emitEvent) internal {
        require(sender != address(0));
        require(recipient != address(0));
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        if (emitEvent) {
            emit Transfer(sender, recipient, amount);
        }
    }

    function mint(address account, uint256 amount) public onlyOwner virtual override {
        require(account != address(0));
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner virtual override {
        require(account != address(0));
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    modifier emptyOwner() {
        require(owner == address(0x00));
        _;
    }

    function initAndObtainOwnership(bytes32 symbol, bytes32 name, uint256 originChain, address originAddress) public emptyOwner {
        owner = msg.sender;
        _symbol = symbol;
        _name = name;
        _originChain = originChain;
        _originAddress = originAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getOrigin() public view override returns (uint256, address) {
        return (_originChain, _originAddress);
    }
}

contract SimpleTokenFactory_R1 {
    address private _template;
    constructor() {
        _template = SimpleTokenFactoryUtils_R1.deploySimpleTokenTemplate(this);
    }

    function getImplementation() public view returns (address) {
        return _template;
    }
}

library SimpleTokenFactoryUtils_R1 {

    bytes32 constant internal SIMPLE_TOKEN_TEMPLATE_SALT = keccak256("SimpleTokenTemplateV2");

    bytes constant internal SIMPLE_TOKEN_TEMPLATE_BYTECODE = hex"608060405234801561001057600080fd5b50610bd5806100206000396000f3fe608060405234801561001057600080fd5b50600436106101165760003560e01c8063898855ed116100a25780639dc29fac116100715780639dc29fac1461024d578063a457c2d714610260578063a9059cbb14610273578063dd62ed3e14610286578063df1f29ee146102bf57600080fd5b8063898855ed146101f45780638da5cb5b1461020757806394bfed881461023257806395d89b411461024557600080fd5b806323b872dd116100e957806323b872dd14610183578063313ce5671461019657806339509351146101a557806340c10f19146101b857806370a08231146101cb57600080fd5b806306fdde031461011b578063095ea7b31461013957806318160ddd1461015c5780631ad8fde61461016e575b600080fd5b6101236102e2565b6040516101309190610ac8565b60405180910390f35b61014c6101473660046109f9565b6102f4565b6040519015158152602001610130565b6005545b604051908152602001610130565b61018161017c366004610a23565b61030c565b005b61014c6101913660046109bd565b610370565b60405160128152602001610130565b61014c6101b33660046109f9565b610396565b6101816101c63660046109f9565b6103a5565b6101606101d9366004610968565b6001600160a01b031660009081526003602052604090205490565b610181610202366004610a23565b610459565b60025461021a906001600160a01b031681565b6040516001600160a01b039091168152602001610130565b610181610240366004610a3c565b6104bd565b61012361050e565b61018161025b3660046109f9565b61051b565b61014c61026e3660046109f9565b6105c9565b61014c6102813660046109f9565b6105d8565b61016061029436600461098a565b6001600160a01b03918216600090815260046020908152604080832093909416825291909152205490565b600654600754604080519283526001600160a01b03909116602083015201610130565b60606102ef6001546105e7565b905090565b600061030333848460016106bd565b50600192915050565b6002546001600160a01b0316331461032357600080fd5b7fd7ad744cc76ebad190995130eec8ba506b3605612d23b5b9cef8e27f14d138b461034c61050e565b610355836105e7565b604051610363929190610adb565b60405180910390a1600055565b600061037f8484846001610765565b61038c8433846001610830565b5060019392505050565b600061030333848460016108ef565b6002546001600160a01b031633146103bc57600080fd5b6001600160a01b0382166103cf57600080fd5b80600560008282546103e19190610b09565b90915550506001600160a01b0382166000908152600360205260408120805483929061040e908490610b09565b90915550506040518181526001600160a01b038316906000907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef906020015b60405180910390a35050565b6002546001600160a01b0316331461047057600080fd5b7f6c20b91d1723b78732eba64ff11ebd7966a6e4af568a00fa4f6b72c20f58b02a6104996102e2565b6104a2836105e7565b6040516104b0929190610adb565b60405180910390a1600155565b6002546001600160a01b0316156104d357600080fd5b60028054336001600160a01b031991821617909155600094909455600192909255600655600780549092166001600160a01b03909116179055565b60606102ef6000546105e7565b6002546001600160a01b0316331461053257600080fd5b6001600160a01b03821661054557600080fd5b6001600160a01b0382166000908152600360205260408120805483929061056d908490610b46565b9250508190555080600560008282546105869190610b46565b90915550506040518181526000906001600160a01b038416907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef9060200161044d565b60006103033384846001610830565b60006103033384846001610765565b60608161060257505060408051600081526020810190915290565b600060105b60ff811615610659578361061b8284610b21565b60ff166020811061062e5761062e610b73565b1a60f81b6001600160f81b0319161561064e5761064b8183610b21565b91505b60011c607f16610607565b506000610667826001610b21565b60ff1667ffffffffffffffff81111561068257610682610b89565b6040519080825280601f01601f1916602001820160405280156106ac576020820181803683370190505b506020810194909452509192915050565b6001600160a01b0384166106d057600080fd5b6001600160a01b0383166106e357600080fd5b6001600160a01b038085166000908152600460209081526040808320938716835292905220829055801561075f57826001600160a01b0316846001600160a01b03167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9258460405161075691815260200190565b60405180910390a35b50505050565b6001600160a01b03841661077857600080fd5b6001600160a01b03831661078b57600080fd5b6001600160a01b038416600090815260036020526040812080548492906107b3908490610b46565b90915550506001600160a01b038316600090815260036020526040812080548492906107e0908490610b09565b9091555050801561075f57826001600160a01b0316846001600160a01b03167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef8460405161075691815260200190565b6001600160a01b03841661084357600080fd5b6001600160a01b03831661085657600080fd5b6001600160a01b0380851660009081526004602090815260408083209387168352929052908120805484929061088d908490610b46565b9091555050801561075f576001600160a01b038481166000818152600460209081526040808320948816808452948252918290205491519182527f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9259101610756565b6001600160a01b03841661090257600080fd5b6001600160a01b03831661091557600080fd5b6001600160a01b0380851660009081526004602090815260408083209387168352929052908120805484929061088d908490610b09565b80356001600160a01b038116811461096357600080fd5b919050565b60006020828403121561097a57600080fd5b6109838261094c565b9392505050565b6000806040838503121561099d57600080fd5b6109a68361094c565b91506109b46020840161094c565b90509250929050565b6000806000606084860312156109d257600080fd5b6109db8461094c565b92506109e96020850161094c565b9150604084013590509250925092565b60008060408385031215610a0c57600080fd5b610a158361094c565b946020939093013593505050565b600060208284031215610a3557600080fd5b5035919050565b60008060008060808587031215610a5257600080fd5b843593506020850135925060408501359150610a706060860161094c565b905092959194509250565b6000815180845260005b81811015610aa157602081850181015186830182015201610a85565b81811115610ab3576000602083870101525b50601f01601f19169290920160200192915050565b6020815260006109836020830184610a7b565b604081526000610aee6040830185610a7b565b8281036020840152610b008185610a7b565b95945050505050565b60008219821115610b1c57610b1c610b5d565b500190565b600060ff821660ff84168060ff03821115610b3e57610b3e610b5d565b019392505050565b600082821015610b5857610b58610b5d565b500390565b634e487b7160e01b600052601160045260246000fd5b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052604160045260246000fdfea26469706673582212208b92490ed0e0682b75f5159cd3275fb397f083f3c75e3b0a44ebccaaa492e72764736f6c63430008060033";

    bytes32 constant internal SIMPLE_TOKEN_TEMPLATE_HASH = keccak256(SIMPLE_TOKEN_TEMPLATE_BYTECODE);

    bytes4 constant internal SET_META_DATA_SIG = bytes4(keccak256("obtainOwnership(bytes32,bytes32)"));

    function deploySimpleTokenTemplate(SimpleTokenFactory_R1 templateFactory) internal returns (address) {
        /* we can use any deterministic salt here, since we don't care about it */
        bytes32 salt = SIMPLE_TOKEN_TEMPLATE_SALT;
        /* concat bytecode with constructor */
        bytes memory bytecode = SIMPLE_TOKEN_TEMPLATE_BYTECODE;
        /* deploy contract and store result in result variable */
        address result;
        assembly {
            result := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(result != address(0x00), "deploy failed");
        /* check that generated contract address is correct */
        require(result == simpleTokenTemplateAddress(templateFactory), "address mismatched");
        return result;
    }

    function simpleTokenTemplateAddress(SimpleTokenFactory_R1 templateFactory) internal pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(uint8(0xff), address(templateFactory), SIMPLE_TOKEN_TEMPLATE_SALT, SIMPLE_TOKEN_TEMPLATE_HASH));
        return address(bytes20(hash << 96));
    }
}
