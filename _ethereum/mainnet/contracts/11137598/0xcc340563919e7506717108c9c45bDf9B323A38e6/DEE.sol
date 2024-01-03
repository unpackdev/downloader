pragma solidity ^0.6.0;
import "./SafeMath.sol";
import "./IERC20.sol";

contract DEE {
    using SafeMath for uint256;
    uint256 public unsettled;
    uint256 public staked;
    uint airDropped;
    uint8 constant toAirdrop = 200;
    uint public tokenClaimCount;

    struct Fees {
        uint stake;
        uint dev;
        uint farm;
        uint airdrop;
    }
    Fees fees;
    address payable public admin;
    address payable public partnership;
    address public TheStake;
    address public UniswapPair;
    address public bounce;
    address public lockedTokens;

    address [] assets;
    address [] tokensClaimable;
    address payable[] public shareHolders;
    struct Participant {
        bool staking;
        uint256 stake;
    }

    address[toAirdrop] airdropList;
    mapping(address => Participant) public staking;
    mapping(address => mapping(address => uint256)) public payout;
    mapping(address => uint256) public ethPayout;
    mapping(address => uint256) public tokenUnsettled;
    mapping(address => uint256) public totalTokensClaimable;

    IERC20 LPToken;

    receive() external payable { }

    modifier onlyAdmin {
        require(msg.sender == admin, "Only the admin can do this");
        _;
    }

    constructor(address _TheStake)  public {
        admin = msg.sender;
        fees.stake = 40;
        fees.dev = 10;
        fees.airdrop = 40;
        fees.farm = 60;
        TheStake = _TheStake;
    }

    /* Admin Controls */
    function changeAdmin(address payable _admin) external onlyAdmin {
        admin = _admin;
    }

    function setPartner(address payable _partnership) external onlyAdmin {
        partnership = _partnership;
    }

    function setUniswapPair(address _uniswapPair) external onlyAdmin {
        UniswapPair = _uniswapPair;
    }

    function addAsset(address _asset) external onlyAdmin {
        assets.push(_asset);
    }

    function remAsset(address _asset) external onlyAdmin {
        for(uint i = 0; i < assets.length ; i++ ) {
            if(assets[i] == _asset) delete assets[i];
        }
    }

    function setStake(address _stake) external onlyAdmin {
        require(TheStake == address(0), "This can only be done once.");
        TheStake = _stake;
    }

    function setBounce(address _bounce) external onlyAdmin {
        require(bounce == address(0), "This can only be done once.");
        bounce = _bounce;
    }
    
    function setLockedTokens(address _contract) external onlyAdmin {
        lockedTokens = _contract;
    }    

    function setLPToken(address _lptokens) external onlyAdmin {
        LPToken = IERC20(_lptokens);
    }
    
    function addPendingTokenRewards(uint256 _transferFee, address _token) external {
        require(assetFound(msg.sender) == true, 'Only Assets can Add Fees.');
        uint topay = _transferFee.add(tokenUnsettled[_token]);

        if(topay < 10000 || topay < shareHolders.length || shareHolders.length == 0)
            tokenUnsettled[_token] = topay;
        else {
            tokenUnsettled[_token] = 0;
            payout[admin][_token] =  payout[admin][_token].add(percent(fees.dev*10000/totalFee(), topay) );

            addClaimableToken(_token, topay);
            addRecentTransactor(tx.origin);

            for(uint i = 0 ; i < shareHolders.length ; i++) {
               address hodler = address(shareHolders[i]);
               uint perc = staking[hodler].stake.mul(10000) / staked;
               if(address(LPToken) != address(0)) {
                    uint farmPerc = LPToken.balanceOf(hodler).mul(10000) / LPtotalSupply();
                    if(farmPerc > 0) payout[hodler][_token] = payout[hodler][_token].add(percent(farmPerc, percent(fees.farm*10000/totalFee(), topay)));
               }
               if(eligableForAirdrop(hodler) ) {
                    payout[hodler][_token] = payout[hodler][_token].add(percent(perc, percent(fees.airdrop*10000/totalFee(), topay)));    
               }
               payout[hodler][_token] = payout[hodler][_token].add(percent(perc, percent(fees.stake*10000/totalFee(), topay)));
            }
        }
    }

    function addPendingETHRewards() external payable {
        require(assetFound(msg.sender) == true, 'Only Assets can Add Fees.');
        uint topay = unsettled.add(msg.value);
        if(topay < 10000 || topay < shareHolders.length || shareHolders.length == 0)
            unsettled = topay;
        else {
            unsettled = 0;
            ethPayout[admin] = ethPayout[admin].add(percent(fees.dev*10000/totalFee(), topay));
             
            for(uint i = 0 ; i < shareHolders.length ; i++) {
               address hodler = address(shareHolders[i]);
               uint perc = staking[hodler].stake.mul(10000) / staked;
               if(address(LPToken) != address(0)) {
                   uint farmPerc = LPToken.balanceOf(hodler).mul(10000) / LPtotalSupply();
                   if(farmPerc > 0) ethPayout[hodler] = ethPayout[hodler].add(percent(farmPerc, percent(fees.farm*10000/totalFee(), topay)));
               }
               if(eligableForAirdrop(hodler) ) {
                    ethPayout[hodler] = ethPayout[hodler].add(percent(perc, percent(fees.airdrop*10000/totalFee(), topay)));    
               }               
               ethPayout[hodler] = ethPayout[hodler].add(percent(perc, percent(fees.stake*10000/totalFee(), topay)));
            }
        }
    }

    function stake(uint256 _amount) external {
        require(msg.sender == tx.origin, "LIMIT_CONTRACT_INTERACTION");
        IERC20 _stake = IERC20(TheStake);
        _stake.transferFrom(msg.sender, address(this), _amount);
        staking[msg.sender].stake = staking[msg.sender].stake.add(_amount);
        staked = staked.add(_amount);
        if(staking[msg.sender].staking == false){
            staking[msg.sender].staking = true;
            shareHolders.push(msg.sender);
        }
    }
 
    function unstake(uint _amount) external {
        require(msg.sender == tx.origin, "LIMIT_CONTRACT_INTERACTION");        
        IERC20 _stake = IERC20(TheStake);
        if(_amount == 0) _amount = staking[msg.sender].stake;
        claimBoth();
        require(staking[msg.sender].stake >= _amount, "Trying to remove too much stake");
        staking[msg.sender].stake = staking[msg.sender].stake.sub(_amount);
        staked = staked.sub(_amount);
        if(staking[msg.sender].stake <= 0) {
            staking[msg.sender].staking = false;
            for(uint i = 0 ; i < shareHolders.length ; i++){
                if(shareHolders[i] == msg.sender){
                    delete shareHolders[i];
                    break;
                }
            }
        }
        _stake.transfer(msg.sender, _amount);
    }

    function claim() public {
        require(msg.sender == tx.origin, "LIMIT_CONTRACT_INTERACTION");        
        for(uint i = 0; i < tokensClaimable.length; i++) {
            address _claimToken = tokensClaimable[i];
            if(payout[msg.sender][_claimToken] > 0) {
                uint256 topay = payout[msg.sender][_claimToken];
                delete payout[msg.sender][_claimToken];
                IERC20(_claimToken).transfer(msg.sender, topay);
            }
        }
    }

    function claimEth() public payable {
        require(msg.sender == tx.origin, "LIMIT_CONTRACT_INTERACTION");
        uint topay = ethPayout[msg.sender];
        require(ethPayout[msg.sender] > 0, "NO PAYOUT");
        delete ethPayout[msg.sender];
        msg.sender.transfer(topay);
    }

    function claimBoth() public payable {
        if(ethPayout[msg.sender] > 0) claimEth();
        claim();
    }

    function burned(address _token) public view returns(uint256) {
        if(_token == TheStake) return IERC20(_token).balanceOf(address(this)).sub(staked);
        return IERC20(_token).balanceOf(address(this));
    }

    function calculateAmountsAfterFee(address _sender, uint _amount) external view returns(uint256, uint256){
        if( _amount < 10000 ||
            _sender == address(this) ||
            _sender == UniswapPair ||
            _sender == admin ||
            _sender == bounce)
            return(_amount, 0);
        uint fee_amount = percent(totalFee(), _amount);
        return (_amount.sub(fee_amount), fee_amount);
    }

    function totalFee() private view returns(uint) {
        return fees.airdrop + fees.dev + fees.stake + fees.farm;
    }

    function eligableForAirdrop(address _addr) private view returns (bool) {
        for(uint i; i < toAirdrop; i++) {
            if(airdropList[i] == _addr) return true;
        }
        return false;
    }

    function assetFound(address _asset) private view returns(bool) {
        for(uint i = 0; i < assets.length; i++) {
            if( assets[i] == _asset) return true;
        }
        return false;
    }
    
    function addClaimableToken(address _token, uint256 _amount) private {
        totalTokensClaimable[_token] = totalTokensClaimable[_token].add(_amount);
        for(uint i = 0; i < tokensClaimable.length ; i++ ) {
            if(_token == tokensClaimable[i]) return;
        }
        tokensClaimable.push(_token);
    }

    function addRecentTransactor(address _actor) internal {
        airdropList[airDropped] = _actor;
        airDropped += 1;
        if(airDropped >= toAirdrop) airDropped = 0;
    }

    function LPtotalSupply() internal view returns (uint256) {
        return LPToken.totalSupply().sub(IERC20(LPToken).balanceOf(lockedTokens));
    }
    
    function percent(uint256 perc, uint256 whole) private pure returns(uint256) {
        uint256 a = (whole / 10000).mul(perc);
        return a;
    }

}