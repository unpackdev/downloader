// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "./ISailorSwapPoolFactory.sol";
import "./ISailorSwapPool.sol";
import "./Ownable.sol";
import "./Clones.sol";
import "./Address.sol";
import "./IERC721.sol";
import "./ERC165Checker.sol";
import "./Pausable.sol";

/**
 * SAILORSWAP
 */
contract SailorSwapPoolFactory is ISailorSwapPoolFactory, Ownable, Pausable {
    using Clones for address;
    using Address for address;
    using ERC165Checker for address;

    address public template;
    address public sznsDao;

    uint256 public daoFeeRate = 0.3e18;
    uint256 public swapFee = 0.0069 ether;
    uint256 public depositLockup = 2 days;

    constructor(address _template, address _sznsDao) {
        template = _template;
        sznsDao = _sznsDao;
        transferOwnership(_sznsDao);
    }

    function setTemplate(address _template) public whenNotPaused onlyOwner {
        template = _template;
    }

    function createPool(address collection) public whenNotPaused returns (address pool) {
        if (!ERC165Checker.supportsInterface(collection, type(IERC721).interfaceId)) {
            revert NotERC721();
        }

        if (hasDeployed(collection)) {
            revert AlreadyDeployed();
        }

        bytes32 salt = keccak256(abi.encode(collection, template));
        pool = Clones.cloneDeterministic(template, salt);

        ISailorSwapPool(pool).initialize(collection);

        emit NewPoolCreated(pool, msg.sender, collection);
    }

    function hasDeployed(address collection) public view returns (bool) {
        address predicted = predictAddress(collection);
        return Address.isContract(predicted);
    }

    function predictAddress(address collection) public view returns (address) {
        bytes32 salt = keccak256(abi.encode(collection, template));
        address predicted = Clones.predictDeterministicAddress(template, salt);
        return predicted;
    }

    function updateSwapFee(uint256 _fee) public whenNotPaused onlyOwner {
        swapFee = _fee;
    }

    function updateDAOFeeRate(uint256 _feeRate) public whenNotPaused onlyOwner {
        daoFeeRate = _feeRate;
    }

    function updateDepositLockup(uint256 _depositLockup) public whenNotPaused onlyOwner {
        depositLockup = _depositLockup;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function paused() public view override(Pausable, ISailorSwapPoolFactory) returns (bool) {
        return Pausable.paused();
    }
}
