// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Initializable.sol";
import "./IWETH.sol";
import "./IThorchainRouter.sol";


contract BaseContract is Pausable, Ownable, ReentrancyGuard {
    address payable constant NULL_ADDRESS = payable(0x0000000000000000000000000000000000000000);

    using SafeMath for uint;

    //keccak256("exchange.rango.basecontract")
    bytes32 internal constant BASE_CONTRACT_NAMESPACE = hex"4c641b369cb23edb735ebedf93a426da9d88d71734c5e7d6076697dcf08d6878";

    struct BaseContractStorage {
        address nativeWrappedAddress;
        mapping (address => bool) whitelistContracts;
    }

    event SendToken(address _token, uint256 _amount, address _receiver, bool _nativeOut, bool _withdraw);

    function addWhitelist(address _factory) external onlyOwner {
        BaseContractStorage storage baseStorage = getBaseContractStorage();
        baseStorage.whitelistContracts[_factory] = true;
    }

    function removeWhitelist(address _factory) external onlyOwner {
        BaseContractStorage storage baseStorage = getBaseContractStorage();
        require(baseStorage.whitelistContracts[_factory], 'Factory not found');
        delete baseStorage.whitelistContracts[_factory];
    }

    function refund(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 ercToken = IERC20(_tokenAddress);
        uint balance = ercToken.balanceOf(address(this));
        require(balance >= _amount, 'Insufficient balance');

        SafeERC20.safeTransfer(IERC20(_tokenAddress), msg.sender, _amount);
    }

    function refundNative(uint256 _amount) external onlyOwner {
        uint balance = address(this).balance;
        require(balance >= _amount, 'Insufficient balance');

        _sendToken(NULL_ADDRESS, _amount, msg.sender, true, false);
    }

    function approve(address token, address to, uint value) internal {
        SafeERC20.safeApprove(IERC20(token), to, 0);
        SafeERC20.safeIncreaseAllowance(IERC20(token), to, value);
    }

    function _sendToken(
        address _token,
        uint256 _amount,
        address _receiver,
        bool _nativeOut,
        bool _withdraw
    ) internal {
        BaseContractStorage storage baseStorage = getBaseContractStorage();
        emit SendToken(_token, _amount, _receiver, _nativeOut, _withdraw);

        if (_nativeOut) {
            if (_withdraw) {
                require(_token == baseStorage.nativeWrappedAddress, "token mismatch");
                IWETH(baseStorage.nativeWrappedAddress).withdraw(_amount);
            }
            _sendNative(_receiver, _amount);
        } else {
            SafeERC20.safeTransfer(IERC20(_token), _receiver, _amount);
        }
    }

    function _sendNative(address _receiver, uint _amount) internal {
        (bool sent, ) = _receiver.call{value: _amount}("");
        require(sent, "failed to send native");
    }


    function getBaseContractStorage() internal pure returns (BaseContractStorage storage s) {
        bytes32 namespace = BASE_CONTRACT_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}
