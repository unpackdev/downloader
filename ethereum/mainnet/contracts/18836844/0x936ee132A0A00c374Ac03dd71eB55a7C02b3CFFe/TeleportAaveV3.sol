// SPDX-LICENSE-IDENTIFIER: AGPL-3.0
pragma solidity ^0.8.20;
// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

import "./FlashLoanReceiverBase.sol";
import "./IPoolAddressesProvider.sol";
import "./IERC20.sol";
import "./IPoolDataProvider.sol";
import "./ICreditDelegationToken.sol";

/**
 * @title A contract that allow users to migrate their Aave V3 position to another wallet
 * @author @yehoudaB
 * @notice this contract hasn't been  audited yet use at your own risk
 * @dev Implements Aave V3 Pool and Flashloan receiver
 */
contract TeleportAaveV3 is FlashLoanReceiverBase {
    error TeleportAaveV3__OnlyAdminCanCallThisFunction();

    IPoolDataProvider public immutable poolDataProvider;
    address payable private admin;
    uint16 private constant REFERRAL_CODE = 0;

    /**
     * Events
     */
    event TeleportAaveV3__transferSuccess(address indexed _from, address indexed _to);

    constructor(address _poolAddressProvider, address payable _admin)
        FlashLoanReceiverBase(IPoolAddressesProvider(_poolAddressProvider))
    {
        poolDataProvider = IPoolDataProvider(_poolAddressProvider);
        admin = _admin;
    }

    function _requestFlashLoan(
        address _receiverAddress,
        address[] memory _assets,
        uint256[] memory _amounts,
        uint256[] memory _interestRateModes,
        address _onBehalfOf,
        bytes memory _params,
        uint16 _referralCode
    ) private {
        POOL.flashLoan(_receiverAddress, _assets, _amounts, _interestRateModes, _onBehalfOf, _params, _referralCode);
    }

    /**
     * @notice this function aims to migrate the Aave position from one wallet to another
     * @dev before excuting this function, the _to address should have allowed the _form address to borrow on behalf of it
     *
     * @param _to the address of the wallet that will receive the Aave position
     * @param assetsBorrowed the list of addresses of assets to borrow from the flashloan (to repay the Aave debts position)
     * @param amountsBorrowed the list of amounts to borrow from the flashloan (to repay the Aave debts position)
     * @param interestRateModesForPositions the types of debt position that the source wallet has
     * @param interestRateModesForFL the types of debt position to open if the flashloan is not returned. for us is 0: (no open debt) (amount+fee must be paid in this case or revert)
     *
     */
    function moveAavePositionToAnotherWallet(
        address _from,
        address _to,
        address[] memory assetsBorrowed,
        uint256[] memory amountsBorrowed,
        uint256[] memory interestRateModesForPositions,
        uint256[] memory interestRateModesForFL,
        address[] memory aTokenAssetsToMove,
        uint256[] memory aTokenAmountsToMove
    ) external {
        bytes memory data =
            abi.encode(_from, _to, aTokenAssetsToMove, aTokenAmountsToMove, interestRateModesForPositions);
        _requestFlashLoan(
            address(this), assetsBorrowed, amountsBorrowed, interestRateModesForFL, address(this), data, REFERRAL_CODE
        );
    }

    /**
     * @notice this function is called after your contract has received the flash loaned amount
     * @dev Ensure that the contract can return the debt + premium, e.g., has
     *      enough funds to repay and has approved the Pool to pull the total amount
     */
    function executeOperation(
        address[] calldata _assets,
        uint256[] calldata _amounts,
        uint256[] calldata _premiums,
        address _initiator,
        bytes calldata _params
    ) external returns (bool) {
        (
            address _from,
            address _to,
            address[] memory aTokenAssetsToMove,
            uint256[] memory aTokenAmountsToMove,
            uint256[] memory interestRateModesForPositions
        ) = abi.decode(_params, (address, address, address[], uint256[], uint256[]));

        for (uint256 i = 0; i < _assets.length; i++) {
            address tokenToBorrow = _assets[i];
            uint256 amountToBorrow = _amounts[i];

            IERC20(tokenToBorrow).approve(address(POOL), amountToBorrow); // approve to repay to the POOL (regular debt)
            POOL.repay(tokenToBorrow, amountToBorrow, interestRateModesForPositions[i], _from); // repay the debt to the POOL for the _from address
        }
        for (uint256 i = 0; i < aTokenAssetsToMove.length; i++) {
            IERC20(aTokenAssetsToMove[i]).transferFrom(_from, _to, aTokenAmountsToMove[i]);
        }
        for (uint256 i = 0; i < _assets.length; i++) {
            address tokenToBorrow = _assets[i];
            uint256 amountToBorrow = _amounts[i];
            /* borrow the debt to the POOL for the _to address 
            * (the _to address should have allowed the contract  to borrow on behalf of it)
            *    we borrow the amount + the premium (the premium is for paying the flashloan fee)
            *  @notice IMPORTANT : the health factor of the _to address should be sufficent the premium fee otherwise the transaction will revert
            *
            */
            POOL.borrow(
                tokenToBorrow, amountToBorrow + _premiums[i], interestRateModesForPositions[i], REFERRAL_CODE, _to
            );
            uint256 maxAllowance = type(uint256).max;
            IERC20(tokenToBorrow).approve(address(POOL), maxAllowance); // approve to repay to the FLASHLOAN
        }
        emit TeleportAaveV3__transferSuccess(_from, _to);
        return true;
    }

    function withdrawERC20(address _tokenAddress) external {
        IERC20(_tokenAddress).transfer(admin, IERC20(_tokenAddress).balanceOf(address(this)));
    }

    function changeAdmin(address payable _newAdmin) external {
        if (msg.sender != admin) revert TeleportAaveV3__OnlyAdminCanCallThisFunction();
        admin = _newAdmin;
    }

    function getAdmin() external view returns (address payable) {
        return admin;
    }

    function withdraw() public {
        admin.transfer(address(this).balance);
    }
}
