// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

/**
 * @author radek.hecl
 * @title Cryptoverse BIT contract.
 */
contract CryptoverseBit is ERC1155, Ownable {

    /**
     * Emitted when prediction is submitted to the chain.
     */
    event PredictionMinted(address indexed player, uint256 tokenId, string series, uint256 seriesNumber, string nickname,
        uint64 lucky, uint64 predict_1, uint64 predict_2, uint64 predict_3, uint64 predict_4, uint64 predict_5, uint64 predict_6);

    /**
     * Emitted when result is submitted to the chain.
     */
    event ResultSet(address indexed operator, uint256 tokenId, string series, uint64 result_0, uint64 result_1, uint64 result_2, uint64 result_3, uint64 result_4, uint64 result_5, uint64 result_6);

    /**
     * Emitted when series is set.
     */
    event SeriesSet(address indexed operator, string series, uint256 limit, uint256 mintPrice);

    /**
     * Prediction structure.
     */
    struct Prediction {
        uint256 timestamp;
        string series;
        uint256 seriesNumber;
        string nickname;
        uint64 lucky;
        uint64 predict_1;
        uint64 predict_2;
        uint64 predict_3;
        uint64 predict_4;
        uint64 predict_5;
        uint64 predict_6;
    }

    /**
     * Result structure.
     */
    struct Result {
        uint64 result_0;
        uint64 result_1;
        uint64 result_2;
        uint64 result_3;
        uint64 result_4;
        uint64 result_5;
        uint64 result_6;
    }
        
    /**
     * Result with score structure.
     */
    struct ScoredResult {
        uint64 totalScore;
        uint64 result_0;
        uint64 result_1;
        uint64 score_1;
        uint64 result_2;
        uint64 score_2;
        uint64 result_3;
        uint64 score_3;
        uint64 result_4;
        uint64 score_4;
        uint64 result_5;
        uint64 score_5;
        uint64 result_6;
        uint64 score_6;
    }


    /**
     * Name for contract identification.
     */
    string private _name;

    /**
     * Number of decimals.
     */
    uint8 private _numDecimals;

    /**
     * Total number of tokens minted so far.
     */
    uint256 private _numTokens;
    
    /**
     * Mapping from token ID to predictions.
     */
    mapping(uint256 => Prediction) private _predictions;

    /**
     * Mapping from token ID to results.
     */
    mapping(uint256 => Result) private _results;

    /**
     * Mapping from series to the maximum amounts that can be minted.
     */
    mapping(string => uint256) private _seriesLimits;

    /**
     * Mapping from series to the mint prices.
     */
    mapping(string => uint256) private _seriesMintPrices;

    /**
     * Mapping from series to the number of so far minted tokens.
     */
    mapping(string => uint256) private _seriesMints;

    /**
     * Creates new instance.
     *
     * @param name_ contract name
     * @param numDecimals_ number of decimals this contract operates with
     */
    constructor(string memory name_, uint8 numDecimals_) ERC1155("") {
        _name = name_;
        _numDecimals = numDecimals_;
    }

    /**
     * Returns the contract name.
     *
     * @return contract name
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * Returns the number of decimal places this contract work with.
     *
     * @return number of decimal points this contract work with
     */
    function numDecimals() public view returns (uint8) {
        return _numDecimals;
    }
    
    /**
     * Sets uri base.
     *
     * @param uriBase uri base
     */
    function setUriBase(string memory uriBase) public onlyOwner {
        _setURI(uriBase);
    }
    
    /**
     * Return uri.
     *
     * @param tokenId token id
     * @return token url
     */
    function uri(uint256 tokenId) public override view returns (string memory) {
      return strConcat(
        super.uri(tokenId),
        Strings.toString(tokenId)
      );
    }
    
    /**
     * Sets series limit.
     *
     * @param series series name
     * @param limit limit of the tokens that can be under this series
     * @param mintPrice price to mint the token
     */
    function setSeries(string memory series, uint256 limit, uint256 mintPrice) public onlyOwner {
        require(bytes(series).length > bytes("").length, "series cannot be empty string");
        _seriesLimits[series] = limit;
        _seriesMintPrices[series] = mintPrice;
        emit SeriesSet(msg.sender, series, limit, mintPrice);
    }

    /**
     * Returns the series limit.
     *
     * @param series series name
     * @return series limit
     */
    function seriesLimit(string memory series) public view returns (uint256) {
        return _seriesLimits[series];
    }

    /**
     * Returns the series mint prices.
     *
     * @param series series name
     * @return series mint price
     */
    function seriesMintPrice(string memory series) public view returns (uint256) {
        return _seriesMintPrices[series];
    }

    /**
     * Returns the number of mints for series.
     *
     * @param series series name
     * @return number of mints already done withing the series
     */
    function seriesMints(string memory series) public view returns (uint256) {
        return _seriesMints[series];
    }
    
    /**
     * Mints the token with predictions. This method will produce the logs so the user can find out the tokenId once transaction is written to the chain.
     *
     * @param series series name
     * @param nickname space for user to put the identifier
     * @param predict_1 prediction 1
     * @param predict_2 prediction 2
     * @param predict_3 prediction 3
     * @param predict_4 prediction 4
     * @param predict_5 prediction 5
     * @param predict_6 prediction 6
     *
     */
     function mint(string memory series, string memory nickname, uint64 predict_1, uint64 predict_2, uint64 predict_3, uint64 predict_4, uint64 predict_5, uint64 predict_6)
        public payable
    {   
        require(_seriesMints[series] < _seriesLimits[series], "Series limit has been reached");
        require(msg.value == _seriesMintPrices[series], "ETH value does not match the series mint price");
        bytes memory b = new bytes(0);
        _mint(msg.sender, _numTokens, 1, b);
        uint64 luck = generateLuckyNum(_numTokens, _numDecimals);
        uint256 seriesNumber = _seriesMints[series] + 1;
        _predictions[_numTokens] = Prediction(block.timestamp, series, seriesNumber, nickname, luck, predict_1, predict_2, predict_3, predict_4, predict_5, predict_6);
        emit PredictionMinted(msg.sender, _numTokens, series, seriesNumber, nickname, luck, predict_1, predict_2, predict_3, predict_4, predict_5, predict_6);
        _numTokens = _numTokens + 1;
        _seriesMints[series] = seriesNumber;
    }    
    
    /**
     *
     * Sets the result for the given token.
     *
     * @param tokenId token id
     * @param result_0 the actual value at the time of when prediction had been written to the chain
     * @param result_1 the actual value to the prediction_1
     * @param result_2 the actual value to the prediction_2
     * @param result_3 the actual value to the prediction_3
     * @param result_4 the actual value to the prediction_4
     * @param result_5 the actual value to the prediction_5
     * @param result_6 the actual value to the prediction_6
     */
     function setResult(uint256 tokenId, uint64 result_0, uint64 result_1, uint64 result_2, uint64 result_3, uint64 result_4, uint64 result_5, uint64 result_6)
        public onlyOwner
    {
        require(bytes(_predictions[tokenId].series).length > bytes("").length, "prediction must be minted before result can be set");
        _results[tokenId] = Result(result_0, result_1, result_2, result_3, result_4, result_5, result_6);
        emit ResultSet(msg.sender, tokenId, _predictions[tokenId].series, result_0, result_1, result_2, result_3, result_4, result_5, result_6);
    }
    
    /**
     * Returns the prediction data under the specified token.
     *
     * @param tokenId token id
     * @return prediction data for the given token
     */
    function prediction(uint256 tokenId) public view returns (Prediction memory) {
        return _predictions[tokenId];
    }

    /**
     * Returns the result data under the specified token.
     *
     * @param tokenId token id
     * @return result data for the given token
     */
    function result(uint256 tokenId) public view returns (ScoredResult memory) {
        uint64 score_1 = calculateScore(_predictions[tokenId].predict_1, _results[tokenId].result_1, _numDecimals);
        uint64 score_2 = calculateScore(_predictions[tokenId].predict_2, _results[tokenId].result_2, _numDecimals);
        uint64 score_3 = calculateScore(_predictions[tokenId].predict_3, _results[tokenId].result_3, _numDecimals);
        uint64 score_4 = calculateScore(_predictions[tokenId].predict_4, _results[tokenId].result_4, _numDecimals);
        uint64 score_5 = calculateScore(_predictions[tokenId].predict_5, _results[tokenId].result_5, _numDecimals);
        uint64 score_6 = calculateScore(_predictions[tokenId].predict_6, _results[tokenId].result_6, _numDecimals);
        uint64 totalScore = calculateTotalScore(score_1, score_2, score_3, score_4, score_5, score_6);
        return ScoredResult(totalScore, _results[tokenId].result_0,
            _results[tokenId].result_1, score_1,
            _results[tokenId].result_2, score_2,
            _results[tokenId].result_3, score_3,
            _results[tokenId].result_4, score_4,
            _results[tokenId].result_5, score_5,
            _results[tokenId].result_6, score_6);

    }

    /**
     * Returns balance of this contract.
     *
     * @return contract balance
     */
    function balance() public view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * Withdraws the balance.
     */
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    /**
     * Generates lucky number. This is a pseudo random number. This is 0-100% (bounds included), with the given number of decimals.
     *
     * @param seed seed number
     * @param nd number of decimal points to work with
     * @return generated number
     */
    function generateLuckyNum(uint256 seed, uint8 nd) internal pure returns (uint64) {
        uint256 fact = (100 * (10**nd)) + 1;
        uint256 kc = uint256(keccak256(abi.encodePacked(seed)));
        uint256 rn = kc % fact;
        return uint64(rn);
    }
    
    /**
     * Calculates score from prediction and results.
     *
     * @param pred preduction
     * @param res the actual value
     * @param nd number of decimal points
     * @return calculated score as 0-100% witgh decimals
     */
    function calculateScore(uint64 pred, uint64 res, uint8 nd) internal pure returns (uint64) {
        if (pred == 0 && res == 0) {
            return 0;
        }
        uint256 fact = 10**nd;
        if (pred >= res) {
            uint256 p2 = pred;
            uint256 r2 = 100 * res * fact;
            uint256 r = r2 / p2;
            return uint64(r);
        }
        else {
            uint256 p2 = 100 * pred * fact;
            uint256 r2 = res;
            uint256 r = p2 / r2;
            return uint64(r);
        }        
    }
    
    /**
     * Calculates total score from the 6 scores.
     *
     * @param s1 score 1     
     * @param s2 score 2
     * @param s3 score 3
     * @param s4 score 4
     * @param s5 score 5
     * @param s6 score 6
     * @return total score as a weigted average
     */
    function calculateTotalScore(uint64 s1, uint64 s2, uint64 s3, uint64 s4, uint64 s5, uint64 s6) internal pure returns (uint64) {
        uint256 s1a = s1 * 11;
        uint256 s2a = s2 * 12;
        uint256 s3a = s3 * 13;
        uint256 s4a = s4 * 14;
        uint256 s5a = s5 * 15;
        uint256 s6a = s6 * 16;
        uint256 res = (s1a + s2a + s3a + s4a + s5a + s6a) / 81;
        return uint64(res);
    }
    
    /**
     * Concatenates strings.
     *
     * @param a string a
     * @param b string b
     * @return concatenateds string
     */
    function strConcat(string memory a, string memory b) internal pure returns (string memory) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        string memory ab = new string(ba.length + bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < ba.length; i++) bab[k++] = ba[i];
        for (uint i = 0; i < bb.length; i++) bab[k++] = bb[i];
        return string(bab);
    }    
}
