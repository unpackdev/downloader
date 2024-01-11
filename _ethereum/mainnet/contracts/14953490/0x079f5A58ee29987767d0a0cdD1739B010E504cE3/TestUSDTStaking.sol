// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./INftContract.sol";
import "./IRewardContract.sol";
import "./IUSDTStaking.sol";

/* 
    ERR-001 : You are not the owner of the token.
    ERR-002 : You do not have rights to that token.
    ERR-003 : Token already received.
    ERR-004 : The billing period has expired.
    ERR-005 : It's not the claim period yet.
*/
contract TestUSDTStaking is Ownable, Pausable, IUSDTStaking {
    using SafeMath for uint256;
    
    struct PlanStructure {
        uint256 earn;    // 하루당 보상
        uint256 duration;    // staking 기간 (flexible의 경우 0)
    }
    struct StakingStructure {
        uint256[] tokenIdArr;           // 적용할 tokenArr
        uint256 planIndex;              // 적용할 planIndex
        uint256 stakingStartTime;       // staking 시작 시간
        uint256 stakingExpiredTime;     // claim 가능 시간
        uint256 stakingClaimDueDate;    // 보상지급 만료 기간
        bool claimStatus;               // 지급 완료 유무 체크
    }

    uint8 public ERAN_DECIMAL;      // 보상 earn decimal
    uint8 public REWARD_DECIMAL;    // TAVA : 18, USDT : 6

    uint256 totalStakingCnt = 0;
    IRewardContract private rewardContract;
    INftContract private NftContract;
    mapping (uint256 => PlanStructure) private infoPlan;
    mapping (address => StakingStructure[]) private infoUserStaking; // (account => (tokenid => StakingStructure))

    // nft 소유자 확인
    modifier VerifyToken(uint256[] calldata _tokenIdArr) {
        for (uint256 i = 0; i < _tokenIdArr.length; i++) {
            require(NftContract.ownerOf(_tokenIdArr[i]) == _msgSender(), "ERR-001");
        }
        _;
    }

    // nft 권한 승인 확인
    modifier VerifyTokenApproved(uint256[] calldata _tokenIdArr) {
        for (uint256 i = 0; i < _tokenIdArr.length; i++) {
            require(NftContract.isApprovedForAll(_msgSender(), address(this)), "ERR-002");
        }
        _;
    }

    constructor (address _RewardContract, address _NFTAddress, uint8 _REWARD_DECIMAL, uint8 _ERAN_DECIMAL) {
        rewardContract = IRewardContract(_RewardContract);
        NftContract = INftContract(_NFTAddress);
        REWARD_DECIMAL = _REWARD_DECIMAL;
        ERAN_DECIMAL = _ERAN_DECIMAL;
    }

    // plan 생성, 수정
    function SetPlan(uint256 _planIndex, uint256 _earn, uint256 _duration) external override onlyOwner {
        infoPlan[_planIndex].earn = _earn;
        infoPlan[_planIndex].duration = _duration;
        emit PlanCreated(_earn, _duration, _planIndex);
    }

    // plan 정보 조회
    function GetInfoPlan(uint256 _planIndex) external override view onlyOwner returns(uint256, uint256){
        return (infoPlan[_planIndex].earn, infoPlan[_planIndex].duration);
    }

    // staking 시작
    function SetInfoStaking (uint256[] calldata _tokenIdArr, uint256 _planIndex) external override whenNotPaused VerifyToken(_tokenIdArr) VerifyTokenApproved(_tokenIdArr) {
        uint256 _stakingStartTime = block.timestamp;
        uint256 _stakingExpiredTime = _stakingStartTime + infoPlan[_planIndex].duration * 1 seconds;
        uint256 _stakingClaimDueDate = _stakingExpiredTime + 365 days;
        infoUserStaking[_msgSender()].push(StakingStructure(_tokenIdArr, _planIndex, _stakingStartTime, _stakingExpiredTime, _stakingClaimDueDate, false));
        for (uint256 i = 0; i < _tokenIdArr.length; i++) {
            NftContract.transferFrom(_msgSender(), address(this), _tokenIdArr[i]);
        }
        totalStakingCnt++;
        emit Staked(_msgSender());
    }

    // staking 정보 조회
    function GetInfoStaking(address _account, uint256 _stakingIndex) external override view returns (uint256 _earn, uint256 _duration, uint256 _startTime, uint256 _endTime){
        uint256 PlanIndex = infoUserStaking[_account][_stakingIndex].planIndex;
        _startTime = infoUserStaking[_account][_stakingIndex].stakingStartTime;
        _endTime = infoUserStaking[_account][_stakingIndex].stakingExpiredTime;
        _earn = infoPlan[PlanIndex].earn;
        _duration = infoPlan[PlanIndex].duration;          
    }

    // 총 staking 된 수량 표기
    function GetStakingOfAddressLength(address _account) public view returns(uint256){
        return infoUserStaking[_account].length;
    }

    // 보상받을 contract 수정
    function SetRewardContract(address _newRewardContract) external onlyOwner {
        rewardContract = IRewardContract(_newRewardContract);
    }

    // 연결할 Nft contract 수정
    function SetNftContract(address _newNftContract) external onlyOwner {
        NftContract = INftContract(_newNftContract);
    }

    // 보상 지급
    function Claim(uint256 _stakingIndex) external override whenNotPaused {
        // 보상 지급 만료 기간 확인
        StakingStructure memory _infoUserStaking = infoUserStaking[_msgSender()][_stakingIndex];

        require(!_infoUserStaking.claimStatus, "ERR-003");
        require(infoUserStaking[_msgSender()][_stakingIndex].stakingClaimDueDate > block.timestamp, "ERR-004"); 
        require(block.timestamp > infoUserStaking[_msgSender()][_stakingIndex].stakingExpiredTime, "ERR-005"); 

        uint256[] memory _tokenIdArr = _infoUserStaking.tokenIdArr;
        uint256 planIndex = _infoUserStaking.planIndex;

        // 보상 지급 & nft 전달
        for (uint256 i = 0; i < _tokenIdArr.length; i++) {
            uint256 earn = infoPlan[planIndex].earn;
            uint256 duration = infoPlan[planIndex].duration;
            NftContract.transferFrom(address(this), _msgSender(), _tokenIdArr[i]);
            rewardContract.transferFrom(address(this), _msgSender(), ((earn.mul(duration)).div(10**ERAN_DECIMAL)).mul(10**REWARD_DECIMAL) );
        }
        infoUserStaking[_msgSender()][_stakingIndex].claimStatus = true;
        totalStakingCnt--;
        emit Claimed(_msgSender());
    }
    
    // contract 내부의 ERC20 token 전량 회수
    function RetrieveToken() external override onlyOwner returns (uint256){
        rewardContract.transferFrom(address(this), _msgSender(), ERC20TokenBalance());
        return ERC20TokenBalance();
    }

    // contract 내부의 ERC20 token 회수
    function OwnerClaim (uint256 amount) external onlyOwner {
        rewardContract.transfer(address(this), amount);
    }

    // contract 내부의 ERC20 잔액 표시
    function ERC20TokenBalance() view override public returns (uint256){
        return rewardContract.balanceOf(address(this));
    }

    // 보상지급 권한 부여
    function ClaimApprove() public {
        rewardContract.approve(address(this), ERC20TokenBalance());
    }

    // earn decimal 수정
    function SetEarnDecimal(uint8 _ERAN_DECIMAL) external onlyOwner {
        ERAN_DECIMAL = _ERAN_DECIMAL;
    }

    // reward decimal 수정
    function SetRewardDecimal(uint8 _REWARD_DECIMAL) external onlyOwner {
        REWARD_DECIMAL = _REWARD_DECIMAL;
    }

    // 스테이킹, 보상지급 기능 잠금
    function Pause() external onlyOwner {
        super._pause();
    }

    // 스테이킹, 보상지급 기능 잠금 해제
    function Unpause() external onlyOwner {
        super._unpause();
    }
}