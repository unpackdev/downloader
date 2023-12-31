// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./Errors.sol";
import "./IConfigurator.sol";
import "./RoboFiTokenSnapshot.sol";
import "./IDABotComponent.sol";
import "./IDABot.sol";
import "./IDABotManager.sol";
import "./IDABotGovernToken.sol";
import "./IDABotStakingModule.sol";


/** Governance Token for DABot
 */
contract GovernToken is RoboFiTokenSnapshot, IDABotComponent, IERC165 {

    IRoboFiERC20 private immutable _vics;
    IDABot private _bot;

    modifier authorizedByBot() {
        require(_msgSender() == address(_bot), Errors.BGT_CALLER_IS_NOT_OWNED_BOT);
        _;
    }

    constructor(IRoboFiERC20 vics) RoboFiToken('', '', 0, address(0)) {
        _vics = vics;
    }

    function init(bytes calldata data) external payable override {
        require(address(_bot)  == address(0), Errors.CM_CONTRACT_HAS_BEEN_INITIALIZED);
        (_bot) = abi.decode(data, (IDABot));
    }

    function moduleInfo() external pure override virtual
        returns(string memory, string memory, bytes32)
    {
        return ("GovernToken", "v0.1.20220420", BOT_GOV_TOKEN_TEMPLATE_ID);
    }

    function isGovernToken() external pure returns(bool) {
        return true;
    }

    function asset() external view returns (IRoboFiERC20) {
        return _vics;
    }

    function snapshot() external authorizedByBot {
         _snapshot();
    }

    function mint(address account, uint amount) external authorizedByBot {
        require(account != address(0), Errors.BGT_CANNOT_MINT_TO_ZERO_ADDRESS);
        _mint(account, amount);
    }

    function burn(uint amount) external {
        __burn(_msgSender(), amount);
    }

    function __burn(address account, uint amount) private {
        if (amount == 0)
            return;
        uint redeemAmount = amount * _vics.balanceOf(address(this)) / totalSupply();
        _burn(account, amount);
        _vics.transfer(account, redeemAmount);
    }

    function value(uint amount) external view returns(uint) {
        return amount * _vics.balanceOf(address(this)) / totalSupply();
    }

    function owner() public view returns (address) {
        return address(_bot);
    }

    function symbol() public view override returns(string memory) {
        return string(abi.encodePacked(_bot.metadata().symbol, "GToken"));
    }

    function name() public view override returns(string memory) {
        return string(abi.encodePacked(_bot.metadata().name, " Governance Token"));
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return (interfaceId == type(IERC165).interfaceId) ||
                (interfaceId == type(IDABotGovernToken).interfaceId)
        ;
    }
}