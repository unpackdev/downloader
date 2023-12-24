// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBRC20Factory {
    function parameters() external view returns (string memory name, string memory symbol, uint8 decimals);
}

contract BRC20 {
    string public name;
    string public symbol;
    uint8 public immutable decimals;
    address public immutable factory;
    uint256  public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;
    mapping (address => uint256) public nonces;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        (name, symbol, decimals) = IBRC20Factory(msg.sender).parameters();

        factory = msg.sender;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes('1')), chainId, address(this)));
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == factory, "unauthorized");
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        require(msg.sender == factory, "unauthorized");
        _burn(msg.sender, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;

        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
        return true;
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'EXPIRED');
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR,
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );
            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0) && recoveredAddress == owner, 'INVALID_SIGNATURE');
            allowance[recoveredAddress][spender] = value;
        }
        emit Approval(owner, spender, value);
    }

    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;

        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        balanceOf[from] -= amount;

        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}


contract BRC20Factory  {

    bytes32 private constant DOMAIN_NAME = keccak256("MultiBit");
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public constant MINT_TYPEHASH = keccak256(abi.encodePacked("Mint(address token,address to,uint256 amount,string txid)"));
    bytes32 public DOMAIN_SEPARATOR;

    struct Parameters {
        string name;
        string symbol;
        uint8 decimals;
    }

    bool private entered;
    Parameters public parameters;
    address public owner;
    uint256 public fee;
    address[] public signers;
    mapping (address => bool) public authorized;
    mapping (address => uint256) public indexes;
    mapping (bytes32 => bool) public used;

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    event FeeChanged(uint256 indexed oldFee, uint256 indexed newFee);

    event BRC20Created(address indexed sender, address indexed dog20);

    event Minted(address indexed token, address indexed to, uint256 indexed amount, string txid);

    event Burned(address indexed token, address indexed from, uint256 indexed amount, uint256 fee, string receiver);
    
    event SignerAdded(address indexed sender, address indexed account);

    event SignerRemoved(address indexed sender, address indexed account);

    modifier nonReentrant() {
        require(!entered, "REENTRANT");
        entered = true;
        _;
        entered = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    constructor(address[] memory _signers) {
        for (uint256 i = 0; i < _signers.length; i++) {
            address _addr = _signers[i];
            signers.push(_addr);
            authorized[_addr] = true;
            indexes[_addr] = i;
        }

        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

        fee = 0.01 ether;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, DOMAIN_NAME, keccak256(bytes('1')), chainId, address(this)));
    }

    function createBRC20(string memory name, string memory symbol, uint8 decimals) external onlyOwner returns (address brc20) {
        parameters = Parameters({name: name, symbol: symbol, decimals: decimals});
        brc20 = address(new BRC20{salt: keccak256(abi.encode(name, symbol, decimals))}());
        delete parameters;
        emit BRC20Created(msg.sender, brc20);
    }

    function mint(address token, address to, uint256 amount, string memory txid, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) external nonReentrant {
        require(v.length == signers.length, "invalid signatures");

        bytes32 digest = buildMintSeparator(token, to, amount, txid);
        require(!used[digest], "reuse");
        used[digest] = true;

        address[] memory signatures = new address[](v.length);
        for (uint256 i = 0; i < v.length; i++) {
            address signer = ecrecover(digest, v[i], r[i], s[i]);
            require(authorized[signer], "invalid signer");
            for (uint256 j = 0; j < i; j++) {
                require(signatures[j] != signer, "duplicated");
            }
            signatures[i] = signer;
        }

        BRC20(token).mint(to, amount);

        emit Minted(token, to, amount, txid);
    }

    function burn(address token, uint256 amount, string memory receiver) external payable nonReentrant {
        require(msg.value >= fee, "invalid ether");

        BRC20(token).transferFrom(msg.sender, address(this), amount);
        BRC20(token).burn(amount);

        emit Burned(token, msg.sender, amount, fee, receiver);
    }

    function withdraw(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    function setOwner(address _owner) external onlyOwner {
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    function setFee(uint256 _fee) external onlyOwner {
        emit FeeChanged(fee, _fee);
        fee = _fee;
    }

    function addSigner(address account) external onlyOwner {
        require(!authorized[account], "already exists");

        indexes[account] = signers.length;
        authorized[account] = true;
        signers.push(account);

        emit SignerAdded(msg.sender, account);
    }

    function removeSigner(address account) external onlyOwner {
        require(authorized[account], "non-existent");
        require(indexes[account] < signers.length, "index out of range");

        uint256 index = indexes[account];
        uint256 lastIndex = signers.length - 1;

        if (index != lastIndex) {
            address lastAddr = signers[lastIndex];
            signers[index] = lastAddr;
            indexes[lastAddr] = index;
        }

        delete authorized[account];
        delete indexes[account];
        signers.pop();

        emit SignerRemoved(msg.sender, account);
    }

    function buildMintSeparator(address token, address to, uint256 amount, string memory txid) view public returns (bytes32) {
        return keccak256(abi.encodePacked(
            '\x19\x01',
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(MINT_TYPEHASH, token, to, amount, keccak256(bytes(txid))))
        ));
    }
}