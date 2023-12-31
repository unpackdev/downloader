// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./KycERC20.sol";
import "./KycETH.sol";
import "./ITornadoInstance.sol";
import "./PGRouter.sol";
import "./InstanceRegistry.sol";

import "./SafeERC20.sol";

import "./ERC20.sol";
import "./IERC20.sol";

contract Zapper {
  using SafeERC20 for IERC20;
  using SafeERC20 for KycERC20;

  event NewGovernanceAddressUpdated(address newGovernanceAddress);

  PGRouter public pgRouter;
  InstanceRegistry public instanceRegistry;
  address public governance;

  modifier onlyGovernance() {
    require(msg.sender == governance, "Not authorized");
    _;
  }

  constructor(address _pgRouter, address _instanceRegistry, address _governance) {
    pgRouter = PGRouter(_pgRouter);
    instanceRegistry = InstanceRegistry(_instanceRegistry);
    governance = _governance;
  }

  /**
    @notice Once click zap in function to convert eth to kycEth tokens and deposit into relevant tc pool. The pool denomination will be the convert and deposit amount by default.
    @param _tornado TC pool instance address
    @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
  */
  function zapInEth(ITornadoInstance _tornado, bytes32 _commitment, bytes calldata _encryptedNote) external payable {
    (, IERC20 token, , , , ) = instanceRegistry.instances(_tornado);
    require(address(token) != address(0), "Token is not configured.");

    address _kycEth = address(token);
    KycETH kycEth = KycETH(_kycEth);
    kycEth.depositFor{ value: msg.value }();

    uint approveAmt = kycEth.allowance(address(this), address(pgRouter));
    if (approveAmt < _tornado.denomination()) {
      IERC20(_kycEth).safeApprove(address(pgRouter), _tornado.denomination());
    }

    pgRouter.deposit(_tornado, _commitment, _encryptedNote, msg.sender);
  }

  /**
    @notice Once click zap in function to convert erc20 tokens to kycErc20 tokens and deposit into relevant tc pool. The pool denomination will be the convert and deposit amount by default.
    @param _tornado TC pool instance address
    @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
  */
  function zapIn(ITornadoInstance _tornado, bytes32 _commitment, bytes calldata _encryptedNote) external {
    (bool isERC20, IERC20 token, , , , ) = instanceRegistry.instances(_tornado);
    require(isERC20, "Token is not ERC20.");

    address _kycErc20 = address(token);
    KycERC20 kycErc20 = KycERC20(_kycErc20);
    IERC20 erc20 = kycErc20.underlying();
    erc20.safeTransferFrom(msg.sender, address(this), _tornado.denomination());
    erc20.safeApprove(_kycErc20, _tornado.denomination());

    kycErc20.depositFor(address(this), _tornado.denomination());
    kycErc20.safeApprove(address(pgRouter), _tornado.denomination());
    pgRouter.deposit(_tornado, _commitment, _encryptedNote, msg.sender);
  }

  function updatePgRouter(address _newPgRouter) external onlyGovernance {
    pgRouter = PGRouter(_newPgRouter);
  }

  function updateInstanceRegistry(address _newinstanceRegistry) external onlyGovernance {
    instanceRegistry = InstanceRegistry(_newinstanceRegistry);
  }

  /**
    @notice Set new governance address.
    @param _govAddr new governance address
  */
  function setNewGovernance(address _govAddr) external onlyGovernance {
    require(_govAddr != address(0), "Empty governance address.");
    governance = _govAddr;
    emit NewGovernanceAddressUpdated(_govAddr);
  }
}
