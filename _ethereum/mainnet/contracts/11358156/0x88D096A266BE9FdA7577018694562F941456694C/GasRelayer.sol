// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./Math.sol";
import "./GasToken.sol";
import "./AccessControl.sol";

contract GasRelayer is AccessControl {
    bytes32 public constant GAS_TOKEN_USER_ROLE =
        keccak256(abi.encodePacked("GAS_TOKEN_USER"));

    address public admin;
    address public gasToken;

    constructor(address _gasToken) public {
        require(_gasToken != address(0), "gas token = zero address");

        admin = msg.sender;
        gasToken = _gasToken;

        _grantRole(GAS_TOKEN_USER_ROLE, admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "!admin");
        _;
    }

    // @dev use CHI token from 1inch to burn gas token
    // https://medium.com/@1inch.exchange/1inch-introduces-chi-gastoken-d0bd5bb0f92b
    modifier useChi(uint _max) {
        uint gasStart = gasleft();
        _;
        uint gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;

        if (_max > 0) {
            GasToken(gasToken).freeUpTo(Math.min(_max, (gasSpent + 14154) / 41947));
        }
    }

    function setAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "admin = zero address");
        admin = _admin;
    }

    function authorized(address _addr) external view returns (bool) {
        return hasRole[GAS_TOKEN_USER_ROLE][_addr];
    }

    function authorize(address _addr) external onlyAdmin {
        _grantRole(GAS_TOKEN_USER_ROLE, _addr);
    }

    function unauthorize(address _addr) external onlyAdmin {
        _revokeRole(GAS_TOKEN_USER_ROLE, _addr);
    }

    function setGasToken(address _gasToken) external onlyAdmin {
        require(_gasToken != address(0), "gas token = zero address");
        gasToken = _gasToken;
    }

    function mintGasToken(uint _amount) external {
        GasToken(gasToken).mint(_amount);
    }

    function transferGasToken(address _to, uint _amount) external onlyAdmin {
        GasToken(gasToken).transfer(_to, _amount);
    }

    function relayTx(
        address _to,
        bytes calldata _data,
        uint _maxGasToken
    ) external onlyAuthorized(GAS_TOKEN_USER_ROLE) useChi(_maxGasToken) {
        (bool success, ) = _to.call(_data);
        require(success, "relay failed");
    }
}
