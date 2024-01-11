//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./ERC721TURD.sol";
contract Moonturds69 is ERC721TURD, Ownable, ReentrancyGuard
{
    bool public _SaleIsActive = false;
    uint public TOTAL_TOKENS_MINTED = 1;
    uint public immutable MAX_TOKENS = 3333;
    string public baseURI = "ipfs://QmX8RxWQa8mRH6NhzdJAcZ3MNJ7ePLs5M3EAFZBNha5bYg/";
    mapping(address=>uint) public Minted;
    constructor() ERC721TURD ("Moonturds69", "Moonturds69") { _safeMint(msg.sender, 1); }
    function MoonturdBingBongAlert42069(uint Amount) external nonReentrant
    {
        require(tx.origin == msg.sender, "You're too smart to be sniping turds");
        require(Amount <= 20, "Incorrect Amount (20 per wallet) AKA Clown Emoji");
        require(Minted[msg.sender] <= 20, "100 Per Wallet Maximum You Turd");
        require(TOTAL_TOKENS_MINTED + Amount <= MAX_TOKENS, "Token Overflow, Cmon");
        require(_SaleIsActive, "Expultion Inactive, Dummy");
        Minted[msg.sender] += Amount;
        TOTAL_TOKENS_MINTED += Amount;
        _mint(msg.sender, Amount, "", false);
    }
    function Withdraw() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }
    function WithdrawToAddress(address payable Recipient) external onlyOwner 
    {
        uint balance = address(this).balance;
        (bool success, ) = Recipient.call{value: balance}("");
        require(success, "Unable to Withdraw, Recipient May Have Reverted");
    }
    function WithdrawERC20ToAddress(address Recipient, address ContractAddress) external onlyOwner
    {
        IERC20 ERC20 = IERC20(ContractAddress);
        ERC20.transferFrom(address(this), Recipient, ERC20.balanceOf(address(this)));
    }
    function FlipSaleState() external onlyOwner { _SaleIsActive = !_SaleIsActive; }
    function setBaseURI(string calldata NewBaseURI) external onlyOwner { baseURI = NewBaseURI; }
    function _baseURI() internal view virtual override returns (string memory) { return baseURI; }
}
