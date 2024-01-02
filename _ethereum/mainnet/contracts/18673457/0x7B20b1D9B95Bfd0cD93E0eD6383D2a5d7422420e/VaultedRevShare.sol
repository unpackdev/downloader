// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./Ownable.sol";
import "./IERC20.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./IUniswapV2Router02.sol";
import "./Vaulted.sol";

contract VaultedRevShare is Ownable, ReentrancyGuard, Pausable {

    VaultedFinance public vaultedFinance;

    IUniswapV2Router02 public constant UNISWAP_ROUTER = 
    IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public currentClaimPool;
    uint256 public currentTotalClaims;

    bool public isClaimLive;

    bytes32 public root;
    mapping(bytes32 => bool) public shareClaimed;

    event UserProfitShareClaim(address account, uint256 amount);
    event BurnedTokens(address _user, uint256 _tokensBurned);


    constructor(address _vaultedAddress) {
        vaultedFinance = VaultedFinance(payable(_vaultedAddress));
    }
    

    /**
     * @dev Set contract address
     * 
     * functionality:
     * - associates smart contract address to imported token interface
     */
    function setToken(address _vaultedAddress) external onlyOwner {
        vaultedFinance = VaultedFinance(payable(_vaultedAddress));
    }


    /**
     * @dev Admin override settings
     * 
     * functionality:
     * - overrides root, claim and pool settings
     */
    function setAdminSettings(
        bytes32 _profitShareMerkleRoot, 
        bool _isClaimLive,
        uint256 _poolSize,
        uint256 _totalClaims
    ) external onlyOwner {
        root = _profitShareMerkleRoot;
        isClaimLive = _isClaimLive;
        currentClaimPool = _poolSize;
        currentTotalClaims = _totalClaims;
    }


    /**
     * @dev Sets new claim round
     * 
     * functionality:
     * - records pool size to share amongst holders and sets a live claim environment
     */
    function setClaimRound(bytes32 _newRoot) external onlyOwner {

        uint256 contractBal = address(this).balance;

        root = _newRoot;
        isClaimLive = true;
        currentClaimPool = contractBal;

    }


    /**
     * @dev Finalize claim round
     * 
     * functionality:
     * - finalizes claim round with a buyback and burn on unclaimed revenue shares and resets state
     */
    function finalizeClaimRound() external onlyOwner {
        
        uint256 unclaimedEth = currentClaimPool - currentTotalClaims;

        if(unclaimedEth > 0) buyBackAndBurn(unclaimedEth);

        currentTotalClaims = 0;
        isClaimLive = false;
    }


    /**
     * @dev Manual buyback and burn
     * 
     * functionality:
     * - provides manual function to buyback and burn contract eth (backup function)
     */
    function manualBuyBackAndBurn(uint256 _amountToBurn) external onlyOwner {
        buyBackAndBurn(_amountToBurn);
    }


    /**
     * @dev User revenue share claim
     * 
     * functionality:
     * - verifies both msg.sender along with amount to claim via merkle proof and performs share claim
     */
    function claimShare(
        uint256 _profitShareAmount,
        bytes32[] memory proof
    ) external whenNotPaused nonReentrant {

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _profitShareAmount));

        require(
            address(this).balance >= _profitShareAmount,
            "not enough funds to cover share payout"
        );

        require(
            isClaimLive,
            "claim is not live"
        );

        require(
            !shareClaimed[leaf],
            "profit share already claimed"
        );

        require(
            MerkleProof.verify(proof, root, leaf),
            "invalid proof"
        );

        shareClaimed[leaf] = true;

        currentTotalClaims += _profitShareAmount;
        
        (bool success, ) = address(msg.sender).call{value: _profitShareAmount}("");

        require(
            success,
            "failed to send Eth profit share"
        );

        emit UserProfitShareClaim(msg.sender, _profitShareAmount);
    }


    /**
     * @dev Buyback and burn
     * 
     * functionality:
     * - takes eth amount as param then buys token and burns it (deflationary)
     */
    function buyBackAndBurn(uint256 ethAmount) internal {

        address[] memory path = new address[](2);
        path[0] = UNISWAP_ROUTER.WETH();
        path[1] = address(vaultedFinance);

        uint256[] memory amounts = UNISWAP_ROUTER.swapExactETHForTokens{value: ethAmount}(
            0,
            path,
            address(this),
            block.timestamp + 3600
        );

        require(
            amounts.length > 0 && amounts[amounts.length - 1] > 0,
            "no tokens received"
        );

        uint256 receivedTokens = amounts[amounts.length - 1];

        vaultedFinance.burn(receivedTokens);

        emit BurnedTokens(msg.sender, receivedTokens);
    }


    /**
     * @dev Receive
     * 
     * functionality:
     * - fallback function to enable smart contract to receive ether
     */
    receive() external payable {}

}

