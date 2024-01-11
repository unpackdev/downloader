// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity 0.7.4;

import "./WrappedERC20.sol";
import "./IWETH.sol";
import "./SafeMath.sol";
import "./IFloorCalculator.sol";


interface IERC31337BNB is IWrappedERC20
{
    function floorCalculator() external view returns (IFloorCalculator);
    function sweepers(address _sweeper) external view returns (bool);
    
    function setFloorCalculator(IFloorCalculator _floorCalculator) external;
    function setSweeper(address _sweeper, bool _allow) external;
    function sweepFloor(address _to) external returns (uint256 amountSwept);
}

abstract contract ERC31337 is WrappedERC20, IERC31337BNB
{
    using SafeERC20 for IERC20;

    IFloorCalculator public override floorCalculator;
    
    mapping (address => bool) public override sweepers;

    constructor(IERC20 _wrappedToken, string memory _name, string memory _symbol)
        WrappedERC20(_wrappedToken, _name, _symbol)
    {}

    function setFloorCalculator(IFloorCalculator _floorCalculator) public override ownerOnly()
    {
        floorCalculator = _floorCalculator;
    }

    function setSweeper(address sweeper, bool allow) public override ownerOnly()
    {
        sweepers[sweeper] = allow;
    }

    function sweepFloor(address to) public override returns (uint256 amountSwept)
    {
        require (to != address(0));
        require (sweepers[msg.sender], "Sweepers only");
        amountSwept = floorCalculator.calculateSubFloorPETH(wrappedToken, this);

        if (amountSwept > 0) {
            wrappedToken.safeTransfer(to, amountSwept);
        }
    }
}


contract pETH is ERC31337, IWETH
{
    using SafeMath for uint256;
    uint256 public FEE=0; // use denomination = 1000 => 1%
    address public FEE_ADDRESS;
    mapping(address=>bool) IGNORED_ADDRESSES;
    event FeeSet(address feeAddress, uint256 fee);

    constructor (address wethAddress)
        ERC31337(IWETH(wethAddress), "pETH", "pETH")
    {
        FEE_ADDRESS = 0x16352774BF9287E0324E362897c1380ABC8B2b35;
    }

    receive() external payable
    {
        if (msg.sender != address(wrappedToken)) {
            deposit();
        }
    }

    function setFee(address feeAddress, uint256 _fee) external ownerOnly{
        FEE_ADDRESS = feeAddress;
        FEE=_fee;
        emit FeeSet(FEE_ADDRESS,FEE);
    }

    function setIgnoredAddresses(address _ignoredAddress, bool ignore)external ownerOnly{
        IGNORED_ADDRESSES[_ignoredAddress]=ignore;
    }
    
    function setIgnoredAddressBulk(address[] memory _ignoredAddressBulk, bool ignore)external ownerOnly{
        
        for(uint i=0;i<_ignoredAddressBulk.length;i++){
            address _ignoredAddress = _ignoredAddressBulk[i];
            IGNORED_ADDRESSES[_ignoredAddress] = ignore;
        }
    }

    function isIgnored(address _ignoredAddress) public view returns (bool) {
        return IGNORED_ADDRESSES[_ignoredAddress];
    }
   
   // 100 axbnb => 100 bnb is deposited to wbnb contract by this AXBNB contract => 100 AXBNB
    function deposit() public payable override 
    {
        uint256 amount = msg.value;
        if(IGNORED_ADDRESSES[msg.sender]){

            IWETH(address(wrappedToken)).deposit{ value: amount }();
            _mint(msg.sender, amount);
            emit Deposit(msg.sender, amount); 
        }
        else{
            uint256 feeAmount = amount.mul(FEE).div(100000);
            IWETH(address(wrappedToken)).deposit{ value: amount }();

            uint256 amountAfterFee = amount.sub(feeAmount);
            _mint(msg.sender, amountAfterFee);
            emit Deposit(msg.sender, amountAfterFee); 
            if(feeAmount>0){
                _mint(FEE_ADDRESS, feeAmount);
                emit Deposit(FEE_ADDRESS, feeAmount); 
            }
        }
    }

    function withdraw(uint256 _amount) public override
    {
        if(IGNORED_ADDRESSES[msg.sender]){
            _burn(msg.sender, _amount);

            IWETH(address(wrappedToken)).withdraw(_amount);
            
            msg.sender.transfer(_amount);
            emit Withdrawal(msg.sender, _amount);
        }
        else{
            uint256 feeAmount = _amount.mul(FEE).div(100000);
            if(feeAmount>0){
                _balanceOf[FEE_ADDRESS] = _balanceOf[FEE_ADDRESS].add(feeAmount);
                _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(feeAmount);
                emit Transfer(msg.sender, FEE_ADDRESS, feeAmount);
            }
            uint256 amountAfterFee = _amount.sub(feeAmount);
            _burn(msg.sender, amountAfterFee);
            IWETH(address(wrappedToken)).withdraw(amountAfterFee);
            (bool success,) = msg.sender.call{ value: amountAfterFee }("");
            require (success, "Transfer failed");

            emit Withdrawal(msg.sender, amountAfterFee);

        }
    }

    

    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
        require(sender != address(0), "pETH: transfer from the zero address");
        require(recipient != address(0), "pETH: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        // cut no FEE
        if(IGNORED_ADDRESSES[recipient]){
            _balanceOf[sender] = _balanceOf[sender].sub(amount, "pETH: transfer amount exceeds balance");
            _balanceOf[recipient] = _balanceOf[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
        else{

            // apply fee if there
            _balanceOf[sender] = _balanceOf[sender].sub(amount, "pETH: transfer amount exceeds balance");

            uint256 pETHFee = amount.mul(FEE).div(100000); 
            uint256 remAmount = amount.sub(pETHFee);

            if(pETHFee>0){
                _balanceOf[FEE_ADDRESS] = _balanceOf[FEE_ADDRESS].add(pETHFee);
                emit Transfer(sender, FEE_ADDRESS, pETHFee);
            }
                
            _balanceOf[recipient] = _balanceOf[recipient].add(remAmount);

            emit Transfer(sender, recipient, remAmount);            

        }

        
    }
}