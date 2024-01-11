pragma solidity 0.8.12;

abstract contract Errors {
    error RejectedNullishAddress();
    error RejectedAlreadyInState();
    error InvalidArg(string message);
    error BlacklistedUser();

    error Exchange_Not_The_Token_Owner();
    error Exchange_UnAuthorized_Collection();
    error Exchange_Insufficient_Operator_Privilege();
    error Exchange_Invalid_Nullish_Price();
    error Exchange_Not_Sale_Owner();
    error Exchange_Wrong_Price_Value();
    error Exchange_Listing_Not_Found();
    error Exchange_Rejected_Nullish_Duration();
    error Exchange_Rejected_Nullish_Offer_Value();
    error Exchange_Insufficient_WETH_Allowance(uint256 minAllowance);
    error Exchange_Wrong_Offer_Value(uint256 offerValue);
    error Exchange_Expired_Offer(uint256 expiredAt);
    error Exchange_Unmatched_Quantity(uint256 expected, uint256 received);
    error Exchange_Rejected_Nullish_Quantity();

    error Exchange_Rejected_Genesis_Collection_Only();

    // Reserve Auction
    error Exchange_Invalid_Start_Price(uint256 expected, uint256 received);
    error Exchange_Rejected_Ended_Auction(uint256 endsAt, uint256 current);
    error Exchange_Rejected_Must_Be_5_Percent_Higher(
        uint256 expected,
        uint256 received
    );
    error Exchange_Rejected_Not_Auction_Owner();
    error Exchange_Rejected_Auction_In_Progress();
    error Exchange_Auction_Not_Found();
    error Exchange_Rejected_Auction_Not_Started_Yet();

    error Exchange_Starts_At_Must_Be_In_Future();
    error Exchange_Starts_At_Too_Far();
    error Exchange_Drop_Not_Started_Yet();
}
