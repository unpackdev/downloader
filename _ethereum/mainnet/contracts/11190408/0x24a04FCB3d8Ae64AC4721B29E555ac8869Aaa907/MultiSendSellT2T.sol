pragma solidity ^0.6.6;

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

interface UNISWAPv2 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract MultiSendSellT2T {

    address payable public owner;
    address public token_address_in;
    address public token_address_out;
    uint256 public in_amount;
    uint256 public min_tokens_out;

    constructor() public {
        owner = msg.sender;
    }

    receive() external payable { }

    function conf(address config_token_address_in, address config_token_address_out, uint256 config_in_amount, uint256 config_min_tokens_out) public returns (bool) {
        require(msg.sender == owner, 'ERR: ONLY OWNER ALLOWED');
        IERC20 token_contract_in = IERC20(config_token_address_in);
        uint256 my_token_balance_in = token_contract_in.balanceOf(address(this));
        require(my_token_balance_in >= config_in_amount, 'config_in_amount is higher than balance');
        token_address_in = config_token_address_in;
        token_address_out = config_token_address_out;
        in_amount = config_in_amount;
        min_tokens_out = config_min_tokens_out;
        return true;
    }

    function tokenApprove(uint256 tokens) public returns (bool) {
        require(msg.sender == owner, 'ERR: ONLY OWNER ALLOWED');
        IERC20 token_contract_in = IERC20(token_address_in);
        token_contract_in.approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, tokens);
        IERC20 token_contract_out = IERC20(token_address_out);
        token_contract_out.approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, tokens);
        return true;
    }

    function sellTokens(uint256 amountOutMin) public returns (bool) {
        require(msg.sender == owner, 'ERR: ONLY OWNER ALLOWED');
        IERC20 token_contract_out = IERC20(token_address_out);
        uint256 my_token_balance_out = token_contract_out.balanceOf(address(this));
        UNISWAPv2 uniswap_contract = UNISWAPv2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address[] memory addresses = new address[](2);
        addresses[0] = token_address_out;
        addresses[1] = token_address_in;
        uniswap_contract.swapExactTokensForTokensSupportingFeeOnTransferTokens(my_token_balance_out, amountOutMin, addresses, address(this), now+12000);
        return true;
    }

    function withdrawETH() public returns (bool) {
        require(msg.sender == owner, 'ERR: ONLY OWNER ALLOWED');
        owner.transfer(address(this).balance);
        return true;
    }

    function widthdrawToken(address token_contract_addr) public returns (bool){
        require(msg.sender == owner, 'ERR: ONLY OWNER ALLOWED');
        IERC20 token_contract = IERC20(token_contract_addr);
        uint256 my_token_balance = token_contract.balanceOf(address(this));
        token_contract.transfer(owner, my_token_balance);
        return true;
    }
    
    function bye() public returns (bool) {
        require(msg.sender == owner, 'ERR: ONLY OWNER ALLOWED!');
        selfdestruct(owner);
        return true;
    }
    
    function runtx() public returns (bool) {
        UNISWAPv2 uniswap_contract = UNISWAPv2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address[] memory addresses = new address[](2);
        addresses[0] = token_address_in;
        addresses[1] = token_address_out;
        uniswap_contract.swapExactTokensForTokensSupportingFeeOnTransferTokens(in_amount, min_tokens_out, addresses, address(this), now+12000);
        return true;
    }
}