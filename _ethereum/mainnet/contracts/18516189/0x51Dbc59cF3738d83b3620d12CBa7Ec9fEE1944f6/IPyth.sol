pragma solidity ^0.8.17;

interface IPyth {
    struct Price {
        int64 price; // Price
        uint64 conf; // Confidence interval around the price
        int32 expo; // Price exponent
        uint256 publishTime; // Unix timestamp describing when the price was published
    }

    function getPriceUnsafe(bytes32 id) external view returns (Price memory price);
    function getPrice(bytes32 id) external view returns (Price memory price);
}
