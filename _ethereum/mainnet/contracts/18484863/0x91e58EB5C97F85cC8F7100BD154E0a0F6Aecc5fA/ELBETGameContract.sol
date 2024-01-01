/******************************************************************

            ███████╗  ██╗       ██████╗   ███████╗  ████████╗
            ██╔════╝  ██║       ██╔══██╗  ██╔════╝  ╚══██╔══╝
            █████╗    ██║       ██████╔╝  █████╗       ██║   
            ██╔══╝    ██║       ██╔══██╗  ██╔══╝       ██║   
            ███████╗  ███████╗  ██████╔╝  ███████╗     ██║   
            ╚══════╝  ╚══════╝  ╚═════╝   ╚══════╝     ╚═╝   

            This is a game contract that acts as an escrow to keep players balances in the game. 
            Website - https://ELBETCoin.com
            DApp - https://app.ELBETCoin.com
            Telegram - https://t.me/ELBETCoin
            X -  https://x.com/ELBETCoin           

******************************************************************/


/**
 *Submitted for verification at Etherscan.io on 2023-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() private view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ELBETGameContract is Context, IERC20, Ownable {
    address public MarketingAddress;
    address public BurnAddress;
    address public TokenAddress;

    uint256 _tax;

    mapping(address => uint256) private _balance;

    constructor() {
        MarketingAddress = (0x000000000000000000000000000000000000dEaD); //Marketing wallet
        BurnAddress = 0x000000000000000000000000000000000000dEaD;
        TokenAddress = 0x000000000000000000000000000000000000dEaD; //Token contract 
    }


    function SetAddress(address newAddress) external onlyOwner() {
        TokenAddress = newAddress; //both marketing and token address are same
        MarketingAddress = newAddress; //both marketing and token address are same
    }


    function KarmicBurn(uint256 Burnamount) external onlyOwner() {
        IERC20(TokenAddress).transfer(BurnAddress, Burnamount * 10**18);
    }

    function WithdrawFunds(address WithdrawltoAddress , uint256 WithdrawlAmount , uint256 TaxVar) external onlyOwner() {
        if (TaxVar == 1) {
            _tax = 5;
        } else if (TaxVar == 2) {
            _tax = 2;
        } else {
            _tax = 0;
        }
        uint256 tokenstowithdraw;
        tokenstowithdraw = WithdrawlAmount * 10**18;
        address withdrawlAddress;
        withdrawlAddress = WithdrawltoAddress;


        if (_tax != 0) {
            //Tax transfer
            uint256 taxTokens = (tokenstowithdraw * _tax) / 100;
            uint256 transferWithdrawlAmount = tokenstowithdraw - taxTokens;
            IERC20(TokenAddress).transfer(MarketingAddress, taxTokens);
            IERC20(TokenAddress).transfer(withdrawlAddress, transferWithdrawlAmount);
        } else {
        IERC20(TokenAddress).transfer(withdrawlAddress, tokenstowithdraw);
        }
    }

        //Use this in case ETH are sent to the contract by mistake
    function rescueStuckETH(uint256 weiAmount) external onlyOwner() {
        require(address(this).balance >= weiAmount, "insufficient ETH balance");
        payable(msg.sender).transfer(weiAmount);
    }
    
    // Function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    function rescueOtherStuckERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner() {
        require(_tokenAddr != address(this));
        IERC20(_tokenAddr).transfer(_to, _amount);
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 1e9, "Min transfer amt");

            _balance[from] -= amount;
            _balance[to] += amount;

            emit Transfer(from, to, amount);
        
    }

}