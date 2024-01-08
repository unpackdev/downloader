// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./IERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./FxBaseRootTunnel.sol";

interface IRootChainManager{
    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;
}

contract L1UniversalOneSidedFarm is FxBaseRootTunnel, Ownable, Pausable {
    
    using SafeERC20 for IERC20;
    IRootChainManager public rootChainManager;
    address public erc20Predicate;
    address public mintableERC20Predicate;
    
    event InitiatedCrossChainFarming(address indexed user, uint256 indexed stakedAmount, uint256 indexed inititatedTime);

    constructor (IRootChainManager _rootChainManager,
        address _erc20Predicate,
        address _mintableERC20Predicate,
        address _checkpointManager,
        address _fxRoot
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot)
    {
        rootChainManager = IRootChainManager(_rootChainManager);
        erc20Predicate = _erc20Predicate;
        mintableERC20Predicate = _mintableERC20Predicate;
    }
    
    /**
    @notice This function is used to farm cross chain by investing in given Uniswap V2 pair through any ERC20 token on L1
    @param _fromToken The L1 ERC20 token used for investment (address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) if eth)
    @param isTokenMintable Is From Token Mintable on L2
    @param _fromTokenAmount The amount of fromToken to invest
    @param _pid PoolID of Hybrid Staking Contract on L2
    @param _pairAddress The Uniswap pair address on L2
    @param _toToken Either of the ERC20 token of the pair on L2
    @param _farm Address of Farm on L2 to finally deposit LP to
    @param slippageAdjustedMinLP Minimum acceptable Slippage LP token amount (in L2)
     */
    function crossChainOneSidedFarm(
        address _fromToken,
        bool isTokenMintable,
        uint256 _fromTokenAmount,
        uint256 _pid,
        address _pairAddress,
        address _toToken,
        address _farm,
        uint256 slippageAdjustedMinLP
    ) external payable whenNotPaused{
        require(
            fxChildTunnel != address(0x0),
            "CHILD_TUNNEL_NOT_SET"
        );
        
        bytes memory depositData = abi.encode(_fromTokenAmount);

        if (_fromToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            require(msg.value > 0, "No ETH sent");
            (bool success, ) =
                address(rootChainManager).call{value: msg.value}(
                    abi.encodeWithSignature(
                        "depositEtherFor(address)",
                        fxChildTunnel
                    )
                );
            require(success, "ETH_TRANSFER_FAILED");
            _fromTokenAmount = msg.value;
        }

        else {
            require(_fromTokenAmount > 0, "Invalid token amount");
            require(msg.value == 0, "ETH sent with token");

            //transfer token
            IERC20(_fromToken).safeTransferFrom(msg.sender, address(this), _fromTokenAmount);
            isTokenMintable ? IERC20(_fromToken).approve(mintableERC20Predicate, _fromTokenAmount)
                            : IERC20(_fromToken).approve(erc20Predicate, _fromTokenAmount);
            rootChainManager.depositFor(fxChildTunnel, _fromToken, depositData);
        }

        _sendMessageToChild(
            abi.encode(
                msg.sender,
                _fromToken,
                _fromTokenAmount,
                _pid,
                _pairAddress,
                _toToken,
                _farm,
                slippageAdjustedMinLP,
                block.timestamp
            )
        );
        
        emit InitiatedCrossChainFarming(msg.sender, _fromTokenAmount, block.timestamp);
    }

    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function _processMessageFromChild(bytes memory message) internal override {}
}