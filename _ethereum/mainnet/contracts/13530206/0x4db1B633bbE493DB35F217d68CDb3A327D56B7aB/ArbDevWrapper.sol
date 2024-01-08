// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.4;

import "./console.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20PresetMinterPauser.sol";
import "./IInbox.sol";
import "./IOutbox.sol";
import "./IBridge.sol";
import "./IGatewayRouter.sol";
import "./ICustomGateway.sol";
import "./IMintRenounceable.sol";

contract ArbDevWrapper is ERC20Upgradeable, OwnableUpgradeable {
	using SafeERC20 for IERC20;

	address public l2Token;
	address public gateway;
	address public inbox;
	address public router;
	address public devAddress;
	bool private shouldRegisterGateway;

	event EscrowMint(address indexed minter, uint256 amount);

	function initialize(
		address _l2TokenAddr,
		address _routerAddr,
		address _gatewayAddr,
		address _inbox,
		address _devAddress
	) public initializer {
		__Ownable_init();
		__ERC20_init("Arb Dev Wrapper", "WDEV");
		l2Token = _l2TokenAddr;
		router = _routerAddr;
		gateway = _gatewayAddr;
		inbox = _inbox;
		devAddress = _devAddress;
	}

	function escrowMint(uint256 amount) external {
		address msgSender = _l2Sender();
		require(msgSender == l2Token, "sender must be l2 token");
		_mint(gateway, amount);
		ERC20PresetMinterPauser(devAddress).mint(address(this), amount);
		emit EscrowMint(msgSender, amount);
	}

	function _l2Sender() private view returns (address) {
		IBridge _bridge = IInbox(inbox).bridge();
		require(address(_bridge) != address(0), "bridge is zero address");
		IOutbox outbox = IOutbox(_bridge.activeOutbox());
		require(address(outbox) != address(0), "outbox is zero address");
		return outbox.l2ToL1Sender();
	}

	/**
	 * Wrap DEV to create Arbitrum compatible token
	 */
	function wrap(uint256 _amount) public returns (bool) {
		IERC20 _token = IERC20(devAddress);
		require(
			_token.balanceOf(address(msg.sender)) >= _amount,
			"Insufficient balance"
		);
		_token.safeTransferFrom(msg.sender, address(this), _amount);
		_mint(msg.sender, _amount);
		_approve(msg.sender, gateway, type(uint256).max);
		return true;
	}

	function wrapAndBridge(
		uint256 _amount,
		uint256 _maxGas,
		uint256 _gasPriceBid,
		bytes calldata _data
	) external payable returns (bool) {
		wrap(_amount);
		IGatewayRouter(router).outboundTransfer{value: msg.value}(
			address(this),
			msg.sender,
			_amount,
			_maxGas,
			_gasPriceBid,
			_data
		);
		return true;
	}

	/**
	 * Burn pegged token and return DEV
	 */
	function unwrap(uint256 _amount) external returns (bool) {
		require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
		_burn(msg.sender, _amount);
		IERC20(devAddress).safeTransfer(msg.sender, _amount);
		return true;
	}

	/** Safety measure to transfer DEV to owner */
	function transferDev() external onlyOwner returns (bool) {
		IERC20 token = IERC20(devAddress);
		uint256 balance = token.balanceOf(address(this));
		return token.transfer(msg.sender, balance);
	}

	/**
	 * Delete mint role
	 */
	function renounceMinter() external onlyOwner {
		IMintRenounceable(devAddress).renounceMinter();
	}

	function isArbitrumEnabled() external view returns (uint16) {
		require(shouldRegisterGateway, "NOT_EXPECTED_CALL");
		return uint16(0xa4b1);
	}

	function registerTokenOnL2(
		address l2CustomTokenAddress,
		uint256 maxSubmissionCostForCustomBridge,
		uint256 maxSubmissionCostForRouter,
		uint256 maxGas,
		uint256 gasPriceBid
	) public onlyOwner {
		// we temporarily set `shouldRegisterGateway` to true for the callback in registerTokenToL2 to succeed
		bool prev = shouldRegisterGateway;
		shouldRegisterGateway = true;

		ICustomGateway(gateway).registerTokenToL2(
			l2CustomTokenAddress,
			maxGas,
			gasPriceBid,
			maxSubmissionCostForCustomBridge
		);

		IGatewayRouter(router).setGateway(
			gateway,
			maxGas,
			gasPriceBid,
			maxSubmissionCostForRouter
		);

		shouldRegisterGateway = prev;
	}
}
