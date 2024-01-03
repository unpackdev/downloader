// SPDX-License-Identifier: MIT
pragma solidity >=0.4.16 <0.8.0;

/**

██████╗░██╗████████╗░█████╗░░█████╗░░██████╗██╗░░██╗██████╗░░█████╗░██╗░░░██╗
██╔══██╗██║╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██║░░██║██╔══██╗██╔══██╗╚██╗░██╔╝
██████╦╝██║░░░██║░░░██║░░╚═╝███████║╚█████╗░███████║██████╔╝███████║░╚████╔╝░
██╔══██╗██║░░░██║░░░██║░░██╗██╔══██║░╚═══██╗██╔══██║██╔═══╝░██╔══██║░░╚██╔╝░░
██████╦╝██║░░░██║░░░╚█████╔╝██║░░██║██████╔╝██║░░██║██║░░░░░██║░░██║░░░██║░░░
╚═════╝░╚═╝░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝░░╚═╝░░░╚═╝░░░

Bitcashpay BCP token has a Decentralized Liquidity Contribution or DLC as we termed it. 
Unlike the traditional ICOs where the project owners or team members gather 
funds to “further develop” the project ( or simply run away ), 
participants to our DLC will directly contribute to uniswap’s ETH/BCP pair. 
Ninety-five percent (95%) of accumulated funds during our DLC event will go directly to ETH/BCP pairing in uniswap, 
this will create a HUGE DECENTRALIZED LIUIDITY POOL in Uniswap, an OWNERLESS POOL 
and only five percent (5%) will go to the team to be used for further development. 
There will be a total of 300M BCP tokens up for grabs on our DLC event with a hardcap of 20,000 ETH

*/






library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface BitcashPay {
    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) external returns (bool success);

    function transfer(address _to, uint _amount) external returns (bool success);
}

interface UniswapRouterV2 {

    function addLiquidityETH(
        address token,
        uint256 amountTokenMax,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (
        uint256 amountB
    );

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (
        uint256[] memory amounts
    );

    function WETH() external pure returns (address);
}

interface IERC20Token {

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )  external returns (
        bool success
    );

    function approve(
        address _spender,
        uint256 _value
    )  external returns (
        bool success
    );

}

interface UniswapV2Pair {

    function getReserves() external view returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function token1() external view returns (address);
}

contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract BitcashPayDecentralizedLiquidityContribution is ReentrancyGuard
{
    using SafeMath for uint;

    BitcashPay public BITCASHPAY_CONTRACT;
    UniswapV2Pair public UNISWAP_PAIR;
    UniswapRouterV2 public UNISWAP_ROUTER;

    address public owner;
    uint investmentDays = 90;

    address payable TEAM_ADDRESS;
    address public TOKEN_DEFINER;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint public startDate;

    uint public reservationChange = 66667000000000 wei; //in wei 15k BCP per 1 ETH

    uint public maxBCPAvailableForContribution = 300000000;

    uint public referraBonusRate = 10;
    uint public hardCap = 20000 ether;

    uint MULTIPLIER = 10 ** 8; // BCP TO WEI

    mapping (address => uint) internal bcpReservations;
    mapping (address => Bonus[]) internal referralBonuses;
    mapping (address => uint) internal reservedEther;

    struct Globals {
        uint totalReservedTokens;
        uint totalWeiContributed;
        uint totalReferralTokens;
    }

    Globals public g;

    struct Bonus {
        address fromAddress;
        address toAddress;
        uint amount;
        uint bonus;
    }

    event UniSwapResult(
        uint amountToken,
        uint amountETH,
        uint liquidity
    );

    event BitcashPayReservation (
        address _reservedTo,
        uint _amountReserved
    );

    event BitcashPayReservationReferralBonus (
        address _from,
        address _referrerAddress,
        uint _amount
    );

    constructor(address _bitcashPayToken, address _uniswapPair, address _uniswapRouter, address payable _teamAddress)
    {
        BITCASHPAY_CONTRACT = BitcashPay(_bitcashPayToken);
        UNISWAP_PAIR = UniswapV2Pair(_uniswapPair);
        UNISWAP_ROUTER = UniswapRouterV2(_uniswapRouter);
        TOKEN_DEFINER = msg.sender;
        TEAM_ADDRESS = _teamAddress;
        startDate = block.timestamp;
        owner = msg.sender;
    }

    // BITCASHPAY DLC VARIABLE SETTERS //

    function setMaxBCPAvailableForContribution(uint _amount) public onlyOwner
    {
        maxBCPAvailableForContribution = _amount;
    }

    
    function setDefaultReservationChange(uint _reservationChange) public onlyOwner
    {
        reservationChange = _reservationChange;
    }
    

    function setInvestmentDays(uint _investmentDays) public onlyOwner
    {
        investmentDays = _investmentDays;
    }

    function setReferralBonusRate(uint _referralBonusRate) public onlyOwner
    {
        referraBonusRate = _referralBonusRate;
    }

    function setHardCap(uint _hardCap) public onlyOwner
    {
        hardCap = _hardCap;
    }

    /** @notice Allows reservation of BitcashPay tokens
      */
    receive() external payable {
        require (
            msg.value >= reservationChange,
            'BitcashPay: Reservation too low.'
        );

        uint reservationAmount = (msg.value).div(reservationChange);

        _reserveBitcashPay(
            msg.sender,
            reservationAmount
        );

        g.totalWeiContributed += msg.value;

        reservedEther[msg.sender] += msg.value;
    }

    /** @notice Allows reservation of BitcashPay Token to be excuted by web3
      * @param _referrerAddress address of referrers been pulled from localstorage/url/cookies
      */
    function reserveBitcashPay(address _referrerAddress) external payable nonReentrant
    {

        uint reservationAmount = (msg.value).div(reservationChange);

        _reserveBitcashPay(
            msg.sender,
            reservationAmount
        );

        _reserveReferralBonus(msg.sender, _referrerAddress, reservationAmount);

        g.totalWeiContributed += msg.value;
        
        reservedEther[msg.sender] += msg.value;
    }

    
    /** @notice Allows reservation of BitcashPay tokens with other ERC20 tokens
      * @dev this will require LT contract to be approved as spender
      * @param _tokenAddress address of an ERC20 token to use
      * @param _tokenAmount amount of tokens to use for reservation
      * @param _referrerAddress referral address for bonus
      */
    function reserveBitcashPayWithToken(
        address _tokenAddress, //erc token address
        uint256 _tokenAmount,
        address _referrerAddress
    )
        external nonReentrant
    {
        IERC20Token _token = IERC20Token(
            _tokenAddress
        );

        _token.transferFrom(
            msg.sender,
            address(this),
            _tokenAmount
        );

        _token.approve(
            address(UNISWAP_ROUTER),
            _tokenAmount
        );

        address[] memory _path = preparePath(
            _tokenAddress
        );

        uint256[] memory amounts =
        UNISWAP_ROUTER.swapExactTokensForETH(
            _tokenAmount,
            0,
            _path,
            address(this),
            block.timestamp.add(2 hours)
        );

        require (
            amounts[1] >= reservationChange,
            'BitcashPay: Reservation too low.'
        );


        uint reservationAmount = (amounts[1]).div(reservationChange);

        _reserveBitcashPay(
            msg.sender,
            reservationAmount
        );

        _reserveReferralBonus(msg.sender, _referrerAddress, reservationAmount);

        g.totalWeiContributed += amounts[1];
        reservedEther[msg.sender] += amounts[1];
    }


    // INFO VIEW FUNCTIONS //

    //----------------------------------------//

    function myTotalContributionAmount() external view returns (uint256) {
        return bcpReservations[msg.sender];
    }

    function reservationDaysRemaining() external view returns (uint) {
        return (block.timestamp - startDate) / 60 / 60 / 24;
    }

    function myTotalClaimableReservations() external view returns (uint)
    {
        return claimableReservation(msg.sender);
    }

    function myTotalClaimableReferralBonus() external view returns (uint)
    {
        return claimableReferralBonus(msg.sender);
    }


    // PAYOUT BITCASHPAY TOKENS //
    // ------------------------ //

    //  BITCASHPAY TOKEN PAYOUT FUNCTIONS (INDIVIDUAL)  //
    //  ----------------------------------------  //

    function getMyTokens()
        external
        afterReservationPhase
    {
        payoutInvestorAddress(msg.sender);
        payoutReferralAddress(msg.sender);
    }

   
    function payoutInvestorAddress(
        address _investorAddress
    )
        public
        afterReservationPhase
        returns (uint claimedReservation)
    {
        uint reservation = claimableReservation(_investorAddress);
        require(claimableReservation(_investorAddress) > 0, "BitcashPay: You dont have claimable reservation.");
        BITCASHPAY_CONTRACT.transferFrom(owner, _investorAddress, reservation);
        bcpReservations[_investorAddress] = 0;
        return claimableReservation(_investorAddress);
    }


    function payoutReferralAddress(
        address _referrerAddress
    ) public
        afterReservationPhase
        returns (uint256 _referralTokens)
    {
        _referralTokens = claimableReferralBonus(_referrerAddress);
        if (_referralTokens > 0) {
            BITCASHPAY_CONTRACT.transferFrom(owner, _referrerAddress, claimableReservation(_referrerAddress));
            delete referralBonuses[_referrerAddress];
        }
    }


    // BITCASHPAY RESERVATION INTERNAL FUNCTIONS //
    // ---------------------------------------- //

    /** @notice Calculates the claimable reservation
      * @dev if contribution reached the hard cap (20,000ETH) the maximum BCP Available for Contribution will be devided
      * @param _contributorsAddress address of the contributor
      */
    function claimableReservation(address _contributorsAddress) public view returns (uint)
    {

        if (g.totalWeiContributed >= hardCap) {
            uint contributorsShare = maxBCPAvailableForContribution.mul(MULTIPLIER).mul(reservedEther[_contributorsAddress] / g.totalWeiContributed);
            return contributorsShare;
        }
        
        return bcpReservations[_contributorsAddress];
    }

    function claimableReferralBonus(address _referrerAddress) public view returns (uint TotalBonus)
    {
        TotalBonus = 0;
        
        for (uint b = 0; b < referralBonuses[_referrerAddress].length; b += 1 ) {
            if (g.totalWeiContributed >= hardCap) {
                TotalBonus += (referralBonuses[_referrerAddress][b].amount).mul(referraBonusRate.mul(100).div(10000));
            } else {
                TotalBonus += referralBonuses[_referrerAddress][b].bonus;
            }
        }
    }


    function _reserveBitcashPay(address _senderAddress, uint _amount) internal
    {
        bcpReservations[_senderAddress] += _amount.mul(MULTIPLIER);
        g.totalReservedTokens += _amount.mul(MULTIPLIER);

        emit BitcashPayReservation(
            _senderAddress,
            _amount.mul(MULTIPLIER)
        );
    }


    function _reserveReferralBonus(address _from, address _referrerAddress,  uint _amount) internal
    {
        uint referralBonus = _amount * referraBonusRate.mul(100) / 10000;

        referralBonuses[_referrerAddress].push(Bonus(_from, _referrerAddress, _amount, referralBonus.mul(MULTIPLIER)));
        g.totalReferralTokens += referralBonus.mul(MULTIPLIER);

        emit BitcashPayReservationReferralBonus (
            _from,
            _referrerAddress,
            referralBonus.mul(MULTIPLIER)
        );
        
    }


    //  LIQUIDITY GENERATION FUNCTION  //
    //  -----------------------------  //

    /** @notice Forwards the contribution to the liquidity pool
      */
    function forwardLiquidity()
        external
        afterReservationPhase
    {

        uint _balance = g.totalWeiContributed;
        uint _buffer = g.totalReservedTokens + g.totalReferralTokens;
        uint _teamContribution = 5;

        // exclude eth for the team (5% of the total contribution)
        _balance = _balance.sub(_balance.mul(_teamContribution * 100 / 10000));

        _buffer = _buffer.mul(_balance).div(
            g.totalWeiContributed
        );

        //pair
        BITCASHPAY_CONTRACT.approve(
            address(UNISWAP_ROUTER), _buffer
        );

        (
            uint amountToken,
            uint amountETH,
            uint liquidity
        ) =

        UNISWAP_ROUTER.addLiquidityETH{value: _balance}(
            address(BITCASHPAY_CONTRACT),
            _buffer,
            0,
            0,
            address(0x0),
            block.timestamp.add(2 hours)
        );

        g.totalReservedTokens = 0;
        g.totalReferralTokens = 0;
        g.totalWeiContributed = 0;

        emit UniSwapResult(
            amountToken, amountETH, liquidity
        );
    }

    function requestTeamFunds(
        uint256 _amount
    )
        external
        afterUniswapTransfer
    {
        TEAM_ADDRESS.transfer(_amount);
    }

    function requestLeftOverBCPFunds(
        uint256 _amount
    )
        external
        afterUniswapTransfer
    {
        BITCASHPAY_CONTRACT.transfer(owner, _amount);
    }

    function preparePath(
        address _tokenAddress
    ) internal pure returns (
        address[] memory _path
    ) {
        _path = new address[](2);
        _path[0] = _tokenAddress;
        _path[1] = WETH;
    }

    function notContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size == 0);
    }


    modifier afterReservationPhase()
    {   
        require(block.timestamp - startDate >= (investmentDays * 60 * 60 * 24), "BitcashPay: Contribution period is not yet done.");
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            'BitcashPay: Access Denied!'
        );
        _;
    }

    modifier afterUniswapTransfer() {
        require (
            g.totalWeiContributed == 0,
            'BitcashPay: forward liquidity first'
        );
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public{
        if (newOwner != address(0)) owner = newOwner;
    }


}