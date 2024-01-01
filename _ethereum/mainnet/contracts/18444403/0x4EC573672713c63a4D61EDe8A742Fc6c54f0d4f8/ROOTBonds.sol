// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./ROOT.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ISmartWalletWhitelist.sol";

contract ROOTBonds is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    ROOT public root;
    IERC20 public quoteToken;

    uint256 public feeBP;
    uint256 public totalDebt;
    uint256 public lastDecay; // reference block for debt decay
    uint256 public vestingPeriod;
    uint256 public minPrice; // bondingToken wei per 1e18 wei ROOT
    uint256 public maxPayout; // in bondingToken

    uint256 public controlVariable;
    uint256 public controlVariableTarget;
    uint256 public controlVariableStep;
    uint256 public controlVariableBuffer;
    uint256 public lastAdjustment;

    address public smartWalletChecker;

    bool public active;

    // Info for bond holder
    struct Bond {
        uint payout; // ROOT to be paid
        uint vestedTill; // block timestamp when bond is fully vested
        uint pricePaid; // In ETH, for front end viewing
        bool claimed;
    }

    mapping(address => Bond[]) public bonds;
    mapping(address => uint256) public lowestUnvestedIndex;
    mapping(address => uint256) public totalBondPayout;

    uint256 totalBondPayoutAllUsers;

    event BondCreated(
        address indexed user,
        uint256 indexed index,
        uint256 amount,
        uint256 payout
    );
    event BondRedeemed(
        address indexed user,
        uint256 indexed index,
        uint256 indexed payout
    );
    event BondPriceChanged(uint256 indexed price, uint256 indexed debtRatio);
    event ControlVariableUpdated(
        uint256 indexed oldBCV,
        uint256 indexed newBCV
    );

    modifier onlyWhitelisted() {
        if (tx.origin != msg.sender) {
            require(
                address(smartWalletChecker) != address(0),
                "Not whitelisted"
            );
            require(
                ISmartWalletWhitelist(smartWalletChecker).check(msg.sender),
                "Not whitelisted"
            );
        }
        _;
    }

    constructor(
        address _root,
        address _quoteToken,
        address _smartWalletChecker
    ) {
        require(_root != address(0), "Zero Address");
        require(_quoteToken != address(0), "Zero Address");
        require(_smartWalletChecker != address(0), "Zero Address");
        root = ROOT(_root);
        quoteToken = IERC20(_quoteToken);
        smartWalletChecker = _smartWalletChecker;
    }

    function initialize(
        uint256 _feeBP,
        uint256 _vestingPeriod,
        uint256 _minPrice,
        uint256 _maxPayout,
        uint256 _controlVariable
    ) external onlyOwner {
        require(!active, "ROOTBonds : Already active");
        require(_feeBP <= 10000, "ROOTBonds : Fee cannot exceed 100%");
        feeBP = _feeBP;
        vestingPeriod = _vestingPeriod;
        minPrice = _minPrice;
        maxPayout = _maxPayout;
        controlVariable = _controlVariable;
        controlVariableTarget = controlVariable;
        controlVariableStep = 0;
        controlVariableBuffer = 0;
        active = true;
    }

    function deactivate() external onlyOwner {
        require(active, "ROOTBonds : Already inactive");
        active = false;
    }

    function setFeeBP(uint256 _feeBP) external onlyOwner {
        require(_feeBP <= 10000, "ROOTBonds : Fee cannot exceed 100%");
        feeBP = _feeBP;
    }

    function setVestingPeriod(uint256 _vestingPeriod) external onlyOwner {
        vestingPeriod = _vestingPeriod;
    }

    function setMinPrice(uint256 _minPrice) external onlyOwner {
        minPrice = _minPrice;
    }

    function setMaxPayout(uint256 _maxPayout) external onlyOwner {
        maxPayout = _maxPayout;
    }

    function setControlVariableAdjustment(
        uint256 _controlVariableTarget,
        uint256 _controlVariableStep,
        uint256 _controlVariableBuffer
    ) external onlyOwner {
        if (_controlVariableTarget > controlVariable) {
            require(
                (_controlVariableTarget - controlVariable) %
                    _controlVariableStep ==
                    0,
                "ROOTBonds : Invalid control variable step"
            );
        } else {
            require(
                (controlVariable - _controlVariableTarget) %
                    _controlVariableStep ==
                    0,
                "ROOTBonds : Invalid control variable step"
            );
        }
        controlVariableTarget = _controlVariableTarget;
        controlVariableStep = _controlVariableStep;
        controlVariableBuffer = _controlVariableBuffer;
    }

    function _adjust() internal {
        if (
            (controlVariable != controlVariableTarget) &&
            (block.timestamp - lastAdjustment > controlVariableBuffer)
        ) {
            uint256 oldControlVariable = controlVariable;
            lastAdjustment = block.timestamp;
            if (controlVariable < controlVariableTarget) {
                controlVariable = controlVariable + controlVariableStep;
                if (controlVariable > controlVariableTarget) {
                    controlVariable = controlVariableTarget;
                }
            } else {
                controlVariable = controlVariable - controlVariableStep;
                if (controlVariable < controlVariableTarget) {
                    controlVariable = controlVariableTarget;
                }
            }
            emit ControlVariableUpdated(oldControlVariable, controlVariable);
        }
    }

    function _decayDebt() internal {
        totalDebt -= debtDecay();
        lastDecay = block.timestamp;
    }

    function debtDecay() public view returns (uint256) {
        if (block.timestamp - lastDecay > vestingPeriod) {
            return totalDebt;
        }
        return (totalDebt * (block.timestamp - lastDecay)) / vestingPeriod;
    }

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt() public view returns (uint) {
        return totalDebt - debtDecay();
    }

    function payout(uint256 _amount) public view returns (uint256) {
        return (_amount * 1e18) / bondPrice();
    }

    function bondPrice() public view returns (uint256) {
        uint256 price = debtRatio() * controlVariable;
        if (price < minPrice) {
            price = minPrice;
        }
        return price;
    }

    function debtRatio() public view returns (uint256) {
        return (totalDebt * 1e9) / root.totalSupply();
    }

    function deposit(
        uint256 _amount,
        uint256 _minPayout,
        address to
    ) external nonReentrant onlyWhitelisted returns (uint256) {
        require(active, "ROOTBonds : Bonds are not active");
        require(_amount > 0, "ROOTBonds : Cannot bond 0");
        require(to != address(0), "ROOTBonds : Cannot bond to 0 address");
        require(
            _minPayout > 10000000,
            "ROOTBonds : Min payout must be greater than 10000000 wei"
        );
        _decayDebt();

        uint256 _payout = payout(_amount);
        require(_payout >= _minPayout, "ROOTBonds : Insufficient payout");
        require(
            _payout <= maxPayout,
            "ROOTBonds : Bonding amount exceeds max payout"
        );

        quoteToken.safeTransferFrom(msg.sender, owner(), _amount);
        root.mint(address(this), _payout);
        root.mint(owner(), (_payout * feeBP) / 10000);

        bonds[to].push(
            Bond({
                payout: _payout,
                vestedTill: block.timestamp + vestingPeriod,
                pricePaid: bondPrice(),
                claimed: false
            })
        );

        totalBondPayout[to] += _payout;
        totalDebt += _payout;
        totalBondPayoutAllUsers += _payout;

        _adjust(); // control variable is adjusted

        emit BondCreated(to, bonds[to].length - 1, _amount, _payout);
        emit BondPriceChanged(bondPrice(), debtRatio());

        return _payout;
    }

    function claim() external nonReentrant onlyWhitelisted {
        uint256 bondCount = bonds[msg.sender].length;
        uint256 totalPayout;
        require(bondCount > 0, "ROOTBonds : No bonds to redeem");
        require(
            lowestUnvestedIndex[msg.sender] < bondCount,
            "ROOTBonds : All bonds have been redeemed"
        );
        for (uint256 i = lowestUnvestedIndex[msg.sender]; i < bondCount; i++) {
            if (bonds[msg.sender][i].vestedTill > block.timestamp) {
                break;
            }
            totalPayout += bonds[msg.sender][i].payout;
            lowestUnvestedIndex[msg.sender]++;
            bonds[msg.sender][i].claimed = true;
            emit BondRedeemed(msg.sender, i, bonds[msg.sender][i].payout);
        }
        require(totalPayout > 0, "ROOTBonds : No bonds to redeem");
        IERC20(root).safeTransfer(msg.sender, totalPayout);
    }

    function claimable(address _account) external view returns (uint256) {
        uint256 totalPayout;
        uint256 bondCount = bonds[_account].length;
        if (bondCount == 0 || lowestUnvestedIndex[_account] < bondCount) {
            return 0;
        }
        for (uint256 i = lowestUnvestedIndex[_account]; i < bondCount; i++) {
            if (bonds[_account][i].vestedTill > block.timestamp) {
                break;
            }
            totalPayout += bonds[_account][i].payout;
        }
        return totalPayout;
    }

    function getBond(
        address _address,
        uint256 _index
    ) external view returns (uint256, uint256, uint256, bool) {
        Bond memory bondToReturn = bonds[_address][_index];
        return (
            bondToReturn.payout,
            bondToReturn.vestedTill,
            bondToReturn.pricePaid,
            bondToReturn.claimed
        );
    }

    function getBondCount(address _address) public view returns (uint256) {
        return bonds[_address].length;
    }

    function getTotalBondPayoutAllUsers() external view returns (uint256) {
        return totalBondPayoutAllUsers;
    }

    function getTotalPayout(address _account) external view returns (uint256) {
        uint256 _totalPayout;
        uint256 _bondCount = getBondCount(_account);
        for (uint256 i = 0; i < _bondCount; i++) {
            if (!bonds[_account][i].claimed) {
                _totalPayout += bonds[_account][i].payout;
            }
        }
        return _totalPayout;
    }

    function emergencyWithdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}
