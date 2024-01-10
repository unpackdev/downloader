// Deployed to Mainnet Date: 3/12/22
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

// Get the latest ETH/USD price from chainlink price feed
import "./AggregatorV3Interface.sol";
import "./SafeMathChainlink.sol";

contract MyStorage {
    // safe math library check uint256 for integer overflows
    using SafeMathChainlink for uint256;

    mapping(address => uint256) private addressToAmountFunded;

    address[] private funders;

    //address of the owner (who deployed the contract)
    address private owner;

    // the first person to deploy the contract is
    // the owner
    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        bool exist = false;
        addressToAmountFunded[msg.sender] += msg.value;
        for (uint256 funderIndex = 0;funderIndex < funders.length;funderIndex++) {
            if (msg.sender == funders[funderIndex]) exist = true;
        }

        if (exist == false) funders.push(msg.sender);
    }

    function getFirstFunder() public view returns (address) {
        return funders[0];
    }

    function getLastFunder() public view returns (address) {
        uint256 num = 1;
        uint256 lastFunderIndex = funders.length - num;
        return funders[lastFunderIndex];
    }

    function getFirstFunderAmount() public view returns (uint256) {
        return addressToAmountFunded[funders[0]];
    }

    function getLastFunderAmount() public view returns (uint256) {
        uint256 num = 1;
        uint256 lastFunderIndex = funders.length - num;
        return addressToAmountFunded[funders[lastFunderIndex]];
    }

    function getTotalFunders() public view returns (uint256) {
        return funders.length;
    }

    function getTotalFundedAmount() public view returns (uint256) {
        uint256 totalFund = 0;
        for (uint256 funderIndex = 0;funderIndex < funders.length;funderIndex++) {
            address funder = funders[funderIndex];
            totalFund += addressToAmountFunded[funder];
        }
        return totalFund;
    }

    function getETHprice() public view returns (uint256) {
        // Rinkeby Test Network
       // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

        // Ethereum Mainnet
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getETHpriceUSD() public view returns (uint256) {
        uint256 ethPrice = getETHprice();
        uint256 ethAmountInUsd = ethPrice / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }

    //modifier: https://medium.com/coinmonks/solidity-tutorial-all-about-modifiers-a86cf81c14cb
    modifier onlyOwner() {
        //is the message sender owner of the contract?
        require(msg.sender == owner);
        _;
    }

    // onlyOwner modifer will first check the condition inside it
    // and
    // if true, withdraw function will be executed
    function withdraw() public payable onlyOwner {
        // If you are using version eight (v0.8) of chainlink aggregator interface,
        // you will need to change the code below to
        payable(msg.sender).transfer(address(this).balance);
        //msg.sender.transfer(address(this).balance);

        //iterate through all the mappings and make them 0
        //since all the deposited amount has been withdrawn
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //funders array will be initialized to 0
        funders = new address[](0);
    }
}
