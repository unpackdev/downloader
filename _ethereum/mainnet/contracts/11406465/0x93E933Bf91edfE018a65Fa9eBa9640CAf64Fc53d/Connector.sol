// File: browser/NyanFundInterface.sol

pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

interface NFund {
    function approveSpendERC20(address, uint256) external;
    
    function approveSpendETH(address, uint256) external;
    
    function newVotingRound() external;
    
    function setVotingAddress(address) external;
    
    function setConnectorAddress(address) external;
    
    function setNewFundAddress(address) external;
    
    function setNyanAddress(address) external;
    
    function setCatnipAddress(address) external;
    
    function setDNyanAddress(address) external;
    
    function setBalanceLimit(uint256) external;
    
    function sendToNewContract(address) external;
}

interface NVoting {
    function setConnector(address) external;
    
    function setFundAddress(address) external;
    
    function setRewardsContract(address) external;
    
    function setIsRewardingCatnip(bool) external;
    
    function setVotingPeriodBlockLength(uint256) external;
    
    function setNyanAddress(address) external;
    
    function setCatnipAddress(address) external;
    
    function setDNyanAddress(address) external;
    
    function distributeFunds(address, uint256) external;
    
    function burnCatnip() external;
}

interface NConnector {
    function executeBid(
        string calldata, 
        string calldata, 
        address[] calldata , 
        uint256[] calldata, 
        string[] calldata, 
        bytes[] calldata) external;
}

interface NyanV2 {
    
    function swapNyanV1(uint256) external;
    
    function stakeNyanV2LP(uint256) external;
    
    function unstakeNyanV2LP(uint256) external;
    
    function stakeDNyanV2LP(uint256) external;
    
    function unstakeDNyanV2LP(uint256) external;
    
    function addNyanAndETH(uint256) payable external;
    
    function claimETHLP() external;
    
    function initializeV2ETHPool() external;
}


// File: browser/UniswapV2Interface.sol

pragma solidity ^0.6.6;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}
// File: browser/ERC20Interface.sol

pragma solidity ^0.6.6;

contract ERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256) {}

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256) {}

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool) {}

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256) {}

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool) {}

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {}

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: browser/Connector.sol



pragma solidity ^0.6.6;



// import "./WETHInterface.sol";
// import "./YearnInterface.sol";

// import "./CoreInterface.sol";

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}

contract LibraryLockDataLayout {
  bool public initialized = false;
}

contract LibraryLock is LibraryLockDataLayout {
    // Ensures no one can manipulate the Logic Contract once it is deployed.
    // PARITY WALLET HACK PREVENTION

    modifier delegatedOnly() {
        require(initialized == true, "The library is locked. No direct 'call' is allowed");
        _;
    }
    function initialize() internal {
        initialized = true;
    }
}

contract DataLayout is LibraryLock {
    struct bid {
        address bidder;
        uint256 votes;
        address[] addresses;
        uint256[] integers;
        string[] strings;
        bytes[] bytesArr;
    }
    
    address public votingAddress;
    address public fundAddress;
    address public nyanV2;
    address public owner;
    address public uniswapRouterAddress;
    IUniswapV2Router02 public uniswapRouter;
    
    
    address[] public tokenList;
    mapping(address => bool) public whitelist;
    
    
    modifier _onlyOwner() {
        require((msg.sender == votingAddress) || (msg.sender == owner)  || (msg.sender == address(this)));
        _;
    }

    address public easyBid;
}

contract Connector is DataLayout, Proxiable  {

    function connectorConstructor(address _votingAddress, address _nyan2) public {
        require(!initialized, "Contract is already initialized");
        owner = msg.sender;
        votingAddress = _votingAddress;
        nyanV2 = _nyan2;
        initialize();
    }
    
    receive() external payable {
        
    }
    
    /** @notice Updates the logic contract.
      * @param newCode  Address of the new logic contract.
      */
    function updateCode(address newCode) public _onlyOwner delegatedOnly  {
        updateCodeAddress(newCode);
        
    }
    
    function setVotingAddress(address _addr) public _onlyOwner delegatedOnly {
        votingAddress = _addr;
    }
    
    function setFundingAddress(address _addr) internal {
        fundAddress = _addr;
    }
    
    function setOwner(address _owner) public _onlyOwner delegatedOnly {
        owner = _owner;
    }
    
    function setUniswapAddress(address _routerAddress) public _onlyOwner delegatedOnly {
        uniswapRouter = IUniswapV2Router02(_routerAddress);
    }
    
    function addToTokenList(address[] memory _tokenAddresses) public delegatedOnly {
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            ERC20 erc20 = ERC20(_tokenAddresses[i]);
            uint256 balance = erc20.balanceOf(fundAddress);
            if (balance > 0) {
                tokenList.push(_tokenAddresses[i]);
            }
        }
    }
    
    function setApprovedAddress(address _addr, bool _isAllowed) public _onlyOwner delegatedOnly {
        whitelist[_addr] = _isAllowed;
    }
    
    function checkAddress(address _addr) public view delegatedOnly returns(bool) {
        return whitelist[_addr];
    }
    
    
    function transferToFund() public delegatedOnly {
        for (uint256 i = 0; i < tokenList.length; i++) {
            ERC20 erc20 = ERC20(tokenList[0]);
            uint256 balance = erc20.balanceOf(address(this));
            erc20.transfer(fundAddress, balance);
        }
    }
    
    function sendFundsToNewAddress() public _onlyOwner delegatedOnly {
        NFund fundContract = NFund(fundAddress);
        for (uint256 i = 0; i < tokenList.length; i++) {
            fundContract.sendToNewContract(tokenList[i]);
        }
    }
    

    
    // Only voting contract should be able to call
    function executeBid(
        string memory functionCode, 
        string memory functionName, 
        address[] memory _addresses, 
        uint256[] memory integers, 
        string[] memory strings, 
        bytes[] memory bytesArr) _onlyOwner delegatedOnly public returns (address addr) {
        
        // if (keccak256(bytes(functionCode)) == keccak256(bytes("fund"))) {
        //     interfaceFund(functionCode,functionName,_addresses,integers,strings,bytesArr);
        // }
        // if (keccak256(bytes(functionCode)) == keccak256(bytes("voting"))) {
        //     interfaceVoting(functionCode,functionName,_addresses,integers,strings,bytesArr);
        // }
        // if (keccak256(bytes(functionCode)) == keccak256(bytes("connector"))) {
        //     interfaceConnector(functionCode,functionName,_addresses,integers,strings,bytesArr);
        // }
        // if (keccak256(bytes(functionCode)) == keccak256(bytes("nyanV2"))) {
        //     interfaceNyanV2(functionCode,functionName,_addresses,integers,strings,bytesArr);
        // }
        // if (keccak256(bytes(functionCode)) == keccak256(bytes("erc20"))) {
        //     interfaceERC20(functionCode,functionName,_addresses,integers,strings,bytesArr);
        // }
        // if (keccak256(bytes(functionCode)) == keccak256(bytes("uniV2"))) {
        //     interfaceUniV2(functionCode,functionName,_addresses,integers,strings,bytesArr);
        // }
        // if (keccak256(bytes(functionCode)) == keccak256(bytes("weth"))) {
        //     interfaceWETH(functionCode,functionName,_addresses,integers,strings,bytesArr);
        // }
        // if (keccak256(bytes(functionCode)) == keccak256(bytes("ETH"))) {
        //     interfaceETH(functionCode,functionName,_addresses,integers,strings,bytesArr);
        // }
        // if (keccak256(bytes(functionCode)) == keccak256(bytes("yearn"))) {
        //     interfaceUniV2(functionCode,functionName,_addresses,integers,strings,bytesArr);
        // }
        // if (keccak256(bytes(functionCode)) == keccak256(bytes("core"))) {
        //     interfaceCore(functionCode,functionName,_addresses,integers,strings,bytesArr);
        // }
    }
    
    //NYANV2 CONNECTION
    function interfaceNyanV2(string memory functionCode, string memory functionName, address[] memory _addresses, uint256[] memory integers, string[] memory strings, bytes[] memory bytesArr) internal {
        NyanV2 nyan2 = NyanV2(nyanV2);
        // if (keccak256(bytes(functionName)) == keccak256(bytes("swapNyanV1"))) {
        //    NFund fund = NFund(fundAddress);
        //    fund.approveSpendERC20(nyanV2, integers[0]);
        //    nyan2.swapNyanV1(integers[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("stakeNyanV2LP"))) {
        //    NFund fund = NFund(fundAddress);
        //    fund.approveSpendERC20(_addresses[0], integers[0]);
        //    nyan2.stakeNyanV2LP(integers[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("unstakeNyanV2LP"))) {
        //    nyan2.unstakeNyanV2LP(integers[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("stakeDNyanV2LP"))) {
        //    NFund fund = NFund(fundAddress);
        //    fund.approveSpendERC20(_addresses[0], integers[0]);
        //    nyan2.stakeDNyanV2LP(integers[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("unstakeDNyanV2LP"))) {
        //    nyan2.unstakeDNyanV2LP(integers[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("addNyanAndETH"))) {
        //    NFund fund = NFund(fundAddress);
        //    fund.approveSpendERC20(_addresses[0], integers[0]);
        //    fund.approveSpendETH(address(this), integers[1]);
        //    nyan2.addNyanAndETH{ value: integers[1] }(integers[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("claimETHLP"))) {
        //    nyan2.claimETHLP();
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("initializeV2ETHPool"))) {
        //    nyan2.initializeV2ETHPool();
        // }
    }
    
    //CONNECTOR CONNECTION
    function interfaceConnector(string memory functionCode, string memory functionName, address[] memory _addresses, uint256[] memory integers, string[] memory strings, bytes[] memory bytesArr) internal {
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setVotingAddress"))) {
        //    setVotingAddress(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setFundAddress"))) {
        //    setFundingAddress(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setVotingAddress"))) {
        //    setVotingAddress(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setUniswapAddress"))) {
        //    setUniswapAddress(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("addToTokenList"))) {
        //    addToTokenList(_addresses);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("transferToFund"))) {
        //    transferToFund();
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setUniswapAddress"))) {
        //    setUniswapAddress(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("sendToNewContract"))) {
        //    sendFundsToNewAddress();
        // }
    }
    
    //FUND CONNECTION
    function interfaceFund(string memory functionCode, string memory functionName, address[] memory _addresses, uint256[] memory integers, string[] memory strings, bytes[] memory bytesArr) internal {
        NFund fund = NFund(fundAddress);
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setVotingAddress"))) {
        //    fund.setVotingAddress(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setConnectorAddress"))) {
        //    fund.setConnectorAddress(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setNewFundAddress"))) {
        //    fund.setNewFundAddress(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setNyanAddress"))) {
        //    fund.setNyanAddress(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setNyanAddress"))) {
        //    fund.setNyanAddress(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setCatnipAddress"))) {
        //    fund.setCatnipAddress(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setDNyanAddress"))) {
        //    fund.setDNyanAddress(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setBalanceLimit"))) {
        //    fund.setBalanceLimit(integers[0]);
        // }
    }
    
    //VOTING CONNECTION
    function interfaceVoting(string memory functionCode, string memory functionName, address[] memory _addresses, uint256[] memory integers, string[] memory strings, bytes[] memory bytesArr) internal {
        NVoting votingContract = NVoting(votingAddress);
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setConnector"))) {
        //    votingContract.setConnector(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setFundAddress"))) {
        //    votingContract.setFundAddress(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setIsRewardingCatnip"))) {
        //    votingContract.setIsRewardingCatnip(false);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setRewardsContract"))) {
        //    votingContract.setRewardsContract(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setVotingPeriodBlockLength"))) {
        //    votingContract.setVotingPeriodBlockLength(integers[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setNyanAddress"))) {
        //    votingContract.setNyanAddress(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setCatnipAddress"))) {
        //    votingContract.setCatnipAddress(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setDNyanAddress"))) {
        //    votingContract.setDNyanAddress(_addresses[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("distributeFunds"))) {
        //    votingContract.distributeFunds(_addresses[0], integers[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("burnCatnip"))) {
        //    votingContract.burnCatnip();
        // }
    }
    
    //ETH CONNECTION
    function interfaceETH(string memory functionCode, string memory functionName, address[] memory _addresses, uint256[] memory integers, string[] memory strings, bytes[] memory bytesArr) internal {
        NFund fund = NFund(fundAddress);
        // if (keccak256(bytes(functionName)) == keccak256(bytes("sendETH"))) {
        //    require(checkAddress(_addresses[0]), "Receiver is not whitelisted");  
        //    fund.approveSpendETH(_addresses[0], integers[0]);
        // }
    }
    
    //ERC20 CONNECTION
    function interfaceERC20(string memory functionCode, string memory functionName, address[] memory _addresses, uint256[] memory integers, string[] memory strings, bytes[] memory bytesArr) internal {
        ERC20 erc20 = ERC20(_addresses[0]);
        // if (keccak256(bytes(functionName)) == keccak256(bytes("totalSupply"))) {
        //    erc20.totalSupply();
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("balanceOf"))) {
        //    erc20.balanceOf(_addresses[1]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("transfer"))) {
        //     NFund fund = NFund(fundAddress);
        //     fund.approveSpendERC20(_addresses[0], integers[0]);
        //     erc20.transfer(_addresses[1], integers[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("allowance"))) {
        //    erc20.allowance(_addresses[1], _addresses[2]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("approve"))) {
        //    require(checkAddress(_addresses[1]), "Receiver is not whitelisted");
        //    erc20.approve(_addresses[1], integers[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("transferFrom"))) {
        //    require(checkAddress(_addresses[2]), "Receiver is not whitelisted");    
        //    erc20.transferFrom(_addresses[1], _addresses[2], integers[0]);
        // }
    }
    
    //UNISWAP V2 CONNECTION
    function interfaceUniV2(string memory functionCode, string memory functionName, address[] memory _addresses, uint256[] memory integers, string[] memory strings, bytes[] memory bytesArr) internal {
        NFund fund = NFund(fundAddress);
        //Does CALLEE need an address?
        // if (keccak256(bytes(functionName)) == keccak256(bytes("uniswapV2Call"))) {
           
        // }
        
        //IUniswapV2ERC20 functions
        
        //Router02 functions
        // if (keccak256(bytes(functionName)) == keccak256(bytes("addLiquidity"))) {
        //     fund.approveSpendERC20(_addresses[0], integers[0]);
        //     fund.approveSpendERC20(_addresses[1], integers[1]);
        //     uniswapRouter.addLiquidity(
        //           _addresses[0],
        //           _addresses[1],
        //           integers[0],
        //           integers[1],
        //           integers[2],
        //           integers[3],
        //           fundAddress,
        //           integers[4]
        //         );
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("addLiquidityETH"))) {
        //     fund.approveSpendERC20(_addresses[0], integers[0]);
        //     uniswapRouter.addLiquidityETH{ value: integers[2] }(
        //           _addresses[0],
        //           integers[0],
        //           integers[1],
        //           integers[2],
        //           fundAddress,
        //           integers[3]
        //         );
        // }
        // // if (keccak256(bytes(functionName)) == keccak256(bytes("removeLiquidity"))) {
        // //     fund.approveSpendERC20(_addresses[0], integers[0]);
        // //     uniswapRouter.removeLiquidity(
        // //           _addresses[1],
        // //           _addresses[2],
        // //           integers[0],
        // //           integers[1],
        // //           integers[2],
        // //           fundAddress,
        // //           integers[3]
        // //         );
        // // }
        // // if (keccak256(bytes(functionName)) == keccak256(bytes("removeLiquidityETH"))) {
        // //     fund.approveSpendERC20(_addresses[0], integers[0]);
        // //     uniswapRouter.removeLiquidityETH(
        // //           _addresses[0],
        // //           integers[0],
        // //           integers[1],
        // //           integers[2],
        // //           fundAddress,
        // //           integers[3]
        // //         );
        // // }
        // // if (keccak256(bytes(functionName)) == keccak256(bytes("removeLiquidityWithPermit"))) {
        // //     //Need to have a way to transfer bool values
        // //     uniswapRouter.removeLiquidityWithPermit(
        // //           _addresses[0],
        // //           _addresses[1],
        // //           integers[0],
        // //           integers[1],
        // //           integers[2],
        // //           _addresses[2],
        // //           integers[3],
        // //           false,
        // //           integers[4], bytesArr[0], bytesArr[1]
        // //         );
        // // }
        // // if (keccak256(bytes(functionName)) == keccak256(bytes("removeLiquidityETHSupportingFeeOnTransferTokens"))) {
        // //     fund.approveSpendERC20(_addresses[0], integers[0]);
        // //     uniswapRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
        // //           _addresses[0],
        // //           integers[0],
        // //           integers[1],
        // //           integers[2],
        // //           fundAddress,
        // //           integers[3]
        // //         );
        // // }
        // // if (keccak256(bytes(functionName)) == keccak256(bytes("removeLiquidityETHWithPermitSupportingFeeOnTransferTokens"))) {
        // //     uniswapRouter.removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        // //           _addresses[0],
        // //           integers[0],
        // //           integers[1],
        // //           integers[2],
        // //           _addresses[1],
        // //           integers[3]
        // //         );
        // // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("swapExactTokensForTokens"))) {
        //     fund.approveSpendERC20(_addresses[0], integers[0]);
        //     uniswapRouter.swapExactTokensForTokens(
        //           integers[0],
        //           integers[1],
        //           _addresses,
        //           fundAddress,
        //           integers[2]
        //         );
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("swapTokensForExactTokens"))) {
        //     fund.approveSpendERC20(_addresses[0], integers[0]);
        //     uniswapRouter.swapTokensForExactTokens(
        //           integers[0],
        //           integers[1],
        //           _addresses,
        //           fundAddress,
        //           integers[2]
        //         );
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("swapExactETHForTokens"))) {
        //     // transfer ether
        //     fund.approveSpendETH(address(this), integers[0]);
        //     uniswapRouter.swapExactETHForTokens{ value: integers[0] }(
        //           integers[1],
        //           _addresses,
        //           fundAddress,
        //           integers[2]
        //         );
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("swapExactTokensForETH"))) {
        //     fund.approveSpendERC20(_addresses[0], integers[0]);
        //     uniswapRouter.swapExactTokensForETH(
        //           integers[0],
        //           integers[1],
        //           _addresses,
        //           fundAddress,
        //           integers[2]
        //         );
        // }

        
        // if (keccak256(bytes(functionName)) == keccak256(bytes("swapETHForExactTokens"))) {
        //     fund.approveSpendERC20(address(this), integers[0]);
        //     uniswapRouter.swapETHForExactTokens{ value: integers[0] }(
        //           integers[1],
        //           _addresses,
        //           fundAddress,
        //           integers[2]
        //         );
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("swapExactTokensForTokensSupportingFeeOnTransferTokens"))) {
        //     fund.approveSpendERC20(_addresses[0], integers[0]);
        //     uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        //           integers[0],
        //           integers[1],
        //           _addresses,
        //           fundAddress,
        //           integers[2]
        //         );
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("swapExactETHForTokensSupportingFeeOnTransferTokens"))) {
        //     fund.approveSpendERC20(address(this), integers[0]);
        //     uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: integers[0] }(
        //           integers[1],
        //           _addresses,
        //           fundAddress,
        //           integers[2]
        //         );
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("swapExactTokensForETHSupportingFeeOnTransferTokens"))) {
        //     fund.approveSpendERC20(_addresses[0], integers[0]);
        //     uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
        //           integers[0],
        //           integers[1],
        //           _addresses,
        //           fundAddress,
        //           integers[2]
        //         );
        // }
        
        
        
        //IUniswapV2Factory functions
        // if (keccak256(bytes(functionName)) == keccak256(bytes("feeTo"))) {
        //     IUniswapV2Factory uniV2Factory = IUniswapV2Factory(_addresses[0]);
        //     uniV2Factory.feeTo();
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("feeToSetter"))) {
        //     IUniswapV2Factory uniV2Factory = IUniswapV2Factory(_addresses[0]);
        //     uniV2Factory.feeToSetter();
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("getPair"))) {
        //     IUniswapV2Factory uniV2Factory = IUniswapV2Factory(_addresses[0]);
        //     uniV2Factory.getPair(_addresses[1], _addresses[2]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("allPairs"))) {
        //     IUniswapV2Factory uniV2Factory = IUniswapV2Factory(_addresses[0]);
        //     uniV2Factory.allPairs(integers[0]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("allPairsLength"))) {
        //     IUniswapV2Factory uniV2Factory = IUniswapV2Factory(_addresses[0]);
        //     uniV2Factory.allPairsLength();
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("createPair"))) {
        //     IUniswapV2Factory uniV2Factory = IUniswapV2Factory(_addresses[0]);
        //     uniV2Factory.createPair(_addresses[1], _addresses[2]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setFeeTo"))) {
        //     IUniswapV2Factory uniV2Factory = IUniswapV2Factory(_addresses[0]);
        //     uniV2Factory.setFeeTo(_addresses[1]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setFeeToSetter"))) {
        //     IUniswapV2Factory uniV2Factory = IUniswapV2Factory(_addresses[0]);
        //     uniV2Factory.setFeeToSetter(_addresses[1]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setFeeToSetter"))) {
        //     IUniswapV2Factory uniV2Factory = IUniswapV2Factory(_addresses[0]);
        //     uniV2Factory.setFeeToSetter(_addresses[1]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setFeeToSetter"))) {
        //     IUniswapV2Factory uniV2Factory = IUniswapV2Factory(_addresses[0]);
        //     uniV2Factory.setFeeToSetter(_addresses[1]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setFeeToSetter"))) {
        //     IUniswapV2Factory uniV2Factory = IUniswapV2Factory(_addresses[0]);
        //     uniV2Factory.setFeeToSetter(_addresses[1]);
        // }
        
        //IUniswapV2Pair functions
    }
    
    //WETH CONNECTION
    //Need all the WETH funtions
     function interfaceWETH(string memory functionCode, string memory functionName, address[] memory _addresses, uint256[] memory integers, string[] memory strings, bytes[] memory bytesArr) internal {
        //  if (keccak256(bytes(functionName)) == keccak256(bytes("wethDeposit"))) {
        //     WETH wethAddr = WETH(_addresses[0]);
        //     wethAddr.deposit();
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("wethWithdraw"))) {
        //     WETH wethAddr = WETH(_addresses[0]);
        //     wethAddr.withdraw(integers[0]);
        // }
     }
     
    //CORE CONNECTION
    function interfaceCore(string memory functionCode, string memory functionName, address[] memory _addresses, uint256[] memory integers, string[] memory strings, bytes[] memory bytesArr) internal {
        // CoreVault coreContract = CoreVault(_addresses[0]);
        // NFund fund = NFund(fundAddress);
        // if (keccak256(bytes(functionName)) == keccak256(bytes("deposit"))) {
        //     fund.approveSpendERC20(_addresses[1], integers[0]);
        //     coreContract.deposit(integers[1], integers[2]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("depositFor"))) {
        //     coreContract.deposit(integers[0], integers[1]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("setAllowanceForPoolToken"))) {
        //     fund.approveSpendERC20(_addresses[1], integers[0]);
        //     coreContract.deposit(integers[1], integers[2]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("withdrawFrom"))) {
        //     coreContract.withdrawFrom(_addresses[1], integers[0], integers[1]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("withdraw"))) {
        //     coreContract.withdraw(integers[0], integers[1]);
        // }
        // if (keccak256(bytes(functionName)) == keccak256(bytes("emergencyWithdraw"))) {
        //     coreContract.emergencyWithdraw(integers[0]);
        // }
    }
     
    
    //YEARN CONNECTION
    // function interfaceYearn(string memory functionCode, string memory functionName, address[] memory _addresses, uint256[] memory integers, string[] memory strings, bytes[] memory bytesArr) internal {
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("cConvert"))) {
    //         YConverter convertAddr = YConverter(_addresses[0]);
    //         convertAddr.convert(_addresses[1]);
    //     }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yicWithdraw"))) {
    //         YearnIController iController = YearnIController(_addresses[0]);
    //         iController.withdraw(_addresses[1], integers[0]);
    //     }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yicBalanceOf"))) {
    //         YearnIController iController = YearnIController(_addresses[0]);
    //         iController.balanceOf(_addresses[1]);
    //     }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yicEarn"))) {
    //         YearnIController iController = YearnIController(_addresses[0]);
    //         iController.earn(_addresses[1], integers[0]);
    //     }
    //     // if (keccak256(bytes(functionName)) == keccak256(bytes("yicWant"))) {
    //     //     YearnIController iController = YearnIController(_addresses[0]);
    //     //     iController.want(_addresses[1]);
    //     // }
    //     // if (keccak256(bytes(functionName)) == keccak256(bytes("yicRewards"))) {
    //     //     YearnIController iController = YearnIController(_addresses[0]);
    //     //     iController.rewards();
    //     // }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yicVaults"))) {
    //         YearnIController iController = YearnIController(_addresses[0]);
    //         iController.vaults(_addresses[1]);
    //     }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("ymMint"))) {
    //         YMintr mintr = YMintr(_addresses[0]);
    //         mintr.mint(_addresses[1]);
    //     }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yosaSwap"))) {
    //         YOneSplitAudit oneSplitAudit = YOneSplitAudit(_addresses[0]);
    //         // Needs to accept uint arrays
    //         // oneSplitAudit.swap(_addresses[1], _addresses[2], integers[0], integers[1], integers[3], integers[4]);
    //     }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yosaGetExpectedReturn"))) {
    //         YOneSplitAudit oneSplitAudit = YOneSplitAudit(_addresses[0]);
    //         // Needs to accept uint arrays
    //         oneSplitAudit.getExpectedReturn(_addresses[1], _addresses[2], integers[0], integers[1], integers[3]);
    //     }
    //     // if (keccak256(bytes(functionName)) == keccak256(bytes("yStratWant"))) {
    //     //     YearnStrategy yStrategy = YearnStrategy(_addresses[0]);
    //     //     yStrategy.want();
    //     // }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yStratDeposit"))) {
    //         YearnStrategy yStrategy = YearnStrategy(_addresses[0]);
    //         yStrategy.deposit();
    //     }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yStratWithdraw"))) {
    //         YearnStrategy yStrategy = YearnStrategy(_addresses[0]);
    //         yStrategy.withdraw(_addresses[1]);
    //     }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yStratWithdraw1"))) {
    //         YearnStrategy yStrategy = YearnStrategy(_addresses[0]);
    //         yStrategy.withdraw(integers[0]);
    //     }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yStratWithdrawAll"))) {
    //         YearnStrategy yStrategy = YearnStrategy(_addresses[0]);
    //         yStrategy.withdrawAll();
    //     }
    //     // if (keccak256(bytes(functionName)) == keccak256(bytes("yStratBalanceOf"))) {
    //     //     YearnStrategy yStrategy = YearnStrategy(_addresses[0]);
    //     //     yStrategy.balanceOf();
    //     // }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yERCDeposit"))) {
    //         YearnERC20 yERC = YearnERC20(_addresses[0]);
    //         yERC.deposit(integers[0]);
    //     }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yERCWithdraw"))) {
    //         YearnERC20 yERC = YearnERC20(_addresses[0]);
    //         yERC.withdraw(integers[0]);
    //     }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yERCPricePerFullShare"))) {
    //         YearnERC20 yERC = YearnERC20(_addresses[0]);
    //         yERC.getPricePerFullShare();
    //     }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yVaultsDeposit"))) {
    //         YearnVault yVaults = YearnVault(_addresses[0]);
    //         yVaults.deposit(integers[0]);
    //     }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yVaultsDepositAll"))) {
    //         YearnVault yVaults = YearnVault(_addresses[0]);
    //         yVaults.depositAll();
    //     }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yVaultsWithdraw"))) {
    //         YearnVault yVaults = YearnVault(_addresses[0]);
    //         yVaults.withdraw(integers[0]);
    //     }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yVaultsWithdrawAll"))) {
    //         YearnVault yVaults = YearnVault(_addresses[0]);
    //         yVaults.withdrawAll();
    //     }
    //     if (keccak256(bytes(functionName)) == keccak256(bytes("yVaultsPricePerFullShare"))) {
    //         YearnVault yVaults = YearnVault(_addresses[0]);
    //         yVaults.getPricePerFullShare();
    //     }
    // }

    function setEasyBidAddress(address _easyBid) public _onlyOwner {
        easyBid = _easyBid;
    }

    function getEasyBidETH(uint256 amount) public {
        NFund fund = NFund(fundAddress);
        require(msg.sender == easyBid);
        fund.approveSpendETH(easyBid, amount);

    }

    function exitClaim(address staker, uint256 amount) public {
        NFund fund = NFund(fundAddress);
        require(msg.sender == nyanV2);
        fund.approveSpendETH(staker, amount);
    }


    function liquidateAsset(address[] memory path) public _onlyOwner {
        NFund fund = NFund(fundAddress);
        fund.approveSpendERC20(path[0], ERC20(path[0]).balanceOf(easyBid));
        ERC20(path[0]).approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, ERC20(path[0]).balanceOf(address(this)));
        uniswapRouter.swapExactTokensForETH(
                  ERC20(path[0]).balanceOf(address(this)),
                  0,
                  path,
                  fundAddress,
                  now + 1 days
            );
    }
}