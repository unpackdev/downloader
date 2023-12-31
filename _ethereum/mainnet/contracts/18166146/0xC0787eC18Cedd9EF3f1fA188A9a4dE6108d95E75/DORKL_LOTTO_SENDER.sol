// SPDX-License-Identifier: MIT




pragma solidity 0.8.20;


interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}




abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}




contract DORKL_LOTTO_SENDER is Ownable {

    IERC20 Dorkl;
    address constant DORKL_ADDRESS = 0x94Be6962be41377d5BedA8dFe1b100F3BF0eaCf3;
    address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;


    uint256 public totalBurned = 0;
    event TokensBurned(address indexed from, uint256 amount);

    constructor() {
        Dorkl = IERC20(DORKL_ADDRESS);
    }

     function PayWinners(address[] memory recipients) external onlyOwner {
        require(recipients.length > 0, "No recipient addresses provided");
        IERC20 token = IERC20(Dorkl);
        uint256 totalBalance = token.balanceOf(address(this));
        uint256 amountPerRecipient = totalBalance / recipients.length;

        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], amountPerRecipient), "Transfer to recipient failed");
        }
    }

    function transferAndBurn() external onlyOwner {
        uint256 walletBalance = Dorkl.balanceOf(msg.sender);
        
        require(Dorkl.transferFrom(msg.sender, address(this), walletBalance), "Transfer failed");
        uint256 burnAmount = walletBalance / 2;
        totalBurned += burnAmount;
        require(Dorkl.transfer(DEAD_ADDRESS, burnAmount), "Burn transfer failed");

        emit TokensBurned(msg.sender, burnAmount);
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(msg.sender).transfer(balance);
    }
}