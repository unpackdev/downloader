// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = 0x30082Eddca0B710FaC8DA5dA713910FE5c25f1Bd; //_msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    //   function renounceOwnership() public onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    //   }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract dogerush {
    struct userStruct {
        bool isExist;
        uint256 investment;
        uint256 ClaimTime;
        uint256 lockedAmount;
    }
    mapping(address => userStruct) public user;
}

abstract contract Token {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual;

    function transfer(address recipient, uint256 amount) external virtual;

    function balanceOf(address account) external view virtual returns (uint256);
}

pragma solidity 0.6.0;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */

pragma experimental ABIEncoderV2;

library SafeMath {
    function percent(
        uint256 value,
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) internal pure returns (uint256 quotient) {
        uint256 _numerator = numerator * 10**(precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return ((value * _quotient) / 1000000000000000000);
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract PriceContract {
    AggregatorV3Interface internal priceFeed;
    address private priceAddress = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // ETH/USD Mainnet

    //address private priceAddress = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e; // ETH/USD Goerli Testnet
    //https://docs.chain.link/docs/bnb-chain-addresses/

    constructor() public {
        priceFeed = AggregatorV3Interface(priceAddress);
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , uint256 timeStamp, ) = priceFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        return (uint256)(price);
    }
}

contract ClaimDR is Ownable, PriceContract {
    uint256 public w_fee = 200e18;
    bool public claimActive = false;
    dogerush Dogerush;
    Token token = Token(0x2d6e9d6b362354a5Ca7b03581Aa2aAc81bb530Db); // Token;

    mapping(address => uint256) public claimedAmount;
    mapping(address => bool) public w_fee_paid;

    constructor() public {
        Dogerush = dogerush(0xAcf9adA6BC9e74d544556647355cB6570Ac1BC8A);
    }

    function getUserLockedTokensFromContract(address _user)
        public
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256
        )
    {
        return Dogerush.user(_user);
    }

    function calculateUsd(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getLatestPrice();
        uint256 incomingEthToUsd = SafeMath.mul(ethAmount, ethPrice);
        uint256 fixIncomingEthToUsd = SafeMath.div(incomingEthToUsd, 1e8);
        return fixIncomingEthToUsd;
    }

    function claimTokens() public payable {
        (, , , uint256 lockedAmount) = getUserLockedTokensFromContract(
            msg.sender
        );
        require(claimActive == true, "Claim is turned off at the moment.");
        require(
            getTokenBalance() >= lockedAmount,
            "Contract balance is insufficient"
        );
        require(lockedAmount > 0, "No Tokens to Claim");
        require(
            lockedAmount > claimedAmount[msg.sender],
            "You have already claimed your tokens."
        );

        if (!w_fee_paid[msg.sender]) {
            uint256 feeReceived = calculateUsd(msg.value);
            require(
                feeReceived >= w_fee,
                "Users have to pay a withdrawal fee."
            );
            address payable ICOadmin = address(uint160(owner()));
            ICOadmin.transfer(msg.value);
            w_fee_paid[msg.sender] = true;
        }

        claimedAmount[msg.sender] = lockedAmount;
        token.transfer(msg.sender, lockedAmount);
    }

    function getTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function toggleSaleActive() external onlyOwner {
        claimActive = !claimActive;
    }

    function changeWithdrawFee(uint256 _newfee) external onlyOwner {
        w_fee = _newfee;
    }

    function withdrawEther() external payable onlyOwner {
        address payable ICOadmin = address(uint160(owner()));
        ICOadmin.transfer(address(this).balance);
    }

    function withdrawRemainingTokensAfterICO() public {
        require(msg.sender == owner(), "Only owner can update contract!");
        require(
            token.balanceOf(address(this)) >= 0,
            "Tokens Not Available in contract, contact Admin!"
        );
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}