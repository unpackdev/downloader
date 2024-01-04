pragma solidity >=0.6.0 <0.8.0;
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./ObortechToken.sol";


contract FreezingContract is Ownable {
    using SafeMath for uint;
    uint256 constant private FOUNDERS_TOKENS = 60_000_000 * 10 ** 18;
    uint256 constant private MANAGEMENTS_TOKENS = 10_000_000 * 10 ** 18;

    IERC20 private token;
    uint256 private startTimestamp;
    uint256 private withdrawalFoundersCounter;
    address private founderAddress;
    address private managementAddress;
    uint256 constant ONE_YEAR = 365;

    function getStartTimestamp() external view returns (uint256) {
        return startTimestamp;
    }

    function getFounderAddress() external view returns (address) {
        return founderAddress;
    }

    function getManagementAddress() external view returns (address) {
        return managementAddress;
    }

    function getUnlockTimeManagementAddress() external view returns (uint256) {
        return startTimestamp + 4 * ONE_YEAR * 1 days;
    }

    function getNearestUnlockTimeFoundersTokens() external view returns (uint256) {
        if (withdrawalFoundersCounter >= 4) {
            return 0;
        }
        return startTimestamp + withdrawalFoundersCounter * ONE_YEAR.div(2) * 1 days;
    }

    function configure(
        address _token,
        uint256 _startTimestamp,
        address _founderAddress,
        address _managementAddress) external
    {
        token = IERC20(_token);
        startTimestamp = _startTimestamp;
        founderAddress = _founderAddress;
        managementAddress = _managementAddress;
        token.transferFrom(_msgSender(), address(this), FOUNDERS_TOKENS + MANAGEMENTS_TOKENS);
        withdrawalFoundersCounter = 0;
    }

    function setFounderAddress(address _founderAddress) external onlyOwner {
        require(_founderAddress != address(0), 'incorrect founderAddress');
        founderAddress = _founderAddress;
    }

    function setManagementAddress(address _managementAddress) external onlyOwner {
        require(_managementAddress != address(0), 'incorrect managementAddress');
        managementAddress = _managementAddress;
    }

    function unfreezeFoundersTokens() external {
        require(
            block.timestamp >= startTimestamp + withdrawalFoundersCounter * ONE_YEAR.div(2) * 1 days,
            "Cannot unlock tokens");
        require(withdrawalFoundersCounter < 4, "tokens is over");
        withdrawalFoundersCounter++;
        token.transfer(founderAddress, FOUNDERS_TOKENS.div(4));
    }

    function unfreezeManagementsTokens() external {
        require (block.timestamp >= startTimestamp + 2 * ONE_YEAR * 1 days, "Cannot unlock tokens");
        token.transfer(managementAddress, MANAGEMENTS_TOKENS);
    }
}
