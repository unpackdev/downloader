// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./Ownable.sol";

/**************************************************
 * @title ApeVineVoucherProxy
 **************************************************/

contract ApeVineVoucherCrossMint is Ownable, ERC1155Holder {
    bool public isPaused = false;
    uint256 public price = 0.045 ether;
    address public apeVineContract;
    uint256 public apeVineVoucherId;

    error Paused();
    error WrongValueSent();
    error FailedToWithdraw();
    error ExceedMaxSupply();

    constructor(address _apeVineContract, uint256 _apeVineVoucherId) {
        _initializeOwner(msg.sender);
        apeVineContract = _apeVineContract;
        apeVineVoucherId = _apeVineVoucherId;
    }

    /// @notice Crossmint specific "mint", will not "mint", just transfer a deposited asset
    function mintTo(address to, uint256 quantity) public payable {
        if (isPaused) revert Paused();
        if (msg.value != price * quantity) revert WrongValueSent();
        uint256 currentBalance = balanceOf(address(this), apeVineVoucherId);
        if (currentBalance < quantity) revert ExceedMaxSupply();
        // Transfer from contract to _to address
        IERC1155(apeVineContract).safeTransferFrom(
            address(this),
            to,
            apeVineVoucherId,
            quantity,
            ""
        );
    }

    /// @notice Just a balance proxy caller
    function balanceOf(
        address account,
        uint256 id
    ) public view returns (uint256) {
        return IERC1155(apeVineContract).balanceOf(account, id);
    }

    /// @notice Sets the pause state
    function setPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    /// @notice Sets the mint config
    function setMintConfig(
        address _apeVineContract,
        uint256 _apeVineVoucherId,
        uint256 _price
    ) external onlyOwner {
        apeVineContract = _apeVineContract;
        apeVineVoucherId = _apeVineVoucherId;
        price = _price;
    }

    /// @notice Withdraw any eth
    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!success) revert FailedToWithdraw();
    }

    /// @notice Deposit vouchers
    function depositAssets(uint256 quantity) external onlyOwner {
        IERC1155(apeVineContract).safeTransferFrom(
            msg.sender,
            address(this),
            apeVineVoucherId,
            quantity,
            ""
        );
    }

    /// @notice Withdraw vouchers
    function withdrawAssets(uint256 quantity) external onlyOwner {
        IERC1155(apeVineContract).safeTransferFrom(
            address(this),
            msg.sender,
            apeVineVoucherId,
            quantity,
            ""
        );
    }
}
