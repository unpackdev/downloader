// SPDX-License-Identifier: MIT
// Developer: @Brougkr

pragma solidity 0.8.10;
import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

contract CryptoCitizenGovernanceTicketSale is Ownable, Pausable, ReentrancyGuard
{
    // Addresses
    address public _TICKET_TOKEN_ADDRESS = 0xC2A3c3543701009d36C0357177a62E0F6459e8A9;
    address public _BRT_MULTISIG = 0xB96E81f80b3AEEf65CB6d0E280b15FD5DBE71937;

    // Token Amounts
    uint256 public _TICKET_INDEX = 50;
    uint256 public _MAX_TICKETS = 100;
    
    // Price
    uint256 public _TICKET_PRICE = 1 ether;

    // Sale State
    bool public _SALE_IS_ACTIVE = true;
    bool public _ALLOW_MULTIPLE_PURCHASES = true;

    // Mint Mapping
    mapping (address => bool) public purchased;
    mapping (address => uint256) public BrightList;

    // Events
    event TicketPurchased(address indexed recipient, uint256 indexed amt, uint256 indexed ticketID);
    event GovernanceRecipientsAdded(address[] wallets, uint256[] amounts);

    constructor() { }

    // Purchases London Ticket
    function TicketPurchase() public payable nonReentrant whenNotPaused
    {
        require(_SALE_IS_ACTIVE, "Sale must be active to mint Tickets");
        require(BrightList[msg.sender] > 0, "Ticket Amount Exceeds `msg.sender` Allowance");
        require(_TICKET_INDEX + 1 < _MAX_TICKETS, "Purchase Would Exceed Max Supply Of Tickets");
        require(_TICKET_PRICE == msg.value, "Ether Value Sent Is Not Correct. 1 ETH Per Ticket");
        if(!_ALLOW_MULTIPLE_PURCHASES) { require(!purchased[msg.sender], "Address Has Already Purchased"); }
        BrightList[msg.sender] -= 1;
        IERC721(_TICKET_TOKEN_ADDRESS).transferFrom(_BRT_MULTISIG, msg.sender, _TICKET_INDEX);
        _TICKET_INDEX += 1;
        purchased[msg.sender] = true;
        emit TicketPurchased(msg.sender, 1, _TICKET_INDEX);
    }

    // Adds Governance Recipients To BrightList Purchase List
    function __addGovernanceRecipients(address[] calldata wallets, uint256[] calldata amounts) external onlyOwner
    {
        for(uint i = 0; i < wallets.length; i++)
        {
            BrightList[wallets[i]] = amounts[i];
        }
        emit GovernanceRecipientsAdded(wallets, amounts);
    }

    // Sets Future Ticket Price
    function __setTicketPrice(uint256 TICKET_PRICE) external onlyOwner { _TICKET_PRICE = TICKET_PRICE; }

    // Sets Max Tickets
    function __setMaxTickets(uint256 MAX_TICKETS) external onlyOwner { _MAX_TICKETS = MAX_TICKETS; }

    // Overrides Ticket Index
    function __setTicketIndex(uint256 TICKET_INDEX) external onlyOwner { _TICKET_INDEX = TICKET_INDEX; }
    
    // Flips Sale State
    function __flip_saleState() external onlyOwner { _SALE_IS_ACTIVE = !_SALE_IS_ACTIVE; }

    // Flips Multiple Purchases
    function __flipMultiplePurchases() external onlyOwner { _ALLOW_MULTIPLE_PURCHASES = !_ALLOW_MULTIPLE_PURCHASES; }

    // Pauses Contract
    function __pause() external onlyOwner { _pause(); }

    // Unpauses Contract
    function __unpause() external onlyOwner { _unpause(); }
    
    // Withdraws Ether from Contract
    function __withdrawEther() external onlyOwner { payable(_BRT_MULTISIG).transfer(address(this).balance); }

    // Withdraws ERC-20 from Contract
    function __withdrawERC20(address contractAddress) external onlyOwner 
    { 
        IERC20 ERC20 = IERC20(contractAddress); 
        uint256 balance = ERC20.balanceOf(address(this));
        ERC20.transferFrom(address(this), _BRT_MULTISIG, balance); 
    }
}
