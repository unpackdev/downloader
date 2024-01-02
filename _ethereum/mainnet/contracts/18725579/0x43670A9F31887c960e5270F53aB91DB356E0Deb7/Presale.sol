pragma solidity '0.8.23';

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/*
        ┌┼┐╦╔═╔═╗╦  
        └┼┐╠╩╗║ ║║  
        └┼┘╩ ╩╚═╝╩═╝

        https://kols.life
        Rewarding LPs like none other.
        Fees can be seen here: https://v2.info.uniswap.org/accounts
*/

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
        ) external returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
        ) external;
}

interface IUniswapV2Pair {
    function sync() external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address) external returns (uint);
}

contract KOL is ERC20 {
    address payable public operations;
    address public uniswapV2WETHPair;
    uint public liquidityAdded;
    bool antisnipe = true;
    bool depth = false;
    uint supplyDivisor = 1000;
    uint sellFee = 5;
    uint buyFee = 5;
    mapping(address => bool) public isUniswapPair;
    
    IWETH weth;
    IUniswapV2Router uniswapV2Router;
    
    error OnlyOps();
    error AntiSnipe();
    error NoBalance();
    error NotZero();
    error NotGreaterThanFive();

    receive() external payable {}

    constructor() ERC20("KOL", "KOL", 18) {
        operations = payable(msg.sender);
        uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2WETHPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        isUniswapPair[uniswapV2WETHPair] = true;
        weth = IWETH(uniswapV2Router.WETH());
        _mint(msg.sender, 21_000_000 * 10 ** 18);
    }

    function addUniswapPair(address pair) external {
        if(msg.sender != operations) revert OnlyOps();
        isUniswapPair[pair] = true;
    }

    function forceSwap() external {
        if(msg.sender != operations) revert OnlyOps();
        if(balanceOf[address(this)] == 0) revert NoBalance();
        swapTokens(balanceOf[address(this)]);
        IUniswapV2Pair(uniswapV2WETHPair).sync();
    }

    function changeOperations(address payable operations_) external {
        if(msg.sender != operations) revert OnlyOps();
        if(operations_ == address(0)) revert NotZero();
        operations = operations_;
    }

    function changeSupplyDivisor(uint supplyDivisor_) external {
        if(msg.sender != operations) revert OnlyOps();
        if(supplyDivisor_ == 0) revert NotZero();
        supplyDivisor = supplyDivisor_;
    }

    function changeSellFee(uint sellFee_) external {
        if(msg.sender != operations) revert OnlyOps();
        if(sellFee_ > 5) revert NotGreaterThanFive();
        sellFee = sellFee_;
    }

    function changeBuyFee(uint buyFee_) external {
        if(msg.sender != operations) revert OnlyOps();
        if(buyFee_ > 5) revert NotGreaterThanFive();
        buyFee = buyFee_;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool){
        if(isUniswapPair[msg.sender] && to != operations && to != address(this)) {
            uint256 fee = (amount * buyFee) / 100;
            super.transfer(address(this), fee);
            if(antisnipe && liquidityAdded != 0) {
                if(block.number - liquidityAdded < 600) {
                    if(amount > (totalSupply / 300) * ((block.number - liquidityAdded)/2)) return false;
                }
                else antisnipe = false;
            }
            return super.transfer(to, amount - fee);
        }    
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if(isUniswapPair[to] ) {
            if(liquidityAdded == 0) 
                liquidityAdded = block.number;
            if(from != operations && from != address(this)){
                uint256 fee = (amount * sellFee) / 100;
                super.transferFrom(from, address(this), fee);
                uint256 balance = balanceOf[address(this)];
                if(balance > totalSupply / supplyDivisor && !depth)  {
                    depth = true;
                    swapTokens(balance);
                    depth = false;
                }     
                return super.transferFrom(from, to, amount - fee);
            }
        }
        return super.transferFrom(from, to, amount);
    }

    function swapTokens(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(weth);
        ERC20(address(this)).approve(address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        weth.deposit{value: address(this).balance/2}();
        weth.transfer(uniswapV2WETHPair, weth.balanceOf(address(this)));
        (bool success,) = operations.call{value: address(this).balance}("");
    }
}

/*
        ╦╔═╔═╗╦    ╔═╗╦═╗╔═╗╔═╗╔═╗╦  ╔═╗
        ╠╩╗║ ║║    ╠═╝╠╦╝║╣ ╚═╗╠═╣║  ║╣ 
        ╩ ╩╚═╝╩═╝  ╩  ╩╚═╚═╝╚═╝╩ ╩╩═╝╚═╝
               https://kols.life
*/

contract Presale {
    mapping(address => uint) public balances;
    mapping(address => uint) public contributorIndexAt;
    address[] public contributors;

    uint256 public tokensForPresale;
    uint256 public tokensPerEth;
    uint256 public airdropPos;

    uint256 public constant MAX_CONTRIBUTION = 2 ether;

    KOL public kol;

    error NoEthSent();
    error NoEthToRefund();
    error PresaleNotEnded();
    error PresaleEnded();
    error AirdropFinished();
    error NotListed();
    error MaxContributions();

    event EthereumReceived(address indexed from, uint256 amount);
    event EthereumRefunded(address indexed to, uint256 amount);

    constructor(
        address payable _token,
        uint256 _tokensPerEth,
        uint256 _tokensForPresale,
        address[4] memory _team,
        uint256 _amount
    ) {
        kol = KOL(_token);
        tokensPerEth = _tokensPerEth;
        tokensForPresale = _tokensForPresale;
        for (uint256 i = 0; i < _team.length; i++) {
            balances[_team[i]] = _amount / tokensPerEth;
            contributors.push(_team[i]);
            contributorIndexAt[_team[i]] = contributors.length;
        }
    }

    receive() external payable {
        if (msg.value == 0) revert NoEthSent();
        if (tokensForPresale == 0) revert PresaleEnded();
        uint256 ethRefund;
        uint256 tokens = msg.value * tokensPerEth;
        if (tokens > tokensForPresale) {
            tokens = tokensForPresale;
            ethRefund = (msg.value - tokens / tokensPerEth);
        }
        if(balances[msg.sender] == MAX_CONTRIBUTION) revert MaxContributions();
        uint256 ethValue = msg.value - ethRefund;
        if(balances[msg.sender] + ethValue > MAX_CONTRIBUTION) {
            ethValue = MAX_CONTRIBUTION - balances[msg.sender];
            tokens = ethValue * tokensPerEth;
            ethRefund = msg.value - ethValue;
        }
        
        tokensForPresale -= tokens;
        balances[msg.sender] += ethValue;
        if (contributorIndexAt[msg.sender] == 0) {
            contributors.push(msg.sender);
            contributorIndexAt[msg.sender] = contributors.length;
        }
        if (ethRefund > 0) {
            payable(msg.sender).transfer(ethRefund);
        }
        emit EthereumReceived(msg.sender, ethValue);
    }

    function refund() external {
        if (balances[msg.sender] == 0) revert NoEthToRefund();
        if (tokensForPresale == 0) revert PresaleEnded();
        uint256 eth = balances[msg.sender];
        balances[msg.sender] = 0;
        tokensForPresale += eth * tokensPerEth;
        payable(msg.sender).transfer(eth);
        emit EthereumRefunded(msg.sender, eth);
    }

    function airdrop(uint256 count) external {
        if (tokensForPresale > 0) revert PresaleNotEnded();
        if (kol.liquidityAdded() == 0) revert NotListed();
        if (airdropPos == contributors.length) revert AirdropFinished();
        uint256 end = airdropPos + count;
        if (end > contributors.length) {
            end = contributors.length;
        }
        uint256 i;
        for (i = airdropPos; i < end; i++) {
            uint256 tokens = balances[contributors[i]] * tokensPerEth;
            balances[contributors[i]] = 0;
            kol.transfer(contributors[i], tokens);
        }
        airdropPos = i;
    }

    function withdraw() external {
        if (tokensForPresale > 0) revert PresaleNotEnded();
        payable(kol.operations()).transfer(address(this).balance);
    }

    function contributorCount() external view returns (uint256) {
        return contributors.length;
    }
}