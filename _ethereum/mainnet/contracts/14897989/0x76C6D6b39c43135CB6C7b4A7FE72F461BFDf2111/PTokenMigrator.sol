//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IERC777RecipientUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC1820Registry.sol";
import "./IERC20.sol";
import "./IPToken.sol";

contract PTokenMigrator is Initializable, UUPSUpgradeable, IERC777RecipientUpgradeable, OwnableUpgradeable {
    error ReceiveNotAllowed();

    address public pTokenV1;
    address public pTokenV2;

    event Migrated(address indexed pTokenV1, address indexed pTokenV2, uint256 amount);

    function initialize(address _pTokenV1, address _pTokenV2) external initializer {
        __Ownable_init();
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24).setInterfaceImplementer(
            address(this),
            keccak256("ERC777TokensRecipient"),
            address(this)
        );
        pTokenV1 = _pTokenV1;
        pTokenV2 = _pTokenV2;
    }

    function tokensReceived(
        address, /*_operator*/
        address _from,
        address, /*_to*/
        uint256 _amount,
        bytes calldata, /*_userData,*/
        bytes calldata /*_operatorData*/
    ) external override {
        if (msg.sender == pTokenV2 && _from != address(0) && _from != owner()) revert ReceiveNotAllowed();
        if (msg.sender == pTokenV1) {
            IPToken(pTokenV1).redeem(_amount, "");
            IERC20(pTokenV2).transfer(_from, _amount);
            emit Migrated(pTokenV1, pTokenV2, _amount);
        }
    }

    function recoverToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}
}
