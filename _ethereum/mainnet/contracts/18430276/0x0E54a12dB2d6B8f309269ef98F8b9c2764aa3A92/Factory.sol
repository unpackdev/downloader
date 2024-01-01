// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// Ownable contract from OpenZeppelin
abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// IERC20 interface from OpenZeppelin
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Factory contract
contract Factory is Ownable {
    event ContractCreated(address contractAddress);

    IERC20 public token;
    string public expectedBytecodeHash;

    function setExpectedBytecodeHash(string memory _hash) public onlyOwner {
        expectedBytecodeHash = _hash;
    }

    function deploy(bytes memory bytecode, uint256 salt) public onlyOwner {
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Deployment failed");
        token = IERC20(addr);
        emit ContractCreated(addr);
    }

    function transferOwnershipOfTokenContract(address newOwner) public onlyOwner {
        require(address(token) != address(0), "Token contract has not been deployed yet");
        Ownable(address(token)).transferOwnership(newOwner);
    }

    function transferAllTokens(address recipient) public onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "No tokens to transfer");
        require(token.transfer(recipient, amount), "Transfer failed");
    }

    function getTokenContractOwner() public view returns (address) {
        return Ownable(address(token)).owner();
    }
}