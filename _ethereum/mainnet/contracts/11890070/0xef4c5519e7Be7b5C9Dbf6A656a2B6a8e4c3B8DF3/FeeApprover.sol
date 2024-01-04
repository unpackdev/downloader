// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./IERC20.sol";
import "./Initializable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./console.sol";
import "./IUniswapV2Factory.sol";

/*
 * @notice Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

/**
 * @notice Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
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

    uint256[49] private __gap;
}

contract FeeApprover is OwnableUpgradeSafe {
    using SafeMath for uint256;

    // constructor(
    //   address _LEVELSAddress,
    //   address _WETHAddress,
    //   address _uniswapFactory
    // ) 
    //   public
    // {
    //   initialize(_LEVELSAddress, _WETHAddress, _uniswapFactory);
    // }

    function initialize(
        address _LEVELSAddress,
        address _LEVELSVaultAddress,
        address _WETHAddress,
        address _uniswapFactory
    ) public initializer {
        OwnableUpgradeSafe.__Ownable_init();
        levelsTokenAddress = _LEVELSAddress;
        levelsVaultAddress = _LEVELSVaultAddress;
        WETHAddress = _WETHAddress;
        tokenUniswapPair = IUniswapV2Factory(_uniswapFactory).getPair(WETHAddress, levelsTokenAddress);

        // Default trasnaction fee is 1%
        feePercentX100 = 10;
        paused = true;
        sync();
    }


    address public tokenUniswapPair;
    IUniswapV2Factory public uniswapFactory;
    address public WETHAddress;
    address public levelsTokenAddress;
    address public levelsVaultAddress;
    uint8 public feePercentX100;
    uint256 public lastTotalSupplyOfLPTokens;


    bool public paused;
    uint256 public lastSupplyOfLevelsInPair;
    uint256 public lastSupplyOfWETHInPair;

    mapping (address => bool) public noFeeList;
    mapping (address => bool) public discountFeeList;
    mapping (address => bool) public blackList;

    function setPaused(bool _pause) public onlyOwner {
        paused = _pause;
        sync();
    }

    function setFeeMultiplier(uint8 _feeMultiplier) public onlyOwner {
        feePercentX100 = _feeMultiplier;
    }

    function setLevelsVaultAddress(address _levelsVaultAddress) public onlyOwner {
        levelsVaultAddress = _levelsVaultAddress;
        noFeeList[levelsVaultAddress] = true;
    }

    function updateNoFeeList(address _address, bool noFee) public onlyOwner{
        noFeeList[_address] = noFee;
    }

    function updateDiscountFeeList(address _address, bool discFee) public onlyOwner{
        discountFeeList[_address] = discFee;
    }

    function updateBlackList(address _address, bool _block) public onlyOwner{
        blackList[_address] = _block;
    }

    function sync() public {
        uint256 _LPSupplyOfPairTotal = IERC20(tokenUniswapPair).totalSupply();
        lastTotalSupplyOfLPTokens = _LPSupplyOfPairTotal;
    }


    function calculateAmountsAfterFee(
        address sender,
        address recipient,
        uint256 amount
        ) public  returns (uint256 transferToAmount, uint256 transferToFeeDistributorAmount)
        {
            require(msg.sender == levelsTokenAddress, "Nuh uh uh");
            require(paused == false, "FEE APPROVER: Transfers Paused");

            uint256 _LPSupplyOfPairTotal = IERC20(tokenUniswapPair).totalSupply();

            if(sender == tokenUniswapPair) {
                // We are keeping the liqudity assets
                require(lastTotalSupplyOfLPTokens <= _LPSupplyOfPairTotal, "Liquidity withdrawals forbidden");
            }

            // Get out bad actors!
            require(blackList[recipient] == false, "Blocked Recipient");

            if(sender == levelsVaultAddress || sender == tokenUniswapPair ||  noFeeList[sender]) {
                // Dont have a fee when levelsvault is sending, or infinite loop
                transferToFeeDistributorAmount = 0;
                transferToAmount = amount;
            }
            else {
                if(discountFeeList[sender]) {
                    // Half fee if offered fee discount
                    transferToFeeDistributorAmount = amount.mul(feePercentX100).div(2000);
                    transferToAmount = amount.sub(transferToFeeDistributorAmount);
                } else {
                    // Normal fee transfer
                    transferToFeeDistributorAmount = amount.mul(feePercentX100).div(1000);
                    transferToAmount = amount.sub(transferToFeeDistributorAmount);
                }
            }

            lastTotalSupplyOfLPTokens = _LPSupplyOfPairTotal;
        }
}