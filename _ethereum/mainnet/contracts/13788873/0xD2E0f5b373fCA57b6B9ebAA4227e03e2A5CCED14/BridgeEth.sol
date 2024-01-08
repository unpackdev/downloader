// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract BridgeEth {
    address public admin;
    address public feeWallet = 0xcae28D03f6042E57B79790840890b53AFDab825a;

    IERC20 public token;

    mapping(address => mapping(uint => bool)) public processedNonces;
    mapping (address => uint256) public accounts;
    
    mapping(address => uint) public nextNonce;

    uint256 public _basefees = 50000000000000000; //0.05 eth
    uint256 public _withdrawfees = 10; //1%  /1000

    enum Step { Burn, Mint }
    event Deposit(
        address from,
        uint256 amount,
        uint date,
        uint nonce,
        bytes signature,
        Step indexed step
    );
    event Mint(
        address to,
        uint256 amount,
        uint date,
        uint nonce,
        bytes signature,
        Step indexed step
    );
    event Withdraw(
        address from,
        uint256 amount
    );

    constructor () {
        admin = 0x11Faf4470d0294C263EC695E23FdC469046393D4;
        token = IERC20(0x309c1b3282c49E4dC6796644417f8c76b7C8233C);
    }

    function setToken (address _token ) external {
        require(msg.sender == admin, "only admin");
        token = IERC20(_token);
    }

    function setAdmin (address _admin ) external {
        require(msg.sender == admin, "only admin");
        admin = _admin;
    }

    function setFees (uint256 _fees ) external {
        require(msg.sender == admin, "only admin");
        _basefees = _fees;
    }

    function setWithdrawFees (uint256 _fees ) external {
        require(msg.sender == admin, "only admin");
        _withdrawfees = _fees;
    }

    function setFeeWallet (address _wallet ) external {
        require(msg.sender == admin, "only admin");
        feeWallet = _wallet;
    }


    function deposit(address from, uint256 amount, uint nonce, bytes calldata signature) external payable{
        require(msg.value >= _basefees, "insufficient fees");
        require(processedNonces[msg.sender][nonce] == false, 'transfer already processed');
        processedNonces[msg.sender][nonce] = true;

        payable(admin).transfer(msg.value);
        
        token.transferFrom(msg.sender, address(this), amount);
        nextNonce[msg.sender] = nextNonce[msg.sender] + 1;

        emit Deposit(
            from,
            amount,
            block.timestamp,
            nonce,
            signature,
            Step.Burn
        );
    }

    function calculateWithdrawFee(uint256 _amount) private view returns (uint256) {
        return _amount*(_withdrawfees)/(10**3);

    }

    fallback () external payable {
    }

    receive () external payable {
    }

    function withdraw( ) external {
        require(accounts[msg.sender] > 0, "invalid amount");
        uint256 amount = accounts[msg.sender];
        uint256 _fees = calculateWithdrawFee(amount);

        bool succ = token.transfer(msg.sender, amount - _fees);
        require(succ, "tokens not transfered");

        bool succ2 = token.transfer(feeWallet , _fees);
        require(succ2, "fees tokens not transfered");

        accounts[msg.sender] = 0;

        emit Withdraw(msg.sender, amount);
    }

    function mint(
        address to, 
        uint256 amount, 
        uint nonce,
        bytes calldata signature
    ) external {
        require(msg.sender == admin, "only admin");
        bytes32 message = prefixed(keccak256(abi.encodePacked(to, amount, nonce )));
        require(recoverSigner(message, signature) == to , 'wrong signature');
        require(processedNonces[to][nonce] == false, 'transfer already processed');
        processedNonces[to][nonce] = true;
        nextNonce[to] = nextNonce[to] + 1;
        accounts[to] += amount;
        
        emit Mint(
            to,
            amount,
            block.timestamp,
            nonce,
            signature,
            Step.Mint
        );
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
        '\x19Ethereum Signed Message:\n32', 
        hash
        ));
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
    
        (v, r, s) = splitSignature(sig);
    
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);
    
        bytes32 r;
        bytes32 s;
        uint8 v;
    
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    
        return (v, r, s);
    }

    function emergencyWithdrawTokens() public {
        require(msg.sender == admin, "only admin");
        uint256 amount = token.balanceOf(address(this));
        bool succ = token.transfer(msg.sender, amount);
        require(succ, "tokens not transfered");
    }

    function emergencyWithdrawEth() public {
        require(msg.sender == admin, "only admin");
        uint256 Balance = address(this).balance;
        (bool succ, ) = msg.sender.call{value: Balance}("");
        require(succ, "withdraw not sent"); 
    }
}