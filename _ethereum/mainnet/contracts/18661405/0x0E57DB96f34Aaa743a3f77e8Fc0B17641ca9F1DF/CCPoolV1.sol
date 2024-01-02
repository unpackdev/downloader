// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IERC20.sol";
import "./WmbApp.sol";

// Cross Chain Token Pool
contract CCPoolV1 is WmbApp {
    address public poolToken;

    // chain id => remote pool address
    mapping(uint => address) public remotePools;

    event CrossArrive(uint256 indexed fromChainId, address indexed from, address indexed to, uint256 amount, string crossType);

    event CrossRequest(uint256 indexed toChainId, address indexed from, address indexed to, uint256 amount);

    constructor(address admin, address _wmbGateway, address _poolToken) WmbApp() {
        initialize(admin, _wmbGateway);
        poolToken = _poolToken;
    }

    function configRemotePool(uint256 chainId, address remotePool) public onlyRole(DEFAULT_ADMIN_ROLE) {
        remotePools[chainId] = remotePool;
    }

    function crossTo(uint256 toChainId, address to, uint256 amount, uint gasLimit) public payable {
        // check support before transfer
        require(remotePools[toChainId] != address(0), "remote pool not configured");
        IERC20(poolToken).transferFrom(msg.sender, address(this), amount);
        uint fee = estimateFee(toChainId, gasLimit);
        _dispatchMessage(toChainId, remotePools[toChainId], abi.encode(msg.sender, to, amount, "crossTo"), fee);
        emit CrossRequest(toChainId, msg.sender, to, amount);
    }

    function _wmbReceive(
        bytes calldata data,
        bytes32 /*messageId*/,
        uint256 fromChainId,
        address /*fromSC*/
    ) internal override {
        (address fromAccount, address to, uint256 amount, string memory crossType) = abi.decode(data, (address, address, uint256, string));
        require(IERC20(poolToken).balanceOf(address(this)) >= amount, "Pool balance not enough");
        IERC20(poolToken).transfer(to, amount);
        emit CrossArrive(fromChainId, fromAccount, to, amount, crossType);
    }
}
