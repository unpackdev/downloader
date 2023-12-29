// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenPreSale is Ownable {
    IERC20 public token;
    uint256 public tokenPrice;
    uint256 public totalSold;
    uint256 public minBuyLimit = 0.001 ether;
    uint256 public maxBuyLimit = 0.1 ether;
    uint256 public tokensForSale = 5000000 ether;
    bool public saleActive = true;

    event Sell(address indexed sender, uint256 totalValue);
    event Withdraw(address indexed owner, uint256 amount);

    constructor(address _tokenAddress, uint256 _tokenPrice) {
        tokenPrice = _tokenPrice;
        token = IERC20(_tokenAddress);
    }

    receive() external payable {
        buyTokens();
    }

    function buyTokens() public payable {
        require(saleActive, "Token sale is not active");
        address buyer = msg.sender;
        uint256 bnbAmount = msg.value;

        // Check minimum and maximum buy limits
        require(bnbAmount >= minBuyLimit && bnbAmount <= maxBuyLimit, "Invalid purchase amount");

        // Calculate the token amount
        uint256 tokenAmount = bnbAmount * tokenPrice;

        // Check if the contract has enough tokens for sale
        require(token.balanceOf(address(this)) >= tokenAmount, "Insufficient tokens in the smart contract");

        // Check if the remaining tokens for sale are greater than the token amount
        require(tokensForSale >= tokenAmount, "Not enough tokens for sale");

        // Transfer tokens to the buyer
        require(token.transfer(buyer, tokenAmount), "Token transfer failed");

        // Update total sold and remaining tokens for sale
        totalSold += tokenAmount;
        tokensForSale -= tokenAmount;

        // Emit sell event for UI
        emit Sell(buyer, tokenAmount);
    }

    function withdraw() public onlyOwner {
        // Transfer all the Ethereum to the owner
        payable(msg.sender).transfer(address(this).balance);

        // Emit withdraw event for UI
        emit Withdraw(msg.sender, address(this).balance);
    }

    function setSaleStatus(bool _status) external onlyOwner {
        saleActive = _status;
    }
        // end sale
    function endsale() public onlyOwner {
        // transfer all the remaining tokens to admin
        token.transfer(msg.sender, token.balanceOf(address(this)));
        // End the token sale
        saleActive = false;
    
    }

}