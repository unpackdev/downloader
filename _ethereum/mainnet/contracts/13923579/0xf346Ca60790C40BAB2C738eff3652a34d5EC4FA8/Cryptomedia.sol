// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./ReentrancyGuard.sol";
import "./Initializable.sol";
import "./BondingCurve.sol";
import "./IBondingCurve.sol";

/**
 * @title Cryptomedia
 * @author neuroswish
 *
 * Cryptomedia
 *
 * I just needed time alone with my own thoughts
 * Got treasures in my mind, but couldn't open up my own vault
 *
 */

contract Cryptomedia is ReentrancyGuard, Initializable {
    // ======== Interface addresses ========
    address public factory; // factory address
    address public bondingCurve; // bonding curve interface address

    // ======== Continuous token params ========
    address public creator; // cryptomedia creator
    string public name; // cryptomedia name
    string public symbol; // cryptomedia symbol
    string public metadataURI; // cryptomedia metadata URI
    uint32 public reserveRatio; // reserve ratio in ppm
    uint32 public ppm; // token units
    uint256 public poolBalance; // ETH balance in contract pool
    uint256 public totalSupply; // total supply of tokens in circulation
    mapping(address => uint256) public balanceOf; // mapping of an address to that user's total token balance
    mapping(address => mapping(address => uint256)) public allowance; // transfer allowance

    // ======== Events ========
    event Buy(
        address indexed buyer,
        uint256 poolBalance,
        uint256 totalSupply,
        uint256 tokens,
        uint256 price
    );
    event Sell(
        address indexed seller,
        uint256 poolBalance,
        uint256 totalSupply,
        uint256 tokens,
        uint256 eth
    );
    event MetadataUpdated(string metadataURI);

    // ERC-20
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // ======== Modifiers ========
    /**
     * @notice Check to see if address holds tokens
     */
    modifier holder() {
        require(balanceOf[msg.sender] > 0, "Must hold tokens");
        _;
    }

    /**
     * @notice Check to see if address holds tokens
     */
    modifier onlyCreator() {
        require(msg.sender == creator, "Must be creator");
        _;
    }

    // ======== Initializer for new market proxy ========
    /**
     * @notice Initialize a new market
     * @dev Sets reserveRatio, ppm, fee, name, and bondingCurve address; called by factory at time of deployment
     */
    function initialize(
        address _creator,
        string calldata _name,
        string calldata _symbol,
        string calldata _metadataURI,
        address _bondingCurve,
        uint256 _reservedTokens
    ) external initializer {
        reserveRatio = 333333;
        ppm = 1000000;
        name = _name;
        symbol = _symbol;
        bondingCurve = _bondingCurve;
        creator = _creator;
        metadataURI = _metadataURI;
        // creator can specify a number of tokens to reserve upon supply initialization
        _mint(creator, _reservedTokens);
    }

    // ======== Functions ========
    /**
     * @notice Buy market tokens with ETH
     * @dev Emits a Buy event upon success; callable by anyone
     */
    function buy(uint256 _price, uint256 _minTokensReturned) external payable {
        require(msg.value == _price && msg.value > 0, "Invalid price");
        require(_minTokensReturned > 0, "Invalid slippage");
        // calculate tokens returned
        uint256 tokensReturned;
        if (totalSupply == 0 || poolBalance == 0) {
            tokensReturned = IBondingCurve(bondingCurve)
                .calculateInitializationReturn(_price, reserveRatio);
        } else {
            tokensReturned = IBondingCurve(bondingCurve)
                .calculatePurchaseReturn(
                    totalSupply,
                    poolBalance,
                    reserveRatio,
                    _price
                );
        }
        require(tokensReturned >= _minTokensReturned, "Slippage");
        // mint tokens for buyer
        _mint(msg.sender, tokensReturned);
        poolBalance += _price;
        emit Buy(msg.sender, poolBalance, totalSupply, tokensReturned, _price);
    }

    /**
     * @notice Sell market tokens for ETH
     * @dev Emits a Sell event upon success; callable by token holders
     */
    function sell(uint256 _tokens, uint256 _minETHReturned)
        external
        holder
        nonReentrant
    {
        require(
            _tokens > 0 && _tokens <= balanceOf[msg.sender],
            "Invalid token amount"
        );
        require(poolBalance > 0, "Insufficient pool balance");
        require(_minETHReturned > 0, "Invalid slippage");

        // calculate ETH returned
        uint256 ethReturned = IBondingCurve(bondingCurve).calculateSaleReturn(
            totalSupply,
            poolBalance,
            reserveRatio,
            _tokens
        );
        require(ethReturned >= _minETHReturned, "Slippage");
        // burn tokens
        _burn(msg.sender, _tokens);
        poolBalance -= ethReturned;
        sendValue(payable(msg.sender), ethReturned);
        emit Sell(msg.sender, poolBalance, totalSupply, _tokens, ethReturned);
    }

    // ============ Metadata ============
    /**
     * @notice Enable creator to update the cryptomedia URI
     * @dev Only callable by creator
     */
    function updateMetadataURI(string memory _metadataURI) public onlyCreator {
        metadataURI = _metadataURI;
    }

    // ============ Utility ============

    /**
     * @notice Send ETH in a safe manner
     * @dev Prevents reentrancy, emits a Transfer event upon success
     */
    function sendValue(address recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Invalid amount");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = payable(recipient).call{value: amount}("Reverted");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    // ============ ERC-20 ============

    /**
     * @notice Mints tokens
     * @dev Emits a Transfer event upon success
     */
    function _mint(address _to, uint256 _value) internal {
        totalSupply += _value;
        balanceOf[_to] += _value;
        emit Transfer(address(0), _to, _value);
    }

    /**
     * @notice Burns tokens
     * @dev Emits a Transfer event upon success
     */
    function _burn(address _from, uint256 _value) internal {
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        emit Transfer(_from, address(0), _value);
    }

    /**
     * @notice Approve token allowance
     * @dev Emits an Approval event upon success
     */
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @notice Transfer tokens
     * @dev Emits a Transfer event upon success
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance[sender][msg.sender];
        require(
            currentAllowance >= amount,
            "Transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }
}
