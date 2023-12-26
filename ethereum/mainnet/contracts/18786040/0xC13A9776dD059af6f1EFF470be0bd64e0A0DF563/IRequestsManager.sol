pragma solidity ^0.8.22;

interface IRequestsManager {

    event DepositRequestCreated(uint256 indexed id, address indexed requester, uint256 amount);
    event DepositRequestCompleted(uint256 indexed id, uint256 mintedAmount);

    event RedeemRequestCreated(uint256 indexed id, address indexed requester, uint256 amount);
    event RedeemRequestCompleted(uint256 indexed id, uint256 burnedAmount);

    error UnknownRequester(address account);
    error InvalidAmount(uint256 amount);
    error ZeroAddress();
    error IllegalState(State expected, State current);
    error IllegalAddress(address expected, address actual);
    error DepositRequestNotExist(uint256 id);
    error RedeemRequestNotExist(uint256 id);

    enum State {CREATED, COMPLETED}
    struct Request {
        uint256 id;
        address requester;
        State state;
        uint256 amount;
        bool exists;
    }

    function addRequester(address _requester) external;

    function removeRequester(address _requester) external;

    function setTreasury(address _treasuryAddress) external;

    function deposit(uint256 _amount) external;

    function completeDeposit(uint256 _id, uint256 _mintAmount) external;

    function redeem(uint256 _amount) external;

    function completeRedeem(uint256 _id, uint256 _collateralAmount) external;
}
