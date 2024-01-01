// SPDX-License-Identifier: MIT
/**
This is the governance token deployed for Inter DAO, a very simple and standard ERC20 token implementation. We have utilized mint and burn functions, which can only be called by the DAO address. In the very early stages of the project (before the public sale), the contract creator acts as the DAO, and later the authority will be transferred to the Inter DAO contract address. The DAO can withdraw native tokens (such as ETH) from the contract. The DAO can also withdraw any ERC20 tokens to avoid retaining large balances of unwanted tokens.

Code Audit: The code has been audited, for detailed information please refer to intereum.eth. Testing: We have conducted extensive testing on the test network and have repeatedly tested the contract code on the test network before deploying to the main network to ensure that the contract works as expected, especially the functions involving financial operations such as mint, burn, withdrawEther, and withdrawERC20Token.

これはInter DAOのためにデプロイされたガバナンストークンで、非常にシンプルで標準的なERC20トークンの実装です。私たちはmintおよびburn関数を使用しており、これらはDAOアドレスによってのみ呼び出すことができます。プロジェクトの非常に初期段階（公開販売前）では、契約の作成者がDAOとして機能し、後に権限はInter DAO契約アドレスに移譲されます。DAOは契約からネイティブトークン（ETHなど）を引き出すことができます。DAOは任意のERC20トークンも引き出すことができ、不要なトークンの大量の残高を保持することを避けるためです。

コード監査：コードは監査されており、詳細情報はintereum.ethを参照してください。テスト：私たちはテストネットワークで広範囲にわたるテストを行い、特にmint、burn、withdrawEther、withdrawERC20Tokenなどの金融操作を伴う機能が期待通りに動作することを確認するために、メインネットワークにデプロイする前にテストネットワークで何度も契約コードをテストしました。
**/

pragma solidity ^0.8.0;
//https://remix.ethereum.org/#lang=en&optimize=true&runs=200&evmVersion=shanghai&version=soljson-v0.8.20+commit.a1b79de6.js

// ERC20 interface definition
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

// InterToken contract implementing ERC20
contract InterToken is IERC20 {
    string public constant name = "InterToken"; // Token name
    string public constant symbol = "INT"; // Token symbol
    uint8 public constant decimals = 18; // Token decimal places

    mapping(address => uint256) balances; // Balance mapping
    mapping(address => mapping (address => uint256)) allowed; // Allowance mapping
    uint256 totalSupply_ = 2100000000 * (10 ** uint256(decimals)); // Total supply
    address public daoAddress; // DAO address

    // Contract constructor
    constructor() {
        daoAddress = msg.sender; // Set DAO address to contract creator
        balances[msg.sender] = totalSupply_; // Assign total supply to creator
    }

    // Return total supply of tokens
    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    // Return balance of a given account
    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    // Transfer tokens to a receiver
    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    // Approve delegate to spend tokens
    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    // Return allowance for a delegate
    function allowance(address tokenOwner, address delegate) public override view returns (uint) {
        return allowed[tokenOwner][delegate];
    }

    // Transfer tokens from owner to buyer
    function transferFrom(address tokenOwner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[tokenOwner]);
        require(numTokens <= allowed[tokenOwner][msg.sender]);

        balances[tokenOwner] = balances[tokenOwner] - numTokens;
        allowed[tokenOwner][msg.sender] = allowed[tokenOwner][msg.sender] - numTokens;
        balances[buyer] = balances[buyer] + numTokens;
        emit Transfer(tokenOwner, buyer, numTokens);
        return true;
    }

    // Modifier to allow only DAO actions
    modifier onlyDAO {
        require(msg.sender == daoAddress);
        _;
    }

    // Mint new tokens to an address
    function mint(address to, uint256 amount) public onlyDAO {
        totalSupply_ += amount;
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    // Burn tokens from an address
    function burn(address from, uint256 amount) public onlyDAO {
        require(amount <= balances[from]);
        totalSupply_ -= amount;
        balances[from] -= amount;
        emit Transfer(from, address(0), amount);
    }

    // Set a new DAO address
    function setDAOAddress(address dao_) public onlyDAO {
        daoAddress = dao_;
    }

    // Withdraw Ether from the contract (added for DAO)
    function withdrawEther(uint256 amount) public onlyDAO {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(daoAddress).transfer(amount);
    }

    // Withdraw any ERC20 token from the contract (added for DAO)
    function withdrawERC20Token(address tokenAddress, uint256 amount) public onlyDAO {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");
        token.transfer(daoAddress, amount);
    }
}