pragma solidity ^0.4.24;


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract IERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract Admin{
  mapping(address=>bool) public admin;
  constructor() public{
    admin[msg.sender]=true;
    admin[address(this)]=true;
  }
  function addAdmin(address newadmin) public{
    require(admin[msg.sender],"caller must be admin");
    admin[newadmin]=true;
  }
  function isAdmin(address tocheck) public view returns(bool){
    return admin[tocheck];
  }
}

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a,"addition failed");
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a,"subtraction failed");
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b,"multiplication failed");
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0,"division failed");
        c = a / b;
    }
}


/**
 * @title Lottery contract
 *
 *
 */

 contract Lottery{
  using SafeMath for uint256;
  mapping(uint => mapping (uint => uint)) public token_map;
  mapping(uint => mapping (uint => address)) public entry_map;
  mapping(uint => mapping (uint => uint)) public entry_position_map;
  mapping (address => uint) public token_count_by_address;
  uint public current_round;
  uint public entry_cursor;
  uint public cursor;
  IERC20 public token;
  IERC20 public ghostToken;
  Admin public administration; //other contracts allowed to access functions
  address public contractCreator; //contract creator allowed to access different functions
  bool public setup_phase=true;//SHOULD BE FALSE. This allows universal whitelisting etc. for the sake of smoother initialization of the whole system.
  //bytes32 public datakey;//the key for retrieving random value
  bytes32 public entropyHash;//secret for preventing miner manipulation of random
  uint256 public finalizationBlock;//the block from which random winner will be derived
  uint256 public winningIndex;
  bool public withdrawOccurred=false;

  //timing variables
  uint public staking_period=18 days;
  uint public pre_staking_period=0;//60*60*24;
  uint public staking_becomes_available_time;
  uint public finalization_time;

  modifier isSetup(){
    require(setup_phase,"not setup phase");
    _;
  }
  modifier isCreator(){
    require(contractCreator==msg.sender,"is not creator");
    _;
  }
  modifier isAdmin(){
    require(administration.isAdmin(msg.sender),"is not admin");
    _;
  }
  modifier isPreStakingTime(){
    require(now<staking_becomes_available_time,"is not prestakingtime");
    _;
  }
  modifier isStakingTime(){
    require(now>=staking_becomes_available_time && now<finalization_time,"is not staking time");
    _;
  }
  modifier contestFinalized(){
    require(now>=finalization_time && getWinningIndex()>0,"is not contestfinalized");
    _;
  }
  constructor(address token,address ghost3dcontract) public{
    ghostToken=IERC20(token);
    administration=new Admin();
    administration.addAdmin(ghost3dcontract);
    contractCreator=msg.sender;
    _reset();
  }


  function setWinningIndex1(bytes32 eh) public isCreator{
    require(now>=finalization_time,"is not finalization time");
    require(finalizationBlock==0,"finalization block is already set");
    entropyHash=eh;
    finalizationBlock=block.number+1;
  }
  //must call this before 256 blocks pass from setWinnngIndex1
  function setWinningIndex2(uint a,uint b) public isCreator{
    require(finalizationBlock!=0,"fblock is zero");
    require(block.number>=finalizationBlock,"block number not large enough yet");
    require(block.number<finalizationBlock+256,"block number progressed too far");
    require(keccak256(abi.encodePacked(a,b))==entropyHash,"hash does not match");
    winningIndex=random(cursor,finalizationBlock,a);
  }
  function getWinningIndex() public view returns(uint256){
    return winningIndex;//rp.data(datakey);
  }
  function getHashCombo(uint a,uint b) pure returns(bytes32){
    return keccak256(abi.encodePacked(a,b));
  }
  function maxRandom(uint blockn, uint256 entropy)
    internal
    returns (uint256 randomNumber)
    {
        return uint256(keccak256(
            abi.encodePacked(
              blockhash(blockn),
              entropy)
        ));
    }
  function random(uint256 upper, uint256 blockn, uint256 entropy)
    internal
    returns (uint256 randomNumber)
    {
        return maxRandom(blockn, entropy) % upper + 1;
    }


  //progress to the next round if no one entered the contest
  //unneeded because only one round
  /*
  function progressUnused() public isAdmin {
    require(now>=finalization_time && entry_cursor==0,"progressUnused failed");
    _reset();
  }
  */
  /*
    Only callable by contracts listed in isAdmin
  */
  function lockTokens(address entrant,uint toLock) public isStakingTime isAdmin{
    require(toLock>3);
    entry_cursor=entry_cursor.add(1);
    token_map[current_round][cursor.add(1)]=entry_cursor;
    token_map[current_round][cursor.add(toLock)]=entry_cursor;
    entry_position_map[current_round][entry_cursor]=cursor.add(1);
    cursor=cursor.add(toLock);
    entry_map[current_round][entry_cursor]=entrant;//msg.sender;
    token_count_by_address[entrant]=token_count_by_address[entrant].add(toLock);
    //token.transferFrom(entrant,this,toLock);
  }
  function withdrawMyFunds(uint left, uint right){
    withdrawFunds(left,right,msg.sender);
  }
  function withdrawFunds(uint left,uint right,address winner) public contestFinalized{//contestFinalized
    require(getWinningIndex().sub(left)!=getWinningIndex().add(right),"w1");//checked indexes should be different positions
    require(getWinningIndex()!=0,"w2");
    require(!withdrawOccurred);//can only be done once
    uint leftval=token_map[current_round][getWinningIndex().sub(left)];
    uint rightval=token_map[current_round][getWinningIndex().add(right)];
    require(leftval!=0,"w3");//both checked indexes should be nonzero
    require(leftval==rightval,"w4");//both checked values should be the same
    require(winner == entry_map[current_round][leftval],"w5");//check that the proposed winner actually submitted the given entry

    ghostToken.transfer(winner,ghostToken.balanceOf(address(this)));
    withdrawOccurred=true;
  }
  function _reset() private{
    current_round=current_round.add(1);
    cursor=0;
    entry_cursor=0;
    staking_becomes_available_time=now.add(pre_staking_period);
    finalization_time=staking_becomes_available_time.add(staking_period);
  }
  /*
    In case tokens are sent after lottery conclusion
  */
  function withdrawTokensAfter(address tokenAddr,address sendTo) public isCreator{
    require(withdrawOccurred); //only possible after winner has been paid.
    IERC20(tokenAddr).transfer(sendTo,IERC20(tokenAddr).balanceOf(address(this)));
  }
  function getWinningAddress() public view returns(address){
    var (l,r) = getWinningOffsets();
    return entry_map[current_round][token_map[current_round][getWinningIndex()-l]];
  }
  function getWinningOffsets() public view returns(uint,uint){
    if(getWinningIndex()==0 || entry_cursor<1){
      return(0,0);
    }
    if(entry_cursor==1){
      return (getWinningIndex()-1,cursor-getWinningIndex());//then return the first entry (the only one)
    }
    for(uint i=2;i<=entry_cursor;i++){
      if(entry_position_map[current_round][i]>getWinningIndex()){
        return (getWinningIndex()-entry_position_map[current_round][i-1],entry_position_map[current_round][i]-1-getWinningIndex());
      }
    }
    return (getWinningIndex()-entry_position_map[current_round][entry_cursor],cursor-getWinningIndex());
  }
  function getEthBalance() public view returns(uint){
    return address(this).balance;
  }
  function contestOver() public view returns(bool){
    return now>=finalization_time;
  }
  function timeToFinalization() public view returns(uint256){
    if(now<finalization_time){
      return finalization_time-now;
    }
    else{
      return 0;
    }
  }
  //fallback function
  function () public payable{
    revert();
  }
  //ends setup phase. Must call this after deploying all the contracts.
  function endSetup() public{
    setup_phase=false;
  }

}