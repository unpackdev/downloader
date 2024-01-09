// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
    
    function percentageOf(uint a, uint b) internal pure returns (uint256) {
        require(b > 0);
        return a * b / 100;
    }
}


/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <remco@2π.com>, Eenae <alexey@mixbytes.io>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
abstract contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

contract RoyaltyDistributor is Context, ReentrancyGuard {
    using SafeMath for uint256;
    
    uint[4] private sharePercentage = [35,59,3,3];
    address[4] private owners;
    address private wETH;

    mapping(address => uint) private royalties;
    
    event Received(address _from, uint _amount);
    event Royalty(address _recipient, uint _amount);
    
    // Owner 1, Nadmid Sergelen, Artist (35%)
    // 0x5eCeb1bcc86181dbDD0e340568cc9139574563fa
    // Owner 2, NovaTerra LLC, General Contractor (59%), ERC721 Owner
    // 0xf9ee21aF7d4664BD57ba9a69203108A914793CC4
    // Owner 3: Cultural Heritage Fund:
    // 0xa3089Ed64FbFaaF75fD50E2F6CfE588624a4c7B0
    // Owner 4: Mongol NFT
    // 0x25526B4db1c52Ec849d143Fee6616ACDc26368BC
    
    constructor () {

        wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        owners[0] = 0x5eCeb1bcc86181dbDD0e340568cc9139574563fa;
        owners[1] = 0xf9ee21aF7d4664BD57ba9a69203108A914793CC4;
        owners[2] = 0xa3089Ed64FbFaaF75fD50E2F6CfE588624a4c7B0;
        owners[3] = 0x25526B4db1c52Ec849d143Fee6616ACDc26368BC;
    }
    
    modifier checkBalance() {
        require(hasWethBalance() || hasEthBalance(), "Not enough balance");
        _;
    }
    
    function hasWethBalance() private view returns(bool) {
        uint balance = wEthBalance();
        uint amount1 = balance.percentageOf(sharePercentage[0]);
        uint amount2 = balance.percentageOf(sharePercentage[1]);
        uint amount3 = balance.percentageOf(sharePercentage[2]);
        uint amount4 = balance.percentageOf(sharePercentage[3]);
        return amount1 > 0 && amount2 > 0 && amount3 > 0 && amount4 > 0;
    }
    
    function hasEthBalance() private view returns(bool) {
        uint balance = ethBalance();
        uint amount1 = balance.percentageOf(sharePercentage[0]);
        uint amount2 = balance.percentageOf(sharePercentage[1]);
        uint amount3 = balance.percentageOf(sharePercentage[2]);
        uint amount4 = balance.percentageOf(sharePercentage[3]);
        return amount1 > 0 && amount2 > 0 && amount3 > 0 && amount4 > 0;
    }
    
    function distirbute() public nonReentrant checkBalance {
        distirbuteWEth();
        distirbuteEth();
    }
    
    function distirbuteWEth() private {
        uint balance = wEthBalance();
        uint amount1 = balance.percentageOf(sharePercentage[0]);
        uint amount2 = balance.percentageOf(sharePercentage[1]);
        uint amount3 = balance.percentageOf(sharePercentage[2]);
        uint amount4 = balance.percentageOf(sharePercentage[3]);
        
        if(amount1 > 0 && amount2 > 0 && amount3 > 0 && amount4 > 0) {
            uint totalAmount = amount1 + amount2 + amount3 + amount4;
            if(totalAmount <= balance) {
                withdrawWEth(owners[0], amount1);
                withdrawWEth(owners[1], amount2);
                withdrawWEth(owners[2], amount3);
                withdrawWEth(owners[3], amount4);
            }
        }
    }
    
    function distirbuteEth() private {
        uint balance = ethBalance();
        uint amount1 = balance.percentageOf(sharePercentage[0]);
        uint amount2 = balance.percentageOf(sharePercentage[1]);
        uint amount3 = balance.percentageOf(sharePercentage[2]);
        uint amount4 = balance.percentageOf(sharePercentage[3]);
        
        if(amount1 > 0 && amount2 > 0 && amount3 > 0 && amount4 > 0) {
            uint totalAmount = amount1 + amount2 + amount3 + amount4;
            if(totalAmount <= balance) {
                withdrawEth(owners[0], amount1);
                withdrawEth(owners[1], amount2);
                withdrawEth(owners[2], amount3);
                withdrawEth(owners[3], amount4);
            }
        }
    }
    
    function withdrawWEth(address _recipient, uint _amount) private {
        royalties[_recipient] = royalties[_recipient].add(_amount);
        IERC20(wETH).transfer(_recipient, _amount);
        emit Royalty(_recipient, _amount);
    }
    
    function withdrawEth(address _recipient, uint _amount) private {
        royalties[_recipient] = royalties[_recipient].add(_amount);
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success);
        emit Royalty(_recipient, _amount);
    }
    
    function allOwners() public view returns (address[4] memory) {
        return owners;
    }
    
    function ownerByIndex(uint _index) public view returns(address) {
        return owners[_index];
    }
    
    function ethBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function wEthBalance() public view returns(uint) {
        return IERC20(wETH).balanceOf(address(this));
    }
    
    function totalPendingRoyalties() public view returns(uint) {
        return ethBalance().add(wEthBalance());
    }
    
    function pendingRoyaltyByIndex(uint _index) private view returns (uint) {
        require(_index >= 0 && _index < owners.length);
        if(!hasWethBalance() && !hasEthBalance()) return 0;
        
        uint ethRoyalty = ethBalance().percentageOf(sharePercentage[_index]);
        uint wEthRoyalty = wEthBalance().percentageOf(sharePercentage[_index]);
        return ethRoyalty.add(wEthRoyalty);
    }
    
    function pendingRoyaltyByAddress(address _owner) private view returns (uint) {
        for (uint i; i < owners.length; i++) {
            if(_owner == owners[i]) return i;
        }
        return ~uint256(0);
    }
    
    function pendingRoyalties() public view returns (uint[4] memory) {
        uint[4] memory data;
        for (uint i; i < owners.length; i++) {
            data[i] = pendingRoyaltyByIndex(i);
        }
        return data;
    }
    
    function sharedRoyaltyByAddress(address _owner) private view returns(uint) {
        return royalties[_owner];
    }
    
    function sharedRoyaltyByIndex(uint _index) private view returns(uint) {
        require(_index >= 0 && _index < owners.length);
        return sharedRoyaltyByAddress(ownerByIndex(_index));
    }
    
    function sharedRoyalties() public view returns (uint[4] memory) {
        uint[4] memory data;
        for (uint i; i < owners.length; i++) {
            data[i] = sharedRoyaltyByIndex(i);
        }
        return data;
    }
    
    function totalSharedRoyalties() public view returns(uint) {
        uint totalAmount;
        for (uint i; i < owners.length; i++) {
            totalAmount = totalAmount.add(sharedRoyaltyByIndex(i));
        }
        return totalAmount;
    }
    
    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }
    
}