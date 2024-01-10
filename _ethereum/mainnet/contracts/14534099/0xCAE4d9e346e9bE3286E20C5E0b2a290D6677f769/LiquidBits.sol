//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./ERC721R.sol";

contract LiquidBits is ERC721R, Ownable, ReentrancyGuard
{
    string public baseURI = "ipfs://QmXbvakU6xhzyfEUZtS2UzC1jBUZgXd9Pjou5jVF97QXCB/";

    /**
     * @dev Constructor 
     */
    constructor() ERC721R("Liquid Bits", "Liquid Bits") { }

    /****************** 
    *    OnlyMinter   *
    *******************/

    /**
     * @dev Mints NFTs
     */
    function _Mint(address Recipient) external onlyOwner { _mint(Recipient, 1, "", false); }

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
    function __WithdrawToAddress(address payable Recipient) external onlyOwner 
    {
        uint balance = address(this).balance;
        (bool success, ) = Recipient.call{value: balance}("");
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
    function __setBaseURI(string calldata NewBaseURI) external onlyOwner { baseURI = NewBaseURI; }

    /****************** 
    *  INTERNAL VIEW  *
    ******************/

    /**
     * @dev Returns Base URI
     */
    function _baseURI() internal view virtual override returns (string memory) { return baseURI; }
}
