// SPDX-License-Identifier: MIT
// dev: @Brougkr

pragma solidity 0.8.11;
import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

contract TicketSale is Ownable, Pausable, ReentrancyGuard
{
    // Addresses
    address public _TICKET_TOKEN_ADDRESS = 0xd64a6F3c0bC12A619fF7eEf511b0258DA913C5c3;
    address public _BRT_MULTISIG = 0x90DBc54DBfe6363aCdBa4E54eE97A2e0073EA7ad;

    // Token Amounts
    uint256 public _TICKET_INDEX = 533;
    uint256 public _MAX_TICKETS = 665;
    
    // Price
    uint256 public _TICKET_PRICE_BRIGHT_LIST = 1 ether;
    uint256 public _TICKET_PRICE_PUBLIC = 2 ether;
    uint256 immutable _BRIGHT_LIST_AMOUNT = 5;

    // Sale State
    bool public _SALE_IS_ACTIVE_PUBLIC = false;
    bool public _SALE_IS_ACTIVE_BRIGHTLIST = false;
    bool public _ALLOW_MULTIPLE_PURCHASES = true;

    // Mint Mapping
    mapping (address => bool) public purchased;
    mapping (address => uint256) public BrightList;

    // Events
    event TicketPurchased(address indexed recipient, uint256 indexed amt, uint256 indexed ticketID);
    event BrightListRecipientsAdded(address[] wallets, uint256[] amounts, uint256 walletLength, uint256 amountLength);
    event BrightListRecipientsAddedAmts(address[] wallets, uint256 amount, uint256 walletLength);

    constructor() { }

    /**
     * @dev All-In-One Wrapped Ticket Purchase Function
     */
    function TicketPurchase() public payable nonReentrant whenNotPaused
    {
        require(_SALE_IS_ACTIVE_BRIGHTLIST || _SALE_IS_ACTIVE_PUBLIC, "No Sale Active");
        require(msg.value == _TICKET_PRICE_PUBLIC || msg.value == _TICKET_PRICE_BRIGHT_LIST, "Incorrect Ether Value Provided");
        require(_TICKET_INDEX + 1 <= _MAX_TICKETS, "Purchase Would Exceed Max Supply Of Tickets");
        if(!_ALLOW_MULTIPLE_PURCHASES) { require(!purchased[msg.sender], "Address Has Already Purchased"); }
        if(_SALE_IS_ACTIVE_BRIGHTLIST && BrightList[msg.sender] > 0)
        {
            require(_TICKET_PRICE_BRIGHT_LIST == msg.value, "Ether Value Sent Is Not Correct. BrightList Sale is 1 ETH Per Ticket");
            BrightList[msg.sender] -= 1;
        }
        else
        {
            require(_TICKET_PRICE_PUBLIC == msg.value && _SALE_IS_ACTIVE_PUBLIC, "Ether Value Sent Is Not Correct Or Public Sale Inactive. Public Sale is 2 ETH Per Ticket");
        }
        IERC721(_TICKET_TOKEN_ADDRESS).transferFrom(_BRT_MULTISIG, msg.sender, _TICKET_INDEX);
        _TICKET_INDEX += 1;
        purchased[msg.sender] = true;
        emit TicketPurchased(msg.sender, 1, _TICKET_INDEX);
    }

    /**
     * @dev Adds Governance Recipients To BrightList Purchase List
     */
    function __modifyBrightListAmounts(address[] calldata wallets, uint256[] calldata amounts) external onlyOwner
    {
        for(uint i = 0; i < wallets.length; i++)
        {
            BrightList[wallets[i]] = amounts[i];
        }
        emit BrightListRecipientsAdded(wallets, amounts, wallets.length, amounts.length);
    }

    /**
     * @dev Adds Governance Recipients To BrightList Purchase List
     */
    function __modifyBrightList(address[] calldata wallets) external onlyOwner
    {
        for(uint i = 0; i < wallets.length; i++)
        {
            BrightList[wallets[i]] = _BRIGHT_LIST_AMOUNT;
        }
        emit BrightListRecipientsAddedAmts(wallets, _BRIGHT_LIST_AMOUNT, wallets.length);
    }

    /**
     * @dev Ends Sale
     */
    function __endSale() external onlyOwner
    {
        _SALE_IS_ACTIVE_PUBLIC = false;
        _SALE_IS_ACTIVE_BRIGHTLIST = false;
    }

    /**
     * @dev Sets BrightList Sale Ticket Price
     */
    function __setTicketPriceBrightList(uint256 TICKET_PRICE) external onlyOwner { _TICKET_PRICE_BRIGHT_LIST = TICKET_PRICE; }

    /**
     * @dev Sets Public Sale Ticket Price
     */
    function __setTicketPricePublic(uint256 TICKET_PRICE) external onlyOwner { _TICKET_PRICE_PUBLIC = TICKET_PRICE; }

    /**
     * @dev Overrides Max Tickets
     */
    function __setMaxTickets(uint256 MAX_TICKETS) external onlyOwner { _MAX_TICKETS = MAX_TICKETS; }

    /**
     * @dev Overrides Ticket Index
     */
    function __setTicketIndex(uint256 TICKET_INDEX) external onlyOwner { _TICKET_INDEX = TICKET_INDEX; }
    
    /**
     * @dev Flips BrightList Sale State
     */
    function __flipSaleStateBrightList() external onlyOwner { _SALE_IS_ACTIVE_BRIGHTLIST = !_SALE_IS_ACTIVE_BRIGHTLIST; }

    /**
     * @dev Flips Public Sale State
     */
    function __flipSaleStatePublic() external onlyOwner { _SALE_IS_ACTIVE_PUBLIC = !_SALE_IS_ACTIVE_PUBLIC; }

    /**
     * @dev Flips Multiple Purchases
     */
    function __flipMultiplePurchases() external onlyOwner { _ALLOW_MULTIPLE_PURCHASES = !_ALLOW_MULTIPLE_PURCHASES; }

    /**
     * @dev Pauses Contract
     */
    function __pauseContract() external onlyOwner { _pause(); }

    /**
     * @dev Unpauses Contract
     */
    function __unpauseContract() external onlyOwner { _unpause(); }
    
    /**
     * @dev Changes Ticket Token Address
     */
    function __changeTicketAddress(address ticketAddress) external onlyOwner { _TICKET_TOKEN_ADDRESS = ticketAddress; }

    /**
     * @dev Changes Multisig Address
     */
    function __changeMultisigAddress(address multisigAddress) external onlyOwner { _BRT_MULTISIG = multisigAddress; }

    /**
     * @dev Withdraws Ether From Contract
     */
    function __withdrawEther() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }

    /**
     * @dev Withdraws ERC-20 From Contract
     */
    function __withdrawERC20(address contractAddress) external onlyOwner 
    { 
        IERC20 ERC20 = IERC20(contractAddress); 
        uint256 balance = ERC20.balanceOf(address(this));
        ERC20.transferFrom(address(this), msg.sender, balance); 
    }
}
