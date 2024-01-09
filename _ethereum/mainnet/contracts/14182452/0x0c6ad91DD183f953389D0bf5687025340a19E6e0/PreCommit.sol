// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.6;

import "IERC20.sol";
import "SafeERC20.sol";
import "SafeMath.sol";
import "IVaderBond.sol";
import "IPreCommit.sol";
import "Ownable.sol";

contract PreCommit is IPreCommit, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event Commit(address indexed depositor, uint amount, uint index);
    event UnCommit(address indexed depositor, uint index, uint last);

    struct CommitStruct {
        uint amount;
        address depositor;
    }

    IVaderBond public immutable bond;
    IERC20 public immutable tokenIn;
    uint public maxCommits;
    uint public minAmountIn;
    uint public maxAmountIn;

    // total amount commited
    uint public total;
    // open for users to commit
    bool public open;
    CommitStruct[] public commits;

    constructor(address _bond, address _tokenIn) {
        bond = IVaderBond(_bond);
        tokenIn = IERC20(_tokenIn);
    }

    modifier isOpen() {
        require(open, "not open");
        _;
    }

    modifier isClosed() {
        require(!open, "not closed");
        _;
    }

    function count() external view returns (uint) {
        return commits.length;
    }

    function start(
        uint _maxCommits,
        uint _minAmountIn,
        uint _maxAmountIn
    ) external onlyOwner isClosed {
        require(_maxAmountIn >= _minAmountIn, "min > max");

        open = true;
        // a = amount to commit
        // v = treasury.valueOf(a)
        // p = bond.payoutFor(v)
        //   = v / bond price
        // min amount in = a such that p >= 0.01 Vader
        // max amount in = a such that p <= bond.maxPayout()
        //                                = % of vader total supply
        // bond total debt >= max commits * max amount in
        maxCommits = _maxCommits;
        minAmountIn = _minAmountIn;
        maxAmountIn = _maxAmountIn;
    }

    function commit(address _depositor, uint _amount) external override isOpen {
        require(commits.length < maxCommits, "commits > max");
        require(_depositor != address(0), "depositor = zero address");
        require(_amount >= minAmountIn, "amount < min");
        require(_amount <= maxAmountIn, "amount > max");

        tokenIn.safeTransferFrom(msg.sender, address(this), _amount);

        commits.push(CommitStruct({amount: _amount, depositor: _depositor}));
        total = total.add(_amount);

        emit Commit(_depositor, _amount, commits.length - 1);
    }

    function uncommit(uint _index) external isOpen {
        CommitStruct memory _commit = commits[_index];
        require(_commit.depositor == msg.sender, "not depositor");

        // replace commits[index] with last commit
        uint last = commits.length - 1;
        if (_index != last) {
            commits[_index] = commits[last];
        }
        commits.pop();

        total = total.sub(_commit.amount);
        tokenIn.safeTransfer(msg.sender, _commit.amount);

        emit UnCommit(msg.sender, _index, last);
    }

    // NOTE: total debt >= Bond.payoutFor(maxAmountIn * maxCommits)
    function init(
        uint _controlVariable,
        uint _vestingTerm,
        uint _minPrice,
        uint _maxPayout,
        uint _maxDebt,
        uint _initialDebt
    ) external onlyOwner isOpen {
        open = false;

        bond.initialize(
            _controlVariable,
            _vestingTerm,
            _minPrice,
            _maxPayout,
            _maxDebt,
            _initialDebt
        );

        tokenIn.approve(address(bond), type(uint).max);

        CommitStruct[] memory _commits = commits;
        uint len = commits.length;
        for (uint i; i < len; i++) {
            bond.deposit(_commits[i].amount, _minPrice, _commits[i].depositor);
        }

        delete commits;
        total = 0;
    }

    function acceptBondOwner() external onlyOwner {
        bond.acceptOwnership();
    }

    function nominateBondOwner() external onlyOwner {
        bond.nominateNewOwner(msg.sender);
    }

    function recover(address _token) external onlyOwner {
        uint bal = IERC20(_token).balanceOf(address(this));

        if (_token == address(tokenIn)) {
            // allow withdraw of excess token in
            IERC20(_token).safeTransfer(msg.sender, bal.sub(total));
        } else {
            IERC20(_token).safeTransfer(msg.sender, bal);
        }
    }
}
