// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IX2ETHFactory.sol";
import "./IX2PriceFeed.sol";

contract X2AppOwner {
    address public gov;
    mapping (bytes32 => bool) public marketHashes;

    event CreateMarket(
        address priceFeed,
        uint256 multiplierBasisPoints,
        uint256 maxProfitBasisPoints,
        uint256 fundingDivisor,
        uint256 appFeeBasisPoints,
        address market,
        address bullToken,
        address bearToken,
        address aggregator,
        string note
    );

    modifier onlyGov() {
        require(msg.sender == gov, "X2AppOwner: forbidden");
        _;
    }

    constructor() public {
        gov = msg.sender;
    }

    function setAppFee(address _factory, address _market, uint256 _appFeeBasisPoints) external onlyGov {
        IX2ETHFactory(_factory).setAppFee(_market, _appFeeBasisPoints);
    }

    function createMarket(
        address _factory,
        address _priceFeed,
        uint256 _multiplierBasisPoints,
        string calldata _note
    ) external {
        require(_multiplierBasisPoints % 5000 == 0, "X2AppOwner: invalid multiplierBasisPoints");
        {
        bytes32 marketHash = keccak256(abi.encodePacked(
            _factory,
            _priceFeed,
            _multiplierBasisPoints
        ));
        require(!marketHashes[marketHash], "X2AppOwner: market already created");
        marketHashes[marketHash] = true;
        }

        (address market, address bullToken, address bearToken) = IX2ETHFactory(_factory).createMarket(
            _priceFeed,
            _multiplierBasisPoints,
            9000, // _maxProfitBasisPoints
            5000, // _fundingDivisor
            10 // _appFeeBasisPoints
        );

        emit CreateMarket(
            _priceFeed,
            _multiplierBasisPoints,
            9000,
            5000,
            10,
            market,
            bullToken,
            bearToken,
            IX2PriceFeed(_priceFeed).aggregator(),
            _note
        );
    }
}
