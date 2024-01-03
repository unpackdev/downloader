pragma solidity ^0.5.0;


interface ZapperFactory {
    function ZapIn(
        address _toWhomToIssue,
        address _FromTokenContractAddress,
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 _amount,
        uint256 _minPoolTokens
    ) external payable returns (uint256);
}


interface UniswapPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}


contract ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function decimals() public view returns(uint);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
}


contract AdminRole {

    mapping (address => bool) adminGroup;
    address payable owner;

    constructor () public {
        adminGroup[msg.sender] = true;
        owner = msg.sender;
    }
    
    modifier onlyAdmin() {
        require(
            isAdmin(msg.sender),
            "The caller is not Admin"
        );
        _;
    }

    modifier onlyOwner {
        require(
            owner == msg.sender,
            "The caller is not Owner"
        );
        _;
    }

    function addAdmin(address addr) external onlyAdmin {
        adminGroup[addr] = true;
    }
    function delAdmin(address addr) external onlyAdmin {
        adminGroup[addr] = false;
    }

    function isAdmin(address addr) public view returns(bool) {
        return adminGroup[addr];
    }

    function kill() external onlyOwner {
        selfdestruct(owner);
    }
}

contract Withdrawable is AdminRole {
    /*
     * External Function to withdraw founds -> Gas or Tokens
     */
    function withdrawTo (address payable dst, uint founds, address token) external onlyAdmin {
        if (token == address(0))
            require (address(this).balance >= founds);
        else {
            ERC20 erc20 = ERC20(token);
            require (erc20.balanceOf(address(this)) >= founds);
        }
        sendFounds(dst,founds, token);
    }

    /*
     * Function to send founds -> Gas or Tokens
     */
    function sendFounds(address payable dst, uint amount, address token) internal returns(bool) {
        ERC20 erc20;
        if (token == address(0))
            require(address(dst).send(amount), "Impossible send founds");
        else {
            erc20 = ERC20(token);
            require(erc20.transfer(dst, amount), "Impossible send founds");
        }
    }
}


contract Split is Withdrawable {
    address factoryAddress = 0xE83554B397BdA8ECAE7FEE5aeE532e83Ee9eB29D;

    
    function changeFactory(address _factory) external onlyAdmin {
        factoryAddress = _factory;
    }
    
    function split(address _FromTokenContractAddress, uint256 amount, address[] calldata pairs) external {
        uint256 len = pairs.length;
        ERC20 token = ERC20(_FromTokenContractAddress);
        
        /*
         * Minimo un elemento
         */
        require(len != 0, "Pairs MUST have at least 1 element");
        
        /*
         * Amount mayor a 0, pero es menos costoso preguntar por != 0
         */
        require(amount != 0, "Amount MUST be greater than zero");

        /*
         * Primero transferimos los fondos totales al contrato
         */
        require(token.transferFrom(msg.sender, address(this), amount), "Unable to transferFrom()");

        /*
         * Habilitamos al contrato que distribuye a que use nuestros fondos
         */
        require(token.approve(factoryAddress, amount), "Unable to appove()");
       
        /*
         * Dividir el total en la cantidad de pair
         */
        uint256 local_amount = amount / len;
        uint256 i;
        for ( i = 0; i < len; i++) {
            require(deposit(_FromTokenContractAddress, local_amount, pairs[i]) != 0, "Deposit Fail");
        }
       
    }
    
    
    function deposit(address _from, uint256 _amount, address _pair) internal returns(uint256) {
        ZapperFactory factory = ZapperFactory(factoryAddress);    
        UniswapPair pair = UniswapPair(_pair);
        address token0 = pair.token0();
        address token1 = pair.token1();
        
        return factory.ZapIn(
            msg.sender,
            _from,
            token0,
            token1,
            _amount,
            0
        );
    }
    
}