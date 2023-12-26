// SPDX-License-Identifier: MIT
// EVM BLP SWAP & ReturnVM
// https://ermine.pro


pragma solidity ^0.8.23;

import "./Ownable.sol";
import "./Strings.sol";
import "./Ermine.sol";
import "./ErmineVM.sol";
import "./ErmineStoreIn.sol";

contract ErmineSwap is Ownable {
    uint256 public totalETH = 0;
    uint256 public totalERM = 0;
    bool start;
    address AddressEVM;
    address AddressERM;
    address payable AddressStore;
    Ermine public coin;
    ErmineVM public nft;
    ErmineStoreIn public store;

    event Received(address, uint);
    event swapETH(address, uint256, uint256);
    event swapERM(address, uint256, uint256);
    event returnvm(address, uint256, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    struct User {
        uint256 lastTime;
    }

    struct Stat {
        uint256[] _dat;
        uint256[] _price;
    }

    mapping(address => User) private _user;
    mapping(uint256 => Stat) private _stat;

    constructor(address _AddressEVM, address _AddressERM, address payable _AddressStore){
        AddressEVM = _AddressEVM;
        nft = ErmineVM(AddressEVM);
        AddressERM = _AddressERM;
        coin = Ermine(AddressERM);
        AddressStore = _AddressStore;
        store = ErmineStoreIn(AddressStore);
    }

    //For onlyOperator
    modifier onlyErmi() {
    require(msg.sender == AddressStore);
    _;                              
    } 

    function swapETHtoERM() external payable {
    require(start, "Exchange not started! Read Ermine announcements!"); 
    require(block.timestamp >= _user[msg.sender].lastTime + 300, "AntiBot: You can not exchange more than once every 5 minutes!");
    require(msg.value > 0, "Ether value sent is not correct!"); 
    uint256 _perETH = (msg.value / 100);
    uint256 _sumERM = PurchaseAmount(_perETH * 99);
    require(totalERM > _sumERM, "Not enough liquidity in the pool!");
    _user[msg.sender].lastTime = block.timestamp;
    coin.transfer(msg.sender, _sumERM);
    totalERM -= _sumERM;
    totalETH += (_perETH * 99);
    if (store.checkUser(msg.sender)) {
        string memory _toStat = string(abi.encodePacked(Strings.toString(block.timestamp), "500", Strings.toString(msg.value), "&", Strings.toString(_sumERM)));
        store.addStat(msg.sender, _toStat);
    }
    _stat[0]._dat.push(block.timestamp); 
    _stat[0]._price.push(getPrice()); 
    emit swapETH(msg.sender, msg.value, _sumERM);
    }

    function swapERMtoETH(uint256 amount) external {
    require(start, "Exchange not started! Read Ermine announcements!");
    require(block.timestamp >= _user[msg.sender].lastTime + 300, "AntiBot: You can not exchange more than once every 5 minutes!");
    require(totalETH > 0, "Not enough liquidity in the pool!");
    require(coin.balanceOf(msg.sender) >= amount, "There are not enough tokens to exchange on your balance!");
    _user[msg.sender].lastTime = block.timestamp;
    uint256 _per = SaleAmount(amount) / 100;
    coin.transferFrom(msg.sender, address(this), amount);
    require(payable(msg.sender).send(_per * 99));
    totalERM += amount;
    totalETH -= (_per * 100);
    if (store.checkUser(msg.sender)) {
        string memory _toStat = string(abi.encodePacked(Strings.toString(block.timestamp), "501", Strings.toString(_per * 99), "&", Strings.toString(amount)));
        store.addStat(msg.sender, _toStat);
    }
    _stat[0]._dat.push(block.timestamp); 
    _stat[0]._price.push(getPrice()); 
    emit swapERM(msg.sender, amount, _per * 99);
    }

    function setPool(uint256 amount) external payable onlyOwner {
    require((totalERM == 0)||(totalETH == 0), "The pool already exists!");
    require(msg.value > 0, "Ether value sent is not correct!"); 
    coin.transferFrom(msg.sender, address(this), amount);
    totalERM += amount;
    totalETH += msg.value;

    }

    function setAddressStore(address payable _AddressStore) external onlyErmi {
        AddressStore = _AddressStore;
    }

    function setLauch() external onlyErmi {
        start = !start;
    }

    function addLiq(uint256 value) external onlyErmi {
        totalERM += ((value  * 1e18) / getPrice());
        totalETH += value;
    }

    function getPrice() public view returns (uint256) {
    return ((totalETH * 1e18) / totalERM);
    }

    function takeTax(address _to) external payable onlyErmi { 
    require(getTax() > 0, "There are no funds to transfer to the Ermine!");
    require(payable(_to).send(getTax()));
    }

    function PurchaseAmount(uint256 amount) public view returns (uint256) {
        return ((amount * totalERM)/(totalETH + amount));
    }  

    function SaleAmount(uint256 amount) public view returns (uint256) {
        return ((totalETH  * amount)/(totalERM + amount));
    }  

    function ReturnVM(uint[] memory valMiner) external {
        require(start, "Exchange not started! Read Ermine announcements!");
        require(valMiner.length == 12, "Invalid miner ID entered!");
        uint256 totalsum = 0;
        for (uint i = 0; i < 12; i++) {
        if ((valMiner[i]>0)&&(nft.balanceOf(msg.sender, i) >= valMiner[i])) { 
                nft.safeTransferFrom(msg.sender, AddressStore, i, valMiner[i], "");
                totalsum += (store.getPriceVM(i) * valMiner[i]);
            }
        }
        require(totalsum > 0, "You do not have selected miners to change back!");
        uint256 hal = (totalsum / 100) * 15;
        uint256 amount = ((hal * 1e18) / getPrice()); 
        coin.transfer(msg.sender, amount);
        require(payable(msg.sender).send(hal));
        totalETH -= hal;
        totalERM -= amount;
        emit returnvm(msg.sender, hal, amount);
    }

    function getViewMoney(uint[] memory valMiner) public view returns (uint256, uint256) {
        uint256 sumETH = 0;
        uint256 sumERM = 0;
        uint256 bufSum = 0;
        uint256[] memory bufMas = new uint256[](12);
        bufMas = store.getPriceAllVM();
        for (uint i = 0; i < 12; i++) {
            bufSum = ((valMiner[i] * bufMas[i]) / 100) * 15;
            sumETH += bufSum;
            sumERM += bufSum * 1e18 / getPrice();
        }
        return (sumETH, sumERM);
    }

    function getTax() public view returns(uint256) {
        if (address(this).balance > totalETH) {
            return(address(this).balance - totalETH);
        }
        else {
            return(0);  
        }    
    }
}