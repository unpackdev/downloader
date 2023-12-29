// SPDX-License-Identifier: MIT
// ERMINE STORE, EVM, Affiliate program
// https://ermine.pro

pragma solidity ^0.8.23;

import "./ERC1155Receiver.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Ermine.sol";
import "./ErmineVM.sol";
import "./ErmineSwap.sol";

contract ErmineStoreIn is ERC1155Receiver, Ownable {
    uint256 public forDEX;
    uint256 public airdrop = 3*1e24;
    uint[] public percent = new uint[](3);
    address walletDev;
    address payable BLP;
    address AddressEVM;
    address AddressERM;
    address payable Treasury;
    Ermine public coin;
    ErmineVM public nft;
    ErmineSwap public swap;

    event Received(address, uint);
    event BuyMiners(address, uint);
    event newUser(uint, address);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(msg.sender == AddressEVM, "You cannot send other NFTs to Ermine Store!");
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(msg.sender == AddressEVM, "You cannot send other NFTs to Ermine Store!");
        return this.onERC1155BatchReceived.selector;
    }

    struct Miners {
        uint ips;
        uint price;
    } 

    struct Users {
        uint256 ids;
        uint status;
        uint256 totalETH;
        uint256 ethBal;
        uint256 ermBal;
        string[] _stat;
        address[] refer;
    }
    
    struct Discount {
        uint numberBuy;
        uint size;
    }

    struct Base { 
        address[] all_user; 
    }

    mapping(address => Users) private _users;
    mapping(uint => Miners) public _miners;
    mapping(address => address) private _refer;
    mapping(uint256 => Base) private _base;
    mapping(address => Discount) private _sale;
    mapping(address => bool) private _statista;
    mapping(address => bool) private _ysc;

    constructor(address _wDev, address _AddressEVM, address _AddressERM, uint[] memory _ips, uint[] memory _price) {
        forDEX = 0;
        walletDev = _wDev;
        _ysc[walletDev] = true;
        AddressEVM = _AddressEVM;
        nft = ErmineVM(AddressEVM);
        AddressERM = _AddressERM;
        coin = Ermine(AddressERM);
        percent[0] = 8;
        percent[1] = 3;
        percent[2] = 2;
        for (uint i = 0; i < 12; i++) {
            _miners[i].ips = _ips[i];
            _miners[i].price = _price[i];
        }
    }
    
    modifier onlyOfficial() {
        require((_users[msg.sender].status == 3)||((_users[msg.sender].refer.length > 39)&&(_users[msg.sender].ermBal > 7999e18)&&(_users[msg.sender].totalETH > 100e18)),"You do not have access rights!");
    _;                              
    } 

    modifier onlySale() {
        require(_sale[msg.sender].numberBuy > 0, "There is no discount on the purchase of miners!");
    _;                              
    } 

    modifier onlyDev() {
        require(msg.sender == walletDev, "You do not have access rights!");
    _;                              
    } 

    modifier onlyStat() {
        require(_statista[msg.sender], "You do not have access rights!");
    _;                              
    } 

    modifier onlyOperator() {
        require(_ysc[msg.sender], "You do not have access rights!");
    _;                              
    }

//New user registration
function regUser(address _toReg, uint _ips) internal {
    Base storage base = _base[0];
    base.all_user.push(_toReg);
    Users storage user = _users[_toReg];
    user.ids = base.all_user.length;
    user.status = 0;
    user.ethBal = 0;
    user.ermBal = 0;
    uint256 forReward = 100e18 * _ips; 
    if ((airdrop >= forReward)&&(forReward > 0)) {
        coin.transfer(_toReg, forReward);
        user._stat.push(string(abi.encodePacked(Strings.toString(block.timestamp), "300", Strings.toString(forReward))));
        airdrop -= forReward;
     }
     else {
        user._stat.push(string(abi.encodePacked(Strings.toString(block.timestamp), "301", Strings.toString(user.ermBal))));
     } 
    emit newUser(block.timestamp, msg.sender);
}

function buyMiners(uint[] calldata valMiner, address whoRef) external payable {
    require(valMiner.length == 12, "Invalid miner ID entered!");
    uint256 totalsum = 0;
    uint totalips = 0;
    for (uint i = 0; i < 12; i++) {
        if (nft.balanceOf(address(this), i) >= valMiner[i]) { 
        totalsum += (_miners[i].price * valMiner[i]);
        totalips += (_miners[i].ips * valMiner[i]);
        }
    }
    require(totalsum <= msg.value, "Ether value sent is not correct!");
    uint256 onePer = (totalsum / 100);
    if (Treasury != address(0)) {
	    require(payable(Treasury).send(50 * onePer));}
    else {
	    forDEX += (50 * onePer);
    }
    require(payable(BLP).send((30 * onePer)));
    swap.addLiq((30 * onePer));
    address[] memory REL = new address[](3); 
    if (!checkUser(msg.sender)) {
    regUser(msg.sender, totalips);
    }
    for (uint i = 0; i < 12; i++) {
    if (valMiner[i] > 0) {
    nft.safeTransferFrom(address(this), msg.sender, i, valMiner[i], "");
    }
    }
    _users[msg.sender]._stat.push(string(abi.encodePacked(Strings.toString(block.timestamp), "400", Strings.toString(totalsum))));
    Users storage user;
    user = _users[whoRef];
    //Direct sale
    if (_refer[msg.sender]==address(0)) {
        if ((!checkUser(whoRef))||(whoRef == msg.sender)) {
            _refer[msg.sender] = walletDev;
            user = _users[walletDev];
            user.refer.push(msg.sender); 
            whoRef = walletDev;
        }
        else {
            _refer[msg.sender] = whoRef;
            user.refer.push(msg.sender);
        }
    }
//A-program
    uint maxper = 20;
    if ((whoRef != msg.sender)&&(whoRef != walletDev)) {
    _users[whoRef].totalETH += totalsum;    
	REL[0] = _refer[msg.sender];
	REL[1] = _refer[REL[0]];
	REL[2] = _refer[REL[1]];
    for (uint i = 0; i < 3; i++) {
        uint x = 0;
	if (REL[i] != address(0)) {
        user = _users[REL[i]];
        if (user.refer.length > 1) {x += 1;} //silver status
        if ((user.refer.length > 19)&&((user.ermBal > 1999e18)||(user.status > 0))) {x += 1;}//gold and official status
        uint realper = (percent[i] + x);
        maxper -= realper;
        uint256 rewSum = (onePer * realper);
        user.ethBal += rewSum;
        user._stat.push(string(abi.encodePacked(Strings.toString(block.timestamp), Strings.toString(110 + i), Strings.toString(rewSum),"&", Strings.toString(user.ids))));
        if ((user.ids > 1)&&(coin.balanceOf(address(this)) >= 30*1e18)) {
            uint256 sumerm = (realper*3e18);
            user.ermBal += sumerm;
            user._stat.push(string(abi.encodePacked(Strings.toString(block.timestamp), Strings.toString(310 + i), Strings.toString(sumerm),"&", Strings.toString(user.ids))));
        }
            }
        }
    }
    else {
        _users[walletDev].totalETH += totalsum; 
    }
    //tax for Ermine
    user = _users[walletDev];
    user.ethBal += (onePer * maxper);
    user._stat.push(string(abi.encodePacked(Strings.toString(block.timestamp), "3103", Strings.toString(onePer * maxper))));
    emit BuyMiners(msg.sender, totalsum);
}

function buyForOfficial(uint[] calldata valMiner, address _to) external payable onlyOfficial {
    require((_refer[_to] == msg.sender), "You can sell miners at a discount only for those whom you originally invited yourself!"); 
    processBuy(msg.sender, valMiner, 20);
    _users[_to]._stat.push(string(abi.encodePacked(Strings.toString(block.timestamp), "401", "0")));
    _users[msg.sender]._stat.push(string(abi.encodePacked(Strings.toString(block.timestamp), "404", Strings.toString(msg.value))));
}

function buyForGift(uint[] calldata valMiner, address _to) external payable {
    require(checkUser(msg.sender), "Purchase with a discount or as a gift is available only for registered addresses!"); 
    if (!checkUser(_to)) {
        regUser(_to, 0);
        _refer[_to] = msg.sender;
        _users[msg.sender].refer.push(_to);
    }
    processBuy(_to, valMiner, 0);
    _users[_to]._stat.push(string(abi.encodePacked(Strings.toString(block.timestamp), "402", Strings.toString(msg.value))));
}

function saleDiscount(uint[] calldata valMiner) external payable onlySale {
    Discount storage saleUser = _sale[msg.sender];
    saleUser.numberBuy -= 1;
    processBuy(msg.sender, valMiner, saleUser.size);
    _users[msg.sender]._stat.push(string(abi.encodePacked(Strings.toString(block.timestamp), "403", Strings.toString(msg.value))));
}

function fixStat() external {
    Users storage user;
    user = _users[msg.sender];
    require(user._stat.length > 0, "This address is not registered in the referral program!");
    require(user.refer.length > 19, "Not enough referrals, invite more!");
    require(user.status < 3, "You already have the highest member status!");
    if ((user.refer.length < 40)&&((user.ermBal >= 1999e18)&&(user.status < 2))) {
        user.status = 2;
        user.ermBal -= 1999e18;
        user._stat.push(string(abi.encodePacked(Strings.toString(block.timestamp), "200", "1999000000000000000000")));
        }
    if ((user.refer.length > 39)&&(user.ermBal >= 7999e18)&&(user.totalETH > 100e18)) {
        user.status = 3;
        user.ermBal -= 7999e18;
        user._stat.push(string(abi.encodePacked(Strings.toString(block.timestamp), "201", "7999000000000000000000")));
        }
}

function depositERM(uint256 _amount, address _to) external {
    Users storage user = _users[_to];
    require(checkUser(_to), "This address is not registered!");
    require(coin.balanceOf(address(msg.sender)) >= _amount, "Your wallet does not have enough Ermine tokens to replenish your account balance!");
    coin.transferFrom(msg.sender, address(this), _amount); 
    user.ermBal += _amount;  
    if (_to==msg.sender) {
        user._stat.push(string(abi.encodePacked(Strings.toString(block.timestamp), "302", Strings.toString(_amount))));  
    }
    else {
        user._stat.push(string(abi.encodePacked(Strings.toString(block.timestamp), "303", Strings.toString(_amount))));    
    }
}

//withdraw ERM token
function withdrawERM() external {
    Users storage user = _users[msg.sender]; 
    require(user.ermBal > 0, "There are no ERM tokens on your account for withdrawal!");
    coin.transfer(msg.sender, user.ermBal);
    user._stat.push(string(abi.encodePacked(Strings.toString(block.timestamp), "202", Strings.toString(user.ermBal))));
    user.ermBal = 0;
}

//withdraw user profit 
function myProfit() external {
    Users storage user = _users[msg.sender];
    //uint256 balance = user.ethBal;
    require(user.ethBal > 0, "Your account has no funds to withdraw!");
    require(user.ethBal < address(this).balance, "It is currently not possible to withdraw funds. There is no liquidity. Please try again later.");
    require(payable(msg.sender).send(user.ethBal));
    user._stat.push(string(abi.encodePacked(Strings.toString(block.timestamp), "000", Strings.toString(user.ethBal))));
    user.ethBal = 0;
}

function processBuy(address _to, uint[] calldata valMiner, uint _sizeD) internal {
    require(valMiner.length == 12, "Invalid miner ID entered!");
    uint256 totalsum = 0;
    for (uint i = 0; i < 12; i++) {
        if (nft.balanceOf(address(this), i) >= valMiner[i]) { 
        totalsum += (_miners[i].price * valMiner[i]);
        }
    }
    uint256 onePer = (totalsum / 100);
    if (Treasury != address(0)) {
	    require(payable(Treasury).send(50 * onePer));}
    else {
	    forDEX += (50 * onePer);
    }
    require(onePer * (100 - _sizeD) <= msg.value, "Ether value sent is not correct!");
    require(payable(BLP).send((30 * onePer)));
    if (((_sizeD) > 0)&&((_sizeD) < 20)) {
        _users[_refer[_to]].ethBal += (onePer * (20 - _sizeD));
        _users[_refer[_to]]._stat.push(string(abi.encodePacked(Strings.toString(block.timestamp), "405", Strings.toString((onePer * (20 - _sizeD))))));
    }
    emit BuyMiners(msg.sender, totalsum);
    swap.addLiq((30 * onePer));
    for (uint i = 0; i < 12; i++) {
    if (valMiner[i] > 0) {
    nft.safeTransferFrom(address(this), _to, i, valMiner[i], "");
    }
    }
    _users[_refer[_to]].totalETH += totalsum;
}

function addStat(address _user, string memory _wordStat) external onlyStat {
    Users storage user = _users[_user];
    user._stat.push(_wordStat);
}

//New User Registration
function regNewUser() external {
    require(!checkUser(msg.sender), "The user is already registered!");
    regUser(msg.sender, 0);
    if (_refer[msg.sender] == address(0)) {
        _refer[msg.sender] = walletDev;
        _users[walletDev].refer.push(msg.sender);
        }
}

//Withdrawing ETH to the Treasury
function toTreasury() external payable onlyOperator {
    require(Treasury != address(0), "The treasury has not yet been set!");
    require(forDEX > 0, "There are no funds to transfer to the treasury!");
    require(payable(Treasury).send(forDEX));
    forDEX = 0;
}

//Withdrawing profit Ermine
function toErmine(address _to) external payable onlyDev {
    swap.takeTax(_to);
}

//Section Set
//Set BLP
function setBLP(address payable newBLP) external onlyOwner {
    BLP = newBLP;
    swap = ErmineSwap(BLP);
    if (!checkUser(walletDev)) {
    regUser(walletDev, 0);
    _users[walletDev].status = 3;
    }
}

//Launch swap and ReturnVM
function setLauch() external onlyDev {
    swap.setLauch();
}

//Set Treasury
function setTreasury(address payable newTreasury) external onlyDev {
    Treasury = newTreasury;
}

//Set Ermine's new income address
function setNewWalletDev(address _newWal) external onlyDev {
    walletDev = _newWal;
    if (!checkUser(walletDev)) {
    regUser(walletDev, 0);
    _users[walletDev].status = 3;
    }
}

//Set the address for recording statistics on/off
function setStatWallet(address _newWal) external onlyDev {
    _statista[_newWal] = !_statista[_newWal];
}

//Set the address for ysc/operator on/off
function setOperatorYSC(address _Wal) external onlyOperator {
    _ysc[_Wal] = !_ysc[_Wal];
}

//Set new store
function setStore(address payable _newStore) external onlyDev {
    swap.setAddressStore(_newStore);
}

//Set discount wallet
function setDiscountWallet(address _to, uint _val, uint _size) external onlyOfficial {
    require(((_val > 0)&&(_val < 4)&&(_size > 0)&&(_size < 20)), "Incorrect parameters set!");
    require(((_refer[_to]==msg.sender)||(msg.sender==walletDev)), "You can add addresses only for clients you invited!");
    _sale[_to].numberBuy = _val;
    _sale[_to].size = _size;
    if ((msg.sender==walletDev)&&(!checkUser(_to))) {
        _refer[_to] = walletDev;
        regUser(_to, 0);
        _users[walletDev].refer.push(_to);
    } 
    }

//View section
function getIPS(uint _ips) public view returns (uint) {
    return (_miners[_ips].ips);
}

function getPriceVM(uint idVM) public view returns (uint256) {
    return (_miners[idVM].price);
}

function getPriceAllVM() public view returns (uint256[] memory) {
    uint256[] memory bufMas = new uint256[](12);
    for (uint i = 0; i < 12; i++) {
            bufMas[i] = _miners[i].price;
        }
    return (bufMas);
}

//User card
function checkUser(address _wallet) public view returns (bool) {
    if (_users[_wallet]._stat.length < 1) {
        return false;
    }
    else { 
        return true;
    }
    }

//User card
function getUser(address _wallet) public view returns (Users memory) {
        Users storage user = _users[_wallet];
        return user;
    }

//Check sale
function getDiscount(address _wallet) public view returns (Discount memory) {
        Discount storage sale = _sale[_wallet];
        return sale;
    }

//All users
function getAllUsers() public view returns (Base memory) {
        Base storage base = _base[0];
        return base;
    }   

//View ref.
function getRef(address _who) public view returns (address[] memory) {
        return _users[_who].refer; 
    }

//Check operator
function checkOperator(address _whoWal) public view returns (bool) {
        bool _verifyYCS = _ysc[_whoWal];
        return _verifyYCS;
    }  

}