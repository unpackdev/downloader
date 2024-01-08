//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";

/**
 * @title A Presale contract made with ❤️ for the AGM folks.
 * @dev   Enable whitelisted investors to contribute to the AGM presale.
 */
contract AGMPresale {
    using SafeMath for uint256;

    uint256 constant ETH_PRICE_BASE = 1 ether;
    string constant ERROR_ADDRESS = "AGM > Invalid address";
    string constant ERROR_PRICE = "AGM > Invalid price";
    string constant ERROR_CAP = "AGM > Invalid cap";
    string constant ERROR_ARRAY = "AGM > Invalid array [too long]";
    string constant ERROR_OPENED = "AGM > Presale opened";
    string constant ERROR_NOT_OPENED = "AGM > Presale not opened yet";
    string constant ERROR_OVER = "AGM > Presale over";
    string constant ERROR_NOT_OVER = "AGM > Presale not over yet";
    string constant ERROR_NOT_WHITELISTED = "AGM > Address not whitelisted";
    string constant ERROR_ALREADY_WHITELISTED =
        "AGM > Address already whitelisted";
    string constant ERROR_GLOBAL_CAP = "AGM > Global cap reached";
    string constant ERROR_INDIVIDUAL_CAP = "AGM > Individual cap reached";
    string constant ERROR_ERC20_TRANSFER = "AGM > ERC20 transfer failed";

    uint256 public ETH_PRICE; // in $ per ETH
    uint256 public TOKEN_PRICE; // in token wei per wei
    uint256 public GLOBAL_CAP; // in wei
    uint256 public INDIVIDUAL_CAP; // in wei
    address public admin;
    address payable public bank;
    IERC20 public token;
    bool public isOpen;
    bool public isClosed;
    uint256 public raised;
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint256) public invested;

    event Open();
    event Close();
    event Whitelist(address indexed investor);
    event Unwhitelist(address indexed investor);
    event Invest(
        address indexed investor,
        uint256 value,
        uint256 investment,
        uint256 amount
    );

    modifier protected() {
        require(msg.sender == admin, "AGM > Protected operation");
        _;
    }

    modifier isPending() {
        require(!isOpen, ERROR_OPENED);
        _;
    }

    modifier isRunning() {
        require(isOpen, ERROR_NOT_OPENED);
        require(!isClosed, ERROR_OVER);
        _;
    }

    modifier isOver() {
        require(isClosed, ERROR_NOT_OVER);
        _;
    }

    /**
     * @dev          Deploy and initialize the AGM presale contract.
     * @param _admin The address of the admin allowed to perform protected operations.
     * @param _bank  The address to which received ETH and remaining AGM tokens are gonna be sent once the presale closes.
     * @param _token The address of the AGM token.
     * @param _price The price of ETH [in $ per ETH, e.g. $350 per ETH].
     */
    constructor(
        address _admin,
        address payable _bank,
        address _token,
        uint256 _price
    ) public {
        require(_admin != address(0), ERROR_ADDRESS);
        require(_bank != address(0), ERROR_ADDRESS);
        require(_token != address(0), ERROR_ADDRESS);
        require(_price != uint256(0), ERROR_PRICE);

        admin = _admin;
        bank = _bank;
        token = IERC20(_token);
        _setPrice(_price);
    }

    /* 1.  protected operations */

    /* 1.1 protected operations that can be performed any time */

    /**
     * @dev          Update admin address.
     * @param _admin The ethereum address of the new admin.
     */
    function updateAdmin(address _admin) external protected {
        require(_admin != address(0), ERROR_ADDRESS);
        require(_admin != admin, ERROR_ADDRESS);

        admin = _admin;
    }

    /**
     * @dev              Whitelist investors.
     * @param _investors An array of investors ethereum addresses to be whitelisted.
     */
    function whitelist(address[] calldata _investors) external protected {
        require(_investors.length <= 20, ERROR_ARRAY);

        for (uint256 i = 0; i < _investors.length; i++) {
            require(_investors[i] != address(0), ERROR_ADDRESS);
            require(!isWhitelisted[_investors[i]], ERROR_ALREADY_WHITELISTED);

            isWhitelisted[_investors[i]] = true;
            emit Whitelist(_investors[i]);
        }
    }

    /**
     * @dev              Un-whitelist investors.
     * @param _investors An array of investors ethereum addresses to be un-whitelisted.
     */
    function unwhitelist(address[] calldata _investors) external protected {
        require(_investors.length <= 20, ERROR_ARRAY);

        for (uint256 i = 0; i < _investors.length; i++) {
            require(isWhitelisted[_investors[i]], ERROR_NOT_WHITELISTED);

            isWhitelisted[_investors[i]] = false;
            emit Unwhitelist(_investors[i]);
        }
    }

    /* 1.2 protected operations that can only be performed before presale opens */

    /**
     * @dev         Update bank address.
     * @param _bank The ethereum address of the new bank.
     */
    function updateBank(address payable _bank) external protected isPending {
        require(_bank != address(0), ERROR_ADDRESS);
        require(_bank != bank, ERROR_ADDRESS);

        bank = _bank;
    }

    /**
     * @dev          Update pricing operations based on ETH price.
     * @param _price The ETH price [in $ per ETH, e.g. $340 per ETH] [no decimals allowed]
     */
    function updateETHPrice(uint256 _price) external protected {
        require(_price != uint256(0), ERROR_PRICE);

        _setPrice(_price);
    }

    /**
     * @dev Open the presale. Open buys and close whitelisting and pricing operations.
     */
    function open() external protected isPending {
        isOpen = true;

        emit Open();
    }

    /* 1.3 protected operations that can only be performed while the presale is running */

    /**
     * @dev Close the presale. Close buys and open whithdrawal operations. Withdraw received ETH and remaining AGM tokens.
     */
    function close() external protected isRunning {
        isClosed = true;

        withdraw();
        withdrawETH();

        emit Close();
    }

    /* 1.4 protected operations that can only be performed after the presale closes */

    /**
     * @dev Transfer any remaining AGM tokens hold by this contract to the bank.
     */
    function withdraw() public protected isOver {
        require(
            token.transfer(bank, token.balanceOf(address(this))),
            ERROR_ERC20_TRANSFER
        );
    }

    /**
     * @dev Transfer any remaining ETH hold by this contract to the bank [though it should not be possible for this contract to receive ETH after the presale is closed].
     */
    function withdrawETH() public protected isOver {
        bank.transfer(address(this).balance);
    }

    /* payment fallback function */

    receive() external payable isRunning {
        require(isWhitelisted[msg.sender], ERROR_NOT_WHITELISTED);
        require(raised < GLOBAL_CAP, ERROR_GLOBAL_CAP);
        require(invested[msg.sender] < INDIVIDUAL_CAP, ERROR_INDIVIDUAL_CAP);

        uint256 investment =
            invested[msg.sender].add(msg.value) <= INDIVIDUAL_CAP
                ? msg.value
                : INDIVIDUAL_CAP.sub(invested[msg.sender]);
        uint256 remains = msg.value.sub(investment);
        uint256 amount = _ETHToTokens(investment);
        // update state
        invested[msg.sender] = invested[msg.sender].add(investment);
        raised = raised.add(investment);
        // assess state consistency
        require(raised <= GLOBAL_CAP, ERROR_GLOBAL_CAP);
        require(invested[msg.sender] <= INDIVIDUAL_CAP, ERROR_INDIVIDUAL_CAP);
        // transfer token
        // PLEASE MAKE SURE AGM ERC20 returns true on success.
        require(token.transfer(msg.sender, amount), ERROR_ERC20_TRANSFER);
        // send remaining ETH back if needed
        if (remains > 0) {
            address payable investor = msg.sender;
            investor.transfer(remains);
        }

        emit Invest(msg.sender, msg.value, investment, amount);
    }

    /* private helpers functions */

   function _setPrice(uint256 _ETHPrice) private {
        ETH_PRICE = _ETHPrice;
        TOKEN_PRICE = _ETHPrice.mul(ETH_PRICE_BASE).mul(uint256(100)).div(
            uint256(3)
        );
        GLOBAL_CAP = uint256(150000).mul(ETH_PRICE_BASE).div(_ETHPrice);
        INDIVIDUAL_CAP = uint256(1500).mul(ETH_PRICE_BASE).div(_ETHPrice);
    }

    function _ETHToTokens(uint256 _value) private view returns (uint256) {
        return _value.mul(TOKEN_PRICE).div(ETH_PRICE_BASE);
    }
}
