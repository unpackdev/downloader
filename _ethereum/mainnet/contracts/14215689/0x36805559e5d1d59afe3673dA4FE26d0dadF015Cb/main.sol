// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./variables.sol";
import "./interfaces.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract InteropPeriphery is Variables {
    using SafeERC20 for TokenInterface;

    TokenInterface public immutable wethContract;

    constructor(
        address weth_,
        address instaIndex_,
        address interopAddress_,
        string memory connectorName_,
        string memory actionId_
    ) {
        _connectorName = connectorName_;
        _actionId = actionId_;
        wethContract = TokenInterface(weth_);

        IndexInterface instaIndex = IndexInterface(instaIndex_);
        ListInterface list = ListInterface(instaIndex.list());

        {
            _dsaAddress = instaIndex.build(address(this), 2, address(this));
            _dsaId = list.accountID(_dsaAddress);
            bytes[] memory _datas = new bytes[](1);
            string[] memory _targets = new string[](1);

            _targets[0] = "AUTHORITY-A";

            _datas[0] = abi.encodeWithSignature(
                "add(address)",
                (interopAddress_)
            );

            IDSA(_dsaAddress).cast(_targets, _datas, address(this));
        }
    }

    /**
     * @notice Helper function for `transfer`
     * @dev This contract will use internally DSA to access Interop
     * @param srcChainTokenAddress_ The `source chain` token Address
     * @param targetChainTokenAddress_ The `target` chain token Address
     * @param tokenAmount_ The `source chain` token Amount
     * @param targetDsaId_ The `target chain` dsa Id
     * @param targetChainId_ The chainID of target chain
     */
    function _transfer(
        address srcChainTokenAddress_,
        address targetChainTokenAddress_,
        uint256 tokenAmount_,
        uint256 targetDsaId_,
        uint256 targetChainId_
    ) internal {
        require(tokenAmount_ > 0, "tokenAmount_-is-zero");
        bytes memory _metadata = abi.encode(Data(msg.sender));
        TokenInfo[] memory _supply = new TokenInfo[](1);
        TokenInfo[] memory _withdraw = new TokenInfo[](0);
        bytes[] memory _datas = new bytes[](1);
        string[] memory _targets = new string[](1);

        _targets[0] = _connectorName;

        _supply[0] = TokenInfo(
            srcChainTokenAddress_,
            targetChainTokenAddress_,
            tokenAmount_
        );

        Position memory _position = Position(_supply, _withdraw);

        _datas[0] = abi.encodeWithSelector(
            0x634d3ade, // "submitActionERC20(Position,string,uint256,uint256,bytes)",
            _position,
            _actionId,
            targetDsaId_,
            targetChainId_,
            _metadata
        );

        IDSA(_dsaAddress).cast(_targets, _datas, address(this));
    }

    /**
     * @notice User will deposit ERC20 tokens to use Interop
     * @dev This contract will internally use DSA to access Interop
     * @param srcChainTokenAddress_ The `source chain` token Address
     * @param targetChainTokenAddress_ The `target` chain token Address
     * @param tokenAmount_ The `source chain` token Amount
     * @param targetDsaId_ The `target chain` dsa Id
     * @param targetChainId_ The chainID of target chain
     */
    function transfer(
        address srcChainTokenAddress_,
        address targetChainTokenAddress_,
        uint256 tokenAmount_,
        uint256 targetDsaId_,
        uint256 targetChainId_
    ) public {
        // create calldata for the spell
        TokenInterface(srcChainTokenAddress_).safeTransferFrom(
            msg.sender,
            _dsaAddress,
            tokenAmount_
        );

        _transfer(
            srcChainTokenAddress_,
            targetChainTokenAddress_,
            tokenAmount_,
            targetDsaId_,
            targetChainId_
        );
    }

    /**
     * @notice User will deposit ETH to use Interop
     * @dev This contract convert ETH => WETH and will use internally DSA to access Interop
     * @param targetChainTokenAddress_ The `target` chain token Address
     * @param targetChainId_ The chainID of target chain
     * @param targetDsaId_ The `target chain` dsa Id
     */
    function transferETH(
        address targetChainTokenAddress_,
        uint256 targetDsaId_,
        uint256 targetChainId_
    ) public payable {
        uint256 _amount = msg.value;
        wethContract.deposit{value: _amount}();
        wethContract.safeTransfer(_dsaAddress, _amount);
        _transfer(
            address(wethContract),
            targetChainTokenAddress_,
            _amount,
            targetDsaId_,
            targetChainId_
        );
    }
}
