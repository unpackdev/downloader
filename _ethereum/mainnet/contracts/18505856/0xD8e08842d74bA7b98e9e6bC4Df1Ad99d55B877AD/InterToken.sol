// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/**
https://remix.ethereum.org/#lang=en&optimize=true&runs=200&evmVersion=shanghai&version=soljson-v0.8.22+commit.4fc1097e.js

This source code is for deploying the Inter DAO governance token INT, with a total issuance of 210 million tokens. Shortly after the contract deployment, all tokens will be temporarily held by the initiator of Inter DAO. The custodian will deposit the tokens into a dedicated open-source contract address for a fair public sale before the initial public offering, ensuring that the entire sales process is transparent enough to be subject to oversight by anyone. After the initial public sale, DAO authority will be transferred to a DAO contract with voting capabilities, and the rights to mint or burn tokens in the future will be exclusively held by the DAO contract.

このソースコードは、Inter DAOのガバナンストークンINTをデプロイするためのもので、総発行量は2億1000万トークンです。コントラクトのデプロイ後間もなく、すべてのトークンはInter DAOの発起人によって一時的に保持されます。保管者は、初回公開販売前に、公平な公開販売のために専用のオープンソースコントラクトアドレスにトークンを預け入れ、販売プロセス全体が透明であり、誰でも監視できることを確保します。初回公開販売後、DAOの権限は投票機能を持つDAOコントラクトに移譲され、将来のトークンの増刷や焼却の権限はDAOコントラクトのみが保有します。
**/
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

interface IUnstoppableDomain {
    function setReverse(string[] memory labels) external;
    function setOwner(address to, uint256 tokenId) external;
}    

interface IENSDomain {
    function setName(string memory name) external returns (bytes32);
    function claimWithResolver(address owner, address resolver) external returns (bytes32);
    function setOwner(bytes32 node, address owner) external;
}    

contract InterToken is IERC20 {
    string public constant name = "Inter Token";
    string public constant symbol = "INT";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 totalSupply_ = 2100000000 * (10 ** uint256(decimals));
    address public daoAddress;

    constructor() {
        daoAddress = msg.sender;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;

    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address tokenOwner, address delegate) public override view returns (uint) {
        return allowed[tokenOwner][delegate];
    }

    function transferFrom(address tokenOwner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[tokenOwner]);
        require(numTokens <= allowed[tokenOwner][msg.sender]);

        balances[tokenOwner] = balances[tokenOwner] - numTokens;
        allowed[tokenOwner][msg.sender] = allowed[tokenOwner][msg.sender] - numTokens;
        balances[buyer] = balances[buyer] + numTokens;
        emit Transfer(tokenOwner, buyer, numTokens);
        return true;
    }

    modifier onlyDAO {
        require(msg.sender == daoAddress);
        _;
    }

    function mint(address to, uint256 amount) public onlyDAO {
        totalSupply_ += amount;
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) public onlyDAO {
        require(amount <= balances[from]);
        totalSupply_ -= amount;
        balances[from] -= amount;
        emit Transfer(from, address(0), amount);
    }

    function setDAOAddress(address dao_) public onlyDAO {
        daoAddress = dao_;
    }

    function withdrawEther(uint256 amount) public onlyDAO {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(daoAddress).transfer(amount);
    }

    function withdrawERC20Token(address tokenAddress, uint256 amount) public onlyDAO {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");
        token.transfer(daoAddress, amount);
    }

    function setUnstoppableDomainReverse(address node,string[] memory labels) external{
        IUnstoppableDomain uDomain = IUnstoppableDomain(node);
        uDomain.setReverse(labels);
    }

    function setUnstoppableDomainOwner(address node,address to,uint256 tokenId) external{
        IUnstoppableDomain uDomain = IUnstoppableDomain(node);
        uDomain.setOwner(to,tokenId);
    }

    function setENSDomainName(address node,string memory _name) external returns (bytes32) {
        IENSDomain eDomain = IENSDomain(node);
        return eDomain.setName(_name);
    } 

    function claimENSDomainWithResolver(address owner,address resolver,address node) external returns (bytes32) {
        IENSDomain eDomain = IENSDomain(node);
        return eDomain.claimWithResolver(owner,resolver);
    } 

    function setENSDomainOwner(address owner,bytes32 nameNode,address node) external {
        IENSDomain eDomain = IENSDomain(node);
        eDomain.setOwner(nameNode,owner);
    } 
}