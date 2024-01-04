// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.0;

// Standard ERC-20 interface
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

interface GasToken {
    function mint(uint256 value) external;
    function free(uint256 value) external returns (bool success);
    function freeUpTo(uint256 value) external returns (uint256 freed);
    function freeFrom(address from, uint256 value) external returns (bool success);
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor (address initOwner) {
        owner = initOwner;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Dummy is Ownable(msg.sender) {
    receive() external payable {
    }
    //transfers tokens from this contract
    function transferStuff(address tokenAddress, uint256 amountTokens, address dest) external onlyOwner() {
        IERC20(tokenAddress).transfer(dest, amountTokens);
    }
    //transfers ETH from this contract
    function drain(address payable dest) external onlyOwner() {
        dest.transfer( address(this).balance );
    }

}


contract GasTokenSwitcher is Dummy {
    //address public GasToken_one = 0x88d60255f917e3eb94eae199d827dad837fac4cb;
    //address public GasToken_two = 0x0000000000b3F879cb30FE243b4Dfee438691c04
    //address public chi =  0x0000000000004946c0e9f43f4dee607b0ef1fa1c
    /*
    function mintAndFreeFrom(address burnToken, address from, uint256 free, address mintToken, uint256 newTokens) public onlyOwner() {
        require(GasToken(burnToken).freeFrom(from, free));
        GasToken(mintToken).mint(newTokens);
    }
    */
    modifier discountGasToken(address burnToken, address from) {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        GasToken(burnToken).freeFromUpTo(from, (gasSpent + 14154) / 41130);
    }
    function mintAndBurn(address burnToken, address from, address mintToken, uint256 newTokens) public onlyOwner() discountGasToken(burnToken, from) {
        GasToken(mintToken).mint(newTokens);
    }
    function burnAndDeploy(address burnToken, address from, bytes memory data) public onlyOwner() discountGasToken(burnToken, from) returns(address contractAddress) {
        assembly {
            contractAddress := create(0, add(data, 32), mload(data))
        }
    }
}




//code below copied from https://etherscan.io/address/deployer.eth#code
interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}


contract Deployer {
    IFreeFromUpTo public constant gst = IFreeFromUpTo(0x0000000000b3F879cb30FE243b4Dfee438691c04);
    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    modifier discountGST {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        gst.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
    }

    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
    }

    function gstDeploy(bytes memory data) public discountGST returns(address contractAddress) {
        assembly {
            contractAddress := create(0, add(data, 32), mload(data))
        }
    }

    function chiDeploy(bytes memory data) public discountCHI returns(address contractAddress) {
        assembly {
            contractAddress := create(0, add(data, 32), mload(data))
        }
    }

    function gstDeploy2(uint256 salt, bytes memory data) public discountGST returns(address contractAddress) {
        assembly {
            contractAddress := create2(0, add(data, 32), mload(data), salt)
        }
    }

    function chiDeploy2(uint256 salt, bytes memory data) public discountCHI returns(address contractAddress) {
        assembly {
            contractAddress := create2(0, add(data, 32), mload(data), salt)
        }
    }
}