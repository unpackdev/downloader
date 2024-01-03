//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IXVIX.sol";
import "./IFloor.sol";
import "./IX2Distributor.sol";

contract BurnVault is ReentrancyGuard {
    using SafeMath for uint256;

    address public token;
    address public floor;
    address public distributor;
    address public gov;

    uint256 public initialDivisor;
    uint256 public _totalSupply;

    mapping (address => uint256) public balances;
    mapping (address => bool) public senders;

    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);
    event GovChange(address gov);
    event DistributorChange(address distributor);

    modifier onlyGov() {
        require(msg.sender == gov, "BurnVault: forbidden");
        _;
    }

    constructor(address _token, address _floor) public {
        token = _token;
        floor = _floor;
        initialDivisor = IXVIX(_token).normalDivisor();
        gov = msg.sender;
    }

    function setGov(address _gov) public onlyGov {
        gov = _gov;
        emit GovChange(_gov);
    }

    function setDistributor(address _distributor) public onlyGov {
        distributor = _distributor;
        emit DistributorChange(_distributor);
    }

    function addSender(address _sender) external onlyGov {
        require(!senders[_sender], "BurnVault: sender already added");
        senders[_sender] = true;
    }

    function removeSender(address _sender) external onlyGov {
        require(senders[_sender], "BurnVault: invalid sender");
        senders[_sender] = false;
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "BurnVault: insufficient amount");

        address account = msg.sender;
        IERC20(token).transferFrom(account, address(this), _amount);

        uint256 scaledAmount = _amount.mul(getDivisor());
        balances[account] = balances[account].add(scaledAmount);
        _totalSupply = _totalSupply.add(scaledAmount);

        emit Deposit(account, _amount);
    }

    function withdraw(address _receiver, uint256 _amount) external nonReentrant {
        require(_amount > 0, "BurnVault: insufficient amount");

        address account = msg.sender;
        uint256 scaledAmount = _amount.mul(getDivisor());
        balances[account] = balances[account].sub(scaledAmount);
        _totalSupply = _totalSupply.sub(scaledAmount);

        IERC20(token).transfer(_receiver, _amount);

        emit Withdraw(account, _amount);
    }

    function distribute() external nonReentrant returns (uint256) {
        require(senders[msg.sender], "BurnVault: forbidden");
        address _distributor = distributor;

        address receiver = msg.sender;

        uint256 _toBurn = toBurn();
        if (_toBurn == 0) {
            return IX2Distributor(_distributor).distribute(receiver, 0);
        }

        uint256 refundAmount = IFloor(floor).getRefundAmount(_toBurn);
        if (refundAmount == 0) {
            return IX2Distributor(_distributor).distribute(receiver, 0);
        }

        uint256 ethAmount = IFloor(floor).refund(_distributor, _toBurn);
        return IX2Distributor(_distributor).distribute(receiver, ethAmount);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply.div(getDivisor());
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account].div(getDivisor());
    }

    function toBurn() public view returns (uint256) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        return balance.sub(totalSupply());
    }

    function getDivisor() public view returns (uint256) {
        uint256 normalDivisor = IXVIX(token).normalDivisor();
        uint256 _initialDivisor = initialDivisor;
        uint256 diff = normalDivisor.sub(_initialDivisor).div(2);
        return _initialDivisor.add(diff);
    }
}
