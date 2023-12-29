pragma solidity ^0.5.15;

interface ERC20 {
    function balanceOf(address _owner)  external view returns (uint balance);
}

interface HexBox{
   function balanceOf(address _customerAddress) view external returns(uint256);
   function dividendsOf(address _customerAddress) view external returns(uint256);
   function buyPrice() view external returns(uint256);
   function sellPrice() view external returns(uint256);
   function totalSupply() view external returns(uint256);
}

interface Fomo {
     function getBuyPrice() view external returns(uint256);
     function getIncrementPrice() view external returns(uint256);
}

interface User {
     function getNameByAddress(address addr) external view returns (bytes32 name);
     function getLastName() view external returns(bytes32);
}

contract MultiCall{
    address internal hexDexAddress;
    address internal fomoAddress;
    address internal usernameAddress;
    address constant internal hexAddress = address(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39);


    constructor (address _hexdex, address _fomo, address _user) public {
        hexDexAddress = _hexdex;
        fomoAddress = _fomo;
        usernameAddress=_user;
    }

    function getData() public view returns (
        uint256 userBalance,
        uint256 userDivs,
        uint256 buyPrice3d,
        uint256 sellPrice3d,
        uint256 totalSupply,
        uint256 h3dbalance,
        uint256 polyPrice,
        uint256 incrementPrice,
        uint256 polyBalance,
        bytes32 username,
        bytes32 lastUser
    ){
        ERC20 HEX = ERC20(hexAddress);
        HexBox H3D = HexBox(hexDexAddress);
        Fomo FOMO = Fomo(fomoAddress);
        User USER = User(usernameAddress);

        userBalance = H3D.balanceOf(msg.sender);
        userDivs =  H3D.dividendsOf(msg.sender);
        buyPrice3d = H3D.buyPrice();
        sellPrice3d = H3D.buyPrice();
        totalSupply = H3D.totalSupply();
        h3dbalance = HEX.balanceOf(hexDexAddress);
        polyPrice = 0;
        incrementPrice = 0;
        polyBalance = 0;
        username = USER.getNameByAddress(msg.sender);
        lastUser = USER.getLastName();
    }
}