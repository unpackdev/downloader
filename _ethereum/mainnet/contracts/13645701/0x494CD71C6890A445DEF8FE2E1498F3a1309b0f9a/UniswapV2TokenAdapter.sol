// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./UniswapV2Library.sol";
import "./UQ112x112.sol";
import "./BlockVerifier.sol";
import "./MerklePatriciaVerifier.sol";
import "./Rlp.sol";
import "./AccountVerifier.sol";
import "./IUniswapV2Pair.sol";
import "./UniswapV2Library.sol";
import "./SushiswapV2Library.sol";
import "./ICSSRRouter.sol";
import "./ICSSRAdapter.sol";
import "./IGovernanceOwned.sol";

struct ObservedData {
    uint32 reserveTimestamp;
    uint112 reserve0;
    uint112 reserve1;
    uint256 priceData;
    bool denominationTokenIs0;
}

struct BlockData {
    bytes32 stateRoot;
    uint256 blockNumber;
    uint256 blockTimestamp;
}

contract UniswapV2TokenAdapter is ICSSRAdapter {
    IGovernanceOwned public immutable owned;
    ICSSRRouter public immutable cssrRouter;
    address public immutable uniswapFactory;
    address public immutable sushiswapFactory;

    address[] public keyCurrency;
    uint256 public minimumLiquidity;
    uint256 public diffmin;
    uint256 public diffmax;
    
    using UQ112x112 for uint224;

    bytes32 public constant reserveTimestampSlotHash =
        keccak256(abi.encodePacked(uint256(8)));
    bytes32 public constant token0Slot =
        keccak256(abi.encodePacked(uint256(9)));
    bytes32 public constant token1Slot =
        keccak256(abi.encodePacked(uint256(10)));
    mapping(address => bool) public isKeyCurrency;

    modifier onlyGov() {
        require(msg.sender == owned.governance(), "!gov");
        _;
    }

    constructor(
        address _owned,
        address _router,
        address _uniswapFactory,
        address _sushiswapFactory
    ) {
        owned = IGovernanceOwned(_owned);
        cssrRouter = ICSSRRouter(_router);
        uniswapFactory = _uniswapFactory;
        sushiswapFactory = _sushiswapFactory;
        diffmin = 50;
        diffmax = 100;
    }

    function addKeyCurrency(address[] calldata _currencies) external onlyGov {
        for(uint256 i = 0; i < _currencies.length; i++){
            isKeyCurrency[_currencies[i]] = true;
        }
    }

    function changeDiffRange(uint256 _min, uint256 _max) external onlyGov {
        diffmin = _min;
        diffmax = _max;
    }

    function removeKeyCurrency(address[] calldata _currencies)
        external
        onlyGov
    {
        for(uint256 i = 0; i < _currencies.length; i++){
            isKeyCurrency[_currencies[i]] = false;
        }
    }

    function setMinimumLiquidity(uint256 _liquidity)
        external
        onlyGov
    {
        minimumLiquidity = _liquidity;
    }

    function support(address _asset) external view override returns (bool) {
        return true;
    }

    function update(address _asset, bytes memory _data)
        external
        override
        returns (float memory)
    {
        (address pair, address p, ObservedData memory historicData, BlockData memory blockData) = parseData(_asset, _data);
        uint256 price = convertToValue(
            getExchangeRatio(blockData.blockTimestamp, IUniswapV2Pair(pair), _asset, p, historicData),
            cssrRouter.getPrice(p)
        ); 
        return float({numerator: price , denominator: 1<<112});
    }

    function parseData(address _asset, bytes memory _data) internal returns(address pair, address key, ObservedData memory historicData, BlockData memory blockData) {
        (uint256 cssrType, bytes memory data) = abi.decode(_data, (uint256, bytes));
        (
            address p,
            bytes memory bd,
            bytes memory ap,
            bytes memory rp,
            bytes memory pp0,
            bytes memory pp1
        ) = abi.decode(data, (address, bytes, bytes, bytes, bytes, bytes));
        key = p;
        require(isKeyCurrency[p], "!keyCurrency");
        blockData = getBlockData(bd);
        {
        uint256 diff = block.number - blockData.blockNumber;
        require(diff >= diffmin && diff <= diffmax, "block out of bound");
        }
        if(cssrType == 0) {
            pair = UniswapV2Library.pairFor(
                uniswapFactory,
                _asset,
                key
            );
        } else if(cssrType == 1) {
            pair = SushiswapV2Library.pairFor(
                sushiswapFactory,
                _asset,
                key
            );
        } else {
            revert("!supported type");
        }
        historicData = getReserveData(blockData.stateRoot, pair, p, ap, rp, pp0, pp1);
    }

    function getBlockData(bytes memory blockData) internal view returns(BlockData memory data){
        (data.stateRoot, data.blockTimestamp, data.blockNumber) = BlockVerifier
            .extractStateRootAndTimestamp(blockData);
    }
    
    function getReserveData(
        bytes32 stateRoot,
        address pair,
        address denominator,
        bytes memory accountProof,
        bytes memory reserveProof,
        bytes memory price0Proof,
        bytes memory price1Proof
    ) internal view returns (ObservedData memory data) {
        bytes32 storageRoot = AccountVerifier.getAccountStorageRoot(
            pair,
            stateRoot,
            accountProof
        );
        (
            data.reserve0,
            data.reserve1,
            data.reserveTimestamp
        ) = unpackReserveData(
            Rlp.rlpBytesToUint256(
                MerklePatriciaVerifier.getValueFromProof(
                    storageRoot,
                    reserveTimestampSlotHash,
                    reserveProof
                )
            )
        );
        if (IUniswapV2Pair(pair).token0() == denominator) {
            data.denominationTokenIs0 = true;
        } else if (IUniswapV2Pair(pair).token1() == denominator) {
            data.denominationTokenIs0 = false;
        } else {
            revert("weird...");
        }
        if(data.denominationTokenIs0){
            data.priceData = Rlp.rlpBytesToUint256(
                MerklePatriciaVerifier.getValueFromProof(
                    storageRoot,
                    token1Slot,
                    price1Proof
                )
            );
        } else {
            data.priceData = Rlp.rlpBytesToUint256(
                MerklePatriciaVerifier.getValueFromProof(
                    storageRoot,
                    token0Slot,
                    price0Proof
                )
            );
        }
    }
    
    function unpackReserveData(uint256 packedReserveData)
        internal
        pure
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 reserveTimestamp
        )
    {
        reserve0 = uint112(packedReserveData & ((1<<112) - 1));
        reserve1 = uint112((packedReserveData >> 112) & ((1<<112) - 1));
        reserveTimestamp = uint32(packedReserveData >> (112 + 112));
    }

    function getExchangeRatio(
        uint256 blockTimestamp,
        IUniswapV2Pair pair,
        address token,
        address denominator,
        ObservedData memory historicData
    ) internal view returns(uint256) {
        float memory denPrice = cssrRouter.getPrice(denominator);
        uint256 historicePriceCumulative = calculatedPriceCumulative(
            historicData.denominationTokenIs0
                ? historicData.reserve0
                : historicData.reserve1,
            historicData.denominationTokenIs0
                ? historicData.reserve1
                : historicData.reserve0,
            historicData.priceData,
            blockTimestamp - uint256(historicData.reserveTimestamp)
        );
        require(convertToValue(historicData.denominationTokenIs0? historicData.reserve0 : historicData.reserve1, denPrice) >minimumLiquidity, "<liquidity");
        //get current data
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair
            .getReserves();
        uint256 currentPriceCumulative = calculatedPriceCumulative(
            historicData.denominationTokenIs0 ? reserve0 : reserve1,
            historicData.denominationTokenIs0 ? reserve1 : reserve0,
            historicData.denominationTokenIs0
                ? pair.price1CumulativeLast()
                : pair.price0CumulativeLast(),
            block.timestamp - blockTimestampLast
        );
        require(convertToValue(historicData.denominationTokenIs0? reserve0 : reserve1, denPrice) >minimumLiquidity, "<liquidity");
        return
            (currentPriceCumulative - historicePriceCumulative) /
            (block.timestamp - blockTimestamp);
    }
    
    function calculatedPriceCumulative(
        uint112 reserve,
        uint112 pairedReserve,
        uint256 priceCumulativeLast,
        uint256 timeElapsed
    ) internal pure returns (uint256) {
        if (timeElapsed == 0) {
            return priceCumulativeLast;
        }
        return
            priceCumulativeLast +
            timeElapsed *
            uint256(UQ112x112.encode(reserve).uqdiv(pairedReserve));
    }

    function getPrice(address _asset)
        public
        view
        override
        returns (float memory price)
    {
        revert("not supported");
    }

    function getLiquidity(address _asset)
        external
        view
        override
        returns (uint256 sum)
    {
        revert("not supported");
    }

    function convertToValue(uint256 _amount, float memory _price)
        internal
        pure
        returns (uint256)
    {
        return (_amount * _price.numerator) / _price.denominator;
    }
}
