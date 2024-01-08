// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25;
import "./Ownable.sol";
abstract contract IERC20{
    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
    function balanceOf(address account) external view  virtual returns (uint256);
}

contract NMTSwap is Ownable{
    struct SwapInfo{
        string toNativeAddress;
        address fromAddress;
        uint256  amount;
    }
    event Swap(address from, string toNativeAddress,uint256 amount);

    SwapInfo[] public swaplist;
    address  public NMTContract= address(0xd81b71cBb89B2800CDb000AA277Dc1491dc923C3);


    function erc20toNative(string memory nativeAddress,uint256 amount) public returns (bool){

        require( bytes(nativeAddress).length >0 ,"native address not null");
        require( amount >= 10**18 ,"amount >= 1 NMT");

        IERC20 NMT = IERC20(NMTContract);
        NMT.transferFrom(msg.sender,address(this),amount);

        SwapInfo memory info= SwapInfo({ amount :amount,fromAddress :msg.sender,toNativeAddress : nativeAddress});
        swaplist.push(info);
        emit Swap(msg.sender,nativeAddress,amount);
        return true;
    }
    function burn(uint256 amount) public onlyOwner returns(bool) {
        IERC20 NMT = IERC20(NMTContract);
        NMT.transfer(address(0x000000000000000000000000000000000000dEaD),amount);
        return true;
    }
    function claim()public onlyOwner returns(bool) {
        IERC20 NMT = IERC20(NMTContract);
        NMT.transfer(owner(),NMT.balanceOf(address(this)));
        return true;
    }
    function getSwapRecord(uint256 index) public view returns(SwapInfo memory){
        require(swaplist.length > index,"error index");
        return swaplist[index];
    }
}
