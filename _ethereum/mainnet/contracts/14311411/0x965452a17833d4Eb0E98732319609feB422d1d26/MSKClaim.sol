pragma solidity ^0.8.9;
import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Context.sol";

contract MSKClaim is Context, Ownable {
    using SafeMath for uint256;

    event Claim(address indexed owner, uint256 indexed amount);

    struct ClaimInfo {
        uint32 time;
        uint224 amount;
    }

    uint32 private m_StartTime = 1643328000; // Jan-28-2022 00:00 UTC
    uint32 private m_EndTime = 1958774400; // Jan-27-2032 00:00 UTC

    uint256 private m_MSKPerDay = 100 ether;

    address private m_MSK = 0x72D7b17bF63322A943d4A2873310a83DcdBc3c8D;
    address private m_Badbear = 0x5E4aAB148410DE1CB50cDCD5108e1260Cc36d266;

    address private m_ClaimWallet = 0xA69e1e8f7afd56126452AcDbCe27374570a52D48;

    bool private m_ClaimPaused = true;

    mapping(address => ClaimInfo) private m_ClaimInfoList;

    constructor() {}

    function eventTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external {
        m_ClaimInfoList[from].amount = uint224(_calcRewardAmount(from));
        m_ClaimInfoList[from].time = uint32(block.timestamp);

        m_ClaimInfoList[to].amount = uint224(_calcRewardAmount(to));
        m_ClaimInfoList[to].time = uint32(block.timestamp);
    }

    function _calcRewardAmount(address _address)
        internal
        view
        returns (uint256)
    {
        ClaimInfo memory claimInfo = m_ClaimInfoList[_address];
        IERC721 badbear = IERC721(m_Badbear);

        uint32 lastRewardTime = m_StartTime > claimInfo.time
            ? m_StartTime
            : claimInfo.time;

        uint32 endTime = m_EndTime > uint32(block.timestamp)
            ? uint32(block.timestamp)
            : m_EndTime;

        uint256 rewardAmount = claimInfo.amount;

        if (lastRewardTime > endTime) return rewardAmount;

        uint256 newAmount = m_MSKPerDay * (endTime - lastRewardTime);
        newAmount = newAmount.div(1 days).mul(badbear.balanceOf(_address));

        return (rewardAmount.add(newAmount));
    }

    function claimMsk(uint256 _amount) external {
        require(m_ClaimPaused == false);
        uint256 availableAmount = _calcRewardAmount(_msgSender());

        require(availableAmount >= _amount);

        IERC20 msk = IERC20(m_MSK);
        msk.transferFrom(m_ClaimWallet, _msgSender(), _amount);

        m_ClaimInfoList[_msgSender()].amount = uint224(
            availableAmount.sub(_amount)
        );
        m_ClaimInfoList[_msgSender()].time = uint32(block.timestamp);

        emit Claim(_msgSender(), _amount);
    }

    function calcRewardAmount(address _address)
        external
        view
        returns (uint256)
    {
        return _calcRewardAmount(_address);
    }

    function setClaimWallet(address _rewardWallet) external onlyOwner {
        m_ClaimWallet = _rewardWallet;
    }

    function getClaimWallet() external view returns (address) {
        return m_ClaimWallet;
    }

    function setMSKperDay(uint256 _mskPerDay) external onlyOwner {
        m_MSKPerDay = _mskPerDay.mul(1 ether);
    }

    function getMSKperDay() external view returns (uint256) {
        return m_MSKPerDay.div(1 ether);
    }

    function setStartTime(uint32 _startTime) external onlyOwner {
        m_StartTime = _startTime;
    }

    function getStartTime() external view returns (uint32) {
        return m_StartTime;
    }

    function setEndTime(uint32 _endTime) external onlyOwner {
        m_EndTime = _endTime;
    }

    function getEndTime() external view returns (uint32) {
        return m_EndTime;
    }

    function setClaimPaused(bool _claimPaused) external onlyOwner {
        m_ClaimPaused = _claimPaused;
    }

    function getClaimPaused() external view returns (bool) {
        return m_ClaimPaused;
    }

    // ######## MSK & BADBEAR #########
    function setMskContract(address _address) external onlyOwner {
        m_MSK = _address;
    }

    function getMskContract() external view returns (address) {
        return m_MSK;
    }

    function setBadbearContract(address _address) external onlyOwner {
        m_Badbear = _address;
    }

    function getBadbearContract() external view returns (address) {
        return m_Badbear;
    }
}
