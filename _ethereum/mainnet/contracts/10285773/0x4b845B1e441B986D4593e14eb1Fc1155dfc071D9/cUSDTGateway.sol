pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Erc20 {
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public;
}

contract CErc20 is Erc20 {
    function mint(uint256 mintAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
}

contract Exchange {
    function trade(
        address src,
        uint256 srcAmount,
        address dest,
        address destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address walletId
    ) public payable returns (uint256);
}

contract cUSDTGateway is Ownable {
    Exchange constant kyberEx = Exchange(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);

    Erc20 constant USDT = Erc20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    CErc20 constant cUSDT = CErc20(0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9);

    address constant etherAddr = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    constructor () public {
        USDT.approve(address(cUSDT), uint256(-1));
    }

    function() external payable {
        etherTocUSDT(msg.sender);
    }

    function etherTocUSDT(address to)
        public
        payable
        returns (uint256 outAmount)
    {
        uint256 in_eth = (msg.value * 994) / 1000;
        uint256 amount = kyberEx.trade.value(in_eth)(
            etherAddr,
            in_eth,
            address(USDT),
            address(this),
            10**28,
            1,
            owner
        );
        cUSDT.mint(amount);
        outAmount = cUSDT.balanceOf(address(this));
        cUSDT.transfer(to, outAmount);
    }

    function makeprofit() public {
        owner.transfer(address(this).balance);
    }
}