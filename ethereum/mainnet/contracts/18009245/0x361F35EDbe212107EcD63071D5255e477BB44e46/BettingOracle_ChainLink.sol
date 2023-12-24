// SPDX-License-Identifier: BUSL-1.1
//0x3e05F982b2C85dD787b6f6d0652724a6791b87B0
//0x6f5Fa8eAe31C5b6c63014042dc1B120987BdbcD2

//main contract for oracle
//0x361F35EDbe212107EcD63071D5255e477BB44e46

pragma solidity ^0.8.12;

import "./AggregatorV3Interface.sol";

contract BettingOracle_ChainLink {
    address public developer;

    AggregatorV3Interface internal priceFeed;

    struct ChainLink_Price_Feed_Contract_Addresses {
        uint256 id;
        address token_address;
        address ENS_address;
        AggregatorV3Interface this_priceFeed;
        uint ENS_address_decimails;
        bool valid;
    }

    mapping(uint256 => ChainLink_Price_Feed_Contract_Addresses)
        public token_address_in_contract_addresses;

    uint256 public ContractAddresses_Id;
    uint256 public current_ContractAddresses_Id;

    /*
    struct TokenPrice {
        uint256 id;
        address token_address;
        address ENS_address;
        uint80 roundID;
        uint256 Timestamp;
        int price;
    }

    mapping(uint256 => TokenPrice) public Token_Price;  

    uint256 public TokenPrice_Id;
    */
    uint public returned_target_price;
    int256 public target_price;
    uint80 public target_roundID;

    /**
     * Network: Sepolia
     * Aggregator: ETH/USD
     * Address:	0x694AA1769357215DE4FAC081bf1f309aDC325306
     */
    /**
     * Network: Sepolia
     * Aggregator: BTC/USD
     * Address: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
     */
    /**
     * Network: Sepolia
     * Aggregator: USDC / USD
     * Address: 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E
     */
    constructor() {
        developer = msg.sender;
    }

    /**
     * to add ChainLink ENS address into struct ChainLink_Price_Feed_Contract_Addresses.
     * parameters:
     * token_address:supported ERC20 token.
     * ENS_address: https://docs.chain.link/data-feeds/price-feeds/addresses
     */
    function add_ENS_address(
        address token_address,
        address ENS_address
    ) public returns (uint256) {
        require(developer == msg.sender, "only developer can add ENS address!");

        ContractAddresses_Id++;

        AggregatorV3Interface this_priceFeed = AggregatorV3Interface(
            ENS_address
        );

        uint ENS_address_decimails = this_priceFeed.decimals();

        ChainLink_Price_Feed_Contract_Addresses
            storage new_ChainLink_Price_Feed_Contract_Addresses = token_address_in_contract_addresses[
                ContractAddresses_Id
            ];
        new_ChainLink_Price_Feed_Contract_Addresses.id = ContractAddresses_Id;
        new_ChainLink_Price_Feed_Contract_Addresses
            .token_address = token_address;
        new_ChainLink_Price_Feed_Contract_Addresses.ENS_address = ENS_address;
        new_ChainLink_Price_Feed_Contract_Addresses
            .this_priceFeed = this_priceFeed;
        new_ChainLink_Price_Feed_Contract_Addresses
            .ENS_address_decimails = ENS_address_decimails;
        new_ChainLink_Price_Feed_Contract_Addresses.valid = true;

        return ContractAddresses_Id;
    }

    /**
     * to set ChainLink ENS address for current price feed query of indicated token address.
     * parameters:
     * token_address:supported ERC20 token address in struct ChainLink_Price_Feed_Contract_Addresses.
     * returns: AggregatorV3Interface object
     */
    function set_ENS_address(
        address token_address
    ) public returns (AggregatorV3Interface) {
        if (
            current_ContractAddresses_Id != 0 &&
            token_address_in_contract_addresses[current_ContractAddresses_Id]
                .token_address ==
            token_address
        ) {
            return
                token_address_in_contract_addresses[
                    current_ContractAddresses_Id
                ].this_priceFeed;
        } else {
            bool priceFeed_exist = false;

            for (uint256 i = 0; i <= ContractAddresses_Id; i++) {
                if (
                    token_address_in_contract_addresses[i].token_address ==
                    token_address &&
                    token_address_in_contract_addresses[i].valid == true
                ) {
                    priceFeed = token_address_in_contract_addresses[i]
                        .this_priceFeed;
                    current_ContractAddresses_Id = i;
                    priceFeed_exist = true;
                }
            }

            require(
                priceFeed_exist == true,
                "token address is not supported @ set_ENS_address()!"
            );

            return priceFeed;
        }
    }

    /**
     * to update ChainLink ENS address in struct ChainLink_Price_Feed_Contract_Addresses.
     * parameters:
     * id: id of ChainLink_Price_Feed_Contract_Addresses
     * token_address:supported ERC20 token in the ChainLink_Price_Feed_Contract_Addresses.
     * ENS_address: https://docs.chain.link/data-feeds/price-feeds/addresses
     * valid: valid or not for this address in the ChainLink_Price_Feed_Contract_Addresses.
     */
    function update_ENS_address(
        uint256 id,
        address token_address,
        address ENS_address,
        bool valid
    ) public {
        require(
            developer == msg.sender,
            "only developer can update ENS address!"
        );

        AggregatorV3Interface this_priceFeed = AggregatorV3Interface(
            ENS_address
        );

        uint ENS_address_decimails = this_priceFeed.decimals();

        token_address_in_contract_addresses[id].token_address = token_address;
        token_address_in_contract_addresses[id].ENS_address = ENS_address;
        token_address_in_contract_addresses[id].this_priceFeed = this_priceFeed;
        token_address_in_contract_addresses[id]
            .ENS_address_decimails = ENS_address_decimails;
        token_address_in_contract_addresses[id].valid = valid;
    }

    /**
     * Returns the round data.
     */
    function getRoundData(
        uint80 _roundId
    ) public view returns (uint80, int256, uint256, uint256, uint80) {
        // prettier-ignore
        (
            uint80 roundID,
            int256 answer,
            uint startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.getRoundData(_roundId);
        return (roundID, answer, startedAt, updatedAt, answeredInRound);
    }

    /**
     * Returns the latest price.
     */
    function getLatestPrice()
        public
        view
        returns (uint80, int, uint, uint, uint80)
    {
        // prettier-ignore
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        return (roundID, price, startedAt, timeStamp, answeredInRound);
    }

    /**
     * to add last price from ChainLink price feed into struct TokenPrice
     * parameters:
     * token_address:supported ERC20 token in the ChainLink_Price_Feed_Contract_Addresses.
     * returns:
     * priceFeed.latestRoundData object
     * uint80 roundID, int price, uint startedAt,uint timeStamp, uint80 answeredInRound
     */
    /*
    function add_last_token_price(address token_address) public returns (uint80, int, uint, uint,uint80) {

        priceFeed = set_ENS_address(token_address);

        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = getLatestPrice();

        bool exist = false;

        for (uint256 i = 0; i <= TokenPrice_Id; i++) {
            
            if( Token_Price[i].token_address == token_address && Token_Price[i].roundID == roundID ) {

                exist = true;

                break;

            }

        }

        if(exist == false){

            TokenPrice_Id++;
    

            TokenPrice storage new_Token_Price = Token_Price[TokenPrice_Id];
            new_Token_Price.id = TokenPrice_Id;
            new_Token_Price.token_address = token_address_in_contract_addresses[current_ContractAddresses_Id].token_address;
            new_Token_Price.ENS_address = token_address_in_contract_addresses[current_ContractAddresses_Id].ENS_address;
            new_Token_Price.roundID = roundID;
            new_Token_Price.Timestamp = timeStamp;
            new_Token_Price.price = price;


        }

        return (roundID, price, startedAt,timeStamp, answeredInRound );

        

    }
    */

    /**
     * Returns historical price for a round id.
     * roundId is NOT incremental. Not all roundIds are valid.
     * You must know a valid roundId before consuming historical data.
     *
     * ROUNDID VALUES:
     *    InValid:      18446744073709562300
     *    Valid:        18446744073709554683
     *
     * @dev A timestamp with zero value means the round is not complete and should not be used.
     */
    function getHistoricalPrice(
        uint80 roundId
    ) public view returns (int256, uint) {
        // prettier-ignore
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            uint timeStamp,
            /*uint80 answeredInRound*/
        ) = priceFeed.getRoundData(roundId);
        //require(timeStamp > 0, "Round not complete");
        if (timeStamp == 0) {
            price = 0;
        }
        return (price, timeStamp);
    }

    /**
     * to fetch the price from ChainLink price feed of specified timeStamp
     * parameters:
     * token_address:supported ERC20 token in the ChainLink_Price_Feed_Contract_Addresses.
     * timeStamp:preffered timestamp.
     * token_decimails:token_decimails of supported ERC20 token
     * returns:
     * priceFeed.getRoundData() object by roundId
     * int256 price.
     * uint80 timeStamp.
     */
    function fetch_closest_price_to_timestamp(
        address token_address,
        uint timeStamp,
        uint token_decimails
    ) public returns (uint256, uint80) {
        set_ENS_address(token_address);

        uint80 roundID;
        int price;
        uint startedAt;
        uint last_timeStamp;
        uint80 answeredInRound;

        /*first get roundID of last price*/
        (
            roundID,
            price,
            startedAt,
            last_timeStamp,
            answeredInRound
        ) = getLatestPrice();

        /*use roundID of last price to find old data*/
        bool found = false;
        uint80 next_roundID = roundID;
        uint ENS_address_decimails;

        int next_price;
        uint next_timeStamp;

        while (found == false) {
            (next_price, next_timeStamp) = getHistoricalPrice(next_roundID);

            target_price = next_price;
            target_roundID = next_roundID;

            /*find the smallest timestamp_difference, means closest timestamp to the target*/
            if (
                next_timeStamp <= timeStamp &&
                next_timeStamp > 0 &&
                next_price > 0
            ) {
                ENS_address_decimails = token_address_in_contract_addresses[
                    current_ContractAddresses_Id
                ].ENS_address_decimails;
                found = true;
                break;
            }

            next_roundID--;
        }

        /* calculates correct deciamls */
        uint correct_decimals = token_decimails - ENS_address_decimails;
        returned_target_price = uint(target_price) * (10 ** correct_decimals);

        return (returned_target_price, target_roundID);
    }
}