// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./CVNXGovernance.sol";
import "./ICVNX.sol";

/// @notice CVNX token contract.
contract CVNX is ICVNX, ERC20("CVNX", "CVNX"), Ownable {
    event TokenLocked(uint256 indexed amount, address tokenOwner);
    event TokenUnlocked(uint256 indexed amount, address tokenOwner);

    /// @notice Governance contract.
    CVNXGovernance public cvnxGovernanceContract;
    IERC20 public cvnContract;

    /// @notice Locked token amount for each address.
    mapping(address => uint256) public lockedAmount;

    /// @notice Governance contract created in constructor.
    constructor(address _cvnContract) {
        uint256 _toMint = 6000000000000;

        _mint(msg.sender, _toMint);
        approve(address(this), _toMint);

        cvnContract = IERC20(_cvnContract);

        cvnxGovernanceContract = new CVNXGovernance(address(this));
        cvnxGovernanceContract.transferOwnership(msg.sender);
    }

    /// @notice Modifier describe that call available only from governance contract.
    modifier onlyGovContract() {
        require(msg.sender == address(cvnxGovernanceContract), "[E-31] - Not a governance contract.");
        _;
    }

    /// @notice Tokens decimal.
    function decimals() public pure override returns (uint8) {
        return 5;
    }

    /// @notice Lock tokens on holder balance.
    /// @param _tokenOwner Token holder
    /// @param _tokenAmount Amount to lock
    function lock(address _tokenOwner, uint256 _tokenAmount) external override onlyGovContract {
        require(_tokenAmount > 0, "[E-41] - The amount to be locked must be greater than zero.");

        uint256 _balance = balanceOf(_tokenOwner);
        uint256 _toLock = lockedAmount[_tokenOwner] + _tokenAmount;

        require(_toLock <= _balance, "[E-42] - Not enough token on account.");
        lockedAmount[_tokenOwner] = _toLock;

        emit TokenLocked(_tokenAmount, _tokenOwner);
    }

    /// @notice Unlock tokens on holder balance.
    /// @param _tokenOwner Token holder
    /// @param _tokenAmount Amount to lock
    function unlock(address _tokenOwner, uint256 _tokenAmount) external override onlyGovContract {
        uint256 _lockedAmount = lockedAmount[_tokenOwner];

        if (_tokenAmount > _lockedAmount) {
            _tokenAmount = _lockedAmount;
        }

        lockedAmount[_tokenOwner] = _lockedAmount - _tokenAmount;

        emit TokenUnlocked(_tokenAmount, _tokenOwner);
    }

    /// @notice Swap CVN to CVNX tokens
    /// @param _amount Token amount to swap
    function swap(uint256 _amount) external override returns (bool) {
        cvnContract.transferFrom(msg.sender, 0x4e07dc9D1aBCf1335d1EaF4B2e28b45d5892758E, _amount);
        this.transferFrom(owner(), msg.sender, _amount);
        return true;
    }

    /// @notice Transfer stuck tokens
    /// @param _token Token contract address
    /// @param _to Receiver address
    /// @param _amount Token amount
    function transferStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external override onlyOwner {
        require(_token.transfer(_to, _amount), "[E-56] - Transfer failed.");
    }

    /// @notice Check that locked amount less then transfer amount
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal view override {
        if (_from != address(0)) {
            require(
                balanceOf(_from) - lockedAmount[_from] >= _amount,
                "[E-61] - Transfer amount exceeds available tokens."
            );
        }
    }
}
