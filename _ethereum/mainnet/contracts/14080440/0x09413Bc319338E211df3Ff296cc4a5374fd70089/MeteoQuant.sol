// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Initializable.sol";

import "./IUniswapV2Router02.sol";
import "./ISwapRouter.sol";
import "./TransferHelper.sol";
import "./Meteorite.sol";
import "./GovernorBravoDelegate.sol";
import "./Timelock.sol";

import "./console.sol";


contract MeteoQuant is Initializable {

    address public MTE;
    address public WETH;
    address public ROUTER;
    address public MteGovernor;
    address public timelock;

    address public  MARTIAN;
    address public pending_martian;
    address public  DAO;
    address public pending_dao;
    
    uint24 public constant poolFee = 3000; //uniV3 swap fee

    // protocol fees = investor profits * 0.05;
    uint24 public treasuryRate;// default protocol fee * 60%
    uint24 public voteSupportRate;//default = protocol fee * 20;
    // uint24 public voteAgainstRate;//default = protocol fee * 4;
    uint24 public mteLabsRate;//default = protocol fee * 20;

    uint256 public treasuryBalances;
    uint256 public voteAgainstRewards;
    uint256 public voteSupportRewards;
    uint256 public mteLabsBalances;
    

    mapping( address => mapping(address => uint256) ) public balances;
    struct Project{
        uint256 projectId;
        uint256 strategyId;
        address token;// foregift token contract address,eth:0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        address investor;
        address strategist;
        uint256 foregift;
        uint256 balance;
        uint256 totalFee;
        uint256 forVotesRewards;
        uint256 endblock; // The end date of the project. In 5 days after this date, if the status == 1, the user can withdraw the pledge deposit
        uint256 status; //1,creative;2.end;3.forceSettle
    }

    /// projectid-->project detail
    mapping( uint256 => Project) public projects;

    /// Each time the strategy settles the service fee, a portion of the cost is allocated to users who have voted for the strategy.
    /// The rewardBalances increases every time you settle, and the rewardsPerVote increases according to the reward/forVotes.
    /// Each time a user claims a reward, rewardBalances decreases and totalReswards increases.
    struct Strategy{
        uint256 proposalId;
        uint256 maxInvest;
        uint256 validInvest;
        uint256 forVotes;
        /// current rewards = user.forVotes * rewardsPerVotes - user.rewardsDebt;
        /// user.rewardsDebt = user.forVotes * rewardsPerVotes;
        uint256 rewardsPerVote;
        uint256 totalRewards;
        uint256 rewardBalances;
    }

    /// strategyId => Strategy
    mapping( uint256 => Strategy ) public strategies;
    /// voter address => (strategyId => rewardsDdebts)
    mapping( address => mapping( uint256 => uint256)) public rewardsDebts;

    event LAUNCH(address investor,uint256 projectId,uint256 foregifts,address token);
    event WITHDRAW(address withdrawer, uint256 amount, uint256 balance);
    event FORCESETTLE(address investor,uint256 amount);
    event DEPOSIT(address investor,uint256 addAmount,uint256 foregift);
    event DEPOSITFEE(address investor,uint256 projectid,uint256 serviceFee,uint256 balance);
    event ENDPROJECT(address martin, uint256 projectid, uint256 totalFee, uint256 strategyFee,uint256 returnForegift);
    event SETTLEMENT(address martin, uint256 projectid, uint256 totalFee, uint256 strategyFee);
    event ADDSTRATEGY(uint256 strategyId, uint256 proposalId,uint256 forVotes);
    event CLAIMREWARDS(address voter, uint256 strategyId, uint256 rewards);
    event SETPROTOCOLRATES(uint24 treasuryRate, uint24 supportRate, uint24 labsRate);
    
    ///@param _martian quant project creator
    // constructor(address _martian, address _dao, address _router, address _mte, address _weth, address _governor, address _timelock){
    //     _setupRole(MARTIAN, _martian);
    //     _setupRole(DAO, _dao);
    //     ROUTER = _router;
    //     MTE = _mte;
    //     WETH = _weth;
    //     MteGovernor = _governor;
    //     timelock = _timelock;
    // }

    function initialize(address _martian, address _dao, address _router, address _mte, address _weth, address _governor, address _timelock) public initializer {
        MARTIAN = _martian;
        DAO = _dao;
        ROUTER = _router;
        MTE = _mte;
        WETH = _weth;
        MteGovernor = _governor;
        timelock = _timelock;

        treasuryRate = 60;
        voteSupportRate = 20;
        // voteAgainstRate = 4;
        mteLabsRate = 20;
    }

    function setPendingMartian(address _martian) external {
        require(MARTIAN == msg.sender && _martian!=address(0) && MARTIAN != _martian, "MUST MARTIAN");
        pending_martian = _martian;
    }

    function acceptPendingMartian() external {
        require(msg.sender == pending_martian,"ERROR ACCOUNT");
        MARTIAN = pending_martian;
    }

    function setPendingDao(address _dao) external {
        require(DAO == msg.sender && _dao!=address(0) && DAO != _dao, "MUST DAO");
        pending_dao =  _dao;
    }

    function acceptPendingDao() external {
        require(msg.sender == pending_dao,"ERROR ACCOUNT");
        DAO = pending_dao;
    }

    function setGovernor(address _governor) external {
        require(MARTIAN == msg.sender  && _governor!=address(0) && _governor!=MteGovernor, "MUST MARTIAN");
        MteGovernor = _governor;
    }

    ///@dev Listing the strategy and add the number of support strategies for the strategy
    ///@param _strategyId strategy id
    ///@param _proposalId strategy's proposal id
    // function ListingStrategy(uint256 _strategyId, uint256 _proposalId, uint256 _maxInvest) external {
    function ListingStrategy(uint256 _strategyId, uint256 _proposalId) external {
        //must timelock or admin
        require(msg.sender == timelock || MARTIAN == msg.sender, "MUST TIMELOCK OR MARTIAN");
        (uint256 strategyId_,uint256 forVotes_, bool succeed_) = GovernorBravoDelegate(MteGovernor).getStrategyPropose(_proposalId);
        uint8 loops = 0;
        while(loops<10){
            loops++;
            if( _strategyId != strategyId_){
                _proposalId++;
                (strategyId_, forVotes_, succeed_) = GovernorBravoDelegate(MteGovernor).getStrategyPropose(_proposalId);
                continue;
            }
            break;
        }
        if( _strategyId == strategyId_ && succeed_){
            Strategy storage strategy = strategies[_strategyId];
            strategy.forVotes = forVotes_;
            // strategy.maxInvest = _maxInvest;
            strategy.proposalId = _proposalId;
            emit ADDSTRATEGY(_strategyId, _proposalId, forVotes_);
        }else{
            emit ADDSTRATEGY(_strategyId, _proposalId, forVotes_);
        }        
    }


    /// @dev Show voter currently unclaimed rewards
    /// @param _strategyId strategy has proposal and support vote
    /// @param _voter Users who voted for support
    function strategyRewards(uint256 _strategyId, address _voter) external view returns( uint256 rewards){
        Strategy memory strategy = strategies[_strategyId];
        if(strategy.proposalId == 0) return 0;
        uint256 forVotes = GovernorBravoDelegate(MteGovernor).getForVotes(strategy.proposalId, _voter);

        rewards = strategy.rewardsPerVote * forVotes / 1e18 - rewardsDebts[_voter][_strategyId];
        // rewards = FixedPoint.uq112x112(strategy.rewardsPerVote).mul(forVotes).decode144() - rewardsDebts[_voter][_strategyId];        
    }

    /// @dev claim strategy rewards
    /// @param _strategyId strategy id, msg.sender for voted this strategy
    function claimStrategyRewards( uint256 _strategyId ) external {
        Strategy storage strategy = strategies[_strategyId];
        uint256 rewardBalances = strategy.rewardBalances;
        require(strategy.proposalId > 0,"UNKNOW STRATEGY");

        uint256 forVotes = GovernorBravoDelegate(MteGovernor).getForVotes(strategy.proposalId, msg.sender);
        require(forVotes > 0, "SUPPORTER ALLOW");

        uint256 rewards = strategy.rewardsPerVote * forVotes / 1e18 - rewardsDebts[msg.sender][_strategyId];
        // uint256 rewards = FixedPoint.uq112x112(strategy.rewardsPerVote).mul(forVotes).decode144() - rewardsDebts[msg.sender][_strategyId];

        /// update rewardDebt
        rewardsDebts[msg.sender][_strategyId] = strategy.rewardsPerVote * forVotes / 1e18;
        // rewardsDebts[msg.sender][_strategyId] = FixedPoint.uq112x112(strategy.rewardsPerVote).mul(forVotes).decode144();

        if(rewards > strategy.rewardBalances) rewards = strategy.rewardBalances;
        strategy.rewardBalances -= rewards;

        if(rewards > IERC20(MTE).balanceOf(address(this))) rewards = IERC20(MTE).balanceOf(address(this));        
        strategy.totalRewards += rewards;

        if(rewards > 0){
            IERC20(MTE).transfer(msg.sender, rewards);
        }
        assert(rewards <= rewardBalances);
        emit CLAIMREWARDS(msg.sender, _strategyId, rewards);
    }

    ///@dev Create a new quantitative project, launch by the investor,If investors have unwithdraw funds, they will be used first.
    /// Before confirming the transaction, the backend must check whether each parameter is correct.
    ///@param _projectId quant prj id, from quant backend
    ///@param _strategyId strategy id, from quant backend
    ///@param _foregift Estimated project fee
    ///@param _token foregift token contract,eth:0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    ///@param _strategist strategist address,from quant backend
    function launch(uint256 _projectId, uint256 _strategyId, uint256 _foregift, address _token, address _strategist) payable external {
        require(_foregift>0 && _token!=address(0) && _strategist!=address(0),"INVALID PARAM");
        Project storage project = projects[_projectId];
        require(project.projectId == 0,"PROJECT EXIST");

        uint256 inbalance = balances[msg.sender][_token];
        uint256 amount = _foregift;
        if(inbalance > 0){ //The investor still has undrawn funds
            if(inbalance >= _foregift){
                balances[msg.sender][_token] -= _foregift;
            }else{
                balances[msg.sender][_token] = 0;
                amount = _foregift - inbalance;
            }
        }

        if(_token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
            require(msg.value >= amount, "INSUFFICIENT FOREGIFT");
            if(msg.value > amount){
                payable(msg.sender).transfer(msg.value - amount);
            }
        }else{
            IERC20(_token).transferFrom(msg.sender, address(this), amount);
            IERC20(_token).approve(ROUTER,type(uint256).max);
        }
        
        
        project.projectId = _projectId;
        project.strategyId = _strategyId;
        project.token = _token;
        project.foregift = _foregift;
        project.strategist = _strategist;
        project.investor = msg.sender;
        project.status = 1;       
        emit LAUNCH(msg.sender, _projectId, _foregift,_token);
    }

    ///@dev Backend query project info
    ///@param _projectId project Id 
    ///@return project struct Project. project.projectId = 0 if _projectId does not exist
    function query(uint256 _projectId) external view returns(Project memory project){
        return projects[_projectId];
    }

    ///@dev When the investor income is close to the forgive, the investor needs to pay a service fee
    ///@param _projectId project
    ///@param _serviceFee service fee,from backend calculate
    function depositFee(uint256 _projectId,uint256 _serviceFee) payable external {
        Project storage project = projects[_projectId];
        require(project.status == 1 && project.investor == msg.sender, "ERROR PROJECT");
        if(project.token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
            require(msg.value >= _serviceFee, "INSUFFICIENT FUNDS");
            if(msg.value > _serviceFee){
                payable(msg.sender).transfer(msg.value - _serviceFee);
            }
        }else{
            require(IERC20(project.token).balanceOf(msg.sender) >= _serviceFee,"INSUFFICIENT FUNDS");
            IERC20(project.token).transferFrom(msg.sender, address(this), _serviceFee);
        }
        project.balance += _serviceFee;

        emit DEPOSITFEE(msg.sender, _projectId, _serviceFee,project.balance);
    }

    ///@dev End project,settle strategist service fee,returns foregift to investor
    ///@param _projectId project ID
    ///@param _totalFee total service fee
    ///@param _strategyFee strategist service fee
    function endProject(uint256 _projectId, uint256 _totalFee, uint256 _strategyFee) external {
        require(MARTIAN == msg.sender, "MUST MARTIAN");
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "ERROR PROJECT");

        settlement(_projectId,_totalFee,_strategyFee,true, true);
    }

    ///@dev allocation protocol fee
    ///@param _amount total protocol fee
    ///@param _project current settment project
    function protocolFees(uint256 _amount, Project storage _project) internal{
        require(_amount>0, "PROTOCOL FEE ZERO");
        
        treasuryBalances += _amount * treasuryRate / 100;
        // voteAgainstRewards += _amount * voteAgainstRate / 100;
        mteLabsBalances += _amount * mteLabsRate / 100;
        
        Strategy storage strategy = strategies[_project.strategyId];
        if(strategy.proposalId>0 && strategy.forVotes>0){
            strategy.rewardBalances += _amount * voteSupportRate / 100;
            strategy.rewardsPerVote += _amount * voteSupportRate / 100 * 1e18 / strategy.forVotes;
            //  strategy.rewardsPerVote += FixedPoint.fraction(_amount * voteSupportRate / 100, strategy.forVotes)._x;
        }else{
            voteSupportRewards += _amount * voteSupportRate / 100;
        }
    }

    ///@dev reset the protocol fee ratio through governance voting
    ///@param _treasuryRate treasury funds rate
    ///@param _supportRate forvote reward rate
    ///@param _labsRate dev funds rate
    function setProtocolRates(uint24 _treasuryRate, uint24 _supportRate, uint24 _labsRate) external{
        require(msg.sender == timelock, "MUST TIMELOCK OR MARTIAN");
        require(_treasuryRate+_supportRate+_labsRate == 100 ,"INVALID RATE");
        treasuryRate = _treasuryRate;
        voteSupportRate = _supportRate;
        // voteAgainstRate = _againstRate;
        mteLabsRate = _labsRate;
        emit SETPROTOCOLRATES(_treasuryRate, _supportRate, _labsRate);
    }

    ///@dev MTE Backend call settlement
    ///@param _projectId project id 
    ///@param _totalFee project total service fee = strategyfee + platform fee
    ///@param _strategyFee stategist service fee
    ///@param _useForegift Whether to use the forgift to supplement the service fee
    ///@param _endProjct end project, return foregift/service balance
    function settlement(uint256 _projectId, uint256 _totalFee, uint256 _strategyFee, bool _useForegift, bool _endProjct) public {
        require(MARTIAN == msg.sender || msg.sender == address(this), "MUST MARTIAN");
        require(_totalFee >= _strategyFee, "TOTALFEE < STRATEGYFEE");
        uint256 mtebalance = IERC20(MTE).balanceOf(address(this));        

        Project storage project = projects[_projectId];
        require(project.projectId > 0 , "INVALID PROJECT");//&& project.status == 1?
        uint256 tokenbalance = project.token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) ? address(this).balance : IERC20(project.token).balanceOf(address(this));
        uint256 projecttoken = project.foregift + project.balance;

        // Use foregift to replenish service fee deficiencies
        if(_useForegift){
            require(project.foregift + project.balance >= _totalFee, "INSUFFICENT FUNDS");
            if(project.balance < _totalFee){
                project.foregift -= (_totalFee - project.balance);
                project.balance = 0;
            }else{
                project.balance -= _totalFee;
            }
        }else{
            require(project.balance >= _totalFee, "INSUFFICENT FUNDS");
            project.balance -= _totalFee;
        }

        uint256 mteAmount = _totalFee;
        if(project.token != MTE && _totalFee > 0){
            mteAmount = swapMteV2(project.token, _totalFee,address(this));
        }

        //strategist service fee
        uint256 strategyMte = _strategyFee;        
        if(_strategyFee>0){
            strategyMte = mteAmount * _strategyFee / _totalFee;
            IERC20(MTE).transfer(project.strategist,  strategyMte);            
        }        
        
        //Return foregift,transfer token(not MTE) to investor
        uint256 returnForegift = project.foregift + project.balance;
        if(_endProjct && returnForegift > 0){
        
            
            project.foregift = 0;
            project.balance = 0;

            //eth
            if(project.token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
                if(address(this).balance < returnForegift){
                   returnForegift =  address(this).balance;
                }
                payable(project.investor).transfer(returnForegift);
            }else{
                if(IERC20(project.token).balanceOf(address(this)) < returnForegift ){
                    returnForegift = IERC20(project.token).balanceOf(address(this));
                }
                IERC20(project.token).transfer(project.investor, returnForegift);
            }
        }
        if(_endProjct){
            project.status = 2;
            emit ENDPROJECT(msg.sender, _projectId, _totalFee, _strategyFee, returnForegift);
        }
        
        //protocol fee 
        if(mteAmount>0 && mteAmount - strategyMte > 0){
            protocolFees(mteAmount - strategyMte, project);
        }

        /// Make sure there is no theft
        assert( mtebalance <= IERC20(MTE).balanceOf(address(this)) );
        uint256 tokenbalance_ = project.token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) ? address(this).balance : IERC20(project.token).balanceOf(address(this));
        assert( tokenbalance_ >= tokenbalance - projecttoken );

        emit SETTLEMENT(msg.sender, _projectId, _totalFee, _strategyFee);
    }

    ///@dev Investor add foregift
    function deposit(uint256 _projectId, uint256 _addAmount) payable external{
        Project storage project = projects[_projectId];
        require(project.investor == msg.sender,"ERROR PROJECTID");

        if(project.token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
            require(msg.value >= _addAmount, "INSUFFICIENT");
            if(msg.value > _addAmount){
                payable(msg.sender).transfer(msg.value - _addAmount);
            }
        }else{
            IERC20(project.token).transferFrom(msg.sender, address(this), _addAmount);
        }

        project.foregift += _addAmount;
        emit DEPOSIT(msg.sender,_addAmount,project.foregift);
    } 


    ///@dev Settlemented or expire deadline, the investor withdraws his remaining funds
    ///@param token foregift token address
    ///@param amount withdraw tokens
    // function withdraw(address token,uint256 amount) external {
    //     require(token!=address(0) && amount>0,"INVALID PARAMS");
    //     require( balances[msg.sender][token] > 0, "BALANCE ZERO");
    //     if(amount>balances[msg.sender][token]){
    //         amount = balances[msg.sender][token];
    //     }
    //     balances[msg.sender][token] -= amount;
    //     if(token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
    //         payable(msg.sender).transfer(amount);
    //     }else{
    //         IERC20(token).transfer(msg.sender, amount);
    //     }        
    //     emit WITHDRAW(msg.sender,amount,balances[msg.sender][token]);
    // }

    ///@dev withdraw from treasury balances
    function withdrawTreasury(uint256 _amount, address _receipt) external {
        require(DAO == msg.sender, "MUST DAO");
        require(_amount>0 && _receipt != address(0), "INVALID PARAM");
        require( treasuryBalances >= _amount, "INSUFFICENT TREASURY");

        _amount = _amount <= treasuryBalances ? _amount : treasuryBalances;
        treasuryBalances -= _amount;
        IERC20(MTE).transfer(_receipt, _amount);

        emit WITHDRAW(_receipt,_amount,treasuryBalances);
    }

    ///@dev withdraw from mteLabsBalanace
    function withdrawLabs(uint256 _amount, address _receipt) external {
        require(DAO == msg.sender, "MUST DAO");
        require(_amount>0 && _receipt != address(0), "INVALID PARAM");
        require( mteLabsBalances >= _amount, "INSUFFICENT LABFEE");
        
        _amount = _amount <= mteLabsBalances ? _amount : mteLabsBalances;
        mteLabsBalances -= _amount;
        IERC20(MTE).transfer(_receipt, _amount);

        emit WITHDRAW(_receipt,_amount,mteLabsBalances);
    }

    ///@dev withdraw from voteAgainstRewards
    function withdrawVoteAgainstRewards(uint256 _amount, address _receipt) external {
        require(DAO == msg.sender, "MUST DAO");
        require(_amount>0 && _receipt != address(0), "INVALID PARAM");
        require( voteAgainstRewards >= _amount, "INSUFFICENT AGAINSTEWARDS");
        
        _amount = _amount <= voteAgainstRewards ? _amount : voteAgainstRewards;
        voteAgainstRewards -= _amount;
        IERC20(MTE).transfer(_receipt, _amount);

        emit WITHDRAW(_receipt,_amount,voteAgainstRewards);
    }

    /// @dev DAO handles with rewards which generated by strategies that did not in voting
    function withdrawVoteSupportRewards(uint256 _amount, address _receipt) external {
        require(DAO == msg.sender, "MUST DAO");
        require(_amount>0 && _receipt != address(0), "INVALID PARAM");
        require( voteSupportRewards >= _amount, "INSUFFICENT SUPPORTREWARDS");
        
        _amount = _amount <= voteSupportRewards ? _amount : voteSupportRewards;
        voteSupportRewards -= _amount;
        IERC20(MTE).transfer(_receipt, _amount);

        emit WITHDRAW(_receipt,_amount,voteSupportRewards);
    }

    /// @dev Swap investor deposit token to MTE. Uniswap V2.
    function swapMteV2(address inToken, uint256 inAmount, address receipt) internal returns (uint256 outAmount){
        require(inToken!=address(0) && inAmount>0 && receipt!=address(0),"INVALID PARAMS");

        uint256 pathLength = 2;
        if(inToken != address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
            pathLength = 3;
        }
        address[] memory path = new address[](pathLength);       
        if(pathLength>2){ 
            path[0] = inToken;          
            path[1] = IUniswapV2Router02(ROUTER).WETH();
            path[2] = MTE;
        }else{
            path[0] = IUniswapV2Router02(ROUTER).WETH();
            path[1] = MTE;
        }

        if(inToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
            console.log("Path1= %s Path2= %s", path[0], path[1]);
            uint256[] memory amounts = IUniswapV2Router02(ROUTER).swapExactETHForTokens{value:inAmount}(0,path,receipt,block.timestamp);
            console.log("outamount1= %s outamount2= %s", amounts[0], amounts[1]);
            outAmount = amounts[1];
        }else{
            uint256[] memory amounts = IUniswapV2Router02(ROUTER).swapExactTokensForTokens(inAmount, 0, path, receipt, block.timestamp);
            outAmount = amounts[2];
        }
    }

    receive() external payable {}

}