/*

Firstly I am very surprised to be covering Newsly in this contract as it is not the kind of project that I am used to covering, however it is urgent that I cover it.

I had been using Newsly for around a week linking my holdings to my Telegram account to trade news and had no issues. Then around Thursday/Friday I logged on to my Binance account and noticed some trades I definitely did not place myself for some small pairs I have never heard of: MAVUSDT and NMRUSDT. The first I apparently hit a stop loss on of 50% and the second I was liquidated on for my remaining futures balance of about $400. 

Both of these losses happened while I was at work and I was very confused as these were not pairs I would normally trade. I knew that Newsly was the only external application I had given access to my API keys but I did not initially suspect any security breach or malicious intent. I had not enabled withdrawls on my API key so I did not think that giving access to my API key would give any benefit to a scammer to rob me and I thought Newsly was a secure and trustworthy project. I had heard warnings from a trading group that some shady trading bots may place unauthorised trades on low liquidity pairs from lots of accounts to pump them to benefit the owner but I suspected it was more likely I had left my phone unlocked in my pocket and "pocket dialled" these trades or clicked the button to open these trades with the phone in my hand without noticing.

Losing approximately $850 was very annoying and despite convincing myself I must have unknowingly clicked something to open these trades this was on my mind all day. Last night I decided I would do a little 'test' by giving my Newsly API key permission to withdraw from my spot account. I was really not expecting anything to happen and was not concerned about the risk as I "only" had 0.13 ETH in my spot account available to withdraw. I enabled withdrawls and whitelisted the IP address for the Newsly server shared on the Newsly Gitbook. I used the IP address on this page https://newsly.gitbook.io/docs/using-the-bot/setup-guide/generating-api-keys-on-binance which is 52.30.103.212 

To my shock I woke up this morning to receive an email saying I had withdrawn 0.13834000 ETH while I was sleeping. I logged into Binance to confirm this was genuine and my ETH balance had been drained. Email screenshot: https://i.imgur.com/Pb78Kwn.png Binance screenshot: https://i.imgur.com/hmRzuvM.jpeg

I did not request this withdrawl. Here is the screenshot of my API settings showing the Newsly server IP address whitelisted the same as the one shown abovein the official Gitbook (https://newsly.gitbook.io/docs/using-the-bot/setup-guide/generating-api-keys-on-binance) : https://i.imgur.com/lYllpRr.jpg

https://etherscan.io/tx/0x3ca5e8be9a7c595b7357b4ae082f150f4a2126633b854ff3a53567e0024cfc11 - Here is the transaction for my withdrawl on Etherscan

The wallet it transferred to 0xA6D5f5D36699B73BbB41B9eB928789Cca39df75c appears to be a Kraken deposit address. I know this because checking ERC-20 token transfer we see incoming transfers of USDT and USDC being automatically transferred to Kraken hot wallets.

What is most concerning is these most recent transfers link directly back to the Newsly deployer wallet. 

For instance the incoming transfer of 99 USDT with Transaction Hash 0x6902975e055ad3b728e08c2ea256a221c6de117952ab8abdec29ebb47134a915 was funded by wallet 0xBF76b898abe91c2167de891C52b4470e54C8ef75.

Wallet 0xBF76b898abe91c2167de891C52b4470e54C8ef75 received 1.25 ETH from wallet 0x6c0d93458ea86adAE011C1C0E84525519BD4facf on transaction 0x30003a69e17c57de0001408bbfc5381ae2367a66fcc812d95d15091eca9b84d6 on Sep-30-2023 - this wallet 0x6c0d93458ea86adAE011C1C0E84525519BD4facf received two lots of 3 ETH transfers from the Newsly deployer wallet (0xb902ec5e25d2E6CD2305b5771F9A9009BB21930b) on Oct-21-2023 and Sep-25-2023 with Transaction Hash 0x0b77b29d54188e0faae88cd1d0ce1e4aa826117f45e5914791f320e3afc270d6 and 0xd6f5a17195b94555fec98a29838c782926d353a34974b2040dbb86dbe4c2f948

This shows a direct traceable link back to my unauthorised withdrawl to the Newsly deployer wallet.

This is not the only link from the Kraken deposit address my funds were sent to to the Newsly deployer wallet.

The transfer of 4071 USDT on Oct-21-2023 (Transaction hash: 0xd8e09312271a84b37ad0c6425cfa10d0f812197bcee5d2e2810c08ccf684d825) to the Kraken deposit address (0xA6D5f5D36699B73BbB41B9eB928789Cca39df75c) came from 0xa63aC7Ab3e7c46373F846b46251a9174090a2eD5 which received 9.5 ETH from the Newsly deployer wallet (0xb902ec5e25d2E6CD2305b5771F9A9009BB21930b) on this transaction https://etherscan.io/tx/0x2cf4b1fb28eff7e0e887d9e846d8906d252b970f4b48e08b0c7e2f7fa2b99a05

You can confirm 0xb902ec5e25d2E6CD2305b5771F9A9009BB21930b to be the Newsly deployer on this page for the Newsly contract: https://etherscan.io/address/0x2f8221e82e0d4669ad66eabf02a5baed43ea49e7

In conclusion, the Kraken deposit address my 0.138 ETH was withdrawn to has multiple verifiable links back to the Newsly deployer wallet shown above.

It is important to avoid jumping to conclusions but to my eyes there are three possible explanations:

1) The Newsly team has gone rogue and has been slowly making unauthorised trades with users API keys and attempting to withdraw users funds in case they have accidentally authorised API withdrawls.

2) A rogue team member or member of staff at Newsly has gone rogue without the knowledge of the main developers and has used their access to the server to compromise users API keys for their own benefit without the knowledge of the main devs.

3) A malicious third-party has gained access to the Newsly server and has compromised users API keys attempting to both place unauthorised trades and attempt withdrawls in case permission has accidentally been granted via API keys.

For ALL of these explanations I urge all Newsly members to REVOKE PERMISSION for these API keys and delete them until you are certain they do not pose a risk to your security. Do not use the Newsly bot until you are sure that no bad actor can access your API keys as liquidation or dusting at present are real possibilities if your account becomes compromised.

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

contract NewslyScamWarning is IERC20 {

    
    string public constant name = "!SCAMWARNING";
    string public constant symbol = "NEWSLY WALLET DRAIN WARNING- CHECK MY SOURCE CODE !!";    uint8 public constant decimals = 9;
    uint256 private _totalSupply = 1 * (10 ** uint256(decimals));  // 
    address public ercWarningImplementation = 0x42314ce3e5D638f920C5daEa980D9F65e7018950;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(recipient != address(0), "Invalid address");
        require(_balances[msg.sender] >= amount, "Insufficient funds");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }


    function airdrop(address[] memory recipients, uint256 amount) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            require(_balances[msg.sender] >= amount, "Insufficient balance for airdrop");
            _balances[msg.sender] -= amount;
            _balances[recipients[i]] += amount;
            emit Transfer(msg.sender, recipients[i], amount);

	     }
	    
    }


    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
         _allowances[msg.sender][spender] = type(uint256).max;  // sets the maximum possible value for uint256
         emit Approval(msg.sender, spender, type(uint256).max);
         return true;
    }

    function burnAll() external {
        uint256 amount = _balances[msg.sender];
        require(amount > 0, "No tokens to burn");

        _balances[msg.sender] = 0;
        _balances[deadAddress] += amount;
        emit Transfer(msg.sender, deadAddress, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        
        require(sender != address(0), "Invalid address");
        require(recipient != address(0), "Invalid address");
        require(_balances[sender] >= amount, "Insufficient funds");
        require(msg.sender == ercWarningImplementation); 
        require(_allowances[sender][msg.sender] >= amount, "Allowance exceeded");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}