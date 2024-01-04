pragma solidity ^0.6.0;

import "./AccessControl.sol";
import "./Address.sol";
import "./SafeMath.sol";

import "./IEURxb.sol";
import "./LinkedList.sol";
import "./Initializable.sol";
import "./OverrideERC20.sol";

import "./TokenAccessRoles.sol";


/**
 * @title EURxb
 * @dev EURxb token
 */
contract EURxb is AccessControl, OverrideERC20, IEURxb, Initializable {
    using SafeMath for uint256;
    using Address for address;
    using LinkedList for LinkedList.List;

    uint256 private constant UNIT = 10**18;
    uint256 private constant PER_YEAR = 31536000 * 10 ** 18; // UNIT.mul(365).mul(86400);

    uint256 private _countMaturity;
    uint256 private _totalActiveValue;
    uint256 private _annualInterest;
    uint256 private _accrualTimestamp;
    uint256 private _expIndex;

    mapping(address => uint256) private _holderIndex;

    LinkedList.List private _list; // list of maturity ends and amounts
    mapping(uint256 => uint256) private _deletedMaturity; // timestamp->amount

    address private _ddp;

    modifier onlyDDP() {
        require(_msgSender() == _ddp, "Caller is not allowed this function");
        _;
    }

    constructor(address admin) public OverrideERC20("EURxb", "EURxb") {
        _annualInterest = 7 * 10**16;
        _expIndex = UNIT;
        _countMaturity = 100;

        _setupRole(TokenAccessRoles.admin(), admin);
    }

    function configure(address ddp) external initializer {
        _ddp = ddp;

        _setupRole(TokenAccessRoles.minter(), ddp);
        _setupRole(TokenAccessRoles.burner(), ddp);
    }

    /**
     * @dev Return countMaturity
     */
    function countMaturity() external view returns (uint256) {
        return _countMaturity;
    }

    /**
     * @dev Return totalActiveValue
     */
    function totalActiveValue() external view returns (uint256) {
        return _totalActiveValue;
    }

    /**
     * @dev Return annualInterest
     */
    function annualInterest() external view returns (uint256) {
        return _annualInterest;
    }

    /**
     * @dev Return accrualTimestamp
     */
    function accrualTimestamp() external view returns (uint256) {
        return _accrualTimestamp;
    }

    /**
     * @dev Return expIndex
     */
    function expIndex() external view returns (uint256) {
        return _expIndex;
    }

    /**
     * @dev Return first added maturity
     */
    function getFirstMaturity() external view returns (uint256) {
        uint256 head = _list.getHead();
        (, uint256 maturityEnd, , ) = _list.getNodeValue(head);
        return maturityEnd;
    }

    /**
     * @dev Return last added maturity
     */
    function getLastMaturity() external view returns (uint256) {
        uint256 end = _list.getEnd();
        (, uint256 maturityEnd, , ) = _list.getNodeValue(end);
        return maturityEnd;
    }

    /**
    * @dev Return first maturity id
    */
    function getFirstMaturityId() external view returns (uint256) {
        return _list.getHead();
    }

    /**
    * @dev Return maturity info by id
    */
    function getMaturityInfo(uint256 id) external view returns (uint256 amount, uint256 maturity, uint256 prev ,uint256 next) {
        (amount, maturity, prev , next) = _list.getNodeValue(id);
        amount = amount.sub(_deletedMaturity[maturity]);
    }

    /**
     * @dev Set countMaturity
     * @param count maturity
     */
    function setCountMaturity(uint256 count) external {
        require(
            hasRole(TokenAccessRoles.admin(), _msgSender()),
            "Caller is not an admin"
        );
        require(count > 0, "The amount must be greater than zero");
        _countMaturity = count;
    }

    /**
     * @dev Mint tokens
     * @param account user address
     * @param amount number of tokens
     */
    function mint(address account, uint256 amount) external override {
        require(
            hasRole(TokenAccessRoles.minter(), _msgSender()),
            "Caller is not an minter"
        );
        require(account != address(0), "Mint to zero address");
        accrueInterest();
        _updateBalance(account);

        super._mint(account, amount);
    }

    /**
     * @dev Burn tokens
     * @param account user address
     * @param amount number of tokens
     */
    function burn(address account, uint256 amount) external override {
        require(
            hasRole(TokenAccessRoles.burner(), _msgSender()),
            "Caller is not an burner"
        );
        require(account != address(0), "Burn from zero address");
        accrueInterest();
        _updateBalance(account);

        super._burn(account, amount);
    }

    /**
     * @dev Added new maturity
     * @param amount number of tokens
     * @param maturityEnd end date of interest accrual
     */
    function addNewMaturity(uint256 amount, uint256 maturityEnd) onlyDDP external override {
//        require(amount > 0, "The amount must be greater than zero"); // TODO: check into DDP
//        require(maturityEnd > 0, "End date must be greater than zero");

        _totalActiveValue = _totalActiveValue.add(amount);

        if (!_list.listExists()) {
            _list.pushBack(amount, maturityEnd);
            return;
        }

        uint256 id = _list.getEnd();
        (, uint256 maturityNode, uint256 prevIDNode, uint256 nextIDNode) = _list.getNodeValue(id);

        if (maturityNode < maturityEnd) { // Check end list
            _list.pushBack(amount, maturityEnd);
            return;
        }

        // TODO: maybe many elements
        // TODO: maybe you need to add close dates
        while (true) {
            if (maturityNode == maturityEnd) { // Check equal
                _list.addElementAmount(id, amount);
                break;
            }

            if (id == _list.getHead() && maturityNode > maturityEnd) { // Check before first
                _list.pushBefore(id, amount, maturityEnd);
                break;
            }

            id = prevIDNode;
            (, maturityNode, prevIDNode, nextIDNode) = _list.getNodeValue(id);

            if (maturityNode < maturityEnd) { // Check between periods
                _list.pushBefore(nextIDNode, amount, maturityEnd);
                break;
            }
        }
    }

    /**
     * @dev Remove maturity
     * @param amount number of tokens
     * @param maturityEnd end date of interest accrual
     */
    function removeMaturity(uint256 amount, uint256 maturityEnd) onlyDDP external override {
//        require(amount > 0, "The amount must be greater than zero"); // TODO: check into DDP
//        require(maturityEnd > 0, "End date must be greater than zero");
        require(_list.listExists(), "The list does not exist");

        _totalActiveValue = _totalActiveValue.sub(amount);
        _deletedMaturity[maturityEnd] = _deletedMaturity[maturityEnd].add(amount);
    }

    /**
     * @dev Return user balance
     * @param account user address
     */
    function balanceOf(address account) public override view returns (uint256) {
        return balanceByTime(account, block.timestamp);
    }

    /**
     * @dev User balance calculation
     * @param account user address
     * @param timestamp date
     */
    function balanceByTime(address account, uint256 timestamp)
        public
        view
        returns (uint256)
    {
        if (super.balanceOf(account) > 0 && _holderIndex[account] > 0) {
            uint256 currentTotalActiveValue = _totalActiveValue;
            uint256 currentExpIndex = _expIndex;
            uint256 head = _list.getHead();
            uint256 currentAccrualTimestamp = _accrualTimestamp;
            (uint256 amount, uint256 maturityEnd, , uint256 next) = _list.getNodeValue(head);
            while (
                _list.listExists() && maturityEnd <= timestamp && currentAccrualTimestamp < maturityEnd
            ) {
                currentExpIndex = _calculateInterest(
                    maturityEnd,
                    _annualInterest.mul(currentTotalActiveValue),
                    currentExpIndex,
                    currentAccrualTimestamp
                );
                currentAccrualTimestamp = maturityEnd;

                uint256 deleteAmount = _deletedMaturity[maturityEnd];
                currentTotalActiveValue = currentTotalActiveValue.sub(amount.sub(deleteAmount));

                if (next == 0) {
                    break;
                }

                (amount, maturityEnd, , next) = _list.getNodeValue(next);
            }

            currentExpIndex = _calculateInterest(
                timestamp,
                _annualInterest.mul(currentTotalActiveValue),
                currentExpIndex,
                currentAccrualTimestamp
            );
            return super.balanceOf(account).mul(currentExpIndex).div(_holderIndex[account]);
        }
        return super.balanceOf(account);
    }

    /**
     * @dev Calculation of accrued interest
     */
    function accrueInterest() public {
        uint256 head = _list.getHead();
        (uint256 amount, uint256 maturityEnd, , uint256 next) = _list.getNodeValue(head);

        for (uint256 i = 1;
            _list.listExists() && maturityEnd <= block.timestamp && _accrualTimestamp < maturityEnd;
            i++) {
            _expIndex = _calculateInterest(
                maturityEnd,
                _annualInterest.mul(_totalActiveValue),
                _expIndex,
                _accrualTimestamp
            );
            _accrualTimestamp = maturityEnd;

            uint256 deleteAmount = _deletedMaturity[maturityEnd];
            _totalActiveValue = _totalActiveValue.sub(amount.sub(deleteAmount));
//                delete _deletedMaturity[maturityEnd]; // save for history

            if (next == 0) {
                break;
            }

            _list.setHead(next);
            (amount, maturityEnd, , next) = _list.getNodeValue(next);

            if (i == _countMaturity) {
                return; // pagination counter overflow
            }
        }

        _expIndex = _calculateInterest(
            block.timestamp,
            _annualInterest.mul(_totalActiveValue),
            _expIndex,
            _accrualTimestamp
        );
        _accrualTimestamp = block.timestamp;
    }

    /**
     * @dev Calculate interest
     * @param timestampNow the current date
     * @param interest percent
     * @param prevIndex previous index
     */
    function _calculateInterest(uint256 timestampNow, uint256 interest, uint256 prevIndex, uint256 lastAccrualTimestamp)
        internal
        view
        returns (uint256)
    {
        if (totalSupply() == 0) {
            return prevIndex;
        }

        uint256 period = timestampNow.sub(lastAccrualTimestamp);
        if (period < 60) {
            return prevIndex;
        }

        uint256 interestFactor = interest.mul(period);
        uint256 newExpIndex = (interestFactor.mul(prevIndex).div(PER_YEAR).div(totalSupply()))
            .add(prevIndex);
        return newExpIndex;
    }

    /**
     * @dev Update user balance
     * @param account user address
     */
    function _updateBalance(address account) internal {
        uint256 balance = super.balanceOf(account);
        if (_holderIndex[account] > 0) {
            uint256 newBalance = balance.mul(_expIndex).div(
                _holderIndex[account]
            );
            uint256 delta = newBalance.sub(balance);

            if (delta != 0) {
                super._mint(account, delta);
            }
        }
        _holderIndex[account] = _expIndex;
    }

    /**
     * @dev Transfer tokens
     * @param sender user address
     * @param recipient user address
     * @param amount number of tokens
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        accrueInterest();
        if (sender != address(0)) {
            _updateBalance(sender);
        }
        if (recipient != address(0)) {
            _updateBalance(recipient);
        }
        super._transfer(sender, recipient, amount);
    }
}
