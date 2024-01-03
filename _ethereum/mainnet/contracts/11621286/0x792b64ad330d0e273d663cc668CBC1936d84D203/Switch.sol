pragma solidity ^0.5.0;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying an instance of this contract,which 
    // should be used via inheritance.
    constructor() internal {}
    
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    
    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);
    
    // Initialized the contract setting the deployer as the initial owner
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0),msgSender);
    }
    
    // Returns the address of the current owner.
    function owner() public view returns (address) {
        return _owner;
    }
    
    modifier onlyOwner(){
        require(isOwner(),"Ownable: caller is not the owner");
        _;
    }
    
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    
    // Leaves the contract without owner.It will not be possible to call "onlyOwner" function anymore.
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner,address(0));
        _owner = address(0);
    }
    
    // Transfers ownership of the contract to a new account
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0),"Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner,newOwner);
        _owner = newOwner;
    }
}

contract IERC20 {
    function name() public view returns (string memory) { }

    function symbol() public view returns (string memory) { }

    function decimals() public view returns (uint8) { }

    function totalSupply() public view returns (uint256) { }

    function balanceOf(address account) public view returns (uint256) { }

    function transfer(address recipient, uint256 amount) public returns (bool) { }

    function allowance(address owner, address spender) public view returns (uint256) { }

    function approve(address spender, uint256 amount) public  returns (bool) { }

    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) { }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) { }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) { }


}


contract Switch is Ownable {
    uint currentChainIndex;
    IERC20 public AntasyContract;
    address public switchContract;
    address payable public beneficiary;
    
    event Init(address initialAddress,uint chainIndex);
    event ChangeSwitchContract(address preAddress,address currentAddress);
    event ChangeBeneficiary(address preAddress,address currentAddress);
    event SwitchRecord(address fromAddress,uint targetChain,uint256 amount,address targetAddress);
    
    // chainIndex == 1 : eth  chainIndex == 2 : heco chainIndex == 3 : bsc
    constructor(uint chainIndex,IERC20 targetContract) public {
        currentChainIndex = chainIndex;
        AntasyContract = targetContract;
        emit Init(_msgSender(),currentChainIndex);
    }
    
   function changeSwitchContractAddress(address contractAddress) onlyOwner public {
        emit ChangeSwitchContract(switchContract,contractAddress);
        switchContract = contractAddress;
    }
    
    function changeBeneficiaryAddress(address payable beneficiayAddress) onlyOwner public {
         emit ChangeBeneficiary(beneficiary,beneficiayAddress);
         beneficiary = beneficiayAddress;
    }
    
    function withdraw(address payable target) onlyOwner public returns(bool){
        uint256 balance = AntasyContract.balanceOf(address(this));
        bool result = AntasyContract.transfer(target,balance);
        return result;
    }
    
    
    function switchTo(uint targetChain,uint256 switchAmount,address targetAddress) public returns(bool){
        uint256 allowance = AntasyContract.allowance(_msgSender(),address(this));
        require(allowance >= switchAmount,"Switch:allowance is not enough");
        
        bool result =  AntasyContract.transferFrom(_msgSender(),address(this),switchAmount);
        if(result){
            emit SwitchRecord(_msgSender(),targetChain,switchAmount,targetAddress);
        }
        
        return result;
    }
    
     function destroy(address payable addr) public onlyOwner {
        selfdestruct(addr);
    }
    
    
    
}