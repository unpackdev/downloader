// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./ERC721A.sol";
import "./AggregatorV3Interface.sol";

contract PrePayTechnoAndChill is Ownable, ERC721A, PaymentSplitter {

    AggregatorV3Interface internal priceFeed;

    using Strings for uint;

    mapping(address => uint) public prepayPerWallet;
    address[] prepayWallet;
    uint prepayBought = 0;
    uint prepayOffered = 0;


    uint public maxPrepayPerWallet = 6;
    uint public prepayPriceUsd = uint(99);
    bool public isPaused;
    uint private teamLength;

    address[] private _team = [
        0xc604E51e78F80BB82cD2f0D1984839EB2d8f21ed
    ];

    uint[] private _teamShares = [
        1000
    ];

    //Constructor
    constructor()
    ERC721A("Prepay Techno And Chill Pass", "PrepayTACPass") 
    PaymentSplitter(_team, _teamShares) {
        teamLength = _team.length;
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

    }


   
    /**
    * @notice This contract can't be called by other contracts
    */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }


    /**
    * @notice prepay function
    *
    * @param _quantity Amount of prepay ther user wants to get
    **/
    function prepay(uint _quantity) external payable callerIsUser {
        require(!isPaused, "Prepay is paused");

        uint priceInEth = getPreOrderPriceEth();

        require(prepayPerWallet[msg.sender] + _quantity <= maxPrepayPerWallet, "You have reached the maximum number of pre-payments");
        require(msg.value >= priceInEth * _quantity, "Not enought funds");

        if(prepayPerWallet[msg.sender] == 0){
            prepayWallet.push(msg.sender);
        }

        prepayBought += _quantity;
        prepayPerWallet[msg.sender] += _quantity;

    }

    /**
    * @notice offerPrepay function
    *
    * @param _quantity Amount of pre-order ther user wants to get
    **/
    function offerPrepay(address _account, uint _quantity) external onlyOwner {

        require(prepayPerWallet[_account] + _quantity <= maxPrepayPerWallet, "You have reached the maximum number of pre-payments");

        if(prepayPerWallet[_account] == 0){
            prepayWallet.push(_account);
        }
        prepayOffered += _quantity;
        prepayPerWallet[_account] += _quantity;

    }


    /**
    * @notice Get Prepayments Wallets
    *
    */
    function getAllPrepayWallet() external view  returns (address[] memory){
        return prepayWallet;
    }


    /**
    * @notice Get Total Prepay Bought
    *
    */
    function getNumberOfPrepayBought() external view  returns (uint){
        return prepayBought;
    }

    /**
    * @notice Get Total Prepay Offered
    *
    */
    function getNumberOfPrepayOffered() external view  returns (uint){
        return prepayOffered;
    }

    /**
    * @notice Get Total Prepay
    *
    */
    function getNumberOfPrepay() external view  returns (uint){
        return prepayOffered + prepayBought;
    }



    /**
    * @notice Allows to set the max per wallet during prepay
    *
    * @param _maxPrepayPerWallet the new max per wallet during prepay
    */
    function setMaxPreOrderPerWallet(uint _maxPrepayPerWallet) external onlyOwner {
        maxPrepayPerWallet = _maxPrepayPerWallet;
    }

    /**
    * @notice Allows to prepay price
    *
    * @param _prepayPriceUsd the new prepay price 
    */
    function setPreOrderPriceUsd(uint _prepayPriceUsd) external onlyOwner {
        prepayPriceUsd = _prepayPriceUsd;
    }

     /**
    * @notice get prepay price
    *
    */
    function getPreOrderPriceEth() public view  returns (uint){ 

        return  uint(prepayPriceUsd * 10**26)/uint(getLatestPrice());
    }


    /**
    * @notice Pause or unpause the smart contract
    *
    * @param _isPaused true or false if we want to pause or unpause the contract
    */
    function setPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }


    function getBalance() public view returns(uint){

        return address(this).balance;
    }
    /**
    * @notice Release the gains on every accounts
    */
    function releaseAll() external {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (uint) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint(price);
    }

    

    //Not allowing receiving ethers outside minting functions
    receive() override external payable {
        revert('Only if you mint');
    }

}