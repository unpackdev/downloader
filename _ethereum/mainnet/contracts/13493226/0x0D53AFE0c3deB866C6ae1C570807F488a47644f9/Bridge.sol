//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./Initializable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract Bridge is Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address owner;
    IERC20 public token;

    event LockedForBridge(address sender, uint256 amount);
    event TransferBridge(address sender, uint256 amount);
    event Release(address sender, uint256 amount);

    mapping(address => bool) oracles;
    mapping(bytes32 => bool) public released;

    bool public paused;

    uint256 public totalFeeBridge;
    uint256 public totalLocked;

    uint256 public constant feeDiv = 1000; // feeTransfer = 20 => fee = 2%
    uint256 public feeRelease;
    uint256 public feeBridge;

    function initialize(address _token) public initializer {
        token = IERC20(_token);
        feeRelease = 50;
        feeBridge = 30;
        oracles[msg.sender] = true;
        owner = msg.sender;
    }

    modifier onlyOracle() {
        require(oracles[msg.sender], "Bridge: only oracles");
        _;
    }

    modifier notPaused() {
        require(!paused, "Bridge: paused");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Bridge: only owner");
        _;
    }

    function updateOracle(address _orc, bool _status) public onlyOwner {
        require(oracles[_orc] != _status, "Nothing to update");
        oracles[_orc] = _status;
    }

    function pause(bool _paused) public onlyOwner {
        require(paused != _paused, "Nothing to update");
        paused = _paused;
    }

    function updateFee(uint256 _feeRelease, uint256 _feeBridge)
        public
        onlyOwner
    {
        feeRelease = _feeRelease;
        feeBridge = _feeBridge;
    }

    function locked(uint256 _amount) public {
        require(_amount > 0, "Nothing to transfer");
        uint256 amountBridge = _amount;

        token.safeTransferFrom(msg.sender, address(this), amountBridge);
        totalLocked = totalLocked.add(amountBridge);

        emit LockedForBridge(msg.sender, _amount);
    }

    function transferBridge(uint256 _amount) public notPaused {
        require(_amount > 0, "Nothing to transfer");
        uint256 amountBridge = _amount;

        if (feeBridge > 0) {
            uint256 fee = amountBridge.mul(feeBridge).div(feeDiv);
            totalFeeBridge = totalFeeBridge.add(fee);
            amountBridge = amountBridge.sub(fee);
        }

        token.safeTransferFrom(msg.sender, address(this), _amount);
        totalLocked = totalLocked.add(amountBridge);

        emit TransferBridge(msg.sender, _amount);
    }

    function release(
        address _receiver,
        uint256 _amount,
        bytes32 _tx,
        bytes32 data
    ) public onlyOracle {
        require(keccak256(abi.encodePacked(_receiver, _amount, _tx)) == data);
        require(!released[data], "Bridge: released");
        uint256 amountRelease = _amount;

        if (feeRelease > 0) {
            uint256 fee = amountRelease.mul(feeRelease).div(feeDiv);
            amountRelease = amountRelease.sub(fee);
        }

        token.safeTransfer(_receiver, amountRelease);
        totalLocked = totalLocked.sub(amountRelease);
        released[data] = true;

        emit Release(_receiver, amountRelease);
    }

    function claimFeeBridge() public onlyOwner {
        require(totalFeeBridge > 0, "Nothing to claim");
        token.safeTransfer(owner, totalFeeBridge);
        totalFeeBridge = 0;
    }

    function safeFund(address _token) public onlyOwner {
        IERC20 erc20 = IERC20(_token);
        if (erc20.balanceOf(address(this)) > 0) {
            erc20.transfer(owner, erc20.balanceOf(address(this)));
        }
    }
}
