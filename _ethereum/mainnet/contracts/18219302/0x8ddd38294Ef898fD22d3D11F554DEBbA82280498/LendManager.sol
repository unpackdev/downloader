// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LendManagerStorage.sol";
import "./LendManagerStorage.sol";
import "./LendManagerInterface.sol";
import "./LendManagerInterface.sol";
import "./LendManagerInterface.sol";
import "./LendMediatorProxy.sol";
import "./LendMediatorStorage.sol";
import "./DetectContract.sol";

/**
 * @title MetaLend's LendManager Contract
 * @author MetaLend
 * @notice Manages staking of lender funds to official onchain staking contracts to be deployed in p2p lending protocols
 * @dev this is an implementation for proxy
 */
contract LendManager is
    LendManagerErrorInterface,
    LendManagerEventInterface,
    LendManagerFunctionInterface,
    LendManagerProxyStorage,
    LendManagerStorage
{
    /// @notice revert function if caller is not an admin
    modifier onlyAdmin() {
        if (msg.sender != admin) revert ErrCallerNotAdmin(msg.sender);
        _;
    }

    /**
     * @inheritdoc LendManagerFunctionInterface
     */
    function createLendMediator() external override {
        if (userLendMediator[msg.sender] != address(0)) revert ErrMediatorExists(msg.sender, userLendMediator[msg.sender]);
        LendMediatorProxy mediatorContract = new LendMediatorProxy(payable(msg.sender));
        address newMediatorAddress = address(mediatorContract);
        emit NewLendMediator(msg.sender, newMediatorAddress);
        userLendMediator[msg.sender] = newMediatorAddress;
    }

    /**
     * @inheritdoc LendManagerFunctionInterface
     */
    function feeDenominator() public pure override returns (uint256) {
        return 10000;
    }

    /**
     * @inheritdoc LendManagerFunctionInterface
     */
    function getValueByRoyaltiesPercentage(uint256 value) external view override returns (uint256) {
        return (value * royaltiesPercentage) / feeDenominator();
    }

    /**
     * @inheritdoc LendManagerFunctionInterface
     */
    function setRoyaltiesPercentage(uint256 newPercentage) external override onlyAdmin {
        if (newPercentage > feeDenominator()) revert ErrInvalidNumber(newPercentage);
        emit NewRoyaltiesPercentage(royaltiesPercentage, newPercentage);
        royaltiesPercentage = newPercentage;
    }

    /**
     * @inheritdoc LendManagerFunctionInterface
     */
    function setRoyaltiesReceiver(address payable newReceiver) external override onlyAdmin {
        if (newReceiver == address(0)) revert ErrInvalidAddress(newReceiver);
        emit NewRoyaltiesReceiver(royaltiesReceiver, newReceiver);
        royaltiesReceiver = newReceiver;
    }

    /**
     * @inheritdoc LendManagerFunctionInterface
     */
    function setOfferSigner(address newSigner) external override onlyAdmin {
        if (newSigner == address(0)) revert ErrInvalidAddress(newSigner);
        emit NewOfferSigner(offerSigner, newSigner);
        offerSigner = newSigner;
    }

    /**
     * @inheritdoc LendManagerFunctionInterface
     */
    function setLendMediatorImplementation(address newImplementation) external override onlyAdmin {
        if (!DetectContract.isExistingContract(newImplementation)) {
            revert ErrImplementationNotLendMediator(newImplementation);
        }
        try LendMediatorProxyStorage(newImplementation).IS_LEND_MEDIATOR() returns (bool isLendMediator) {
            if (!isLendMediator) {
                revert ErrImplementationNotLendMediator(newImplementation);
            }
        } catch {
            revert ErrImplementationNotLendMediator(newImplementation);
        }
        emit NewLendMediatorImplementation(lendMediatorImplementation, newImplementation);
        lendMediatorImplementation = newImplementation;
    }
}
