//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract PictureDay is ERC721A, Ownable, ReentrancyGuard
{
    uint public PRICE = 0.055 ether;
    uint public MAX_NFTS = 5555;
    string public baseURI = "ipfs://Qme9hzkKJH2dWC2sgFQPK3omK5SDrH64nH8aBTYvaE4gFn/";
    address public _FUNDS_RECIPIENT = 0x6B1A77e8E277b2300cD8b1eC342C9d2cEd17688e;
    event Minted(address Recipient, uint Amount, uint EtherAmount);

    /**
     * @dev Constructor 
     */
    constructor() ERC721A("PictureDay", "BOTZ") 
    { 
        _mint(_FUNDS_RECIPIENT, 100); 
        _transferOwnership(_FUNDS_RECIPIENT);
    }

    /****************** 
    *     Public      *
    *******************/

    /**
     * @dev Mints Collection
     */
    function Mint(uint AMOUNT) public payable nonReentrant
    {
        require(msg.value == PRICE * AMOUNT, "Incorrect ETH Amount Sent");
        require(AMOUNT > 0, "Invalid Amount");
        require(_totalMinted() + AMOUNT <= MAX_NFTS, "Sold Out");
        _mint(msg.sender, AMOUNT);
        emit Minted(msg.sender, AMOUNT, msg.value);
    }

    /****************** 
    *    OnlyOwner    *
    *******************/

    /**
     * @dev Withdraws Ether From Contract To Message Sender
     */
    function __Withdraw() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }

    /**
     * @dev Withdraws Ether From Contract To Address
     */
    function __WithdrawToAddress(address payable recipient) external onlyOwner 
    {
        uint balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Unable to Withdraw, Recipient May Have Reverted");
    }

    /**
     * @dev Withdraws ERC20 From Contract To Address
     */
    function __WithdrawERC20ToAddress(address Recipient, address ContractAddress) external onlyOwner
    {
        IERC20 ERC20 = IERC20(ContractAddress);
        ERC20.transferFrom(address(this), Recipient, ERC20.balanceOf(address(this)));
    }

    /**
     * @dev Sets Base URI
     */
    function __SetBaseURI(string calldata NewBaseURI) external onlyOwner { baseURI = NewBaseURI; }

    /**
     * @dev Changes Price
     */
    function __ChangePrice(uint NewPrice) external onlyOwner { PRICE = NewPrice; }

    /****************** 
    *  INTERNAL VIEW  *
    ******************/

    /**
     * @dev Returns Base URI
     */
    function _baseURI() internal view virtual override returns (string memory) { return baseURI; }
}
