//SPDX-License-Identifier: MIT
/*
* MIT License
* ===========
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

pragma solidity 0.6.2;


import "./ITreasury.sol";
import "./ISwapRouter.sol";
import "./LPTokenWrapperWithSlash.sol";
import "./AdditionalMath.sol";

contract AlunaGov is LPTokenWrapperWithSlash {
    
    using AdditionalMath for uint256;


    struct Proposal {
        address proposer;
        address withdrawAddress;
        uint256 withdrawAmount;
        mapping(address => uint256) forVotes;
        mapping(address => uint256) againstVotes;
        uint256 totalForVotes;
        uint256 totalAgainstVotes;
        uint256 totalSupply;
        uint256 start; // block start;
        uint256 end; // start + period
        string url;
        string title;
    }

    // 1% = 100
    uint256 public constant MIN_QUORUM_PUNISHMENT = 500; // 5%
    uint256 public constant MIN_QUORUM_THRESHOLD = 3000; // 30%
    uint256 public constant PERCENTAGE_PRECISION = 10000;
    uint256 public constant WITHDRAW_THRESHOLD = 1e21; // 1000 yCRV
    uint256 public constant proposalPeriod = 2 days;
    uint256 public constant lockPeriod = 3 days;
    uint256 public constant minimum = 1337e18; // 1337 ALN
    uint256 public proposalCount;

    IERC20 public stablecoin;
    ITreasury public treasury;
    SwapRouter public swapRouter;

    mapping(address => uint256) public voteLock; // timestamp that boost stakes are locked after voting
    mapping (uint256 => Proposal) public proposals;

    constructor(IERC20 _stakeToken, ITreasury _treasury, SwapRouter _swapRouter)
        public
        LPTokenWrapperWithSlash(_stakeToken)
    {
        treasury = _treasury;
        stablecoin = treasury.defaultToken();
        swapRouter = _swapRouter;
        stablecoin.safeApprove(address(treasury), uint256(-1));
        stakeToken.safeApprove(address(_swapRouter), uint256(-1));
    }

    function propose(
        string calldata _url,
        string calldata _title,
        uint256 _withdrawAmount,
        address _withdrawAddress
    ) external {
        require(balanceOf(msg.sender) > minimum, "stake more boost");
        proposals[proposalCount++] = Proposal({
            proposer: msg.sender,
            withdrawAddress: _withdrawAddress,
            withdrawAmount: _withdrawAmount,
            totalForVotes: 0,
            totalAgainstVotes: 0,
            totalSupply: 0,
            start: block.timestamp,
            end: proposalPeriod.add(block.timestamp),
            url: _url,
            title: _title
            });
        voteLock[msg.sender] = lockPeriod.add(block.timestamp);
    }

    function voteFor(uint256 id) external {
        require(proposals[id].start < block.timestamp , "<start");
        require(proposals[id].end > block.timestamp , ">end");
        require(proposals[id].againstVotes[msg.sender] == 0, "cannot switch votes");
        uint256 userVotes = AdditionalMath.sqrt(balanceOf(msg.sender));
        uint256 votes = userVotes.sub(proposals[id].forVotes[msg.sender]);
        proposals[id].totalForVotes = proposals[id].totalForVotes.add(votes);
        proposals[id].forVotes[msg.sender] = userVotes;

        voteLock[msg.sender] = lockPeriod.add(block.timestamp);
    }

    function voteAgainst(uint256 id) external {
        require(proposals[id].start < block.timestamp , "<start");
        require(proposals[id].end > block.timestamp , ">end");
        require(proposals[id].forVotes[msg.sender] == 0, "cannot switch votes");
        uint256 userVotes = AdditionalMath.sqrt(balanceOf(msg.sender));
        uint256 votes = userVotes.sub(proposals[id].againstVotes[msg.sender]);
        proposals[id].totalAgainstVotes = proposals[id].totalAgainstVotes.add(votes);
        proposals[id].againstVotes[msg.sender] = userVotes;

        voteLock[msg.sender] = lockPeriod.add(block.timestamp);
    }

    function stake(uint256 amount) public override {
        super.stake(amount);
    }

    function withdraw(uint256 amount) public override {
        require(voteLock[msg.sender] < block.timestamp, "tokens locked");
        super.withdraw(amount);
    }

    function resolveProposal(uint256 id) external {
        require(proposals[id].proposer != address(0), "non-existent proposal");
        require(proposals[id].end < block.timestamp , "ongoing proposal");
        require(proposals[id].totalSupply == 0, "already resolved");

        // update proposal total supply
        proposals[id].totalSupply = AdditionalMath.sqrt(totalSupply());

        uint256 quorum = getQuorum(id);

        if ((quorum < MIN_QUORUM_PUNISHMENT) && proposals[id].withdrawAmount > WITHDRAW_THRESHOLD) {
            // user's stake gets slashed, converted to stablecoin and sent to treasury
            uint256 amount = slash(proposals[id].proposer);
            convertAndSendTreasuryFunds(amount);
        } else if (
            (quorum > MIN_QUORUM_THRESHOLD) &&
            (proposals[id].totalForVotes > proposals[id].totalAgainstVotes)
         ) {
            // treasury to send funds to proposal
            treasury.withdraw(
                proposals[id].withdrawAmount,
                proposals[id].withdrawAddress
            );
        }
    }
    
    function convertAndSendTreasuryFunds(uint256 amount) internal {
        address[] memory routeDetails = new address[](3);
        routeDetails[0] = address(stakeToken);
        routeDetails[1] = swapRouter.WETH();
        routeDetails[2] = address(stablecoin);
        uint[] memory amounts = swapRouter.swapExactTokensForTokens(
            amount,
            0,
            routeDetails,
            address(this),
            block.timestamp + 100
        );
        // 0 = input token amt, 1 = weth output amt, 2 = stablecoin output amt
        treasury.deposit(stablecoin, amounts[2]);
    }

    function getQuorum(uint256 id) public view returns (uint256){
        // sum votes, multiply by precision, divide by square rooted total supply
        require(proposals[id].proposer != address(0), "non-existent proposal");
        
        uint256 _totalSupply;      
        
        if (proposals[id].totalSupply == 0) {
            _totalSupply = AdditionalMath.sqrt(totalSupply());
        } else {
            _totalSupply = proposals[id].totalSupply;
        }             
        uint256 _quorum = 
            (proposals[id].totalForVotes.add(proposals[id].totalAgainstVotes))
            .mul(PERCENTAGE_PRECISION)
            .div(_totalSupply);

        return _quorum;
    }
}
