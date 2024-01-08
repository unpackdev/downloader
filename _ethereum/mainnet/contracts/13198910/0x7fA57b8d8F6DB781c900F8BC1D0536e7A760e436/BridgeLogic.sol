pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./TokenLogic.sol";
import "./MPondLogic.sol";
import "./SafeERC20.sol";


// convertMultipleEpochs()
contract BridgeLogic is Initializable {
    using SafeMath for uint256;

    uint256 public constant pondPerMpond = 1000000;
    uint256 public constant epochLength = 1 days;
    uint256 public constant liquidityStartEpoch = 1;

    uint256 public liquidityBp;
    uint256 public lockTimeEpochs;
    uint256 public liquidityEpochLength;

    MPondLogic public mpond;
    TokenLogic public pond;
    address public owner;
    address public governanceProxy;
    uint256 public startTime;
    uint256 public liquidityStartTime;

    struct Requests {
        uint256 amount;
        uint256 releaseEpoch;
    }

    event PlacedRequest(
        address indexed sender,
        uint256 requestCreateEpoch,
        uint256 unlockRequestEpoch
    );
    event CancelledRequest(
        address indexed sender,
        uint256 indexed requestCreateEpoch
    );
    event MPondToPond(
        address indexed sender,
        uint256 indexed requestCreateEpoch,
        uint256 PondReceived
    );
    event PondToMPond(address indexed sender, uint256 MpondReceived);

    mapping(address => mapping(uint256 => Requests)) public requests; //address->epoch->Request(amount, lockTime)
    mapping(address => mapping(uint256 => uint256)) public claimedAmounts; //address->epoch->amount
    mapping(address => uint256) public totalAmountPlacedInRequests; //address -> amount

    address public stakingContract;

    function initialize(
        address _mpond,
        address _pond,
        address _owner,
        address _governanceProxy
    ) public initializer {
        mpond = MPondLogic(_mpond);
        pond = TokenLogic(_pond);
        owner = _owner;
        governanceProxy = _governanceProxy;
        startTime = block.timestamp;
        liquidityStartTime = block.timestamp;
        liquidityBp = 1000;
        lockTimeEpochs = 180;
        liquidityEpochLength = 180 days;
    }

    function changeStakingContract(address _newAddr) external {
        require(
            msg.sender == owner || msg.sender == governanceProxy,
            "Liquidity can be only changed by governance or owner"
        );
        stakingContract = _newAddr;
    }

    function changeLiquidityBp(uint256 _newLbp) external {
        require(
            msg.sender == owner || msg.sender == governanceProxy,
            "Liquidity can be only changed by governance or owner"
        );
        liquidityBp = _newLbp;
    }

    // input should be number of days
    function changeLockTimeEpochs(uint256 _newLockTimeEpochs) external {
        require(
            msg.sender == owner || msg.sender == governanceProxy,
            "LockTime can be only changed by goveranance or owner"
        );
        lockTimeEpochs = _newLockTimeEpochs;
    }

    // input should be number of days
    function changeLiquidityEpochLength(uint256 _newLiquidityEpochLength)
        external
    {
        require(
            msg.sender == owner || msg.sender == governanceProxy,
            "LiquidityEpoch length can only be changed by governance or owner"
        );
        liquidityEpochLength = _newLiquidityEpochLength.mul(1 days);
    }

    function getCurrentEpoch() internal view returns (uint256) {
        return (block.timestamp - startTime) / (epochLength);
    }

    function getLiquidityEpoch(uint256 _startTime) public view returns (uint256) {
        if (block.timestamp < _startTime) {
            return 0;
        }
        return
            (block.timestamp - _startTime) /
            (liquidityEpochLength) +
            liquidityStartEpoch;
    }

    function effectiveLiquidity(uint256 _startTime) public view returns (uint256) {
        uint256 effective = getLiquidityEpoch(_startTime).mul(liquidityBp);
        if (effective > 10000) {
            return 10000;
        }
        return effective;
    }

    function getConvertableAmount(address _address, uint256 _epoch)
        public
        view
        returns (uint256)
    {
        uint256 _reqAmount = requests[_address][_epoch].amount;
        uint256 _reqReleaseTime = requests[_address][_epoch].releaseEpoch.mul(epochLength).add(liquidityStartTime);
        uint256 _claimedAmount = claimedAmounts[_address][_epoch];
        if (_claimedAmount >= _reqAmount.mul(effectiveLiquidity(_reqReleaseTime)) / (10000)) {
            return 0;
        }
        return
            (_reqAmount.mul(effectiveLiquidity(_reqReleaseTime)) / (10000)).sub(
                _claimedAmount
            );
    }

    function convert(uint256 _epoch, uint256 _amount) public returns (uint256) {
        require(_amount != 0, "Should be non zero amount");
        uint256 _claimedAmount = claimedAmounts[msg.sender][_epoch];
        uint256 totalUnlockableAmount = _claimedAmount.add(_amount);
        Requests memory _req = requests[msg.sender][_epoch];
        uint256 _reqReleaseTime = _req.releaseEpoch.mul(epochLength).add(liquidityStartTime);

        // replace div with actual divide
        require(
            totalUnlockableAmount <=
                _req.amount.mul(effectiveLiquidity(_reqReleaseTime)) / (10000),
            "total unlock amount should be less than or equal to requests_amount*effective_liquidity."
        );
        require(
            getCurrentEpoch() >= _req.releaseEpoch,
            "Funds can only be released after requests exceed locktime"
        );
        claimedAmounts[msg.sender][_epoch] = totalUnlockableAmount;

        mpond.transferFrom(msg.sender, address(this), _amount);
        // pond.tranfer(msg.sender, _amount.mul(pondPerMpond));
        SafeERC20.safeTransfer(pond, msg.sender, _amount.mul(pondPerMpond));
        uint256 amountLockedInRequests = totalAmountPlacedInRequests[msg.sender];
        totalAmountPlacedInRequests[msg.sender] = amountLockedInRequests.sub(_amount);
        emit MPondToPond(msg.sender, _epoch, _amount.mul(pondPerMpond));
        return _amount.mul(pondPerMpond);
    }

    function placeRequest(uint256 amount) external returns (uint256, uint256) {
        uint256 epoch = getCurrentEpoch();
        uint256 amountInRequests = totalAmountPlacedInRequests[msg.sender];
        uint256 amountOnWhichRequestCanBePlaced = mpond
            .balanceOf(msg.sender)
            .add(mpond.delegates(stakingContract, msg.sender))
            .sub(amountInRequests);
        require(
            amount != 0 && amount <= amountOnWhichRequestCanBePlaced,
            "Request should be placed with amount greater than 0 and less than remainingAmount"
        );
        // require(
        //     amount != 0 && amount <= mpond.balanceOf(msg.sender),
        //     "Request should be placed with amount greater than 0 and less than the balance of the user"
        // );
        require(
            requests[msg.sender][epoch].amount == 0,
            "Only one request per epoch is acceptable"
        );
        Requests memory _req = Requests(amount, epoch.add(lockTimeEpochs));
        requests[msg.sender][epoch] = _req;
        totalAmountPlacedInRequests[msg.sender] = amountInRequests.add(amount);
        emit PlacedRequest(msg.sender, epoch, _req.releaseEpoch);
        return (epoch, _req.releaseEpoch);
    }

    function cancelRequest(uint256 _epoch) external {
        uint256 _epochAmount = requests[msg.sender][_epoch].amount;
        uint256 _claimedAmount = claimedAmounts[msg.sender][_epoch];
        uint256 _amountInRequests = totalAmountPlacedInRequests[msg.sender];

        delete requests[msg.sender][_epoch];
        delete claimedAmounts[msg.sender][_epoch];
        totalAmountPlacedInRequests[msg.sender] = _amountInRequests.add(_claimedAmount).sub(_epochAmount);

        emit CancelledRequest(msg.sender, _epoch);
    }

    function addLiquidity(uint256 _mpond, uint256 _pond)
        external
        onlyOwner("addLiquidity: only owner can call this function")
        returns (bool)
    {
        mpond.transferFrom(msg.sender, address(this), _mpond);
        // pond.transferFrom(msg.sender, address(this), _pond);
        SafeERC20.safeTransferFrom(pond, msg.sender, address(this), _pond);
        return true;
    }

    function removeLiquidity(
        uint256 _mpond,
        uint256 _pond,
        address _withdrawAddress
    )
        external
        onlyOwner("removeLiquidity: only owner can call this function")
        returns (bool)
    {
        mpond.transfer(_withdrawAddress, _mpond);
        // pond.transfer(_withdrawAddress, _pond);
        SafeERC20.safeTransfer(pond, _withdrawAddress, _pond);
        return true;
    }

    function getLiquidity() public view returns (uint256, uint256) {
        return (pond.balanceOf(address(this)), mpond.balanceOf(address(this)));
    }

    function getMpond(uint256 _mpond) public returns (uint256) {
        uint256 pondToDeduct = _mpond.mul(pondPerMpond);
        // pond.transferFrom(msg.sender, address(this), pondToDeduct);
        SafeERC20.safeTransferFrom(
            pond,
            msg.sender,
            address(this),
            pondToDeduct
        );
        mpond.transfer(msg.sender, _mpond);
        emit PondToMPond(msg.sender, _mpond);
        return pondToDeduct;
    }

    function transferOwner(address newOwner)
        public
        onlyOwner("transferOwner: only existing owner can call this function")
    {
        require(
            newOwner != address(0),
            "BridgeLogic: newOwner is the zero address"
        );
        owner = newOwner;
    }

    function renounceOwnership()
        public
        onlyOwner(
            "renounceOwnership: only existing owner can call this function"
        )
    {
        owner = address(0);
    }

    function transferGovernance(address newGoverance)
        public
        onlyGovernance(
            "transferGovernance: only governance can call this function"
        )
    {
        require(
            newGoverance != address(0),
            "BridgeLogic: newGovernance is the zero address"
        );
        governanceProxy = newGoverance;
    }

    modifier onlyOwner(string memory _error) {
        require(msg.sender == owner, _error);
        _;
    }
    modifier onlyGovernance(string memory _error) {
        require(msg.sender == governanceProxy, _error);
        _;
    }
}
