// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

import "./IDispatcher.sol";
import "./IAllowedAirdrops.sol";
import "./INftWrapper.sol";
import "./KeysMapping.sol";

contract AirdropBurstLoan is ERC721Holder, ERC1155Holder, ReentrancyGuard {
    using Address for address;
    using SafeERC20 for IERC20;

    IDispatcher public immutable hub;

    constructor(address _dispatcher) {
        hub = IDispatcher(_dispatcher);
    }

    function pullAirdrop(
        address _nftCollateralContract,
        uint256 _nftCollateralId,
        address _nftWrapper,
        address _target,
        bytes calldata _data,
        address _nftAirdrop,
        uint256 _nftAirdropId,
        bool _is1155,
        uint256 _nftAirdropAmount,
        address _beneficiary
    ) external nonReentrant {
        require(
            IAllowedAirdrops(hub.getContract(KeysMapping.PERMITTED_AIRDROPS)).isAirdropPermitted(
                abi.encode(_target, _getSelector(_data))
            ),
            "Invalid Airdrop"
        );

        _target.functionCall(_data);

        _transferNFT(_nftWrapper, address(this), msg.sender, _nftCollateralContract, _nftCollateralId);

        if (_nftAirdrop != address(0) && _beneficiary != address(0)) {
            if (_is1155) {
                IERC1155(_nftAirdrop).safeTransferFrom(
                    address(this),
                    _beneficiary,
                    _nftAirdropId,
                    _nftAirdropAmount,
                    "0x"
                );
            } else {
                IERC721(_nftAirdrop).safeTransferFrom(address(this), _beneficiary, _nftAirdropId);
            }
        }
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC1155Receiver) returns (bool) {
        return _interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(_interfaceId);
    }

    function _transferNFT(
        address _nftWrapper,
        address _sender,
        address _recipient,
        address _nftCollateralContract,
        uint256 _nftCollateralId
    ) internal {
        _nftWrapper.functionDelegateCall(
            abi.encodeWithSelector(
                INftWrapper(_nftWrapper).transferNFT.selector,
                _sender,
                _recipient,
                _nftCollateralContract,
                _nftCollateralId
            ),
            "NFT was not successfully transferred"
        );
    }

    function _getSelector(bytes memory _data) internal pure returns (bytes4 selector) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            selector := mload(add(_data, 32))
        }
    }
}
