pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./IDola.sol";
import "./IL1ERC20Bridge.sol";
import "./ArbiGasManager.sol";
import "./IL1GatewayRouter.sol";

contract ArbiFed is ArbiGasManager{
    address public chair;
    uint public underlyingSupply;

    IDola public immutable DOLA = IDola(0x865377367054516e17014CcdED1e7d814EDC9ce4);
    IL1GatewayRouter public immutable gatewayRouter = IL1GatewayRouter(0x72Ce9c846789fdB6fC1f34aC4AD25Dd9ef7031ef); 
    IL1GatewayRouter  public immutable gateway = IL1GatewayRouter(0xb4299A1F5f26fF6a98B7BA35572290C359fde900);
    address public immutable l1ERC20Gateway = 0xa3A7B6F88361F48403514059F1F16C8E78d60EeC;

    address public auraFarmer; // On L2

    event Expansion(uint amount);
    event Contraction(uint amount);

    error OnlyChair();
    error OnlyGuardian();
    error CantBurnZeroDOLA();
    error DeltaAboveMax();
    error ZeroGasPriceBid();
    error InsufficientGasFunds();
    
    constructor(
            address _gov,
            address _auraFarmer,
            address _chair,
            address _gasClerk,
            address _l2RefundAddress
    ) ArbiGasManager(_gov, _gasClerk, _l2RefundAddress)
    {
        chair = _chair;
        auraFarmer = _auraFarmer;

        DOLA.approve(address(l1ERC20Gateway), type(uint).max); 
    }

    modifier onlyChair {
        if (msg.sender != chair) revert OnlyChair();
        _;
    }

    /**
     * @notice Mints & deposits `amountToBridge` of DOLA into Arbitrum Gateway to the `auraFarmer` contract
     * @param amountToBridge Amount of underlying token to briged into Aura farmer on Arbitrum
     */
    function expansion(uint amountToBridge) external payable onlyChair {
        if (gasPrice == 0) revert ZeroGasPriceBid();
        if (msg.value < maxSubmissionCost + defaultGasLimit * gasPrice) revert InsufficientGasFunds();
        uint dolaBal = DOLA.balanceOf(address(this));
        if(dolaBal < amountToBridge){
            uint amountToMint = amountToBridge - dolaBal;
            underlyingSupply += amountToMint;
            DOLA.mint(address(this), amountToMint);
            emit Expansion(amountToMint);
        }
        bytes memory data = abi.encode(maxSubmissionCost, "");
        gatewayRouter.outboundTransferCustomRefund{value: msg.value}(
            address(DOLA),
            refundAddress,
            auraFarmer,
            amountToBridge,
            defaultGasLimit, 
            gasPrice, 
            data
        );

    }

    /**
     * @notice Burns `amountUnderlying` of DOLA held in this contract
     * @param amountUnderlying Amount of underlying DOLA to burn
     */
    function contraction(uint amountUnderlying) external onlyChair {

        _contraction(amountUnderlying);
    }

    /**
     * @notice Attempts to contract (burn) all DOLA held by this contract
     */
    function contractAll() external onlyChair {

        _contraction(DOLA.balanceOf(address(this)));
    }

    /**
     * @notice Attempts to contract (burn) `amount` of DOLA. Sends remainder to `gov` if `amount` > DOLA minted by this fed.
     * @param amount Amount to contract
     */
    function _contraction(uint amount) internal {
        if (amount == 0) revert CantBurnZeroDOLA();
        if(amount > underlyingSupply){
            DOLA.burn(underlyingSupply);
            DOLA.transfer(gov, amount - underlyingSupply);
            emit Contraction(underlyingSupply);
            underlyingSupply = 0;
        } else {
            DOLA.burn(amount);
            underlyingSupply -= amount;
            emit Contraction(amount);
        }
    }

    /**
     * @notice Method for current chair of the Arbi FED to resign
     */
    function resign() external onlyChair {
        chair = address(0);
    }

    /**
     * @notice Method for gov to change the chair
     */
    function changeChair(address newChair) external onlyGov {
        chair = newChair;
    }

    /**
     * @notice Method for gov to change the L2 auraFarmer address
     */
    function changeAuraFarmer(address newAuraFarmer) external onlyGov {
        auraFarmer = newAuraFarmer;
    }

    /**
     * @notice Method for gov to withdraw any ERC20 token from this contract
     */
    function emergecyWithdraw(address token, address to, uint256 amount) external onlyGov {
        IERC20(token).transfer(to, amount);
    }
    
}
