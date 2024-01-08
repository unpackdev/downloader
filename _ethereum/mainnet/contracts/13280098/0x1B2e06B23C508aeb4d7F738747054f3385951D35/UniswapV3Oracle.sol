// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./AccessControl.sol";
import "./IOracle.sol";
import "./CastBytes32Bytes6.sol";
import "./OracleLibrary.sol";
import "./IUniswapV3PoolImmutables.sol";

/**
 * @title UniswapV3Oracle
 */
contract UniswapV3Oracle is IOracle, AccessControl {
    using CastBytes32Bytes6 for bytes32;

    event SecondsAgoSet(uint32 indexed secondsAgo);
    event SourceSet(
        bytes6 indexed base,
        bytes6 indexed quote,
        address indexed source
    );

    struct Source {
        address source;
        bool inverse;
    }

    struct SourceData {
        address factory;
        address baseToken;
        address quoteToken;
        uint24 fee;
    }

    uint32 public secondsAgo = 600;
    mapping(bytes6 => mapping(bytes6 => Source)) public sources;
    mapping(address => SourceData) public sourcesData;

    /// @dev Set or reset the number of seconds Uniswap will use for its Time Weighted Average Price computation
    function setSecondsAgo(uint32 secondsAgo_) external auth {
        require(secondsAgo_ != 0, "Uniswap must look into the past.");
        secondsAgo = secondsAgo_;
        emit SecondsAgoSet(secondsAgo_);
    }

    /// @dev Set or reset an oracle source and its inverse
    function setSource(
        bytes6 base,
        bytes6 quote,
        address source
    ) external auth {
        sources[base][quote] = Source(source, false);
        sources[quote][base] = Source(source, true);
        sourcesData[source] = SourceData(
            IUniswapV3PoolImmutables(source).factory(),
            IUniswapV3PoolImmutables(source).token0(),
            IUniswapV3PoolImmutables(source).token1(),
            IUniswapV3PoolImmutables(source).fee()
        );
        emit SourceSet(base, quote, source);
        emit SourceSet(quote, base, source);
    }

    /// @dev Convert amountBase base into quote at the latest oracle price.
    function peek(
        bytes32 base,
        bytes32 quote,
        uint256 amountBase
    )
        external
        view
        virtual
        override
        returns (uint256 amountQuote, uint256 updateTime)
    {
        return _peek(base.b6(), quote.b6(), amountBase);
    }

    /// @dev Convert amountBase base into quote at the latest oracle price, updating state if necessary. Same as `peek` for this oracle.
    function get(
        bytes32 base,
        bytes32 quote,
        uint256 amountBase
    )
        external
        virtual
        override
        returns (uint256 amountQuote, uint256 updateTime)
    {
        return _peek(base.b6(), quote.b6(), amountBase);
    }

    /// @dev Convert amountBase base into quote at the latest oracle price.
    function _peek(
        bytes6 base,
        bytes6 quote,
        uint256 amountBase
    ) private view returns (uint256 amountQuote, uint256 updateTime) {
        Source memory source = sources[base][quote];
        SourceData memory sourceData;
        require(source.source != address(0), "Source not found");
        sourceData = sourcesData[source.source];
        int24 twapTick = OracleLibrary.consult(source.source, secondsAgo);
        amountQuote = OracleLibrary.getQuoteAtTick(
            twapTick,
            uint128(amountBase),
            (source.inverse) ? sourceData.quoteToken : sourceData.baseToken,
            (source.inverse) ? sourceData.baseToken : sourceData.quoteToken
        );
        updateTime = block.timestamp - secondsAgo;
    }
}
