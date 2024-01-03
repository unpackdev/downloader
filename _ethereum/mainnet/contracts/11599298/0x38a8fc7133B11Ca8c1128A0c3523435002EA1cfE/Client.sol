pragma solidity ^0.6.12;

// describe the interface

contract Service{
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) public payable{}
    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) public payable{}
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) public payable {}
}

contract ERC20 {
    function balanceOf(address tokenOwner) public view returns (uint balance) {}
    function transfer(address to, uint tokens) public returns (bool success){}
    function approve(address useder, uint tokens) public returns (bool success){}
}

contract Client {

    Service _s;

    address payable public manager;

    address[] public path;
    
    bool public ready = false;

    uint public price;

    uint public baseDecimal;

    uint public quoteDecimal;

    constructor() public {
        _s = Service(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        manager = msg.sender;
    }

    modifier restricted {
        require(msg.sender == manager);
        _;
    }
    
    function transferManager(address payable addr) public restricted{
        manager = addr;
    }

    function deposit() public payable {}

    function withdraw() public restricted {
        manager.transfer(address(this).balance);
    }
    
    function withdraw_t(address _token) public restricted {
        ERC20(_token).transfer(manager, ERC20(_token).balanceOf(address(this)));
    }

    function config(address _baseAddr, uint _baseDecimal, address _quoteAddr, uint _quoteDecimal, uint _price) public payable restricted {
        delete path;
        path.push(_quoteAddr);
        path.push(_baseAddr);
        price = _price;
        baseDecimal = _baseDecimal;
        quoteDecimal = _quoteDecimal;
        ready = true;
    }

    function t() public{
        require(ready);
        _s.swapExactTokensForTokens(ERC20(path[0]).balanceOf(address(this)), ERC20(path[0]).balanceOf(address(this)) * price / (10 ** (quoteDecimal - baseDecimal)), path, manager, block.timestamp + 10);
        if(ERC20(path[0]).balanceOf(address(this)) < 100000){
            ready = false;
        }
    }

    function e() public{
        require(ready);
        _s.swapExactETHForTokens{value: address(this).balance}(address(this).balance * price / (10 ** (18 - baseDecimal)), path, manager, block.timestamp + 10) ;
        if(address(this).balance < 0.1 ether){
            ready = false;
        }
    }
}