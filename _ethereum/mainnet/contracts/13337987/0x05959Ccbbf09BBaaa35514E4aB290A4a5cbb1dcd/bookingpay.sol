// SPDX-License-Identifier: MIT

/**
 * 
Definition	            Total Supply for 2 Blockchains	            %PERC 	ETHEREUM	    BINANCE SMART CHAIN
	                    1.000.000.000		                                500.000.000     500.000.000
	                    
Community Sale Account	0x4Ab96f99DA819443291F0e9e7CB15cf647535674	45	    225.000.000	    225.000.000 
Reserve Fund	        0xA82A14a753E56a7a87Ef6d502FfFD221642074e6	13	    65.000.000	    65.000.000
Team and Founders	    0x6B29B1Cd517ECC89924f86bafE0E2cB76dBa7Cf9	10	    50.000.000	    50.000.000
Marketing and Bounty	0x283403Df720b27A7967e5e11bD267808c20267A3	10	    50.000.000	    50.000.000
Ecosystem Development	0x6E1Ba728D93e4D32b25875a5dF2CEecc761F3275	8	    40.000.000	    40.000.000
Board Advisors	        0x6754531F32233653Bd8b54959cd3b565f1299A07	4	    20.000.000	    20.000.000

Public Sale 1           Address: Buyers Address                     10      50.000.000      50.000.000

We are going to build a bridge from ethereum to - bsc network to transfer tokens between 2 blockchains.
Burned amount from from one chain, is going to be minted to burner address on other chain.
Total token amount of 2 Blockchains is limited to maxSupply 1.000.000.000 token.
Public sale is One time event for fundraising. It is not going to be repeated.
Public Sale Dates planned 01 Oct 2021 - 31 Oct 2021. Interval changes will be announced at https://bookingpay.network
* */

pragma solidity ^0.8.2;
import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";

contract BPN  is ERC20, Ownable, ERC20Burnable { 
    bool    public isPublicSaleActive   = false;
    uint256 public maxMintForPublicSale = 50  * 10 ** 6 * 10 ** decimals(); //50.000.000 Token
    uint256 public mintedForPublicSale  = 0;                //How Many tokens minted for public sale purchase. It is increased by amount after every purchase.
    uint256 public publicSalePrice      = 40000000000000;  //0.00004 ether - 1 BPN for 40000000000000 wei -  1BPN = approx 0.12 USDT 
    uint256 public constant maxSupply   = 1000000000 * 10 ** 18;//maxSupply = 1.000.0000.0000 Token;

    constructor() ERC20("BookingPay Network", "BPN") payable {
        _mint(0x4Ab96f99DA819443291F0e9e7CB15cf647535674,   225 * 10 ** 6 * 10 ** decimals());      //Community Sale        %45 For Listing On A Market
        _mint(0xA82A14a753E56a7a87Ef6d502FfFD221642074e6,   65  * 10 ** 6 * 10 ** decimals());      //Reserve Fund          %13
        _mint(0x6B29B1Cd517ECC89924f86bafE0E2cB76dBa7Cf9,   50  * 10 ** 6 * 10 ** decimals());      //Team and Founders     %10
        _mint(0x283403Df720b27A7967e5e11bD267808c20267A3,   50  * 10 ** 6 * 10 ** decimals());      //Marketing and Bounty  %10
        _mint(0x6E1Ba728D93e4D32b25875a5dF2CEecc761F3275,   40  * 10 ** 6 * 10 ** decimals());      //Ecosystem Development %8
        _mint(0x6754531F32233653Bd8b54959cd3b565f1299A07,   20  * 10 ** 6 * 10 ** decimals());      //Board Advisors        %4
      //_mint to Purchasers' address during public sale.    50  * 10 ** 6 * 10 ** decimals()        //Public Sale           %10    
    }

    /**
     * @dev Public Token Sale  
     * Firstly check whether Public Sale is active.
     * Calculate Bpn Token amount for sent value.
     * Check if max minted token amount for public sale is reached.
     * If Not Reached, mint token to sender's address.
     * When reached at maxMintForPublicSale purchase amount, end public sale..
     */
    function BuyTokenFromPublicSale() public payable {
        require(isPublicSaleActive,"Public Sale Is Not Active!");
        require(msg.value > 0, "Sent amount must be bigger than Zero (0)!");
        uint256 amountTobuy = (msg.value * 10 ** decimals() ) / publicSalePrice;
        require( amountTobuy <= getLeftTokenForPublicSale(),"Max Token Minted For Public Sale. Goal Reached & Public Sale Ended!");
        _mint(msg.sender, amountTobuy);
        mintedForPublicSale += amountTobuy;  // Increment Total Minted Token to check max mint reached. 
    }
    
    /**
     * @dev Minting Token
     * Prevent Minting token over 1.000.000.000 
     * Max Supply is 1 Billion Token 1.000.000.000 
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(amount+totalSupply()<=maxSupply,"Maximum Token Supply is 1.000.000.000!");
        _mint(to, amount); 
    }

    /**
     * Get Token Amont Left for Public Token Sale.
     * Max mintable token amount 50.000.000 for public sale.
     * When reached at 50.000.000 purchase amount, public sale is over.
    */
    function getLeftTokenForPublicSale() public view returns (uint256){
        return (maxMintForPublicSale - mintedForPublicSale);
    }

    /**
     * @dev Set Public Sale Price 
     * Check Fluctations on markets and 
     * set the publicSalePrice to apprx. 0.1 USDT During Public Sale Period.
     */
    function setPublicSalePrice(uint256 _pubSalePrice) external onlyOwner{
        publicSalePrice = _pubSalePrice;
    }

    /**
     * @dev 
     * Contrat itself, can respond to payments and send tokens. 
     * A user can easily send transaction from his metamask wallet and get tokens easily.
     * If Public Sale not started or finished, Eth transactions is reverted with errors. It is very safe.
     * Even if a user send ether accidentally , Equalent amount of token will be minted to his wallet, and he purchase will be completed.
     */
    receive() external payable {
         if(isPublicSaleActive){
            BuyTokenFromPublicSale();
        }else{
            revert("Public Sale is Not Acive!");
        }
    }
    
    /**
     * @dev 
     * This function starts and finishes public sale.
     */
    function setPublicSaleStatus(bool status) public onlyOwner (){
        isPublicSaleActive = status;
    }

    /**
     * @dev 
     * This is the function to transfer funds between accounts. 
     */    
    function TransferFunds(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }
    
}