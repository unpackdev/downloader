//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";
import "./IERC3156FlashLender.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

/**
 * @title Dola Flash Minter
 * @notice Allow users to mint an arbitrary amount of DOLA without collateral
 *         as long as this amount is repaid within a single transaction.
 * @dev This contract is abstract, any concrete implementation must have the DOLA
 *      token address hardcoded in the contract to facilitate code auditing.
 */
abstract contract DolaFlashMinter is Ownable, IERC3156FlashLender {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    event FlashLoan(address receiver, address token, uint256 value);
    event FlashLoanRateUpdated(uint256 oldRate, uint256 newRate);
    event TreasuryUpdated(address oldTreasury, address newTreasury);

    IERC20 public immutable dola;
    address public treasury;
    uint256 public flashMinted;
    uint256 public flashLoanRate = 0.0008 ether;

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    constructor(address _dola, address _treasury) {
        require(_dola.isContract(), "FLASH_MINTER:INVALID_DOLA");
        require(_treasury != address(0), "FLASH_MINTER:INVALID_TREASURY");
        dola = IERC20(_dola);
        treasury = _treasury;
    }

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 value,
        bytes calldata data
    ) external override returns (bool) {
        require(token == address(dola), "FLASH_MINTER:NOT_DOLA");
        require(value <= type(uint112).max, "FLASH_MINTER:INDIVIDUAL_LIMIT_BREACHED");
        flashMinted = flashMinted + value;
        require(flashMinted <= type(uint112).max, "total loan limit exceeded");

        // Step 1: Mint Dola to receiver
        dola.mint(address(receiver), value);
        emit FlashLoan(address(receiver), token, value);
        uint256 fee = flashFee(token, value);

        // Step 2: Make flashloan callback
        require(
            receiver.onFlashLoan(msg.sender, token, value, fee, data) == CALLBACK_SUCCESS,
            "FLASH_MINTER:CALLBACK_FAILURE"
        );
        // Step 3: Retrieve (minted + fee) Dola from receiver
        dola.safeTransferFrom(address(receiver), address(this), value + fee);

        // Step 4: Burn minted Dola (and leave accrued fees in contract)
        dola.burn(value);

        flashMinted = flashMinted - value;
        return true;
    }

    // Collect fees and retrieve any tokens sent to this contract by mistake
    function collect(address _token) external {
        if (_token == address(0)) {
            payable(treasury).sendValue(address(this).balance);
        } else {
            uint256 balance = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(treasury, balance);
        }
    }

    function setFlashLoanRate(uint256 _newRate) external onlyOwner {
        emit FlashLoanRateUpdated(flashLoanRate, _newRate);
        flashLoanRate = _newRate;
    }

    function setTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "FLASH_MINTER:INVALID_TREASURY");
        emit TreasuryUpdated(treasury, _newTreasury);
        treasury = _newTreasury;
    }

    function maxFlashLoan(address _token) external view override returns (uint256) {
        return _token == address(dola) ? type(uint112).max - flashMinted : 0;
    }

    function flashFee(address _token, uint256 _value) public view override returns (uint256) {
        require(_token == address(dola), "FLASH_MINTER:NOT_DOLA");
        return (_value * flashLoanRate) / 1e18;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}
