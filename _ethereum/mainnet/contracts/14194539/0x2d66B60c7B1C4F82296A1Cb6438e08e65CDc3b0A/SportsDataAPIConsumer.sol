// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ChainlinkClient.sol";
import "./IERC20.sol";

enum DataState {
    Waiting,
    Getting,
    SetRaw,
    Complete
}

struct Quarter {
    uint256 homeScoreQuarter;
    uint256 awayScoreQuarter;
    uint256 homeScoreTotal;
    uint256 awayScoreTotal;
    DataState homeDataState;
    DataState awayDataState;
    string homePath;
    string awayPath;
}

contract SportsDataAPIConsumer is ChainlinkClient  {

    using Chainlink for Chainlink.Request;

    struct JobSpec {
        uint256 quarter;
        // 1 - home, 2 - away
        uint256 team;
    }

    mapping(uint256 => Quarter) public quarter;
    mapping(bytes32 => JobSpec) public jobSpecs;

    bytes32 private jobId;
    uint256 public dataFee;
    DataState public gameScoreDataState;

    event ScoresReceived(uint256 _quarter, uint256 _team, uint256 _score);

    /**
     * Network: Mainnet
     * Oracle: 0x0aefab6f66d0278B99B6eCbFa8a03f9828cD90b0 (Atlas Chainlink Node) 
     * Job ID: 47a7f197fec844fc8c1fe259441bd3dc
     * Fee: 2 LINK
     */
    constructor(address _oracleAddress){
        setPublicChainlinkToken();
        setChainlinkOracle(_oracleAddress);
        // Mainnet
        jobId = "47a7f197fec844fc8c1fe259441bd3dc";

        dataFee = 2 ether;  

        gameScoreDataState = DataState.Waiting;

        quarter[1].homePath = "0,HomeScoreQuarter1";
        quarter[1].awayPath = "0,AwayScoreQuarter1";
        quarter[2].homePath = "0,HomeScoreQuarter2";
        quarter[2].awayPath = "0,AwayScoreQuarter2";
        quarter[3].homePath = "0,HomeScoreQuarter3";
        quarter[3].awayPath = "0,AwayScoreQuarter3";
        quarter[4].homePath = "0,HomeScoreQuarter4";
        quarter[4].awayPath = "0,AwayScoreQuarter4";
        quarter[5].homePath = "0,HomeScoreOvertime";
        quarter[5].awayPath = "0,AwayScoreOvertime";

    }

    function getGameScores() public virtual {
        for(uint256 i = 1; i <= 5; i++){
            requestQuarterScoreData(i);
        }
    }

    function requestQuarterScoreData(uint256 _quarter) internal {
        require(_quarter > 0, "Quarter must be greater than 0");
        require(_quarter <= 5, "Quarter must be less than or equal to 5, includes overtime");
        require(quarter[_quarter].homeDataState == DataState.Waiting, "Quarter score lookup already initiated");
        require(quarter[_quarter].awayDataState == DataState.Waiting, "Quarter score lookup already initiated");
        jobSpecs[requestScoreData(quarter[_quarter].homePath)] = JobSpec({quarter: _quarter, team: 1});
        jobSpecs[requestScoreData(quarter[_quarter].awayPath)] = JobSpec({quarter: _quarter, team: 2});

        quarter[_quarter].homeDataState = DataState.Getting;
        quarter[_quarter].awayDataState = DataState.Getting;
    }

    function requestScoreData(string memory _dataPath) private returns (bytes32 requestId) 
    {
        require(IERC20(chainlinkTokenAddress()).balanceOf(address(this)) >= dataFee, "Not enough LINK - fill contract with faucet");
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
    
        request.add("path", _dataPath);
        
        return sendChainlinkRequest(request, dataFee);
    }
    
    /**
     * Receive the response in the form of uint256
     */ 
    function fulfill(bytes32 _requestId, uint256 _score) public recordChainlinkFulfillment(_requestId)
    {
        // home team score
        if(jobSpecs[_requestId].team==1){
            quarter[jobSpecs[_requestId].quarter].homeScoreQuarter = _score;
            quarter[jobSpecs[_requestId].quarter].homeDataState = DataState.SetRaw;
            emit ScoresReceived(jobSpecs[_requestId].quarter, 1, _score);
        }
        else if (jobSpecs[_requestId].team==2){
            quarter[jobSpecs[_requestId].quarter].awayScoreQuarter = _score;
            quarter[jobSpecs[_requestId].quarter].awayDataState = DataState.SetRaw;
            emit ScoresReceived(jobSpecs[_requestId].quarter, 2, _score);
        }

        if(allQuartersScoresReturned()){
            sumQuarterScores();
            gameScoreDataState = DataState.Complete;
        }
        
    }

    function sumQuarterScores() private {

        quarter[1].homeScoreTotal = quarter[1].homeScoreQuarter;
        quarter[1].homeDataState = DataState.Complete;
        quarter[1].awayScoreTotal = quarter[1].awayScoreQuarter;
        quarter[1].awayDataState = DataState.Complete;

        for(uint256 i = 2; i <= 5; i++ ){
            quarter[i].homeScoreTotal = quarter[i].homeScoreQuarter + quarter[i-1].homeScoreTotal;
            quarter[i].homeDataState = DataState.Complete;
            quarter[i].awayScoreTotal = quarter[i].awayScoreQuarter + quarter[i-1].awayScoreTotal;
            quarter[i].awayDataState = DataState.Complete;
        }

    }

    function allQuartersScoresReturned() private view returns (bool){
        for(uint256 i = 1; i <= 5; i++){
            if (
                quarter[i].homeDataState != DataState.SetRaw ||
                quarter[i].awayDataState != DataState.SetRaw 
            )
            {
                return false;
            }
            
        }
        return true;
    }

}