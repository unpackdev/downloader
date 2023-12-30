/* 
 *  Ticket 1.0
 *  VERSION: 1.0
 *
 */

pragma solidity ^0.6.0;


contract ERC20{
    function allowance(address owner, address spender) external view returns (uint256){}
    function transfer(address recipient, uint256 amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){}
    function balanceOf(address account) external view returns (uint256){}
}


contract HappyBox{
    
    event Shipped(address shipped);
    
    address[] public modules_list;
    mapping(address => bool)public modules;
    address master;
    
    constructor() public{
        master=msg.sender;
    }
    
    function gift(address tkn,uint amount,address destination) public returns(bool){
        require(modules[msg.sender]);
        require(ERC20(tkn).transfer(destination, amount));
        emit Shipped(tkn);
        return true;
    } 
    
    //mode 1 = install module
    //mode 2 = set master
    //mode 3 = enable module
    //mode 4 = pull token
    function set(address tkn,bool what,uint mode)public{
         require((msg.sender==master)||(modules[msg.sender]));
        if(mode==1){
            require(MVMCertList(0x261CaA04e78D6226Ec7DDdE1C64FEAe155d3dEb2).isModule(tkn));
            modules[tkn]=true;
            modules_list.push(tkn);
        }else if(mode==2){
                master=tkn;
        }else if(mode==3){
                modules[tkn]=what;
        }else if(mode==4){
              ERC20 token=ERC20(tkn);
                token.transfer(master,token.balanceOf(address(this)));
        }
        
    }
}

contract priceList {
    
    event priceSet(address token);
    
    address public master;
    mapping(address => uint)public price;
    address[] list;
    

    constructor() public {
        master=msg.sender;
    }
    
    function priceListing(uint index)view public returns(address,uint,uint){
        return (list[index],price[list[index]],list.length);
    }
    
    function setPrice(address tkn,uint prc)public returns(bool){
        require(msg.sender==master);
        require(prc > 0, "Price > 0 please");
        if(price[tkn]==0)list.push(tkn);
        price[tkn]=prc;
        emit priceSet(tkn);
        return true;
    }
    
}

contract MVMCertList {

    address public master;
    mapping(address => bool)public isFactory;
    mapping(address => bool)public isModule;
    address[] public factory;

    constructor() public {
        master=msg.sender;
    }
    
    function setFactory(address tkn,bool val)public returns(bool){
        require((msg.sender==master)||(isFactory[msg.sender]));
        isFactory[tkn]=val;
        if(val)factory.push(tkn);
        return true;
    }
    
    function setModule(address tkn)public returns(bool){
        require(isFactory[msg.sender]||(msg.sender==master));
        isModule[tkn]=true;
        return true;
    }
    
    function setMaster(address mstr)public returns(bool){
        require((msg.sender==master)||(isFactory[msg.sender]));
        master=mstr;
        return true;
    }
    
}

contract Ticket_1_0_Factory{
    
        uint public code=1;
        
        function install(address happyBox,address priceList)public returns(bool){
            address tkt=address(new Ticket(msg.sender,priceList,happyBox));
            MVMCertList(0x261CaA04e78D6226Ec7DDdE1C64FEAe155d3dEb2).setModule(tkt);
            HappyBox(happyBox).set(tkt,false,1);
            return true;
        }
}


contract Ticket {
    
    uint8 public code=1;
    address public vault;
    HappyBox public box;
    priceList public prices;
    
    constructor(address vlt, address prcs, address gftr) public{
        vault=vlt;
        prices=priceList(prcs);
        box=HappyBox(gftr);
    }
    
    function buy(address tkn,address ref) payable public returns(bool){
        require(box.gift(tkn,msg.value*1000/prices.price(tkn),msg.sender));
        payable(ref).transfer(msg.value/10);
        return true;
    } 
    
    function pull() public {
       payable(vault).transfer(address(this).balance);
    }
    
}