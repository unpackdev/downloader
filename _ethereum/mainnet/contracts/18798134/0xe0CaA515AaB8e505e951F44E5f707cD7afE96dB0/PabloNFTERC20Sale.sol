// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
    
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;//
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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



contract PabloNFTERC20Sale is Ownable {
    
    address public token;

    constructor(address _token, uint256 _tokenPrice) {
        token = _token;
        tokenPrice = _tokenPrice;
    }
    uint256 public tokenPrice;

    function buyTokens() public payable {
        uint256 amountToBuy = msg.value / tokenPrice;
        require(amountToBuy > 0, "You need to send some ether"); 
        require(amountToBuy <= IERC20(token).balanceOf(owner()), "Not enough tokens available");

        uint256 cost = amountToBuy * tokenPrice;
        uint256 excess = msg.value - cost;

        payable(owner()).transfer(cost);
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }

        IERC20(token).transferFrom(owner(), msg.sender, amountToBuy);
    }

    function setTokenPrice(uint256 newPrice) public onlyOwner {
        tokenPrice = newPrice;
    }
}