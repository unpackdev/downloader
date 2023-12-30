pragma solidity ^0.5.14;

contract Interface_Father {
    function Repurchase() external payable;
    function PayAnotherAccount(uint _sponsorID, address _user) external payable;
}

contract Fund_Interface {
    function Game(uint _turns) external payable;
}

contract Father {

    address public addrPayment;
    address public addContract;
    address public fund;
    address owner;
    uint amount = 0.3 ether;
    uint amount_game = 0.05 ether;

    function() external payable {}

    modifier onlyOwner{
        require(owner == msg.sender, "Only the owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setAddr(address _addr) external onlyOwner {
        addrPayment = _addr;
    }

    function setAddrContract(address payable _addr) external onlyOwner {
        addContract = _addr;
    }

    function setAddrFund(address payable _addr) external onlyOwner {
        fund = _addr;
    }

    function withdrawEth() public {
        address(uint160(addrPayment)).transfer(address(this).balance);
    }

    function Repurchase() external onlyOwner {
        Interface_Father(addContract).Repurchase.value(amount)();
    }

    function PayAnotherAccount(uint _sponsorID, address _user) external onlyOwner {
        Interface_Father(addContract).PayAnotherAccount.value(amount)(_sponsorID, _user);
    }

    function Game(uint _turns) external onlyOwner {
        uint _amount = _turns * amount_game;
        Fund_Interface(fund).Game.value(_amount)(_turns);
    }

}