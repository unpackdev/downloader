// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

interface SkyToken {
    function extMint(address _addr, uint256 _amount) external returns (bool);

    function isWhitelistedReceiver(address _addr) external view returns (bool);

    function isWhitelistedMinter(address _addr) external view returns (bool);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract staking is Ownable, ERC20 {
    using SafeMath for uint256;

    uint256 public currentRound = 0;

    uint24 public WEEK = 604800;
    uint256 public readyAt = 0;
    uint256 public deployTime = block.timestamp ; 

    address public token_addr;
    SkyToken token_contract = SkyToken(token_addr);

    uint256 public am1 = 250e3 * 1e18 ; 
    uint256 public am2 = 500e3 * 1e18 ; 
    uint256 public am3 = 750e3 * 1e18 ;
    uint256 public am4 = 1e6 * 1e18 ; 

    mapping(uint256 => uint256) public roundPricePerShare;
    mapping(address => uint256) public roundDeposited;
    uint256 public ppsMultiplier = 1e18;

    event Deposit(address indexed addr, uint256 assetAmount);
    event Withdraw(
        address indexed addr,
        uint256 shareAmount,
        uint256 assetAmount
    );
    event Roll(uint256 newRound, uint256 newPPS);

    constructor() ERC20("Staked SkyToken", "sSKY") {
        roundPricePerShare[currentRound] = 1 * ppsMultiplier ; 
    }

    /**
     * @notice Set Skycoin token contract address
     * @param addr Address of Skycoin token contract
     */
    function set_token_address(address addr) external onlyOwner {
        token_addr = addr;
        token_contract = SkyToken(addr);
    }

    /**
     * @notice Deposits the `asset` into the contract and mint vault shares.
     * @param amount is the amount of `asset` to deposit
     */
    function deposit(uint256 amount) external {
        token_contract.transferFrom(msg.sender, address(this), amount);
        _deposit(amount);

        roundDeposited[msg.sender] = currentRound;

        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice Mints the vault shares to the msg.sender
     * @param amount is the amount of `asset` deposited
     */
    function _deposit(uint256 amount) private {
        uint256 totalWithDepositedAmount = totalBalance();

        // amount needs to be subtracted from totalBalance because it has already been
        // added to it from either IWETH.deposit and IERC20.safeTransferFrom
        uint256 total = totalWithDepositedAmount.sub(amount);

        uint256 shareSupply = totalSupply();

        // Following the pool share calculation from Alpha Homora:
        // solhint-disable-next-line
        // https://github.com/AlphaFinanceLab/alphahomora/blob/340653c8ac1e9b4f23d5b81e61307bf7d02a26e8/contracts/5/Bank.sol#L104
        uint256 share = shareSupply == 0
            ? amount
            : amount.mul(shareSupply).div(total);

        _mint(msg.sender, share);
    }

    /**
     * @notice Withdraws WETH from vault using vault shares
     * @param shares is the number of vault shares to be burned
     */
    function withdraw(uint256 shares) public {
        uint256 withdrawAmount = getWithdrawAmount(shares, msg.sender);

        _burn(msg.sender, shares);

        token_contract.transfer(msg.sender, withdrawAmount);

        emit Withdraw(msg.sender, shares, withdrawAmount);
    }

    /**
     * @dev Get withdraw amount of shares value
     * @param shares How many shares will be exchanged
     */
    function getWithdrawAmount(uint256 shares, address _addr)
        public
        view
        returns (uint256 amount)
    {
        uint256 PPS;

        //check if last user: cannot use shares, could be partial withdraw
        uint256 userShareBalance = balanceOf(_addr);

        if (userShareBalance == totalSupply()) {
            //last user
            PPS = getPricePerShare(currentRound);
        } else {
            PPS = getPricePerShare(currentRound.sub(1));
        }

        amount = (shares.mul(PPS)).div(ppsMultiplier);
    }

    /**
     * @dev Get round in which user started staking latest staking round
     */
    function getUserStartRound(address _addr)
        public
        view
        returns (uint256 startRound)
    {
        startRound = roundDeposited[_addr];
    }

    /**
     * @dev Get mint amount for roll()
     * @param timestamp current timestamp     
     */
    function getMintAmount(uint timestamp) public view returns (uint256 amount) {
        if (timestamp < deployTime + 31557600) {
            amount = am1 ; 
        } else {
            if (timestamp < deployTime + 63115200) {
                amount = am2 ; 
            } else {
                if (timestamp < deployTime + 94672800) {
                    amount = am3 ; 
                } else {
                    amount = am4 ; 
                   }
                }
            }
        }

    /**
     * @dev Change mint amounts for year 1, 2, 3 and >= 4
     * @param _am1 Amount to mint per week in year 1
     * @param _am2 Amount to mint per week in year 2
     * @param _am3 Amount to mint per week in year 3
     * @param _am4 Amount to mint per week in year 4
     */
    function changeMintAmounts(uint _am1, uint _am2, uint _am3, uint _am4) external onlyOwner {
        am1 = _am1 ; 
        am2 = _am2 ; 
        am3 = _am3 ; 
        am4 = _am4 ; 
    }

    /*
     * @notice Rolls the vault's funds into a new short position.
     */
    function roll() external onlyOwner {
        require(block.timestamp >= readyAt, "not ready to roll yet");
        
        uint mintAmount = getMintAmount(block.timestamp)/52 ; 
        token_contract.extMint(address(this), mintAmount);

        readyAt = block.timestamp.add(WEEK);
        currentRound = currentRound.add(1);

        roundPricePerShare[currentRound] = getPricePerShare(currentRound);

        emit Roll(currentRound, roundPricePerShare[currentRound]);
    }

    /**
     * @dev Get pricePerShare of a certain round (multiplied with ppsMultiplier!)
     * @param round Round to get the pricePerShare
     */
    function getPricePerShare(uint256 round) public view returns (uint256 pps) {
        if (round == currentRound) {
            uint256 _assetBalance = assetBalance();
            uint256 _shareSupply = totalSupply();

            if (_shareSupply == 0) {
                pps = 1;
            } else {
                pps = (_assetBalance.mul(ppsMultiplier)).div(_shareSupply);
            }
        } else {
            pps = roundPricePerShare[round];
        }
    }

    /**
     * @dev Get user asset balance using user share balance
     * @param _addr Address to get the user asset balance from
     */
    function getUserAssetBalance(address _addr)
        external
        view
        returns (uint256 balance)
    {
        uint256 userShareBalance = balanceOf(_addr);
        balance = getWithdrawAmount(userShareBalance, _addr);
    }

    /**
     * @notice Returns the vault's total balance, including the amounts locked into a short position
     * @return total balance of the vault, including the amounts locked in third party protocols
     */
    function totalBalance() public view returns (uint256) {
        return token_contract.balanceOf(address(this));
    }

    /**
     * @notice Returns the asset balance on the vault. This balance is freely withdrawable by users.
     */
    function assetBalance() public view returns (uint256) {
        return token_contract.balanceOf(address(this));
    }
}
